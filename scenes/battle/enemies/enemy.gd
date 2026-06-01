extends CharacterBody2D
## 敌人控制器
## 支持多种行为模式：冲锋/远程/环绕/分裂/冲刺/坦克
## 死亡时掉落经验宝石 + 播放死亡动画

@onready var sprite: Sprite2D = $Sprite

var speed: float = 80.0
var hp: float = 20.0
var max_hp: float = 20.0
var damage: float = 5.0
var exp_value: int = 1
var player_ref: Node2D = null
var is_dead: bool = false

## 行为类型
var behavior: EnemyData.BehaviorType = EnemyData.BehaviorType.CHARGE

## 碰撞伤害冷却
var _damage_cooldown: float = 0.0
const DAMAGE_INTERVAL: float = 0.5

## 受击闪白
var _flash_timer: float = 0.0

## 远程攻击
var _attack_cooldown: float = 0.0
var _attack_interval: float = 2.0
var _attack_range: float = 180.0
var _projectile_speed: float = 200.0

## 环绕
var _circle_angle: float = 0.0
var _circle_radius: float = 120.0
var _circle_shrink_speed: float = 8.0

## 冲刺
var _dash_timer: float = 0.0
var _dash_interval: float = 3.0
var _dash_duration: float = 0.4
var _dash_speed_mult: float = 3.0
var _is_dashing: bool = false
var _dash_elapsed: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO

## 分裂
var _split_count: int = 2
var _split_hp_ratio: float = 0.3
var _is_split_child: bool = false

## 减速状态（被队友施加）
var _slow_timer: float = 0.0
var _slow_mult: float = 1.0

## 中毒状态
var _poison_timer: float = 0.0
var _poison_dps: float = 0.0

## 预加载
var _exp_gem_scene: PackedScene = preload("res://scenes/battle/pickups/exp_gem.tscn")
var _damage_number_scene: PackedScene = preload("res://scenes/battle/effects/damage_number.tscn")
var _projectile_scene: PackedScene = preload("res://scenes/battle/projectiles/projectile.tscn")


func _ready() -> void:
	# 默认占位纹理（如果 initialize 没被调用）
	if sprite and not sprite.texture:
		sprite.texture = PlaceholderTexture.outlined_circle(12, Color(0.8, 0.2, 0.2), Color(0.3, 0.0, 0.0))
		sprite.scale = Vector2(1.0, 1.0)
		sprite.modulate = Color.WHITE


func initialize(data: EnemyData, player: Node2D, difficulty_mult: float = 1.0) -> void:
	player_ref = player
	if not data:
		return
	behavior = data.behavior
	speed = data.speed
	hp = data.base_hp * difficulty_mult
	max_hp = hp
	damage = data.base_damage * difficulty_mult
	exp_value = data.exp_drop

	# 占位纹理：红色圆形
	if sprite and not sprite.texture:
		var radius := int(12 * data.scale_mult)
		sprite.texture = PlaceholderTexture.outlined_circle(radius, data.color, Color(0.3, 0.0, 0.0))
		sprite.scale = Vector2(1.0, 1.0)
		sprite.modulate = Color.WHITE

	# 行为专用参数
	match behavior:
		EnemyData.BehaviorType.RANGED:
			_projectile_speed = data.projectile_speed
			_attack_range = data.attack_range
			_attack_interval = data.attack_interval
			_attack_cooldown = randf() * _attack_interval
		EnemyData.BehaviorType.CIRCLE:
			_circle_angle = randf() * TAU
			_circle_radius = 120.0 + randf_range(-20.0, 20.0)
		EnemyData.BehaviorType.SPLIT:
			_split_count = data.split_count
			_split_hp_ratio = data.split_hp_ratio
		EnemyData.BehaviorType.DASH:
			_dash_interval = data.dash_interval
			_dash_duration = data.dash_duration
			_dash_speed_mult = data.dash_speed_mult
			_dash_timer = randf() * _dash_interval
		EnemyData.BehaviorType.TANK:
			# 坦克更大：用更大的纹理
			if sprite:
				sprite.texture = PlaceholderTexture.outlined_circle(int(18 * data.scale_mult), data.color, Color(0.3, 0.0, 0.0))
				sprite.scale = Vector2(1.0, 1.0)


func _physics_process(delta: float) -> void:
	if is_dead or not player_ref:
		return

	# 状态效果
	_process_status_effects(delta)

	# 根据行为类型执行不同 AI
	var effective_speed := speed * _slow_mult
	match behavior:
		EnemyData.BehaviorType.CHARGE:
			_behavior_charge(effective_speed)
		EnemyData.BehaviorType.RANGED:
			_behavior_ranged(delta, effective_speed)
		EnemyData.BehaviorType.CIRCLE:
			_behavior_circle(delta, effective_speed)
		EnemyData.BehaviorType.SPLIT:
			_behavior_charge(effective_speed)  # 分裂怪移动方式同冲锋
		EnemyData.BehaviorType.DASH:
			_behavior_dash(delta, effective_speed)
		EnemyData.BehaviorType.TANK:
			_behavior_charge(effective_speed * 0.6)  # 坦克更慢

	move_and_slide()

	# 碰撞伤害检测
	_damage_cooldown -= delta
	if _damage_cooldown <= 0.0:
		_check_player_collision()

	# 闪白恢复
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE


## --- 行为实现 ---

func _behavior_charge(spd: float) -> void:
	var direction := global_position.direction_to(player_ref.global_position)
	velocity = direction * spd


func _behavior_ranged(delta: float, spd: float) -> void:
	var dist := global_position.distance_to(player_ref.global_position)
	var direction := global_position.direction_to(player_ref.global_position)

	# 保持距离
	if dist > _attack_range * 0.8:
		velocity = direction * spd
	elif dist < _attack_range * 0.5:
		velocity = -direction * spd * 0.6  # 后退
	else:
		# 横向移动
		velocity = direction.rotated(PI * 0.5) * spd * 0.4

	# 远程攻击
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0 and dist <= _attack_range:
		_fire_at_player()
		_attack_cooldown = _attack_interval


func _behavior_circle(delta: float, spd: float) -> void:
	_circle_angle += delta * (spd / _circle_radius)
	_circle_radius -= _circle_shrink_speed * delta  # 慢慢靠近
	_circle_radius = maxf(_circle_radius, 30.0)

	var target_pos := player_ref.global_position + Vector2(
		cos(_circle_angle) * _circle_radius,
		sin(_circle_angle) * _circle_radius
	)
	var direction := global_position.direction_to(target_pos)
	velocity = direction * spd * 1.2


func _behavior_dash(delta: float, spd: float) -> void:
	if _is_dashing:
		_dash_elapsed += delta
		velocity = _dash_direction * spd * _dash_speed_mult
		if _dash_elapsed >= _dash_duration:
			_is_dashing = false
			_dash_timer = _dash_interval
	else:
		# 普通移动
		var direction := global_position.direction_to(player_ref.global_position)
		velocity = direction * spd * 0.7

		_dash_timer -= delta
		if _dash_timer <= 0.0:
			# 开始冲刺
			_is_dashing = true
			_dash_elapsed = 0.0
			_dash_direction = global_position.direction_to(player_ref.global_position)
			# 冲刺预警：短暂变红
			if sprite:
				sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
				_flash_timer = _dash_duration


## --- 远程攻击 ---

func _fire_at_player() -> void:
	var proj := _projectile_scene.instantiate() as Projectile
	proj.global_position = global_position
	proj.direction = global_position.direction_to(player_ref.global_position)
	proj.damage = damage
	proj.speed = _projectile_speed
	proj.max_distance = _attack_range + 50.0
	# 敌人弹道用红色
	var proj_sprite := proj.get_node_or_null("Sprite") as Sprite2D
	if proj_sprite:
		proj_sprite.modulate = Color(1.0, 0.3, 0.2, 1.0)
	# 敌人弹道碰撞层改为打玩家
	proj.collision_mask = 1  # 玩家层
	get_tree().current_scene.add_child(proj)


## --- 碰撞 ---

func _check_player_collision() -> void:
	var distance := global_position.distance_to(player_ref.global_position)
	if distance < 32.0:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)
			_damage_cooldown = DAMAGE_INTERVAL


## --- 状态效果 ---

func _process_status_effects(delta: float) -> void:
	# 减速
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_mult = 1.0

	# 中毒
	if _poison_timer > 0.0:
		_poison_timer -= delta
		hp -= _poison_dps * delta
		# 中毒视觉：绿色闪烁
		if sprite and fmod(_poison_timer, 0.4) < 0.2:
			sprite.modulate = Color(0.3, 0.9, 0.2, 1.0)
		if hp <= 0.0:
			_die()


func apply_slow(percent: float, duration: float) -> void:
	_slow_mult = 1.0 - percent
	_slow_timer = duration


func apply_poison(dps: float, duration: float) -> void:
	_poison_dps = dps
	_poison_timer = duration


func apply_knockback(direction: Vector2, force: float) -> void:
	global_position += direction * force * 0.1


## --- 受伤 ---

func take_damage(amount: float) -> void:
	if is_dead:
		return
	hp -= amount

	# 受击闪白
	if sprite:
		sprite.modulate = Color(10.0, 10.0, 10.0, 1.0)
		_flash_timer = 0.06

	# 伤害飘字
	_spawn_damage_number(amount)

	if hp <= 0.0:
		_die()


func _spawn_damage_number(value: float) -> void:
	var dmg_num := _damage_number_scene.instantiate() as DamageNumber
	dmg_num.value = value
	dmg_num.global_position = global_position + Vector2(0, -20)
	get_tree().current_scene.add_child(dmg_num)


## --- 死亡 ---

func _die() -> void:
	is_dead = true

	# 分裂逻辑
	if behavior == EnemyData.BehaviorType.SPLIT and not _is_split_child:
		_spawn_split_children()

	# 掉落经验宝石
	_drop_exp_gems()

	# 通知战斗场景
	var battle := get_tree().current_scene
	if battle and battle.has_method("on_enemy_killed"):
		battle.on_enemy_killed(self, 0)

	# 死亡动画
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(0.05, 0.05), 0.15)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)

	# 停止移动和碰撞
	set_physics_process(false)
	var col := get_node_or_null("CollisionShape") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)


func _spawn_split_children() -> void:
	var enemy_scene := preload("res://scenes/battle/enemies/enemy.tscn")
	for i: int in _split_count:
		var child := enemy_scene.instantiate()
		var angle := (float(i) / float(_split_count)) * TAU
		child.global_position = global_position + Vector2(cos(angle), sin(angle)) * 20.0
		child.player_ref = player_ref
		child.hp = max_hp * _split_hp_ratio
		child.max_hp = child.hp
		child.damage = damage * 0.6
		child.speed = speed * 1.3
		child.exp_value = maxi(exp_value / 2, 1)
		child._is_split_child = true
		child.behavior = EnemyData.BehaviorType.CHARGE
		# 分裂子体更小
		child.add_to_group("enemies")
		get_tree().current_scene.get_node("Enemies").add_child(child)
		# 视觉：更小的红色圆
		var child_sprite := child.get_node_or_null("Sprite") as Sprite2D
		if child_sprite:
			child_sprite.texture = PlaceholderTexture.outlined_circle(8, Color(0.6, 0.15, 0.15), Color(0.2, 0.0, 0.0))
			child_sprite.scale = Vector2(1.0, 1.0)
			child_sprite.modulate = Color.WHITE


func _drop_exp_gems() -> void:
	var gem_count := 1
	if exp_value >= 5:
		gem_count = 2
	if exp_value >= 10:
		gem_count = 3

	var per_gem := maxi(exp_value / gem_count, 1)
	for i: int in gem_count:
		var gem := _exp_gem_scene.instantiate() as ExpGem
		gem.exp_value = per_gem
		gem.global_position = global_position
		get_tree().current_scene.add_child(gem)

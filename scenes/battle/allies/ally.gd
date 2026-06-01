class_name Ally
extends CharacterBody2D
## 队友鱼人控制器
## 自动跟随主角（阵型站位）+ 自动攻击最近敌人
## 支持多种特殊效果：穿透/减速/中毒/击退/治疗/爆炸/连锁

signal star_upgraded(new_star: int)

@export var ally_data: AllyData

@onready var sprite: Sprite2D = $Sprite

var star_level: int = 1  ## 1★ / 2★ / 3★
var damage: float = 8.0
var attack_interval: float = 1.0
var attack_range: float = 120.0
var preferred_distance: float = 80.0
var follow_speed: float = 280.0
var player_ref: Node2D = null

## 阵型相关
var formation_index: int = 0
var formation_offset: Vector2 = Vector2.ZERO

## 攻击相关
var _attack_cooldown: float = 0.0
var _target: Node2D = null
var _target_search_timer: float = 0.0
const TARGET_SEARCH_INTERVAL: float = 0.25

## 治疗光环
var _heal_timer: float = 0.0

## 视觉
var _flash_timer: float = 0.0

## 弹道
var _projectile_scene: PackedScene = preload("res://scenes/battle/projectiles/projectile.tscn")


func initialize(data: AllyData, player: Node2D, index: int) -> void:
	ally_data = data
	player_ref = player
	formation_index = index
	if not data:
		return

	damage = data.base_damage
	attack_interval = data.attack_interval
	attack_range = 120.0
	preferred_distance = data.preferred_distance

	# 根据攻击类型调整行为
	match data.attack_type:
		AllyData.AttackType.MELEE:
			attack_range = 48.0
			preferred_distance = 40.0
			follow_speed = 320.0
		AllyData.AttackType.RANGED:
			attack_range = 150.0
			preferred_distance = 90.0
		AllyData.AttackType.SUPPORT:
			attack_range = 200.0
			preferred_distance = 60.0
		AllyData.AttackType.TRAP:
			attack_range = 100.0
			preferred_distance = 50.0
		AllyData.AttackType.AOE:
			attack_range = 80.0
			preferred_distance = 60.0
		AllyData.AttackType.CHAIN:
			attack_range = 160.0
			preferred_distance = 85.0

	# 占位纹理：绿色圆形带白边
	if sprite and not sprite.texture:
		sprite.texture = PlaceholderTexture.outlined_circle(16, data.color, Color(1.0, 1.0, 1.0, 0.8))
		sprite.scale = Vector2(1.0, 1.0)
		sprite.modulate = Color.WHITE

	_update_formation_offset()
	_attack_cooldown = randf() * attack_interval


func _physics_process(delta: float) -> void:
	if not player_ref:
		return

	_follow_player(delta)
	_update_attack(delta)
	_update_heal_aura(delta)
	_update_visual(delta)


func _follow_player(_delta: float) -> void:
	var target_pos := player_ref.global_position + formation_offset
	var to_target := target_pos - global_position
	var distance := to_target.length()

	if distance > 300.0:
		global_position = target_pos
		velocity = Vector2.ZERO
	elif distance > 16.0:
		var speed_mult := clampf(distance / preferred_distance, 0.5, 2.0)
		velocity = to_target.normalized() * follow_speed * speed_mult
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.15)

	move_and_slide()


func _update_attack(delta: float) -> void:
	_attack_cooldown -= delta

	_target_search_timer -= delta
	if _target_search_timer <= 0.0:
		_target_search_timer = TARGET_SEARCH_INTERVAL
		_find_target()

	if _attack_cooldown <= 0.0 and _target and is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		if dist <= attack_range:
			_perform_attack()
			_attack_cooldown = attack_interval
		else:
			_target = null


func _update_heal_aura(delta: float) -> void:
	if not ally_data:
		return
	if ally_data.special_effect != AllyData.SpecialEffect.HEAL_AURA:
		return
	_heal_timer -= delta
	if _heal_timer <= 0.0:
		_heal_timer = ally_data.heal_interval
		if player_ref and player_ref.has_method("heal"):
			player_ref.heal(ally_data.heal_amount * star_level)


func _find_target() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		_target = null
		return

	var nearest: Node2D = null
	var nearest_dist := attack_range * 1.5
	for enemy: Node2D in enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	_target = nearest


func _perform_attack() -> void:
	if not _target or not is_instance_valid(_target):
		return

	# 攻击视觉反馈
	if sprite:
		sprite.scale = Vector2(1.3, 1.3)
		_flash_timer = 0.08

	if not ally_data:
		_fire_projectile_basic()
		return

	match ally_data.attack_type:
		AllyData.AttackType.MELEE:
			_attack_melee()
		AllyData.AttackType.AOE:
			_attack_aoe()
		AllyData.AttackType.CHAIN:
			_attack_chain()
		_:
			_fire_projectile_with_effect()


func _attack_melee() -> void:
	if not _target or not _target.has_method("take_damage"):
		return
	_target.take_damage(damage)
	_apply_special_effect_to(_target)


func _attack_aoe() -> void:
	## 对范围内所有敌人造成伤害
	var enemies := get_tree().get_nodes_in_group("enemies")
	var hit_count: int = 0
	for enemy: Node2D in enemies:
		if hit_count >= 5:
			break
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= attack_range and enemy.has_method("take_damage"):
			enemy.take_damage(damage * 0.7)
			_apply_special_effect_to(enemy)
			hit_count += 1


func _attack_chain() -> void:
	## 连锁攻击：从目标开始弹射到附近敌人
	var chain_count: int = ally_data.chain_targets if ally_data else 3
	var hit_targets: Array[Node2D] = []
	var current_target := _target

	for i: int in chain_count:
		if not current_target or not is_instance_valid(current_target):
			break
		if current_target.has_method("take_damage"):
			var chain_damage := damage * (1.0 - i * 0.15)  # 每次弹射衰减 15%
			current_target.take_damage(chain_damage)
			_apply_special_effect_to(current_target)
			hit_targets.append(current_target)

		# 找下一个最近的未命中目标
		current_target = _find_next_chain_target(current_target, hit_targets)

	# 连锁视觉：发射弹道到第一个目标
	_fire_projectile_basic()


func _find_next_chain_target(from: Node2D, exclude: Array[Node2D]) -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := 100.0  # 连锁范围
	for enemy: Node2D in enemies:
		if enemy in exclude:
			continue
		var dist := from.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _fire_projectile_with_effect() -> void:
	if not _target or not is_instance_valid(_target):
		return
	var proj := _projectile_scene.instantiate() as Projectile
	proj.global_position = global_position
	proj.direction = global_position.direction_to(_target.global_position)
	proj.damage = damage
	proj.speed = 350.0
	proj.max_distance = attack_range + 30.0

	# 穿透效果
	if ally_data and ally_data.special_effect == AllyData.SpecialEffect.PIERCE:
		proj.pierce_count = ally_data.pierce_count * star_level

	# 弹道颜色
	var proj_sprite := proj.get_node_or_null("Sprite") as Sprite2D
	if proj_sprite:
		proj_sprite.modulate = _get_projectile_color()

	get_tree().current_scene.add_child(proj)

	# 非穿透效果需要在命中时触发（通过信号或直接在 projectile 里处理）
	# 简化处理：直接对目标施加效果
	if ally_data and ally_data.special_effect != AllyData.SpecialEffect.PIERCE:
		_apply_special_effect_to(_target)


func _fire_projectile_basic() -> void:
	if not _target or not is_instance_valid(_target):
		return
	var proj := _projectile_scene.instantiate() as Projectile
	proj.global_position = global_position
	proj.direction = global_position.direction_to(_target.global_position)
	proj.damage = damage
	proj.speed = 350.0
	proj.max_distance = attack_range + 30.0
	var proj_sprite := proj.get_node_or_null("Sprite") as Sprite2D
	if proj_sprite:
		proj_sprite.modulate = _get_projectile_color()
	get_tree().current_scene.add_child(proj)


func _apply_special_effect_to(target: Node2D) -> void:
	if not ally_data or not target or not is_instance_valid(target):
		return
	match ally_data.special_effect:
		AllyData.SpecialEffect.SLOW:
			if target.has_method("apply_slow"):
				target.apply_slow(ally_data.slow_percent, ally_data.slow_duration)
		AllyData.SpecialEffect.POISON:
			if target.has_method("apply_poison"):
				target.apply_poison(ally_data.poison_dps * star_level, ally_data.poison_duration)
		AllyData.SpecialEffect.KNOCKBACK:
			if target.has_method("apply_knockback"):
				var dir := global_position.direction_to(target.global_position)
				target.apply_knockback(dir, ally_data.knockback_force)
		AllyData.SpecialEffect.EXPLODE:
			_do_explode_at(target.global_position)
		_:
			pass


func _do_explode_at(pos: Vector2) -> void:
	var radius := ally_data.explode_radius if ally_data else 60.0
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node2D in enemies:
		var dist := pos.distance_to(enemy.global_position)
		if dist <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage * 0.5)


func _get_projectile_color() -> Color:
	if not ally_data:
		return Color(1.0, 0.8, 0.3, 1.0)
	match ally_data.special_effect:
		AllyData.SpecialEffect.SLOW:
			return Color(0.3, 0.6, 1.0, 1.0)  # 冰蓝
		AllyData.SpecialEffect.POISON:
			return Color(0.2, 0.9, 0.3, 1.0)  # 毒绿
		AllyData.SpecialEffect.PIERCE:
			return Color(1.0, 0.9, 0.2, 1.0)  # 金黄
		AllyData.SpecialEffect.EXPLODE:
			return Color(1.0, 0.4, 0.1, 1.0)  # 火红
		AllyData.SpecialEffect.CHAIN_LIGHTNING:
			return Color(0.6, 0.3, 1.0, 1.0)  # 紫电
		AllyData.SpecialEffect.KNOCKBACK:
			return Color(0.8, 0.8, 0.8, 1.0)  # 银白
		_:
			return ally_data.color


func _update_visual(delta: float) -> void:
	if not sprite:
		return
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			sprite.scale = Vector2(1.0, 1.0)


func _update_formation_offset() -> void:
	var ring: int = 0
	var index_in_ring: int = formation_index
	var ring_capacity: int = 6

	while index_in_ring >= ring_capacity:
		index_in_ring -= ring_capacity
		ring += 1
		ring_capacity = 6 * (ring + 1)

	var ring_radius := preferred_distance + ring * 40.0
	var angle := (float(index_in_ring) / float(ring_capacity)) * TAU
	angle += ring * 0.5
	formation_offset = Vector2(cos(angle), sin(angle)) * ring_radius


func upgrade_star() -> void:
	if star_level >= 3:
		return
	star_level += 1
	_apply_star_bonus()
	star_upgraded.emit(star_level)


func _apply_star_bonus() -> void:
	match star_level:
		2:
			damage *= 1.5
			attack_interval *= 0.85
			if sprite:
				sprite.modulate = sprite.modulate.lightened(0.2)
		3:
			damage *= 1.5
			attack_interval *= 0.8
			attack_range *= 1.3
			if sprite:
				sprite.modulate = sprite.modulate.lightened(0.3)


func update_formation_index(new_index: int) -> void:
	formation_index = new_index
	_update_formation_offset()

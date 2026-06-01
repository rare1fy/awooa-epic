class_name Player
extends CharacterBody2D
## 玩家角色控制器
## 处理移动输入、自动攻击（发射弹道）、受伤、死亡、大招

signal hp_changed(current: float, max_hp: float)
signal ultimate_ready
signal died

@export var character_data: CharacterData

var max_hp: float = 120.0
var current_hp: float = 120.0
var speed: float = 180.0
var damage: float = 12.0
var attack_range: float = 160.0
var ultimate_energy: float = 0.0
var ultimate_max: float = 100.0
var is_dead: bool = false

## 虚拟摇杆输入方向（由 UI 层设置）
var input_direction: Vector2 = Vector2.ZERO

## 攻击相关
var _attack_cooldown: float = 0.0
var _attack_interval: float = 0.5
var _projectile_scene: PackedScene = preload("res://scenes/battle/projectiles/projectile.tscn")

## 大招
var _ultimate_active: bool = false

## 受伤闪烁
var _flash_timer: float = 0.0

## 受伤无敌帧
var _invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 0.15

## 当前朝向（用于动画）
var _facing: String = "south"

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	if character_data:
		max_hp = character_data.base_hp
		current_hp = max_hp
		speed = character_data.base_speed
		damage = character_data.base_damage
		_attack_interval = character_data.attack_interval


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 移动
	velocity = input_direction * speed
	move_and_slide()

	# 动画方向切换
	_update_animation()

	# 自动攻击
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_try_attack()
		_attack_cooldown = _attack_interval

	# 无敌帧
	if _invincible_timer > 0.0:
		_invincible_timer -= delta

	# 受伤闪烁恢复
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			sprite.modulate = Color.WHITE


func _try_attack() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var nearest: Node2D = null
	var nearest_dist := attack_range
	for enemy: Node2D in enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	if not nearest:
		return

	# 发射弹道
	_fire_projectile(nearest)
	add_ultimate_energy(3.0)


func _fire_projectile(target: Node2D) -> void:
	var proj := _projectile_scene.instantiate() as Projectile
	proj.global_position = global_position
	proj.direction = global_position.direction_to(target.global_position)
	proj.damage = damage
	proj.speed = 450.0
	proj.max_distance = attack_range + 50.0
	proj.pierce_count = 0
	# 弹道颜色跟随主角
	var proj_sprite := proj.get_node_or_null("Sprite") as Sprite2D
	if proj_sprite:
		proj_sprite.modulate = Color(0.4, 0.8, 1.0, 1.0)
	get_tree().current_scene.add_child(proj)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	if _invincible_timer > 0.0:
		return

	current_hp -= amount
	current_hp = maxf(current_hp, 0.0)
	hp_changed.emit(current_hp, max_hp)

	# 无敌帧
	_invincible_timer = INVINCIBLE_DURATION

	# 受伤闪烁
	sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
	_flash_timer = 0.1

	if current_hp <= 0.0:
		_die()


func heal(amount: float) -> void:
	current_hp = minf(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)


func add_ultimate_energy(amount: float) -> void:
	ultimate_energy = minf(ultimate_energy + amount, ultimate_max)
	if ultimate_energy >= ultimate_max:
		_trigger_ultimate()


func _trigger_ultimate() -> void:
	if _ultimate_active:
		return
	_ultimate_active = true
	ultimate_energy = 0.0
	ultimate_ready.emit()

	# 大招效果：全屏 AOE，对范围内所有敌人造成大量伤害
	var ult_damage := damage * 5.0
	var ult_range := 250.0
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node2D in enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= ult_range and enemy.has_method("take_damage"):
			enemy.take_damage(ult_damage)

	# 屏幕震动
	var battle := get_tree().current_scene
	if battle and battle.has_method("shake_camera"):
		battle.shake_camera(6.0, 5.0)

	# 大招视觉：短暂放大 + 闪白
	sprite.scale = Vector2(1.5, 1.5)
	sprite.modulate = Color(2.0, 2.0, 3.0, 1.0)

	# 用 tween 恢复
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	tween.tween_callback(func() -> void: _ultimate_active = false)


func _update_animation() -> void:
	if input_direction == Vector2.ZERO:
		# 停止时播放 idle（保持最后朝向的第一帧）
		if sprite.animation != &"idle":
			sprite.play(&"idle")
		return

	# 判断主方向
	var new_facing := _facing
	if absf(input_direction.x) > absf(input_direction.y):
		# 水平为主
		if input_direction.x > 0:
			new_facing = "east"
		else:
			new_facing = "west"
	else:
		# 垂直为主
		if input_direction.y > 0:
			new_facing = "south"
		else:
			new_facing = "north"

	# 处理翻转（east 用 west 动画 + flip_h）
	if new_facing == "east":
		sprite.flip_h = true
		if _facing != "east" or not sprite.is_playing():
			sprite.play(&"walk_east")
	else:
		sprite.flip_h = false
		var anim_name := &"walk_" + new_facing
		if _facing != new_facing or not sprite.is_playing():
			sprite.play(anim_name)

	_facing = new_facing


func _die() -> void:
	is_dead = true
	died.emit()
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
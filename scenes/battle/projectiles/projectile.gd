class_name Projectile
extends Area2D
## 通用弹道
## 支持：直线 / 穿透 / 追踪(homing) / 回旋(boomerang)

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 10.0
var max_distance: float = 300.0
var pierce_count: int = 0  ## 穿透次数（0=碰到就消失，999=持续穿透）
var _traveled: float = 0.0
var _pierced: int = 0

## 追踪
var _homing: bool = false
var _homing_target: Node2D = null
## 回旋
var _boomerang: bool = false
var _returning: bool = false
var _origin: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_homing = bool(get_meta("homing", false)) if has_meta("homing") else false
	_boomerang = bool(get_meta("boomerang", false)) if has_meta("boomerang") else false
	_origin = (get_meta("origin_ref") as Node2D) if has_meta("origin_ref") else null
	# 占位纹理：小方块
	var proj_sprite := get_node_or_null("Sprite") as Sprite2D
	if proj_sprite and not proj_sprite.texture:
		proj_sprite.texture = PlaceholderTexture.square(6, Color.WHITE)
		proj_sprite.scale = Vector2(1.0, 1.0)

func _physics_process(delta: float) -> void:
	if _homing:
		_update_homing(delta)
	elif _boomerang:
		_update_boomerang(delta)

	var move := direction * speed * delta
	global_position += move
	_traveled += move.length()

	if _boomerang:
		# 回旋：飞到最远处后掉头回原点
		if not _returning and _traveled >= max_distance:
			_returning = true
		if _returning and is_instance_valid(_origin):
			if global_position.distance_to(_origin.global_position) < 24.0:
				queue_free()
		return

	if _traveled >= max_distance:
		queue_free()

func _update_homing(delta: float) -> void:
	if not is_instance_valid(_homing_target):
		_homing_target = _find_target()
	if is_instance_valid(_homing_target):
		var want := global_position.direction_to(_homing_target.global_position)
		direction = direction.lerp(want, delta * 5.0).normalized()

func _update_boomerang(_delta: float) -> void:
	if _returning and is_instance_valid(_origin):
		direction = global_position.direction_to(_origin.global_position)

func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var best := 600.0
	for e: Node2D in enemies:
		var d := global_position.distance_to(e.global_position)
		if d < best:
			best = d
			nearest = e
	return nearest

func _on_body_entered(body: Node2D) -> void:
	# 打敌人（玩家弹道）
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		_pierced += 1
		if _pierced > pierce_count:
			queue_free()
	# 打玩家（敌人弹道）
	elif body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

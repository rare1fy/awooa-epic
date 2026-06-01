class_name Projectile
extends Area2D
## 通用弹道
## 从发射点飞向目标方向，碰到敌人造成伤害后消失

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 10.0
var max_distance: float = 300.0
var pierce_count: int = 0  ## 穿透次数（0=碰到就消失）
var _traveled: float = 0.0
var _pierced: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 占位纹理：小方块
	var proj_sprite := get_node_or_null("Sprite") as Sprite2D
	if proj_sprite and not proj_sprite.texture:
		proj_sprite.texture = PlaceholderTexture.square(6, Color.WHITE)
		proj_sprite.scale = Vector2(1.0, 1.0)


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	global_position += move
	_traveled += move.length()
	if _traveled >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# 打敌人（玩家/队友弹道）
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		_pierced += 1
		if _pierced > pierce_count:
			queue_free()
	# 打玩家（敌人弹道）
	elif body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

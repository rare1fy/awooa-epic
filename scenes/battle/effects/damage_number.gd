class_name DamageNumber
extends Node2D
## 伤害飘字
## 从生成位置向上飘动并淡出

var value: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 0.6
var _elapsed: float = 0.0

@onready var label: Label = $Label


func _ready() -> void:
	_velocity = Vector2(randf_range(-20.0, 20.0), -60.0)
	if label:
		label.text = str(int(value))
		if value >= 50.0:
			label.modulate = Color(1.0, 0.3, 0.1, 1.0)
			label.scale = Vector2(1.3, 1.3)
		elif value >= 20.0:
			label.modulate = Color(1.0, 0.8, 0.2, 1.0)
		else:
			label.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _process(delta: float) -> void:
	_elapsed += delta
	global_position += _velocity * delta
	_velocity.y += 80.0 * delta  # 轻微重力

	var progress := _elapsed / _lifetime
	if label:
		label.modulate.a = 1.0 - progress

	if _elapsed >= _lifetime:
		queue_free()

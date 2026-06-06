class_name VirtualJoystick
extends Control
## 虚拟摇杆
## 支持触摸 + 鼠标拖拽（PC调试用）

signal direction_changed(direction: Vector2)

@export var dead_zone: float = 0.2
@export var max_radius: float = 60.0

var _is_active: bool = false
var _center: Vector2 = Vector2.ZERO
var _current_direction: Vector2 = Vector2.ZERO

@onready var _base: Control = $Base
@onready var _knob: Control = $Base/Knob
@onready var _bg_visual: TextureRect = $Base/Background
@onready var _knob_visual: TextureRect = $Base/Knob/KnobVisual


func _ready() -> void:
	_base.visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	# 程序化圆形纹理：内外都是圆形，低透明度
	_bg_visual.texture = PlaceholderTexture.circle(64, Color(1, 1, 1, 1))
	_bg_visual.modulate = Color(1, 1, 1, 0.18)
	_knob_visual.texture = PlaceholderTexture.circle(32, Color(1, 1, 1, 1))
	_knob_visual.modulate = Color(1, 1, 1, 0.32)


func _input(event: InputEvent) -> void:
	# 触摸支持
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _is_in_touch_zone(touch.position):
			_activate(touch.position)
		elif not touch.pressed and _is_active:
			_deactivate()

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _is_active:
			_update_direction(drag.position)

	# 鼠标支持（PC调试）
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed and _is_in_touch_zone(mouse.position):
				_activate(mouse.position)
			elif not mouse.pressed and _is_active:
				_deactivate()

	elif event is InputEventMouseMotion:
		if _is_active:
			_update_direction((event as InputEventMouseMotion).position)


func _is_in_touch_zone(pos: Vector2) -> bool:
	# 左半屏为摇杆触摸区
	return pos.x < get_viewport_rect().size.x * 0.6


func _activate(pos: Vector2) -> void:
	_is_active = true
	_center = pos
	_base.global_position = _center - _base.size / 2.0
	_base.visible = true


func _update_direction(pos: Vector2) -> void:
	var delta := pos - _center
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius

	_knob.position = _base.size / 2.0 + delta

	var normalized := delta / max_radius
	if normalized.length() < dead_zone:
		_current_direction = Vector2.ZERO
	else:
		var strength := (normalized.length() - dead_zone) / (1.0 - dead_zone)
		_current_direction = normalized.normalized() * strength

	direction_changed.emit(_current_direction)


func _deactivate() -> void:
	_is_active = false
	_base.visible = false
	_knob.position = _base.size / 2.0
	_current_direction = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)

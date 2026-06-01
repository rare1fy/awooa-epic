class_name ExpGem
extends Area2D
## 经验宝石
## 敌人死亡后掉落，玩家靠近自动吸取

var exp_value: int = 1
var _state: int = 0  ## 0=idle, 1=attracted, 2=collected
var _attract_target: Node2D = null
var _attract_speed: float = 0.0
const ATTRACT_RADIUS: float = 80.0
const ATTRACT_ACCEL: float = 1200.0
const MAX_ATTRACT_SPEED: float = 600.0
const COLLECT_RADIUS: float = 16.0

## 掉落动画
var _drop_velocity: Vector2 = Vector2.ZERO
var _drop_timer: float = 0.0
const DROP_DURATION: float = 0.3


func _ready() -> void:
	# 占位纹理：蓝色菱形
	var gem_sprite := get_node_or_null("Sprite") as Sprite2D
	if gem_sprite and not gem_sprite.texture:
		gem_sprite.texture = PlaceholderTexture.diamond(10, Color(0.3, 0.7, 1.0))
		gem_sprite.scale = Vector2(1.0, 1.0)
		gem_sprite.modulate = Color.WHITE

	# 随机掉落方向
	var angle := randf() * TAU
	_drop_velocity = Vector2(cos(angle), sin(angle)) * randf_range(30.0, 60.0)
	_drop_timer = DROP_DURATION
	add_to_group("exp_gems")


func _physics_process(delta: float) -> void:
	match _state:
		0:  # idle
			# 掉落动画
			if _drop_timer > 0.0:
				_drop_timer -= delta
				global_position += _drop_velocity * delta
				_drop_velocity *= 0.85
			# 检测玩家距离
			_check_player_proximity()
		1:  # attracted
			if not _attract_target or not is_instance_valid(_attract_target):
				_state = 0
				return
			var dir := global_position.direction_to(_attract_target.global_position)
			_attract_speed = minf(_attract_speed + ATTRACT_ACCEL * delta, MAX_ATTRACT_SPEED)
			global_position += dir * _attract_speed * delta
			# 到达玩家
			if global_position.distance_to(_attract_target.global_position) < COLLECT_RADIUS:
				_collect()


func _check_player_proximity() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	var dist := global_position.distance_to(player.global_position)
	if dist < ATTRACT_RADIUS:
		_state = 1
		_attract_target = player
		_attract_speed = 100.0


func _collect() -> void:
	_state = 2
	# 通知战斗场景加经验
	var battle := get_tree().current_scene
	if battle and battle.has_method("add_exp"):
		battle.add_exp(exp_value)
	queue_free()


## 经验磁铁：强制吸引到指定位置
func attract_to(target_pos: Vector2) -> void:
	if _state == 2:
		return
	if _state == 0:
		_state = 1
		_attract_speed = 200.0
	# 找到玩家作为吸引目标
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_attract_target = players[0]

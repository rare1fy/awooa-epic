class_name Pickup
extends Area2D
## 通用地图拾取道具：金币 / 回血 / 宝箱
## 复用经验宝石的掉落动画 + 玩家靠近自动吸取逻辑

enum Kind { COIN, HEAL, CHEST }

@export var kind: Kind = Kind.COIN
## 数值含义随类型变化：COIN=金币数，HEAL=回血量，CHEST 忽略
var value: int = 10

var _state: int = 0  ## 0=idle, 1=attracted, 2=collected
var _attract_target: Node2D = null
var _attract_speed: float = 0.0
const ATTRACT_RADIUS: float = 70.0
const ATTRACT_ACCEL: float = 1100.0
const MAX_ATTRACT_SPEED: float = 560.0
const COLLECT_RADIUS: float = 18.0

## 掉落动画
var _drop_velocity: Vector2 = Vector2.ZERO
var _drop_timer: float = 0.0
const DROP_DURATION: float = 0.3


func _ready() -> void:
	_apply_visual()
	add_to_group("pickups")
	# 随机掉落方向（宝箱不弹太远）
	var spread := 30.0 if kind == Kind.CHEST else 55.0
	var angle := randf() * TAU
	_drop_velocity = Vector2(cos(angle), sin(angle)) * randf_range(20.0, spread)
	_drop_timer = DROP_DURATION


func _apply_visual() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if not sprite:
		return
	match kind:
		Kind.COIN:
			sprite.texture = PlaceholderTexture.circle(7, Color(1.0, 0.84, 0.2))
		Kind.HEAL:
			sprite.texture = PlaceholderTexture.diamond(11, Color(0.3, 0.95, 0.4))
		Kind.CHEST:
			sprite.texture = PlaceholderTexture.square(20, Color(0.85, 0.6, 0.2))
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	match _state:
		0:  # idle：掉落动画 + 检测玩家靠近
			if _drop_timer > 0.0:
				_drop_timer -= delta
				global_position += _drop_velocity * delta
				_drop_velocity *= 0.85
			_check_player_proximity()
		1:  # attracted：飞向玩家
			if not _attract_target or not is_instance_valid(_attract_target):
				_state = 0
				return
			var dir := global_position.direction_to(_attract_target.global_position)
			_attract_speed = minf(_attract_speed + ATTRACT_ACCEL * delta, MAX_ATTRACT_SPEED)
			global_position += dir * _attract_speed * delta
			if global_position.distance_to(_attract_target.global_position) < COLLECT_RADIUS:
				_collect()


func _check_player_proximity() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	# 拾取半径受玩家拾取范围被动影响（宝箱不吸附，需玩家走过去碰到）
	var radius := ATTRACT_RADIUS
	if kind != Kind.CHEST:
		var mult: float = player.get("pickup_range_mult") if player.get("pickup_range_mult") != null else 1.0
		radius *= mult
	else:
		radius = COLLECT_RADIUS + 12.0
	if global_position.distance_to(player.global_position) < radius:
		_state = 1
		_attract_target = player
		_attract_speed = 100.0


func _collect() -> void:
	_state = 2
	var battle := get_tree().current_scene
	match kind:
		Kind.COIN:
			if battle and battle.has_method("collect_coin"):
				battle.collect_coin(value)
		Kind.HEAL:
			var players := get_tree().get_nodes_in_group("player")
			if not players.is_empty() and players[0].has_method("heal"):
				players[0].heal(float(value))
		Kind.CHEST:
			if battle and battle.has_method("open_chest"):
				battle.open_chest()
	queue_free()


## 经验磁铁联动：强制吸引（金币/回血响应，宝箱不响应）
func attract_to(_target_pos: Vector2) -> void:
	if _state == 2 or kind == Kind.CHEST:
		return
	if _state == 0:
		_state = 1
		_attract_speed = 200.0
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_attract_target = players[0]

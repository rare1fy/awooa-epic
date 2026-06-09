class_name WeaponManager
extends Node2D
## 武器管理器（挂在玩家身上）
## 持有所有已获得武器/被动，每帧驱动各武器自动攻击，并汇总被动加成

const Effects = preload("res://scenes/battle/weapons/weapon_effects.gd")

## 已拥有武器：id -> {data: WeaponData, level: int}
var _weapons: Dictionary = {}
## 已拥有被动：id -> {data: WeaponData, level: int}
var _passives: Dictionary = {}
## 每把武器的冷却计时器：id -> float
var _cooldowns: Dictionary = {}

var _player: Node2D = null
var _effects: Effects = null


func setup(player: Node2D) -> void:
	_player = player
	_effects = Effects.new()
	_effects.name = "WeaponEffects"
	add_child(_effects)
	_effects.setup(player, self)


func _process(delta: float) -> void:
	if not _player or _player.is_dead:
		return
	for id: StringName in _weapons:
		var entry: Dictionary = _weapons[id]
		var data: WeaponData = entry["data"]
		var level: int = entry["level"]
		var cd: float = _cooldowns.get(id, 0.0)
		cd -= delta * (1.0 + get_passive_value(WeaponData.PassiveType.ATTACK_SPEED))
		if cd <= 0.0:
			_fire_weapon(data, level)
			cd = data.get_cooldown(level) * (1.0 - get_passive_value(WeaponData.PassiveType.COOLDOWN))
		_cooldowns[id] = cd


## 发射一把武器（按类型分发到效果器）
func _fire_weapon(data: WeaponData, level: int) -> void:
	var dmg := data.get_damage(level) * (1.0 + get_passive_value(WeaponData.PassiveType.DAMAGE))
	var area := data.get_area(level) * (1.0 + get_passive_value(WeaponData.PassiveType.AREA))
	var amount := data.get_amount(level) + int(get_passive_value(WeaponData.PassiveType.AMOUNT))
	var spd := data.base_speed * (1.0 + get_passive_value(WeaponData.PassiveType.PROJECTILE_SPEED))
	_effects.fire(data, dmg, area, amount, spd)


## --- 武器/被动增删 ---

func add_or_upgrade(data: WeaponData) -> void:
	if data.kind == WeaponData.Kind.PASSIVE:
		_add_passive(data)
	else:
		_add_weapon(data)
	_try_evolve()


func _add_weapon(data: WeaponData) -> void:
	if _weapons.has(data.id):
		var entry: Dictionary = _weapons[data.id]
		entry["level"] = mini(entry["level"] + 1, data.max_level)
	else:
		_weapons[data.id] = {"data": data, "level": 1}
		_cooldowns[data.id] = 0.2  # 入手稍后即触发


func _add_passive(data: WeaponData) -> void:
	if _passives.has(data.id):
		var entry: Dictionary = _passives[data.id]
		entry["level"] = mini(entry["level"] + 1, data.max_level)
	else:
		_passives[data.id] = {"data": data, "level": 1}
	# 被动可能影响最大生命 -> 通知玩家刷新
	if _player and _player.has_method("on_passive_changed"):
		_player.on_passive_changed()


## 汇总某类被动的总加成值
func get_passive_value(ptype: WeaponData.PassiveType) -> float:
	var total := 0.0
	for id: StringName in _passives:
		var entry: Dictionary = _passives[id]
		var data: WeaponData = entry["data"]
		if data.passive_type == ptype:
			total += data.passive_per_level * float(entry["level"])
	return total


## --- 进化检测 ---

func _try_evolve() -> void:
	for id: StringName in _weapons.keys():
		var entry: Dictionary = _weapons[id]
		var data: WeaponData = entry["data"]
		if data.evolves_into == &"" or entry["level"] < data.max_level:
			continue
		# 检查所需被动是否满级（空=无被动要求）
		if data.evolution_requires != &"":
			if not _passives.has(data.evolution_requires):
				continue
			var req: Dictionary = _passives[data.evolution_requires]
			var req_data: WeaponData = req["data"]
			if req["level"] < req_data.max_level:
				continue
		_do_evolve(id, data.evolves_into)


func _do_evolve(from_id: StringName, to_id: StringName) -> void:
	var evo: WeaponData = WeaponRegistry.get_weapon(to_id)
	if not evo:
		return
	_weapons.erase(from_id)
	_cooldowns.erase(from_id)
	_weapons[to_id] = {"data": evo, "level": 1}
	_cooldowns[to_id] = 0.2
	# 进化特效提示
	if _player:
		var battle := get_tree().current_scene
		if battle and battle.has_method("shake_camera"):
			battle.shake_camera(4.0, 4.0)


## --- 查询（供升级面板用）---

func has_weapon(id: StringName) -> bool:
	return _weapons.has(id)


func has_passive(id: StringName) -> bool:
	return _passives.has(id)


func get_weapon_level(id: StringName) -> int:
	if _weapons.has(id):
		return _weapons[id]["level"]
	return 0


func get_passive_level(id: StringName) -> int:
	if _passives.has(id):
		return _passives[id]["level"]
	return 0


func get_weapon_count() -> int:
	return _weapons.size()


func get_passive_count() -> int:
	return _passives.size()


## 已满级（无法再升）的武器/被动 id 集合
func is_maxed(data: WeaponData) -> bool:
	if data.kind == WeaponData.Kind.PASSIVE:
		return get_passive_level(data.id) >= data.max_level
	return get_weapon_level(data.id) >= data.max_level

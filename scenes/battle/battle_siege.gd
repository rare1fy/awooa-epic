extends Node2D
## Vertical murloc siege prototype.
## This replaces the survivors battle loop with a low-asset, card-driven tower attack.

class SiegeUnit:
	extends Node2D

	var side: StringName = &"murloc"
	var lane: int = 1
	var hp: float = 30.0
	var max_hp: float = 30.0
	var damage: float = 5.0
	var speed: float = 40.0
	var attack_range: float = 32.0
	var attack_interval: float = 0.8
	var attack_timer: float = 0.0
	var radius: float = 11.0
	var color: Color = Color.WHITE
	var title: String = ""
	var role: StringName = &"melee"
	var heal_amount: float = 0.0
	var heal_interval: float = 1.6
	var heal_timer: float = 0.0
	var battle: Node = null
	var target: Node2D = null

	var _sprite: Sprite2D
	var _label: Label
	var _hp_bar: ColorRect

	func setup(config: Dictionary, owner_battle: Node) -> void:
		battle = owner_battle
		side = config.get("side", &"murloc")
		lane = config.get("lane", 1)
		max_hp = config.get("hp", 30.0)
		hp = max_hp
		damage = config.get("damage", 5.0)
		speed = config.get("speed", 40.0)
		attack_range = config.get("range", 32.0)
		attack_interval = config.get("interval", 0.8)
		radius = config.get("radius", 11.0)
		color = config.get("color", Color.WHITE)
		title = config.get("title", "")
		role = config.get("role", &"melee")
		heal_amount = config.get("heal", 0.0)
		attack_timer = randf() * attack_interval
		_build_visual()

	func _build_visual() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = PlaceholderTexture.outlined_circle(int(radius), color, Color(0.05, 0.08, 0.09, 1.0))
		add_child(_sprite)

		_label = Label.new()
		_label.text = title
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.position = Vector2(-18, -9)
		_label.size = Vector2(36, 18)
		_label.add_theme_font_size_override("font_size", 10)
		add_child(_label)

		var bg := ColorRect.new()
		bg.color = Color(0.06, 0.06, 0.06, 0.8)
		bg.position = Vector2(-14, radius + 3)
		bg.size = Vector2(28, 3)
		add_child(bg)

		_hp_bar = ColorRect.new()
		_hp_bar.color = Color(0.2, 0.9, 0.35, 1.0) if side == &"murloc" else Color(0.95, 0.25, 0.18, 1.0)
		_hp_bar.position = bg.position
		_hp_bar.size = bg.size
		add_child(_hp_bar)

	func tick(delta: float) -> void:
		if hp <= 0.0:
			return
		attack_timer -= delta
		target = battle.find_target_for(self)
		if role == &"healer":
			_tick_healer(delta)
		if target and is_instance_valid(target):
			var dist := global_position.distance_to(target.global_position)
			if dist <= attack_range:
				if attack_timer <= 0.0:
					battle.unit_attack(self, target)
					attack_timer = attack_interval
				velocity_zero()
				return
		_move_forward(delta)

	func _tick_healer(delta: float) -> void:
		heal_timer -= delta
		if heal_timer > 0.0:
			return
		heal_timer = heal_interval
		var wounded: SiegeUnit = battle.find_wounded_murloc(global_position, 74.0)
		if wounded:
			wounded.heal(heal_amount)
			battle.flash_at(wounded.global_position, Color(0.35, 1.0, 0.65, 0.9), 22.0)

	func _move_forward(delta: float) -> void:
		var dir := -1.0 if side == &"murloc" else 1.0
		global_position.y += dir * speed * delta

	func velocity_zero() -> void:
		pass

	func take_damage(amount: float) -> void:
		hp = maxf(hp - amount, 0.0)
		_update_hp()
		if _sprite:
			_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
			var tween := create_tween()
			tween.tween_property(_sprite, "modulate", Color.WHITE, 0.08)
		if hp <= 0.0:
			die()

	func heal(amount: float) -> void:
		hp = minf(hp + amount, max_hp)
		_update_hp()

	func _update_hp() -> void:
		if _hp_bar:
			_hp_bar.size.x = 28.0 * clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)

	func die() -> void:
		if battle:
			battle.on_unit_died(self)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(0.15, 0.15), 0.16)
		tween.tween_property(self, "modulate:a", 0.0, 0.16)
		tween.chain().tween_callback(queue_free)


class SiegeBuilding:
	extends Node2D

	var id: StringName
	var lane: int = 1
	var hp: float = 100.0
	var max_hp: float = 100.0
	var damage: float = 8.0
	var attack_range: float = 110.0
	var attack_interval: float = 1.2
	var attack_timer: float = 0.0
	var color: Color = Color(0.7, 0.7, 0.7)
	var title: String = ""
	var kind: StringName = &"tower"
	var battle: Node = null
	var radius: float = 20.0

	var _body: ColorRect
	var _label: Label
	var _hp_bar: ColorRect

	func setup(config: Dictionary, owner_battle: Node) -> void:
		battle = owner_battle
		id = config.get("id", &"")
		lane = config.get("lane", 1)
		max_hp = config.get("hp", 100.0)
		hp = max_hp
		damage = config.get("damage", 8.0)
		attack_range = config.get("range", 110.0)
		attack_interval = config.get("interval", 1.2)
		color = config.get("color", Color(0.7, 0.7, 0.7))
		title = config.get("title", "")
		kind = config.get("kind", &"tower")
		radius = config.get("radius", 20.0)
		attack_timer = randf() * attack_interval
		_build_visual()

	func _build_visual() -> void:
		_body = ColorRect.new()
		_body.color = color
		_body.position = Vector2(-radius, -radius)
		_body.size = Vector2(radius * 2.0, radius * 2.0)
		add_child(_body)

		_label = Label.new()
		_label.text = title
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.position = Vector2(-radius - 4.0, -10.0)
		_label.size = Vector2(radius * 2.0 + 8.0, 20.0)
		_label.add_theme_font_size_override("font_size", 11)
		add_child(_label)

		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.04, 0.04, 0.85)
		bg.position = Vector2(-radius, radius + 5.0)
		bg.size = Vector2(radius * 2.0, 5.0)
		add_child(bg)

		_hp_bar = ColorRect.new()
		_hp_bar.color = Color(0.95, 0.25, 0.18, 1.0)
		_hp_bar.position = bg.position
		_hp_bar.size = bg.size
		add_child(_hp_bar)

	func tick(delta: float) -> void:
		if hp <= 0.0 or kind == &"barricade" or kind == &"core":
			return
		attack_timer -= delta
		if attack_timer > 0.0:
			return
		var target: SiegeUnit = battle.find_nearest_murloc(global_position, attack_range, lane)
		if target:
			battle.building_attack(self, target)
			attack_timer = attack_interval

	func take_damage(amount: float) -> void:
		hp = maxf(hp - amount, 0.0)
		_update_hp()
		if _body:
			_body.color = color.lightened(0.35)
			var tween := create_tween()
			tween.tween_property(_body, "color", color, 0.08)
		if hp <= 0.0:
			die()

	func _update_hp() -> void:
		if _hp_bar:
			_hp_bar.size.x = radius * 2.0 * clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)

	func die() -> void:
		if battle:
			battle.on_building_destroyed(self)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.25, 0.2), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(queue_free)


const VIEW_SIZE := Vector2(480, 854)
const LANE_X := [120.0, 240.0, 360.0]
const SPAWN_Y_START := 760.0
const CARD_Y := 760.0
const MUD_CORE_MAX_HP := 160.0

@onready var camera: Camera2D = %Camera2D
@onready var allies_container: Node2D = %Allies
@onready var enemies_container: Node2D = %Enemies
@onready var ui_layer: CanvasLayer = %UI

var elapsed_time: float = 0.0
var is_game_over: bool = false
var is_victory: bool = false
var energy: float = 4.0
var energy_max: float = 10.0
var energy_regen: float = 0.9
var selected_lane: int = 1
var current_stage: int = 1
var mud_core_hp: float = MUD_CORE_MAX_HP
var kill_count: int = 0
var breach_level: int = 0

var murlocs: Array[SiegeUnit] = []
var defenders: Array[SiegeUnit] = []
var buildings: Array[SiegeBuilding] = []
var card_buttons: Array[Button] = []
var lane_buttons: Array[Button] = []
var effects: Array[Dictionary] = []

var guard_timer: float = 0.0
var reinforcement_timer: float = 14.0

var cards := [
	{
		"id": &"grunt",
		"name": "Grunt",
		"short": "G",
		"cost": 2.0,
		"count": 3,
		"unit": {"hp": 26.0, "damage": 4.0, "speed": 54.0, "range": 24.0, "interval": 0.62, "radius": 10.0, "color": Color(0.14, 0.78, 0.62), "title": "G", "role": &"melee"},
	},
	{
		"id": &"crab",
		"name": "Crab",
		"short": "C",
		"cost": 4.0,
		"count": 1,
		"unit": {"hp": 96.0, "damage": 11.0, "speed": 32.0, "range": 26.0, "interval": 0.95, "radius": 15.0, "color": Color(0.9, 0.36, 0.18), "title": "C", "role": &"siege"},
	},
	{
		"id": &"spear",
		"name": "Spear",
		"short": "S",
		"cost": 3.0,
		"count": 2,
		"unit": {"hp": 32.0, "damage": 7.0, "speed": 42.0, "range": 96.0, "interval": 0.9, "radius": 11.0, "color": Color(0.18, 0.56, 0.95), "title": "S", "role": &"ranged"},
	},
	{
		"id": &"shaman",
		"name": "Shaman",
		"short": "H",
		"cost": 5.0,
		"count": 1,
		"unit": {"hp": 44.0, "damage": 3.0, "speed": 36.0, "range": 78.0, "interval": 1.2, "radius": 12.0, "color": Color(0.55, 0.36, 0.96), "title": "H", "role": &"healer", "heal": 7.0},
	},
]


func _ready() -> void:
	randomize()
	current_stage = GameManager.current_stage if GameManager else 1
	_setup_camera()
	_build_level()
	_build_ui()
	queue_redraw()


func _setup_camera() -> void:
	camera.position = VIEW_SIZE * 0.5
	camera.zoom = Vector2.ONE
	camera.enabled = true


func _build_level() -> void:
	_spawn_building({"id": &"gate_left", "lane": 0, "pos": Vector2(LANE_X[0], 372), "hp": 72.0, "damage": 6.0, "range": 118.0, "interval": 1.25, "color": Color(0.54, 0.47, 0.38), "title": "T", "kind": &"tower", "radius": 18.0})
	_spawn_building({"id": &"gate_mid", "lane": 1, "pos": Vector2(LANE_X[1], 344), "hp": 115.0, "damage": 0.0, "range": 0.0, "interval": 99.0, "color": Color(0.46, 0.34, 0.22), "title": "GATE", "kind": &"barricade", "radius": 24.0})
	_spawn_building({"id": &"gate_right", "lane": 2, "pos": Vector2(LANE_X[2], 372), "hp": 72.0, "damage": 6.0, "range": 118.0, "interval": 1.25, "color": Color(0.54, 0.47, 0.38), "title": "T", "kind": &"tower", "radius": 18.0})

	_spawn_building({"id": &"inner_left", "lane": 0, "pos": Vector2(LANE_X[0], 204), "hp": 92.0, "damage": 8.0, "range": 126.0, "interval": 1.1, "color": Color(0.56, 0.62, 0.78), "title": "X", "kind": &"tower", "radius": 19.0})
	_spawn_building({"id": &"inner_right", "lane": 2, "pos": Vector2(LANE_X[2], 204), "hp": 92.0, "damage": 8.0, "range": 126.0, "interval": 1.1, "color": Color(0.56, 0.62, 0.78), "title": "X", "kind": &"tower", "radius": 19.0})
	_spawn_building({"id": &"core", "lane": 1, "pos": Vector2(LANE_X[1], 90), "hp": 190.0, "damage": 0.0, "range": 0.0, "interval": 99.0, "color": Color(0.83, 0.73, 0.36), "title": "CORE", "kind": &"core", "radius": 31.0})


func _process(delta: float) -> void:
	if is_game_over:
		return
	elapsed_time += delta
	energy = minf(energy + energy_regen * delta, energy_max)
	_tick_units(delta)
	_tick_buildings(delta)
	_tick_reinforcements(delta)
	_check_mud_core()
	_update_ui()
	_update_effects(delta)
	queue_redraw()


func _tick_units(delta: float) -> void:
	for unit: SiegeUnit in murlocs.duplicate():
		if is_instance_valid(unit):
			unit.tick(delta)
	for unit: SiegeUnit in defenders.duplicate():
		if is_instance_valid(unit):
			unit.tick(delta)


func _tick_buildings(delta: float) -> void:
	for building: SiegeBuilding in buildings.duplicate():
		if is_instance_valid(building):
			building.tick(delta)


func _tick_reinforcements(delta: float) -> void:
	guard_timer -= delta
	reinforcement_timer -= delta
	if reinforcement_timer <= 0.0:
		reinforcement_timer = maxf(9.0, 15.0 - elapsed_time * 0.025)
		_spawn_guard_wave()
	if guard_timer <= 0.0:
		guard_timer = 4.5
		var lane := randi() % 3
		_spawn_defender(lane, Vector2(LANE_X[lane], 265.0 + randf_range(-18.0, 18.0)), false)


func _spawn_guard_wave() -> void:
	for lane: int in 3:
		_spawn_defender(lane, Vector2(LANE_X[lane], 238.0 + randf_range(-12.0, 12.0)), lane == 1)
	flash_at(Vector2(240, 245), Color(0.9, 0.72, 0.25, 0.7), 44.0)


func _spawn_building(config: Dictionary) -> void:
	var building := SiegeBuilding.new()
	building.setup(config, self)
	building.global_position = config.get("pos", Vector2.ZERO)
	enemies_container.add_child(building)
	buildings.append(building)


func _spawn_defender(lane: int, pos: Vector2, elite: bool) -> void:
	var unit := SiegeUnit.new()
	var cfg := {
		"side": &"defender",
		"lane": lane,
		"hp": 54.0 if elite else 34.0,
		"damage": 8.0 if elite else 5.0,
		"speed": 28.0 if elite else 34.0,
		"range": 30.0,
		"interval": 0.88,
		"radius": 13.0 if elite else 10.0,
		"color": Color(0.92, 0.84, 0.58) if elite else Color(0.72, 0.75, 0.82),
		"title": "K" if elite else "M",
		"role": &"melee",
	}
	unit.setup(cfg, self)
	unit.global_position = pos
	enemies_container.add_child(unit)
	defenders.append(unit)


func _spawn_murloc(card: Dictionary, lane: int) -> void:
	var unit_cfg: Dictionary = card.get("unit", {}).duplicate()
	unit_cfg["side"] = &"murloc"
	unit_cfg["lane"] = lane
	var count: int = card.get("count", 1)
	for i: int in count:
		var unit := SiegeUnit.new()
		unit.setup(unit_cfg, self)
		var offset := Vector2(randf_range(-16.0, 16.0), i * 14.0 + randf_range(-4.0, 4.0))
		unit.global_position = Vector2(LANE_X[lane], SPAWN_Y_START - breach_level * 54.0) + offset
		allies_container.add_child(unit)
		murlocs.append(unit)
	flash_at(Vector2(LANE_X[lane], SPAWN_Y_START - breach_level * 54.0), Color(0.1, 0.95, 0.7, 0.65), 28.0)


func find_target_for(unit: SiegeUnit) -> Node2D:
	if unit.side == &"murloc":
		var nearest_unit: SiegeUnit = _nearest_unit(unit.global_position, defenders, unit.attack_range, unit.lane)
		var nearest_building: SiegeBuilding = _nearest_building(unit.global_position, unit.attack_range, unit.lane)
		if nearest_unit and nearest_building:
			return nearest_unit if unit.global_position.distance_to(nearest_unit.global_position) < unit.global_position.distance_to(nearest_building.global_position) else nearest_building
		return nearest_unit if nearest_unit else nearest_building
	var target: SiegeUnit = _nearest_unit(unit.global_position, murlocs, unit.attack_range, unit.lane)
	if target:
		return target
	if unit.global_position.y >= SPAWN_Y_START + 8.0:
		damage_mud_core(unit.damage * 0.35)
		unit.take_damage(9999.0)
	return null


func find_nearest_murloc(pos: Vector2, range: float, lane: int = -1) -> SiegeUnit:
	return _nearest_unit(pos, murlocs, range, lane)


func find_wounded_murloc(pos: Vector2, range: float) -> SiegeUnit:
	var best: SiegeUnit = null
	var best_ratio := 1.0
	for unit: SiegeUnit in murlocs:
		if not is_instance_valid(unit) or unit.hp <= 0.0 or unit.hp >= unit.max_hp:
			continue
		if pos.distance_to(unit.global_position) > range:
			continue
		var ratio := unit.hp / unit.max_hp
		if ratio < best_ratio:
			best_ratio = ratio
			best = unit
	return best


func _nearest_unit(pos: Vector2, pool: Array[SiegeUnit], range: float, lane: int = -1) -> SiegeUnit:
	var best: SiegeUnit = null
	var best_dist := range
	for unit: SiegeUnit in pool:
		if not is_instance_valid(unit) or unit.hp <= 0.0:
			continue
		if lane >= 0 and abs(unit.lane - lane) > 1:
			continue
		var dist := pos.distance_to(unit.global_position)
		if dist <= best_dist:
			best_dist = dist
			best = unit
	return best


func _nearest_building(pos: Vector2, range: float, lane: int = -1) -> SiegeBuilding:
	var best: SiegeBuilding = null
	var best_dist := range
	for building: SiegeBuilding in buildings:
		if not is_instance_valid(building) or building.hp <= 0.0:
			continue
		if lane >= 0 and abs(building.lane - lane) > 1:
			continue
		var dist := pos.distance_to(building.global_position)
		if dist <= best_dist:
			best_dist = dist
			best = building
	return best


func unit_attack(attacker: SiegeUnit, target: Node2D) -> void:
	if not target or not is_instance_valid(target):
		return
	var dmg := attacker.damage
	if attacker.role == &"siege" and target is SiegeBuilding:
		dmg *= 1.65
	if target.has_method("take_damage"):
		target.take_damage(dmg)
	_draw_projectile(attacker.global_position, target.global_position, attacker.color)


func building_attack(attacker: SiegeBuilding, target: SiegeUnit) -> void:
	if not target or not is_instance_valid(target):
		return
	target.take_damage(attacker.damage)
	_draw_projectile(attacker.global_position, target.global_position, Color(1.0, 0.78, 0.26, 1.0))


func _draw_projectile(from: Vector2, to: Vector2, color: Color) -> void:
	effects.append({"from": from, "to": to, "color": color, "time": 0.13, "max": 0.13, "radius": 0.0})


func flash_at(pos: Vector2, color: Color, radius: float) -> void:
	effects.append({"pos": pos, "color": color, "time": 0.24, "max": 0.24, "radius": radius})


func _update_effects(delta: float) -> void:
	for effect: Dictionary in effects:
		effect["time"] = effect.get("time", 0.0) - delta
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.get("time", 0.0) > 0.0)


func on_unit_died(unit: SiegeUnit) -> void:
	if unit.side == &"murloc":
		murlocs.erase(unit)
	else:
		defenders.erase(unit)
		kill_count += 1
		energy = minf(energy + 0.25, energy_max)
	flash_at(unit.global_position, Color(1.0, 0.32, 0.18, 0.6), 18.0)


func on_building_destroyed(building: SiegeBuilding) -> void:
	buildings.erase(building)
	kill_count += 4
	energy = minf(energy + 1.4, energy_max)
	flash_at(building.global_position, Color(1.0, 0.72, 0.18, 0.75), 42.0)
	if building.kind == &"core":
		_victory()
		return
	_update_breach_level()


func _update_breach_level() -> void:
	var outer_alive := false
	var inner_alive := false
	for building: SiegeBuilding in buildings:
		if not is_instance_valid(building):
			continue
		if building.id in [&"gate_left", &"gate_mid", &"gate_right"]:
			outer_alive = true
		if building.id in [&"inner_left", &"inner_right"]:
			inner_alive = true
	var new_level := 0
	if not outer_alive:
		new_level = 1
	if not inner_alive and new_level == 1:
		new_level = 2
	if new_level > breach_level:
		breach_level = new_level
		energy = minf(energy + 3.0, energy_max)
		_show_banner("BREACH! Spawn line advanced")


func damage_mud_core(amount: float) -> void:
	mud_core_hp = maxf(mud_core_hp - amount, 0.0)
	if mud_core_hp <= 0.0:
		_defeat()


func _check_mud_core() -> void:
	for unit: SiegeUnit in defenders.duplicate():
		if not is_instance_valid(unit):
			continue
		if unit.global_position.y >= SPAWN_Y_START + 12.0:
			damage_mud_core(unit.damage * 0.6)
			unit.take_damage(9999.0)


func _build_ui() -> void:
	var hud := Control.new()
	hud.name = "SiegeHUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(hud)

	var top := Label.new()
	top.name = "TopLabel"
	top.position = Vector2(14, 10)
	top.size = Vector2(452, 28)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.text = "Murloc Siege  WAVE 1"
	hud.add_child(top)

	var energy_bg := ColorRect.new()
	energy_bg.name = "EnergyBG"
	energy_bg.position = Vector2(88, 700)
	energy_bg.size = Vector2(304, 12)
	energy_bg.color = Color(0.04, 0.12, 0.14, 0.92)
	hud.add_child(energy_bg)

	var energy_bar := ColorRect.new()
	energy_bar.name = "EnergyBar"
	energy_bar.position = energy_bg.position
	energy_bar.size = Vector2(0, 12)
	energy_bar.color = Color(0.05, 0.86, 0.74, 1.0)
	hud.add_child(energy_bar)

	var lane_row := HBoxContainer.new()
	lane_row.position = Vector2(58, 720)
	lane_row.size = Vector2(364, 34)
	lane_row.add_theme_constant_override("separation", 10)
	hud.add_child(lane_row)
	for i: int in 3:
		var btn := Button.new()
		btn.text = ["LEFT", "MID", "RIGHT"][i]
		btn.custom_minimum_size = Vector2(112, 32)
		btn.pressed.connect(_on_lane_pressed.bind(i))
		lane_row.add_child(btn)
		lane_buttons.append(btn)

	var card_row := HBoxContainer.new()
	card_row.position = Vector2(12, CARD_Y)
	card_row.size = Vector2(456, 82)
	card_row.add_theme_constant_override("separation", 8)
	hud.add_child(card_row)
	for card: Dictionary in cards:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(108, 76)
		btn.pressed.connect(_on_card_pressed.bind(card))
		card_row.add_child(btn)
		card_buttons.append(btn)

	var skill_btn := Button.new()
	skill_btn.name = "RushButton"
	skill_btn.text = "MURLOC RUSH"
	skill_btn.position = Vector2(156, 650)
	skill_btn.size = Vector2(168, 42)
	skill_btn.pressed.connect(_on_rush_pressed)
	hud.add_child(skill_btn)


func _on_lane_pressed(lane: int) -> void:
	selected_lane = lane
	_update_ui()


func _on_card_pressed(card: Dictionary) -> void:
	var cost: float = card.get("cost", 1.0)
	if energy < cost or is_game_over:
		_show_banner("Not enough spawn energy")
		return
	energy -= cost
	_spawn_murloc(card, selected_lane)
	_update_ui()


func _on_rush_pressed() -> void:
	if energy < 6.0 or is_game_over:
		_show_banner("Need 6 energy")
		return
	energy -= 6.0
	for lane: int in 3:
		_spawn_murloc(cards[0], lane)
	for unit: SiegeUnit in murlocs:
		if is_instance_valid(unit):
			unit.speed *= 1.18
	_show_banner("MURLOC RUSH!")


func _update_ui() -> void:
	var hud := ui_layer.get_node_or_null("SiegeHUD")
	if not hud:
		return
	var top := hud.get_node_or_null("TopLabel") as Label
	if top:
		var wave := 1 + int(elapsed_time / 30.0)
		top.text = "Murloc Siege  WAVE %d   Breaks:%d   Swamp:%d%%" % [wave, kill_count, int(mud_core_hp / MUD_CORE_MAX_HP * 100.0)]
	var energy_bar := hud.get_node_or_null("EnergyBar") as ColorRect
	if energy_bar:
		energy_bar.size.x = 304.0 * energy / energy_max
	for i: int in card_buttons.size():
		var btn := card_buttons[i]
		var card: Dictionary = cards[i]
		var cost: float = card.get("cost", 1.0)
		btn.text = "%s\n%d energy\n%s" % [card.get("name", ""), int(cost), card.get("short", "")]
		btn.disabled = energy < cost
	for i: int in lane_buttons.size():
		lane_buttons[i].modulate = Color(0.65, 1.0, 0.8, 1.0) if i == selected_lane else Color.WHITE
	var rush_btn := hud.get_node_or_null("RushButton") as Button
	if rush_btn:
		rush_btn.disabled = energy < 6.0


func _show_banner(text: String) -> void:
	var hud := ui_layer.get_node_or_null("SiegeHUD")
	if not hud:
		return
	var old := hud.get_node_or_null("Banner")
	if old:
		old.queue_free()
	var banner := Label.new()
	banner.name = "Banner"
	banner.text = text
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(60, 292)
	banner.size = Vector2(360, 34)
	banner.add_theme_font_size_override("font_size", 16)
	hud.add_child(banner)
	var tween := banner.create_tween()
	tween.tween_property(banner, "position:y", 270.0, 0.3)
	tween.tween_interval(0.9)
	tween.tween_property(banner, "modulate:a", 0.0, 0.35)
	tween.tween_callback(banner.queue_free)


func _victory() -> void:
	if is_game_over:
		return
	is_game_over = true
	is_victory = true
	_show_result("SIEGE WON!\n\nMurloc banner on the keep\nBreaks: %d\n\nTap to return" % kill_count)


func _defeat() -> void:
	if is_game_over:
		return
	is_game_over = true
	_show_result("SWAMP CLEARED...\n\nSurvived: %ds\nBreaks: %d\n\nTap to return" % [int(elapsed_time), kill_count])


func _show_result(text: String) -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.03, 0.04, 0.78)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(panel)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(60, 270)
	label.size = Vector2(360, 210)
	label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			GameManager.return_to_menu()
		if event is InputEventScreenTouch and event.pressed:
			GameManager.return_to_menu()
	)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.08, 0.12, 0.13, 1.0))
	draw_rect(Rect2(0, 0, 480, 155), Color(0.27, 0.28, 0.33, 1.0))
	draw_rect(Rect2(0, 155, 480, 520), Color(0.18, 0.35, 0.23, 1.0))
	draw_rect(Rect2(0, 675, 480, 179), Color(0.1, 0.27, 0.22, 1.0))

	for i: int in 3:
		var x: float = LANE_X[i]
		draw_rect(Rect2(x - 34.0, 150.0, 68.0, 520.0), Color(0.24, 0.44, 0.29, 0.45))
		draw_line(Vector2(x, 675.0), Vector2(x, 45.0), Color(0.8, 0.9, 0.7, 0.18), 2.0)

	var spawn_y := SPAWN_Y_START - breach_level * 54.0
	draw_line(Vector2(46, spawn_y), Vector2(434, spawn_y), Color(0.1, 0.95, 0.7, 0.9), 4.0)
	draw_circle(Vector2(240, 760), 46.0, Color(0.03, 0.55, 0.46, 0.5))
	draw_circle(Vector2(240, 760), 24.0, Color(0.02, 0.82, 0.64, 0.45))

	draw_rect(Rect2(42, 78, 396, 16), Color(0.68, 0.63, 0.55, 1.0))
	draw_rect(Rect2(68, 52, 344, 26), Color(0.42, 0.42, 0.47, 1.0))
	draw_rect(Rect2(205, 22, 70, 42), Color(0.67, 0.58, 0.28, 1.0))

	for effect: Dictionary in effects:
		var ratio: float = effect.get("time", 0.0) / effect.get("max", 1.0)
		var color: Color = effect.get("color", Color.WHITE)
		color.a *= ratio
		if effect.has("from"):
			draw_line(effect["from"], effect["to"], color, 3.0)
		else:
			draw_circle(effect["pos"], effect.get("radius", 20.0) * (1.2 - ratio * 0.2), color)

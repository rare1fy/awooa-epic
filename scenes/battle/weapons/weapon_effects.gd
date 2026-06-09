extends Node2D
## 武器效果器：根据 WeaponData.weapon_type 生成对应的攻击表现与伤害
## 复用同一套弹道/AOE 原语，覆盖全部 18 武器 + 9 进化

const PlaceholderTexture = preload("res://common/utils/placeholder_texture.gd")

var _player: Node2D = null
var _manager: Node = null
var _projectile_scene: PackedScene = preload("res://scenes/battle/projectiles/projectile.tscn")

## 环绕类武器需要常驻节点：weapon_id -> Array[Node2D]
var _orbit_nodes: Dictionary = {}
var _orbit_angle: float = 0.0
## 跟随召唤物
var _familiars: Array[Node2D] = []


func setup(player: Node2D, manager: Node) -> void:
	_player = player
	_manager = manager


func _physics_process(delta: float) -> void:
	_orbit_angle += delta * 2.5
	_update_orbits()
	_update_familiars(delta)


func fire(data: WeaponData, dmg: float, area: float, amount: int, spd: float) -> void:
	match data.weapon_type:
		WeaponData.WeaponType.PROJECTILE:
			_fire_projectile(data, dmg, amount, spd)
		WeaponData.WeaponType.WHIP:
			_fire_whip(dmg, area, amount)
		WeaponData.WeaponType.ORBIT:
			_refresh_orbit(data, dmg, area, amount)
		WeaponData.WeaponType.AURA:
			_fire_aura(dmg, area)
		WeaponData.WeaponType.LIGHTNING:
			_fire_lightning(dmg, amount, area)
		WeaponData.WeaponType.BOOMERANG:
			_fire_boomerang(data, dmg, amount, spd)
		WeaponData.WeaponType.HOMING:
			_fire_homing(data, dmg, amount, spd)
		WeaponData.WeaponType.GROUND_AREA:
			_fire_ground_area(data, dmg, area, amount)
		WeaponData.WeaponType.GARLIC_RING:
			_fire_ring(dmg, area)
		WeaponData.WeaponType.SHIELD:
			_fire_aura(dmg, area)  # 护盾复用近身脉冲
		WeaponData.WeaponType.BIBLE_LASER:
			_fire_laser(data, dmg, amount, spd)
		WeaponData.WeaponType.FOLLOW_FAMILIAR:
			_ensure_familiars(data, dmg, amount)


## --- 通用：取面向 / 最近敌人 ---

func _aim_dir() -> Vector2:
	# 优先朝最近敌人，否则朝移动方向，再否则朝右
	var nearest := _nearest_enemy(99999.0)
	if nearest:
		return _player.global_position.direction_to(nearest.global_position)
	if _player.velocity.length() > 1.0:
		return _player.velocity.normalized()
	return Vector2.RIGHT


func _nearest_enemy(max_dist: float) -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var best := max_dist
	for e: Node2D in enemies:
		var d := _player.global_position.distance_to(e.global_position)
		if d < best:
			best = d
			nearest = e
	return nearest


func _spawn_proj(pos: Vector2, dir: Vector2, dmg: float, spd: float,
		pierce: int, max_dist: float, color: Color, size: int = 6) -> void:
	var proj := _projectile_scene.instantiate() as Projectile
	proj.global_position = pos
	proj.direction = dir
	proj.damage = dmg
	proj.speed = spd
	proj.pierce_count = pierce
	proj.max_distance = max_dist
	var ps := proj.get_node_or_null("Sprite") as Sprite2D
	if ps:
		ps.texture = PlaceholderTexture.square(size, color)
		ps.modulate = Color.WHITE
	get_tree().current_scene.add_child(proj)


## --- 各攻击模式 ---

func _fire_projectile(data: WeaponData, dmg: float, amount: int, spd: float) -> void:
	var base_dir := _aim_dir()
	# 多发：散开成小扇形
	var spread := 0.18
	for i: int in amount:
		var off := (float(i) - float(amount - 1) * 0.5) * spread
		var dir := base_dir.rotated(off)
		_spawn_proj(_player.global_position, dir, dmg, spd, data.pierce, 420.0, data.color)


func _fire_whip(dmg: float, area: float, amount: int) -> void:
	# 左右横扫：在玩家左右生成短暂扇形伤害区
	var dir := _aim_dir()
	for i: int in maxi(1, amount):
		var side := 1.0 if i % 2 == 0 else -1.0
		var center := _player.global_position + dir * side * 70.0 * area
		_aoe_burst(center, 60.0 * area, dmg, Color(0.4, 0.7, 1.0, 0.5))


func _fire_aura(dmg: float, area: float) -> void:
	var radius := 90.0 * area
	_aoe_burst(_player.global_position, radius, dmg, Color(0.4, 0.9, 0.3, 0.25))


func _fire_ring(dmg: float, area: float) -> void:
	var radius := 130.0 * area
	_aoe_burst(_player.global_position, radius, dmg, Color(0.6, 0.5, 1.0, 0.3))


func _fire_lightning(dmg: float, amount: int, area: float) -> void:
	var radius := 320.0 * area
	var enemies := get_tree().get_nodes_in_group("enemies")
	var candidates: Array[Node2D] = []
	for e: Node2D in enemies:
		if _player.global_position.distance_to(e.global_position) <= radius:
			candidates.append(e)
	candidates.shuffle()
	var hits := mini(amount, candidates.size())
	for i: int in hits:
		var target := candidates[i]
		if target.has_method("take_damage"):
			target.take_damage(dmg)
		_draw_zap(target.global_position)


func _fire_boomerang(data: WeaponData, dmg: float, amount: int, spd: float) -> void:
	var base_dir := _aim_dir()
	for i: int in amount:
		var off := (float(i) - float(amount - 1) * 0.5) * 0.4
		_spawn_boomerang(base_dir.rotated(off), dmg, spd, data.color)


func _fire_homing(data: WeaponData, dmg: float, amount: int, spd: float) -> void:
	for i: int in amount:
		var target := _nearest_enemy(99999.0)
		var dir := _aim_dir().rotated(randf_range(-0.5, 0.5))
		var proj := _projectile_scene.instantiate() as Projectile
		proj.global_position = _player.global_position
		proj.direction = dir
		proj.damage = dmg
		proj.speed = spd
		proj.pierce_count = 0
		proj.max_distance = 600.0
		proj.set_meta("homing", true)
		var ps := proj.get_node_or_null("Sprite") as Sprite2D
		if ps:
			ps.texture = PlaceholderTexture.diamond(7, data.color)
		get_tree().current_scene.add_child(proj)


func _fire_ground_area(data: WeaponData, dmg: float, area: float, amount: int) -> void:
	for i: int in amount:
		var off := Vector2(randf_range(-160, 160), randf_range(-160, 160))
		var pos := _player.global_position + off
		_ground_pool(pos, 55.0 * area, dmg, data.base_duration, data.color)


func _fire_laser(data: WeaponData, dmg: float, amount: int, spd: float) -> void:
	var base_dir := _aim_dir()
	for i: int in amount:
		var off := (float(i) - float(amount - 1) * 0.5) * 0.12
		_spawn_proj(_player.global_position, base_dir.rotated(off), dmg, spd,
			data.pierce, 700.0, data.color, 5)


## --- 环绕（常驻节点）---

func _refresh_orbit(data: WeaponData, dmg: float, area: float, amount: int) -> void:
	# 重建环绕节点组（数量/伤害随等级变化）
	var existing: Array = _orbit_nodes.get(data.id, [])
	for n in existing:
		if is_instance_valid(n):
			n.queue_free()
	var arr: Array[Node2D] = []
	for i: int in amount:
		var orb := Area2D.new()
		orb.collision_layer = 0
		orb.collision_mask = 4  # 敌人层
		var spr := Sprite2D.new()
		spr.texture = PlaceholderTexture.circle(int(9 * area), data.color)
		orb.add_child(spr)
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12.0 * area
		col.shape = shape
		orb.add_child(col)
		orb.set_meta("dmg", dmg)
		orb.set_meta("base_angle", TAU * float(i) / float(amount))
		orb.set_meta("radius", 70.0 * area)
		orb.set_meta("hit_cd", 0.0)
		orb.body_entered.connect(_on_orbit_hit.bind(orb))
		get_tree().current_scene.add_child(orb)
		arr.append(orb)
	_orbit_nodes[data.id] = arr


func _update_orbits() -> void:
	if not _player:
		return
	for id: StringName in _orbit_nodes:
		var arr: Array = _orbit_nodes[id]
		for orb in arr:
			if not is_instance_valid(orb):
				continue
			var ang: float = orb.get_meta("base_angle", 0.0) + _orbit_angle
			var r: float = orb.get_meta("radius", 70.0)
			orb.global_position = _player.global_position + Vector2(cos(ang), sin(ang)) * r


func _on_orbit_hit(body: Node2D, orb: Area2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(orb.get_meta("dmg", 10.0))


## --- 跟随召唤物 ---

func _ensure_familiars(data: WeaponData, dmg: float, amount: int) -> void:
	# 维持 amount 个召唤物，每次 fire 时让它们扑咬最近敌人
	while _familiars.size() < amount:
		var fam := Sprite2D.new()
		fam.texture = PlaceholderTexture.outlined_circle(8, data.color, Color(0.1, 0.2, 0.3))
		get_tree().current_scene.add_child(fam)
		fam.global_position = _player.global_position
		_familiars.append(fam)
	# 清理失效
	_familiars = _familiars.filter(func(f: Node2D) -> bool: return is_instance_valid(f))
	# 每个召唤物攻击一个最近敌人
	for fam: Node2D in _familiars:
		var target := _nearest_enemy(260.0)
		if target and target.has_method("take_damage"):
			target.take_damage(dmg)
			_draw_zap_between(fam.global_position, target.global_position, data.color)


func _update_familiars(delta: float) -> void:
	if not _player:
		return
	for i: int in _familiars.size():
		var fam: Node2D = _familiars[i]
		if not is_instance_valid(fam):
			continue
		var ang := _orbit_angle * 1.5 + TAU * float(i) / float(maxi(1, _familiars.size()))
		var want := _player.global_position + Vector2(cos(ang), sin(ang)) * 50.0
		fam.global_position = fam.global_position.lerp(want, delta * 6.0)


## --- AOE / 视觉原语 ---

func _aoe_burst(center: Vector2, radius: float, dmg: float, color: Color) -> void:
	# 即时范围伤害 + 一个淡出的圆形提示
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e: Node2D in enemies:
		if center.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
			e.take_damage(dmg)
	_draw_circle_fx(center, radius, color)


func _ground_pool(center: Vector2, radius: float, dmg: float, duration: float, color: Color) -> void:
	# 持续伤害区：用一个带计时的 Area 节点，每 0.4s 结算一次
	var area := Area2D.new()
	area.global_position = center
	var spr := Sprite2D.new()
	spr.texture = PlaceholderTexture.circle(int(radius), Color(color.r, color.g, color.b, 0.3))
	area.add_child(spr)
	get_tree().current_scene.add_child(area)
	var elapsed := 0.0
	var tick := 0.0
	# 用 tween 控制生命周期 + 自定义 tick
	var timer := Timer.new()
	timer.wait_time = 0.4
	timer.autostart = true
	area.add_child(timer)
	timer.timeout.connect(func() -> void:
		elapsed += 0.4
		var es := get_tree().get_nodes_in_group("enemies")
		for e: Node2D in es:
			if area.global_position.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
				e.take_damage(dmg)
		if elapsed >= duration:
			area.queue_free()
	)


func _spawn_boomerang(dir: Vector2, dmg: float, spd: float, color: Color) -> void:
	var proj := _projectile_scene.instantiate() as Projectile
	proj.global_position = _player.global_position
	proj.direction = dir
	proj.damage = dmg
	proj.speed = spd
	proj.pierce_count = 999
	proj.max_distance = 240.0
	proj.set_meta("boomerang", true)
	proj.set_meta("origin_ref", _player)
	var ps := proj.get_node_or_null("Sprite") as Sprite2D
	if ps:
		ps.texture = PlaceholderTexture.diamond(8, color)
	get_tree().current_scene.add_child(proj)


func _draw_zap(pos: Vector2) -> void:
	_draw_zap_between(_player.global_position, pos, Color(0.7, 0.5, 1.0))


func _draw_zap_between(from: Vector2, to: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 3.0
	line.default_color = color
	get_tree().current_scene.add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.18)
	tw.tween_callback(line.queue_free)


func _draw_circle_fx(center: Vector2, radius: float, color: Color) -> void:
	var spr := Sprite2D.new()
	spr.texture = PlaceholderTexture.circle(int(radius), color)
	spr.global_position = center
	get_tree().current_scene.add_child(spr)
	var tw := spr.create_tween()
	tw.tween_property(spr, "modulate:a", 0.0, 0.2)
	tw.tween_callback(spr.queue_free)

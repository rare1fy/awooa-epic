extends Node2D
## 战斗场景主控制器
## M3 版本：M2 + Boss + 尸潮 + 时间轴敌人 + 通关 + 三星

signal player_leveled_up(level: int)

@onready var camera: Camera2D = %Camera2D
@onready var player_node: Node2D = %Player
@onready var allies_container: Node2D = %Allies
@onready var enemies_container: Node2D = %Enemies
@onready var ui_layer: CanvasLayer = %UI
@onready var spawn_timer: Timer = %SpawnTimer

## 预加载场景
var _enemy_scene: PackedScene = preload("res://scenes/battle/enemies/enemy.tscn")
var _player_scene: PackedScene = preload("res://scenes/battle/player/player.tscn")
var _ally_scene: PackedScene = preload("res://scenes/battle/allies/ally.tscn")

## 关卡数据（由外部注入或默认）
@export var stage_data: StageData

## 战斗状态
var elapsed_time: float = 0.0
var is_game_over: bool = false
var is_paused: bool = false
var is_victory: bool = false
var player_level: int = 1
var player_exp: int = 0
var exp_to_next_level: int = 10
var kill_count: int = 0

## 刷怪配置
var spawn_radius: float = 350.0
var max_enemies: int = 220
var _stage_duration: float = 900.0

## 玩家实例引用
var _player: Node2D = null
var _joystick: Control = null

## --- 队友系统 ---
var _allies: Array[Node2D] = []
var _ally_roster: Dictionary = {}

## --- Boss 系统 ---
var _boss_times: Array[float] = [300.0, 600.0, 900.0]
var _next_boss_index: int = 0
var _boss_active: bool = false

## --- 尸潮系统 ---
var _swarm_times: Array[float] = [180.0, 480.0, 780.0]
var _swarm_duration: float = 20.0
var _next_swarm_index: int = 0
var _swarm_active: bool = false
var _swarm_end_time: float = 0.0

## --- 时间轴敌人解锁 ---
var _unlocked_enemies: Array[Dictionary] = []  ## [{data: EnemyData, weight: int, max: int}]

## 摄像机缩放
var _camera_target_zoom: float = 1.0
const CAMERA_ZOOM_MIN: float = 0.55
const CAMERA_ZOOM_MAX: float = 1.0
const CAMERA_ZOOM_SPEED: float = 1.5

## 屏幕震动
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0

## 经验磁铁（升级时吸取全屏宝石）
var _magnet_active: bool = false
var _magnet_timer: float = 0.0
const MAGNET_DURATION: float = 1.5


func _ready() -> void:
	_setup_ground()
	_load_stage_config()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = 1.0
	spawn_timer.start()
	_setup_player()
	_setup_joystick()
	_setup_hud()


func _setup_ground() -> void:
	var ground := BattleGround.new()
	ground.name = "Ground"
	add_child(ground)
	move_child(ground, 0)  # 确保在最底层


func _load_stage_config() -> void:
	# 优先从 GameManager 获取关卡数据
	if not stage_data and GameManager.pending_stage_data:
		stage_data = GameManager.pending_stage_data
	if not stage_data:
		# 无关卡数据时使用默认值（调试用）
		return
	_stage_duration = stage_data.duration_seconds
	_boss_times = Array(stage_data.boss_times, TYPE_FLOAT, &"", null)
	_swarm_times = Array(stage_data.swarm_times, TYPE_FLOAT, &"", null)
	_swarm_duration = stage_data.swarm_duration
	spawn_timer.wait_time = stage_data.base_spawn_interval
	# 解析敌人时间轴
	for entry: EnemyTimelineEntry in stage_data.enemy_timeline:
		_unlocked_enemies.append({
			"data": entry.enemy,
			"weight": entry.spawn_weight,
			"max": entry.max_concurrent,
			"unlock_time": entry.unlock_time,
			"unlocked": false,
		})


func _process(delta: float) -> void:
	if is_game_over or is_paused:
		return

	elapsed_time += delta
	_update_spawn_difficulty()
	_check_boss_trigger()
	_check_swarm_trigger()
	_check_enemy_unlocks()
	_check_victory()
	_update_camera(delta)
	_update_shake(delta)
	_update_magnet(delta)
	_update_hud()
	_update_boss_hp_bar()


## --- Boss 系统 ---

func _check_boss_trigger() -> void:
	if _boss_active:
		return
	if _next_boss_index >= _boss_times.size():
		return
	if elapsed_time >= _boss_times[_next_boss_index]:
		_trigger_boss()


func _trigger_boss() -> void:
	_boss_active = true

	# 清场：秒杀所有小怪
	_clear_all_enemies()

	# 暂停刷怪计时器
	spawn_timer.stop()

	# 生成 Boss
	var boss := _enemy_scene.instantiate()
	var angle := randf() * TAU
	var spawn_pos := _player.global_position + Vector2(cos(angle), sin(angle)) * 200.0
	boss.global_position = spawn_pos
	boss.player_ref = _player

	# Boss 强化属性
	var boss_mult := 1.0 + _next_boss_index * 0.5
	boss.hp = 200.0 * boss_mult
	boss.max_hp = boss.hp
	boss.damage = 15.0 * boss_mult
	boss.speed = 50.0
	boss.exp_value = 20 + _next_boss_index * 10

	# Boss 视觉差异化：更大 + 不同颜色
	var boss_sprite := boss.get_node_or_null("Sprite") as Sprite2D
	if boss_sprite:
		boss_sprite.scale = Vector2(1.2, 1.2)
		boss_sprite.modulate = Color(1.0, 0.4, 0.8, 1.0)

	boss.add_to_group("enemies")
	boss.add_to_group("boss")
	enemies_container.add_child(boss)

	# Boss 出场屏幕震动
	shake_camera(8.0, 4.0)

	# 给 Boss 加头顶血条
	_add_boss_hp_bar(boss)

	# Boss 死亡后恢复刷怪
	boss.tree_exited.connect(_on_boss_defeated)

	_next_boss_index += 1


func _add_boss_hp_bar(boss: Node2D) -> void:
	## 在 UI 层添加 Boss 血条
	var bar_bg := ColorRect.new()
	bar_bg.name = "BossHPBarBG"
	bar_bg.size = Vector2(300, 12)
	bar_bg.position = Vector2(90, 100)
	bar_bg.color = Color(0.15, 0.15, 0.15, 0.9)
	ui_layer.add_child(bar_bg)

	var bar := ColorRect.new()
	bar.name = "BossHPBar"
	bar.size = Vector2(300, 12)
	bar.position = Vector2(90, 100)
	bar.color = Color(0.9, 0.2, 0.4, 1.0)
	ui_layer.add_child(bar)

	var boss_label := Label.new()
	boss_label.name = "BossLabel"
	boss_label.text = "BOSS"
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.position = Vector2(90, 82)
	boss_label.size = Vector2(300, 20)
	ui_layer.add_child(boss_label)


func _on_boss_defeated() -> void:
	_boss_active = false
	# 清理 Boss 血条 UI
	var bar_bg := ui_layer.get_node_or_null("BossHPBarBG")
	if bar_bg:
		bar_bg.queue_free()
	var bar := ui_layer.get_node_or_null("BossHPBar")
	if bar:
		bar.queue_free()
	var boss_label := ui_layer.get_node_or_null("BossLabel")
	if boss_label:
		boss_label.queue_free()
	# 恢复刷怪
	if not is_game_over:
		spawn_timer.start()


func _clear_all_enemies() -> void:
	for enemy: Node2D in enemies_container.get_children():
		if not enemy.is_in_group("boss"):
			kill_count += 1
			enemy.queue_free()


## --- 尸潮系统 ---

func _check_swarm_trigger() -> void:
	if _swarm_active:
		# 检查尸潮是否结束
		if elapsed_time >= _swarm_end_time:
			_swarm_active = false
		return
	if _next_swarm_index >= _swarm_times.size():
		return
	if elapsed_time >= _swarm_times[_next_swarm_index]:
		_trigger_swarm()


func _trigger_swarm() -> void:
	_swarm_active = true
	_swarm_end_time = elapsed_time + _swarm_duration
	_next_swarm_index += 1
	# 尸潮期间大量刷怪（临时提高上限和频率）
	max_enemies = 400
	spawn_timer.wait_time = 0.1


func _end_swarm() -> void:
	_swarm_active = false
	max_enemies = 220


## --- 时间轴敌人解锁 ---

func _check_enemy_unlocks() -> void:
	for entry: Dictionary in _unlocked_enemies:
		if not entry.get("unlocked", false) and elapsed_time >= entry.get("unlock_time", 0.0):
			entry["unlocked"] = true


## --- 通关判定 ---

func _check_victory() -> void:
	if elapsed_time >= _stage_duration and not _boss_active:
		_victory()


func _victory() -> void:
	is_game_over = true
	is_victory = true
	spawn_timer.stop()
	_clear_all_enemies()
	_show_victory()


## --- 刷怪 ---

func _update_spawn_difficulty() -> void:
	if _swarm_active:
		# 尸潮期间保持高频
		spawn_timer.wait_time = 0.1
		return
	if _boss_active:
		return
	var base_interval := 1.0
	var min_interval := 0.2
	if stage_data:
		base_interval = stage_data.base_spawn_interval
		min_interval = stage_data.min_spawn_interval
	var progress := minf(elapsed_time / _stage_duration, 1.0)
	spawn_timer.wait_time = lerpf(base_interval, min_interval, progress)
	# 尸潮结束后恢复上限
	if not _swarm_active and max_enemies > 220:
		max_enemies = 220


func _on_spawn_timer_timeout() -> void:
	if is_game_over or is_paused or not _player or _boss_active:
		return
	var current := enemies_container.get_child_count()
	if current >= max_enemies:
		return
	# 批量生成：数量随进度递增，尸潮期间翻倍
	var batch := _get_spawn_batch_count()
	var room := max_enemies - current
	batch = mini(batch, room)
	for i: int in batch:
		_spawn_enemy()


## 单次刷怪批量数量：随关卡进度从 2 递增到 6，尸潮期间额外翻倍
func _get_spawn_batch_count() -> int:
	var progress := minf(elapsed_time / _stage_duration, 1.0)
	var base_batch := int(round(lerpf(2.0, 6.0, progress)))
	if _swarm_active:
		base_batch *= 2
	return maxi(1, base_batch)


func _spawn_enemy() -> void:
	var enemy := _enemy_scene.instantiate()
	var angle := randf() * TAU
	var dist := spawn_radius + randf_range(0.0, 80.0)
	var spawn_pos := _player.global_position + Vector2(cos(angle), sin(angle)) * dist

	enemy.global_position = spawn_pos
	enemy.player_ref = _player

	var difficulty_mult := 1.0 + elapsed_time / _stage_duration * 0.5

	# 如果有时间轴解锁的敌人数据，随机选一个
	var available_entries := _get_available_enemy_entries()
	if not available_entries.is_empty():
		var entry: Dictionary = _weighted_pick(available_entries)
		var data: EnemyData = entry.get("data")
		if data:
			enemy.initialize(data, _player, difficulty_mult)
	else:
		# 无 stage_data 时使用默认敌人池（调试用）
		_apply_default_enemy_type(enemy, difficulty_mult)

	enemy.add_to_group("enemies")
	enemies_container.add_child(enemy)


## 调试用默认敌人池：魔兽正派阵营，根据时间解锁
func _apply_default_enemy_type(enemy: Node2D, difficulty_mult: float) -> void:
	var data := EnemyData.new()
	var roll := randf()

	if elapsed_time < 60.0:
		# 前 1 分钟：渔村民兵（最弱冲锋兵）
		data.behavior = EnemyData.BehaviorType.CHARGE
		data.base_hp = 15.0
		data.base_damage = 4.0
		data.speed = 80.0
		data.exp_drop = 1
		data.color = Color(0.7, 0.6, 0.4, 1.0)  # 土黄色布衣
	elif elapsed_time < 180.0:
		# 1-3 分钟：暴风城步兵 + 矮人火枪手
		if roll < 0.7:
			# 暴风城步兵 — 蓝甲冲锋
			data.behavior = EnemyData.BehaviorType.CHARGE
			data.base_hp = 22.0
			data.base_damage = 5.0
			data.speed = 85.0
			data.exp_drop = 1
			data.color = Color(0.2, 0.3, 0.7, 1.0)  # 暴风城蓝
		else:
			# 矮人火枪手 — 环绕走位
			data.behavior = EnemyData.BehaviorType.CIRCLE
			data.base_hp = 14.0
			data.base_damage = 7.0
			data.speed = 95.0
			data.exp_drop = 2
			data.color = Color(0.6, 0.4, 0.2, 1.0)  # 矮人棕
	elif elapsed_time < 360.0:
		# 3-6 分钟：精灵弓箭手 + 暴风城骑士 + 达拉然法师
		if roll < 0.35:
			# 暴风城步兵（加强版）
			data.behavior = EnemyData.BehaviorType.CHARGE
			data.base_hp = 28.0
			data.base_damage = 6.0
			data.speed = 90.0
			data.exp_drop = 2
			data.color = Color(0.2, 0.3, 0.7, 1.0)
		elif roll < 0.55:
			# 精灵弓箭手 — 远程射箭
			data.behavior = EnemyData.BehaviorType.RANGED
			data.base_hp = 12.0
			data.base_damage = 9.0
			data.speed = 60.0
			data.exp_drop = 3
			data.color = Color(0.2, 0.7, 0.3, 1.0)  # 精灵绿
			data.attack_range = 180.0
			data.attack_interval = 2.0
			data.projectile_speed = 220.0
		elif roll < 0.8:
			# 暴风城骑士 — 冲刺
			data.behavior = EnemyData.BehaviorType.DASH
			data.base_hp = 22.0
			data.base_damage = 11.0
			data.speed = 70.0
			data.exp_drop = 3
			data.color = Color(0.8, 0.8, 0.9, 1.0)  # 银甲白
			data.dash_speed_mult = 3.0
			data.dash_interval = 3.0
			data.dash_duration = 0.4
		else:
			# 达拉然法师 — 远程火球
			data.behavior = EnemyData.BehaviorType.RANGED
			data.base_hp = 10.0
			data.base_damage = 12.0
			data.speed = 50.0
			data.exp_drop = 4
			data.color = Color(0.5, 0.2, 0.8, 1.0)  # 达拉然紫
			data.attack_range = 200.0
			data.attack_interval = 2.5
			data.projectile_speed = 180.0
	else:
		# 6 分钟后：全类型 + 圣光牧师(分裂) + 铁炉堡山王(坦克) + 白银之手骑士(冲刺)
		if roll < 0.2:
			# 暴风城精锐步兵
			data.behavior = EnemyData.BehaviorType.CHARGE
			data.base_hp = 35.0
			data.base_damage = 7.0
			data.speed = 95.0
			data.exp_drop = 2
			data.color = Color(0.15, 0.25, 0.6, 1.0)
		elif roll < 0.35:
			# 达拉然大法师
			data.behavior = EnemyData.BehaviorType.RANGED
			data.base_hp = 14.0
			data.base_damage = 14.0
			data.speed = 45.0
			data.exp_drop = 4
			data.color = Color(0.5, 0.2, 0.8, 1.0)
			data.attack_range = 220.0
			data.attack_interval = 1.8
			data.projectile_speed = 240.0
		elif roll < 0.5:
			# 白银之手骑士 — 圣光冲锋
			data.behavior = EnemyData.BehaviorType.DASH
			data.base_hp = 28.0
			data.base_damage = 14.0
			data.speed = 75.0
			data.exp_drop = 4
			data.color = Color(1.0, 0.85, 0.2, 1.0)  # 圣光金
			data.dash_speed_mult = 3.5
			data.dash_interval = 2.5
			data.dash_duration = 0.5
		elif roll < 0.65:
			# 矮人火枪手精锐
			data.behavior = EnemyData.BehaviorType.CIRCLE
			data.base_hp = 20.0
			data.base_damage = 9.0
			data.speed = 110.0
			data.exp_drop = 3
			data.color = Color(0.6, 0.4, 0.2, 1.0)
		elif roll < 0.8:
			# 圣光牧师 — 死亡分裂出祈祷者
			data.behavior = EnemyData.BehaviorType.SPLIT
			data.base_hp = 45.0
			data.base_damage = 4.0
			data.speed = 65.0
			data.exp_drop = 5
			data.color = Color(1.0, 1.0, 0.8, 1.0)  # 圣光白金
			data.split_count = 2
			data.split_hp_ratio = 0.3
		else:
			# 铁炉堡山王 — 超厚坦克
			data.behavior = EnemyData.BehaviorType.TANK
			data.base_hp = 90.0
			data.base_damage = 5.0
			data.speed = 38.0
			data.exp_drop = 6
			data.color = Color(0.5, 0.5, 0.6, 1.0)  # 铁灰
			data.scale_mult = 1.5

	enemy.initialize(data, _player, difficulty_mult)


func _get_available_enemy_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _unlocked_enemies:
		if entry.get("unlocked", false):
			result.append(entry)
	return result


func _weighted_pick(entries: Array[Dictionary]) -> Dictionary:
	var total_weight: int = 0
	for entry: Dictionary in entries:
		total_weight += entry.get("weight", 10) as int
	var roll := randi() % maxi(total_weight, 1)
	var cumulative: int = 0
	for entry: Dictionary in entries:
		cumulative += entry.get("weight", 10) as int
		if roll < cumulative:
			return entry
	return entries[0]


func on_enemy_killed(_enemy: Node2D, _exp_value: int) -> void:
	kill_count += 1


## --- 经验 / 升级 ---

func add_exp(amount: int) -> void:
	player_exp += amount
	while player_exp >= exp_to_next_level:
		player_exp -= exp_to_next_level
		player_level += 1
		exp_to_next_level = _calc_exp_requirement(player_level)
		player_leveled_up.emit(player_level)
		activate_magnet()
		_show_recruit_panel()


func _calc_exp_requirement(level: int) -> int:
	# 前5级快速升级（教学期），之后平缓增长
	if level <= 5:
		return 8 + (level - 1) * 3
	else:
		return 20 + (level - 5) * 4


## --- 摄像机 ---

func _update_camera(delta: float) -> void:
	if not _player:
		return
	camera.global_position = _player.global_position

	var ally_count := _allies.size()
	if ally_count <= 4:
		_camera_target_zoom = CAMERA_ZOOM_MAX
	else:
		var t := clampf((float(ally_count) - 4.0) / 16.0, 0.0, 1.0)
		_camera_target_zoom = lerpf(CAMERA_ZOOM_MAX, CAMERA_ZOOM_MIN, t)

	var current_zoom := camera.zoom.x
	var new_zoom := lerpf(current_zoom, _camera_target_zoom, delta * CAMERA_ZOOM_SPEED)
	camera.zoom = Vector2(new_zoom, new_zoom)


## --- 屏幕震动 ---

func _update_shake(delta: float) -> void:
	if _shake_intensity > 0.0:
		_shake_intensity = maxf(_shake_intensity - _shake_decay * delta, 0.0)
		camera.offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO


func shake_camera(intensity: float, decay: float = 5.0) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_decay = decay


## --- 经验磁铁 ---

func _update_magnet(delta: float) -> void:
	if not _magnet_active:
		return
	_magnet_timer -= delta
	if _magnet_timer <= 0.0:
		_magnet_active = false
		return
	# 吸取所有经验宝石
	var gems := get_tree().get_nodes_in_group("exp_gems")
	for gem: Node2D in gems:
		if gem.has_method("attract_to"):
			gem.attract_to(_player.global_position)


func activate_magnet() -> void:
	_magnet_active = true
	_magnet_timer = MAGNET_DURATION


## --- 玩家初始化 ---

func _setup_player() -> void:
	_player = _player_scene.instantiate()
	_player.global_position = Vector2.ZERO
	player_node.add_child(_player)
	_player.add_to_group("player")
	_player.died.connect(_on_player_died)
	_player.hp_changed.connect(_on_player_hp_changed)

	# 应用选中角色数据
	var char_data: Dictionary = GameManager.get_selected_character_data()
	if not char_data.is_empty():
		var char_id: StringName = char_data.get("id", &"swordfish")
		var level: int = SaveManager.get_character_level(char_id)
		var level_mult: float = 1.0 + (level - 1) * 0.1
		_player.max_hp = char_data.get("base_hp", 120.0) * level_mult
		_player.current_hp = _player.max_hp
		_player.speed = char_data.get("base_speed", 180.0)
		_player.damage = char_data.get("base_damage", 12.0) * level_mult
		_player.attack_range = 160.0
		_player._attack_interval = char_data.get("attack_interval", 0.5)
		# 角色颜色
		var char_color: Color = char_data.get("color", Color(0.3, 0.7, 1.0))
		if _player.sprite:
			_player.sprite.modulate = char_color


func _setup_joystick() -> void:
	var joystick_scene := preload("res://scenes/ui/virtual_joystick.tscn")
	_joystick = joystick_scene.instantiate()
	ui_layer.add_child(_joystick)
	_joystick.direction_changed.connect(_on_joystick_direction_changed)


## --- 队友管理 ---

func recruit_ally(ally_data: AllyData) -> void:
	# 自走棋式：每次招募都生成一个独立单位，凑齐 3 个同名同星自动合成
	_spawn_ally(ally_data)
	var ally_id := ally_data.id
	if _ally_roster.has(ally_id):
		_ally_roster[ally_id]["count"] += 1
	else:
		_ally_roster[ally_id] = {"data": ally_data, "count": 1}
	_check_merge(ally_id, 1)


func _spawn_ally(ally_data: AllyData) -> void:
	var ally := _ally_scene.instantiate() as Ally
	var index := _allies.size()
	# 先加入场景树，确保 @onready 的 Sprite 已就绪，再初始化（否则占位纹理赋值会被跳过）
	allies_container.add_child(ally)
	ally.global_position = _player.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	ally.initialize(ally_data, _player, index)
	_allies.append(ally)
	# 招募出现动画
	if ally.has_method("play_spawn_anim"):
		ally.play_spawn_anim()


## 检测并执行合成：同 id 同星级满 3 个 → 合成 1 个高一星
func _check_merge(ally_id: StringName, star: int) -> void:
	if star >= 3:
		return
	var same: Array[Ally] = []
	for node: Node2D in _allies:
		if node is Ally:
			var a := node as Ally
			if a.ally_data and a.ally_data.id == ally_id and a.star_level == star:
				same.append(a)
	if same.size() < 3:
		return

	# 取前 3 个合成
	var merge_group: Array[Ally] = []
	merge_group.append(same[0])
	merge_group.append(same[1])
	merge_group.append(same[2])
	var merge_pos: Vector2 = merge_group[0].global_position
	var base_data: AllyData = merge_group[0].ally_data
	var new_star := star + 1

	# 合成动画：3 个聚拢到中心点 + 闪光，然后销毁
	for unit: Ally in merge_group:
		if unit.has_method("play_merge_anim"):
			unit.play_merge_anim(merge_pos)
		_allies.erase(unit)

	# 延迟生成合成体（等聚拢动画播完）
	var timer := get_tree().create_timer(0.35)
	timer.timeout.connect(_finish_merge.bind(base_data, new_star, merge_pos))


func _finish_merge(base_data: AllyData, new_star: int, pos: Vector2) -> void:
	var ally := _ally_scene.instantiate() as Ally
	var index := _allies.size()
	allies_container.add_child(ally)
	ally.global_position = pos
	ally.initialize(base_data, _player, index)
	# 升到目标星级
	while ally.star_level < new_star:
		ally.upgrade_star()
	_allies.append(ally)
	# 合成完成爆发动画
	if ally.has_method("play_merge_pop_anim"):
		ally.play_merge_pop_anim()
	# 继续检测是否能再次合成（如 2★ 也凑够 3 个）
	if base_data:
		_check_merge(base_data.id, new_star)


## --- 升级招募面板（3选1）---

func _show_recruit_panel() -> void:
	is_paused = true
	get_tree().paused = true

	var panel := ColorRect.new()
	panel.name = "RecruitPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0, 0, 0, 0.6)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	# 显式设置字体
	var font := load("res://assets/fonts/zpix.ttf") as Font
	if font:
		var panel_theme := Theme.new()
		panel_theme.default_font = font
		panel_theme.default_font_size = 12
		panel.theme = panel_theme
	ui_layer.add_child(panel)

	var title := Label.new()
	title.text = "等级 %d！选择一位队友（集齐3个同名合成升星）" % player_level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(40, 200)
	title.size = Vector2(400, 40)
	panel.add_child(title)

	var options := _generate_recruit_options(3)
	for i: int in options.size():
		var btn := Button.new()
		var opt: Dictionary = options[i]
		var ally_name: String = opt.get("name", "鱼人")
		var ally_desc: String = opt.get("desc", "")
		btn.text = "%s\n%s" % [ally_name, ally_desc]
		btn.position = Vector2(80, 280 + i * 120)
		btn.size = Vector2(320, 100)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_recruit_selected.bind(opt, panel))
		panel.add_child(btn)


func _generate_recruit_options(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = [
		{"id": &"murloc_tidehunter", "name": "鱼人猎潮者", "type": "远程", "effect": "pierce",
			"desc": "鱼叉穿透2敌", "color": Color(0.2, 0.7, 0.5)},
		{"id": &"murloc_warleader", "name": "鱼人战争队长", "type": "近战", "effect": "none",
			"desc": "高伤冲锋近战，鼓舞周围", "color": Color(0.3, 0.9, 0.3)},
		{"id": &"murloc_tidecaller", "name": "鱼人唤潮者", "type": "范围", "effect": "slow",
			"desc": "潮汐波减速范围敌人", "color": Color(0.2, 0.5, 0.9)},
		{"id": &"murloc_oracle", "name": "鱼人先知", "type": "辅助", "effect": "heal",
			"desc": "水疗术周期治疗主角", "color": Color(0.3, 0.8, 0.9)},
		{"id": &"murloc_nightcrawler", "name": "鱼人夜行者", "type": "近战", "effect": "poison",
			"desc": "淬毒匕首持续掉血", "color": Color(0.4, 0.9, 0.2)},
		{"id": &"makrura_snapclaw", "name": "螃蟹人利爪", "type": "近战", "effect": "knockback",
			"desc": "钳击猛击击退敌人", "color": Color(0.8, 0.3, 0.2)},
		{"id": &"murloc_seer", "name": "鱼人巫医", "type": "连锁", "effect": "chain",
			"desc": "闪电链弹射3目标", "color": Color(0.6, 0.2, 0.9)},
		{"id": &"murloc_raider", "name": "鱼人掠袭者", "type": "远程", "effect": "pierce",
			"desc": "高速飞鱼镖穿透3敌", "color": Color(0.1, 0.6, 0.7)},
		{"id": &"makrura_boomer", "name": "螃蟹人爆破蟹", "type": "近战", "effect": "explode",
			"desc": "蟹钳炸裂AOE伤害", "color": Color(0.9, 0.4, 0.1)},
		{"id": &"murloc_lurker", "name": "鱼人潜伏者", "type": "陷阱", "effect": "slow",
			"desc": "放置水洼减速陷阱", "color": Color(0.2, 0.4, 0.6)},
	]

	var results: Array[Dictionary] = []
	var used_indices: Array[int] = []

	for i: int in count:
		var idx := randi() % pool.size()
		var attempts: int = 0
		while idx in used_indices and attempts < 10:
			idx = randi() % pool.size()
			attempts += 1
		used_indices.append(idx)
		results.append(pool[idx])

	return results


func _get_ally_name_by_id(id: StringName) -> String:
	var names := {
		&"murloc_tidehunter": "鱼人猎潮者",
		&"murloc_warleader": "鱼人战争队长",
		&"murloc_tidecaller": "鱼人唤潮者",
		&"murloc_oracle": "鱼人先知",
		&"murloc_nightcrawler": "鱼人夜行者",
		&"makrura_snapclaw": "螃蟹人利爪",
		&"murloc_seer": "鱼人巫医",
		&"murloc_raider": "鱼人掠袭者",
		&"makrura_boomer": "螃蟹人爆破蟹",
		&"murloc_lurker": "鱼人潜伏者",
	}
	return names.get(id, "鱼人")


func _on_recruit_selected(option: Dictionary, panel: Control) -> void:
	panel.queue_free()
	is_paused = false
	get_tree().paused = false

	var ally_id: StringName = option.get("id", &"")
	var data := AllyData.new()
	data.id = ally_id
	data.display_name = option.get("name", "鱼人")
	data.base_damage = 6.0 + player_level * 2.0
	data.attack_interval = 1.0
	data.preferred_distance = 80.0
	data.color = option.get("color", Color(0.3, 0.8, 1.0))

	# 攻击类型
	var type_str: String = option.get("type", "远程")
	match type_str:
		"近战":
			data.attack_type = AllyData.AttackType.MELEE
			data.base_damage *= 1.3
			data.attack_interval = 0.7
		"远程":
			data.attack_type = AllyData.AttackType.RANGED
		"辅助":
			data.attack_type = AllyData.AttackType.SUPPORT
			data.base_damage *= 0.8
			data.attack_interval = 1.5
		"范围":
			data.attack_type = AllyData.AttackType.AOE
			data.base_damage *= 0.9
			data.attack_interval = 1.2
		"连锁":
			data.attack_type = AllyData.AttackType.CHAIN
			data.attack_interval = 1.3
		"陷阱":
			data.attack_type = AllyData.AttackType.TRAP
			data.attack_interval = 2.0

	# 特殊效果
	var effect_str: String = option.get("effect", "none")
	match effect_str:
		"pierce":
			data.special_effect = AllyData.SpecialEffect.PIERCE
			data.pierce_count = 2
		"slow":
			data.special_effect = AllyData.SpecialEffect.SLOW
			data.slow_percent = 0.4
			data.slow_duration = 2.0
		"poison":
			data.special_effect = AllyData.SpecialEffect.POISON
			data.poison_dps = 3.0
			data.poison_duration = 3.0
		"knockback":
			data.special_effect = AllyData.SpecialEffect.KNOCKBACK
			data.knockback_force = 150.0
		"heal":
			data.special_effect = AllyData.SpecialEffect.HEAL_AURA
			data.heal_amount = 2.0
			data.heal_interval = 3.0
		"explode":
			data.special_effect = AllyData.SpecialEffect.EXPLODE
			data.explode_radius = 60.0
		"chain":
			data.special_effect = AllyData.SpecialEffect.CHAIN_LIGHTNING
			data.chain_targets = 3
		_:
			data.special_effect = AllyData.SpecialEffect.NONE

	recruit_ally(data)


## --- 输入 ---

func _on_joystick_direction_changed(direction: Vector2) -> void:
	if _player:
		_player.input_direction = direction


## --- 暂停系统 ---

func _on_pause_pressed() -> void:
	if is_game_over:
		return
	if is_paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true

	var panel := ColorRect.new()
	panel.name = "PausePanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0, 0, 0, 0.5)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(panel)

	# 居中容器：自动撑满全屏并把内容居中
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var label := Label.new()
	label.text = "暂停"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var resume_btn := Button.new()
	resume_btn.text = "继续"
	resume_btn.custom_minimum_size = Vector2(160, 50)
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(_resume_game)
	vbox.add_child(resume_btn)

	var quit_btn := Button.new()
	quit_btn.text = "退出关卡"
	quit_btn.custom_minimum_size = Vector2(160, 50)
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		GameManager.return_to_chapter_map()
	)
	vbox.add_child(quit_btn)


func _resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	var panel := ui_layer.get_node_or_null("PausePanel")
	if panel:
		panel.queue_free()


## --- 玩家事件 ---

func _on_player_died() -> void:
	is_game_over = true
	spawn_timer.stop()
	_show_game_over()


func _on_player_hp_changed(_current: float, _max_hp: float) -> void:
	pass


## --- HUD ---

func _setup_hud() -> void:
	var hud := Control.new()
	hud.name = "HUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 显式设置字体 theme，确保 Web 上不乱码
	var font := load("res://assets/fonts/zpix.ttf") as Font
	if font:
		var hud_theme := Theme.new()
		hud_theme.default_font = font
		hud_theme.default_font_size = 12
		hud.theme = hud_theme
	ui_layer.add_child(hud)

	var hp_bg := ColorRect.new()
	hp_bg.name = "HPBarBG"
	hp_bg.position = Vector2(16, 16)
	hp_bg.size = Vector2(200, 16)
	hp_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	hud.add_child(hp_bg)

	var hp_bar := ColorRect.new()
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(16, 16)
	hp_bar.size = Vector2(200, 16)
	hp_bar.color = Color(0.2, 0.8, 0.3, 1.0)
	hud.add_child(hp_bar)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.position = Vector2(16, 36)
	level_label.text = "Lv.1"
	hud.add_child(level_label)

	var ally_label := Label.new()
	ally_label.name = "AllyLabel"
	ally_label.position = Vector2(16, 56)
	ally_label.text = "队友: 0"
	hud.add_child(ally_label)

	var time_label := Label.new()
	time_label.name = "TimeLabel"
	time_label.position = Vector2(380, 16)
	time_label.text = "0:00"
	hud.add_child(time_label)

	var exp_bg := ColorRect.new()
	exp_bg.name = "EXPBarBG"
	exp_bg.position = Vector2(16, 76)
	exp_bg.size = Vector2(200, 8)
	exp_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	hud.add_child(exp_bg)

	var exp_bar := ColorRect.new()
	exp_bar.name = "EXPBar"
	exp_bar.position = Vector2(16, 76)
	exp_bar.size = Vector2(0, 8)
	exp_bar.color = Color(0.3, 0.5, 1.0, 1.0)
	hud.add_child(exp_bar)

	# 大招充能条背景
	var ult_bg := ColorRect.new()
	ult_bg.name = "UltBarBG"
	ult_bg.position = Vector2(16, 90)
	ult_bg.size = Vector2(100, 6)
	ult_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	hud.add_child(ult_bg)

	# 大招充能条前景
	var ult_bar := ColorRect.new()
	ult_bar.name = "UltBar"
	ult_bar.position = Vector2(16, 90)
	ult_bar.size = Vector2(0, 6)
	ult_bar.color = Color(1.0, 0.6, 0.1, 1.0)
	hud.add_child(ult_bar)

	# 击杀数
	var kill_label := Label.new()
	kill_label.name = "KillLabel"
	kill_label.position = Vector2(380, 36)
	kill_label.text = "击杀: 0"
	hud.add_child(kill_label)

	# 暂停按钮
	var pause_btn := Button.new()
	pause_btn.name = "PauseButton"
	pause_btn.text = "||"
	pause_btn.position = Vector2(420, 56)
	pause_btn.size = Vector2(40, 40)
	pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn.pressed.connect(_on_pause_pressed)
	hud.add_child(pause_btn)


func _update_hud() -> void:
	var hud := ui_layer.get_node_or_null("HUD")
	if not hud:
		return

	var hp_bar := hud.get_node_or_null("HPBar") as ColorRect
	if hp_bar and _player:
		var ratio: float = _player.current_hp / _player.max_hp
		hp_bar.size.x = 200.0 * ratio
		if ratio < 0.3:
			hp_bar.color = Color(0.9, 0.2, 0.2, 1.0)
		elif ratio < 0.6:
			hp_bar.color = Color(0.9, 0.7, 0.2, 1.0)
		else:
			hp_bar.color = Color(0.2, 0.8, 0.3, 1.0)

	var level_label := hud.get_node_or_null("LevelLabel") as Label
	if level_label:
		level_label.text = "Lv.%d" % player_level

	var ally_label := hud.get_node_or_null("AllyLabel") as Label
	if ally_label:
		ally_label.text = "队友: %d" % _allies.size()

	var time_label := hud.get_node_or_null("TimeLabel") as Label
	if time_label:
		var remaining := maxi(int(_stage_duration - elapsed_time), 0)
		var minutes := remaining / 60
		var seconds := remaining % 60
		time_label.text = "%d:%02d" % [minutes, seconds]

	var exp_bar := hud.get_node_or_null("EXPBar") as ColorRect
	if exp_bar:
		var ratio: float = float(player_exp) / float(exp_to_next_level)
		exp_bar.size.x = 200.0 * ratio

	var kill_label := hud.get_node_or_null("KillLabel") as Label
	if kill_label:
		kill_label.text = "击杀: %d" % kill_count

	# 大招充能条
	var ult_bar := hud.get_node_or_null("UltBar") as ColorRect
	if ult_bar and _player:
		var ult_ratio: float = _player.ultimate_energy / _player.ultimate_max
		ult_bar.size.x = 100.0 * ult_ratio
		if ult_ratio >= 1.0:
			ult_bar.color = Color(1.0, 1.0, 0.3, 1.0)  # 满了变亮黄
		else:
			ult_bar.color = Color(1.0, 0.6, 0.1, 1.0)


## --- Boss 血条更新 ---

func _update_boss_hp_bar() -> void:
	if not _boss_active:
		return
	var bar := ui_layer.get_node_or_null("BossHPBar") as ColorRect
	if not bar:
		return
	# 找到当前 Boss
	var bosses := get_tree().get_nodes_in_group("boss")
	if bosses.is_empty():
		return
	var boss: Node2D = bosses[0]
	var hp_val: float = boss.get("hp") if boss.get("hp") != null else 0.0
	var max_hp_val: float = boss.get("max_hp") if boss.get("max_hp") != null else 1.0
	var ratio: float = clampf(hp_val / maxf(max_hp_val, 1.0), 0.0, 1.0)
	bar.size.x = 300.0 * ratio


## --- 胜利结算 ---

func _show_victory() -> void:
	var stars := _calc_stars()
	GameManager.complete_stage(stars)

	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0, 0, 0, 0.7)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(panel)

	var star_text := "★".repeat(stars) + "☆".repeat(3 - stars)
	var gold_reward: int = 20 + stars * 10 + GameManager.current_stage * 5
	var label := Label.new()
	label.text = "胜利！\n\n%s\n\n击杀: %d\n等级: %d\n队友: %d\n金币: +%d\n\n点击返回" % [
		star_text,
		kill_count,
		player_level,
		_allies.size(),
		gold_reward,
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-80, -60)
	panel.add_child(label)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventScreenTouch and event.pressed:
			get_tree().paused = false
			GameManager.return_to_chapter_map()
		elif event is InputEventMouseButton and event.pressed:
			get_tree().paused = false
			GameManager.return_to_chapter_map()
	)


func _calc_stars() -> int:
	if not _player:
		return 1
	var hp_percent: float = _player.current_hp / _player.max_hp
	var star3_threshold := 0.8
	var star2_threshold := 0.5
	if stage_data:
		star3_threshold = stage_data.star3_hp_percent
		star2_threshold = stage_data.star2_hp_percent
	if hp_percent >= star3_threshold:
		return 3
	elif hp_percent >= star2_threshold:
		return 2
	else:
		return 1


## --- 游戏结束（死亡）---

func _show_game_over() -> void:
	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0, 0, 0, 0.7)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(panel)

	var label := Label.new()
	label.text = "战败...\n\n存活: %d:%02d\n击杀: %d\n等级: %d\n队友: %d\n\n点击返回" % [
		int(elapsed_time) / 60,
		int(elapsed_time) % 60,
		kill_count,
		player_level,
		_allies.size(),
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-80, -60)
	panel.add_child(label)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventScreenTouch and event.pressed:
			get_tree().paused = false
			GameManager.return_to_chapter_map()
		elif event is InputEventMouseButton and event.pressed:
			get_tree().paused = false
			GameManager.return_to_chapter_map()
	)

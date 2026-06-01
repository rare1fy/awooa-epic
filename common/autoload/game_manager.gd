class_name GameManagerClass
extends Node
## 全局游戏状态管理器
## 管理关卡进度、当前选择的角色、游戏状态、场景导航

signal stage_completed(chapter: int, stage: int, stars: int)
signal game_state_changed(new_state: GameState)

enum GameState {
	MENU,
	CHAPTER_MAP,
	CHARACTER_LIST,
	CHARACTER_DETAIL,
	BATTLE,
	PAUSED,
	RESULT,
}

var current_state: GameState = GameState.MENU
var current_chapter: int = 1
var current_stage: int = 1
var selected_character_id: StringName = &"swordfish"

## 当前关卡数据（传递给 battle 场景）
var pending_stage_data: StageData = null

## 角色详情页用
var viewing_character_id: StringName = &""

## 全局字体
var _pixel_font: Font = null


func _ready() -> void:
	_setup_global_font()


func _setup_global_font() -> void:
	# 加载像素字体并设置为全局默认 Theme（作为 project.godot 设置的备份）
	_pixel_font = load("res://assets/fonts/zpix.ttf") as Font
	if _pixel_font:
		var theme := Theme.new()
		theme.default_font = _pixel_font
		theme.default_font_size = 12
		# 设置为全局 Theme
		if get_tree() and get_tree().root:
			get_tree().root.theme = theme
	else:
		push_warning("Failed to load zpix.ttf font")


func change_state(new_state: GameState) -> void:
	current_state = new_state
	game_state_changed.emit(new_state)


func open_chapter_map() -> void:
	change_state(GameState.CHAPTER_MAP)
	get_tree().change_scene_to_file("res://scenes/chapter_map/chapter_map.tscn")


func open_character_list() -> void:
	change_state(GameState.CHARACTER_LIST)
	get_tree().change_scene_to_file("res://scenes/character_list/character_list.tscn")


func open_character_detail(character_id: StringName) -> void:
	viewing_character_id = character_id
	change_state(GameState.CHARACTER_DETAIL)
	get_tree().change_scene_to_file("res://scenes/character_detail/character_detail.tscn")


func start_battle(chapter: int, stage: int) -> void:
	current_chapter = chapter
	current_stage = stage
	pending_stage_data = StageRegistry.get_stage_data(chapter, stage)
	change_state(GameState.BATTLE)
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")


func complete_stage(stars: int) -> void:
	# 通关奖励金币
	var gold_reward: int = 20 + stars * 10 + current_stage * 5
	SaveManager.add_currency("gold", gold_reward)
	SaveManager.set_stage_stars(current_chapter, current_stage, stars)

	# 随机掉落角色碎片（30%概率）
	if randf() < 0.3 + stars * 0.1:
		var all_chars: Array[Dictionary] = CharacterRegistry.get_all_characters()
		var locked_chars: Array[Dictionary] = []
		for c: Dictionary in all_chars:
			var cid: StringName = c.get("id", &"")
			if not SaveManager.is_character_unlocked(cid):
				locked_chars.append(c)
		if not locked_chars.is_empty():
			var random_char: Dictionary = locked_chars[randi() % locked_chars.size()]
			var frag_id: StringName = random_char.get("id", &"")
			var frag_amount: int = 1 + stars  # 星级越高碎片越多
			SaveManager.add_character_fragments(frag_id, frag_amount)

	stage_completed.emit(current_chapter, current_stage, stars)
	change_state(GameState.RESULT)


func return_to_chapter_map() -> void:
	change_state(GameState.CHAPTER_MAP)
	get_tree().change_scene_to_file("res://scenes/chapter_map/chapter_map.tscn")


func return_to_menu() -> void:
	change_state(GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


## 获取当前出战角色的数据
func get_selected_character_data() -> Dictionary:
	return CharacterRegistry.get_character(selected_character_id)

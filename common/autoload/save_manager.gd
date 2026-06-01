class_name SaveManagerClass
extends Node
## 存档管理器
## 抖音小游戏环境下使用 tt.setStorage，编辑器环境下使用本地文件

const SAVE_KEY := "awooa_epic_save"

var save_data: Dictionary = {}


func _ready() -> void:
	load_game()


func save_game() -> void:
	if OS.has_feature("web"):
		_save_web()
	else:
		_save_local()


func load_game() -> void:
	if OS.has_feature("web"):
		_load_web()
	else:
		_load_local()


func get_stage_stars(chapter: int, stage: int) -> int:
	var key := "ch%d_st%d" % [chapter, stage]
	return save_data.get(key, 0) as int


func set_stage_stars(chapter: int, stage: int, stars: int) -> void:
	var key := "ch%d_st%d" % [chapter, stage]
	var current: int = get_stage_stars(chapter, stage)
	if stars > current:
		save_data[key] = stars
		save_game()


func get_character_level(character_id: StringName) -> int:
	var key := "char_%s_lv" % character_id
	return save_data.get(key, 1) as int


func set_character_level(character_id: StringName, level: int) -> void:
	var key := "char_%s_lv" % character_id
	save_data[key] = level
	save_game()


func is_character_unlocked(character_id: StringName) -> bool:
	var key := "char_%s_unlocked" % character_id
	if character_id == &"swordfish":
		return true  # 初始角色永远解锁
	return save_data.get(key, false) as bool


func unlock_character(character_id: StringName) -> void:
	var key := "char_%s_unlocked" % character_id
	save_data[key] = true
	save_game()


func get_character_fragments(character_id: StringName) -> int:
	var key := "char_%s_frags" % character_id
	return save_data.get(key, 0) as int


func add_character_fragments(character_id: StringName, amount: int) -> void:
	var key := "char_%s_frags" % character_id
	var current: int = get_character_fragments(character_id)
	save_data[key] = current + amount
	save_game()


func get_selected_talent(character_id: StringName) -> String:
	## 返回 "a" 或 "b"，默认 "a"
	var key := "char_%s_talent" % character_id
	return save_data.get(key, "a") as String


func set_selected_talent(character_id: StringName, talent: String) -> void:
	var key := "char_%s_talent" % character_id
	save_data[key] = talent
	save_game()


func get_currency(currency_type: String) -> int:
	return save_data.get(currency_type, 0) as int


func add_currency(currency_type: String, amount: int) -> void:
	var current: int = get_currency(currency_type)
	save_data[currency_type] = current + amount
	save_game()


# --- 本地存档 ---

func _save_local() -> void:
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))


func _load_local() -> void:
	if not FileAccess.file_exists("user://save.json"):
		save_data = _default_save()
		return
	var file := FileAccess.open("user://save.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			save_data = json.data
		else:
			save_data = _default_save()


# --- Web 存档（抖音 tt.setStorage）---

func _save_web() -> void:
	if OS.has_feature("web"):
		var tt := JavaScriptBridge.get_interface("tt")
		if tt:
			tt.setStorageSync(SAVE_KEY, JSON.stringify(save_data))


func _load_web() -> void:
	if OS.has_feature("web"):
		var tt := JavaScriptBridge.get_interface("tt")
		if tt:
			var raw = tt.getStorageSync(SAVE_KEY)
			if raw:
				var json := JSON.new()
				if json.parse(str(raw)) == OK:
					save_data = json.data
					return
	save_data = _default_save()


func _default_save() -> Dictionary:
	return {
		"gold": 0,
		"gems": 0,
		"char_swordfish_lv": 1,
	}

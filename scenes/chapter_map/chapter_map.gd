extends Control
## 章节选关界面
## 两级结构：章节列表 → 关卡列表（显示星级和解锁状态）

@onready var back_button: Button = %BackButton
@onready var chapter_list: VBoxContainer = %ChapterList
@onready var stage_panel: PanelContainer = %StagePanel
@onready var stage_list: VBoxContainer = %StageList
@onready var chapter_title_label: Label = %ChapterTitleLabel

var _current_chapter: int = 0


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	stage_panel.visible = false
	_build_chapter_list()


func _build_chapter_list() -> void:
	for child: Node in chapter_list.get_children():
		child.queue_free()

	for chapter_id: int in range(1, 6):
		var btn := Button.new()
		var chapter_name := StageRegistry.get_chapter_name(chapter_id)
		var total_stars := _get_chapter_total_stars(chapter_id)
		var max_stars := StageRegistry.get_stage_count(chapter_id) * 3
		var unlocked := _is_chapter_unlocked(chapter_id)

		if unlocked:
			btn.text = "第%d章：%s  ★%d/%d" % [chapter_id, chapter_name, total_stars, max_stars]
		else:
			btn.text = "第%d章：%s  🔒" % [chapter_id, chapter_name]
			btn.disabled = true

		btn.pressed.connect(_on_chapter_selected.bind(chapter_id))
		chapter_list.add_child(btn)


func _on_chapter_selected(chapter: int) -> void:
	_current_chapter = chapter
	_show_stage_list(chapter)


func _show_stage_list(chapter: int) -> void:
	stage_panel.visible = true
	chapter_title_label.text = "第%d章：%s" % [chapter, StageRegistry.get_chapter_name(chapter)]

	for child: Node in stage_list.get_children():
		child.queue_free()

	var stage_count := StageRegistry.get_stage_count(chapter)
	for stage_id: int in range(1, stage_count + 1):
		var hbox := HBoxContainer.new()

		var btn := Button.new()
		var stage_name := StageRegistry.get_stage_name(chapter, stage_id)
		var stars := SaveManager.get_stage_stars(chapter, stage_id)
		var unlocked := StageRegistry.is_stage_unlocked(chapter, stage_id)

		if unlocked:
			var star_text := _star_display(stars)
			btn.text = "%d. %s  %s" % [stage_id, stage_name, star_text]
			btn.pressed.connect(_on_stage_selected.bind(chapter, stage_id))
		else:
			btn.text = "%d. %s  🔒" % [stage_id, stage_name]
			btn.disabled = true

		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(btn)
		stage_list.add_child(hbox)

	# 返回章节列表按钮
	var back_btn := Button.new()
	back_btn.text = "← 返回章节列表"
	back_btn.pressed.connect(_on_stage_panel_back)
	stage_list.add_child(back_btn)


func _on_stage_selected(chapter: int, stage: int) -> void:
	GameManager.start_battle(chapter, stage)


func _on_stage_panel_back() -> void:
	stage_panel.visible = false


func _on_back_pressed() -> void:
	if stage_panel.visible:
		stage_panel.visible = false
	else:
		GameManager.return_to_menu()


func _star_display(stars: int) -> String:
	match stars:
		0: return "☆☆☆"
		1: return "★☆☆"
		2: return "★★☆"
		3: return "★★★"
		_: return "☆☆☆"


func _get_chapter_total_stars(chapter: int) -> int:
	var total := 0
	var stage_count := StageRegistry.get_stage_count(chapter)
	for stage_id: int in range(1, stage_count + 1):
		total += SaveManager.get_stage_stars(chapter, stage_id)
	return total


func _is_chapter_unlocked(chapter: int) -> bool:
	if chapter == 1:
		return true
	return StageRegistry.is_stage_unlocked(chapter, 1)

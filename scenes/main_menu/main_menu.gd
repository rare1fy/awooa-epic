extends Control

@onready var start_button: Button = %StartButton
@onready var chapter_button: Button = %ChapterButton
@onready var character_button: Button = %CharacterButton
@onready var title_label: Label = %TitleLabel
@onready var gold_label: Label = %GoldLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	chapter_button.pressed.connect(_on_chapter_pressed)
	character_button.pressed.connect(_on_character_pressed)
	_add_siege_prototype_button()
	start_button.grab_focus()
	_update_currency_display()


func _update_currency_display() -> void:
	var gold: int = SaveManager.get_currency("gold")
	gold_label.text = "Gold: %d" % gold


func _on_start_pressed() -> void:
	var target := _find_latest_unlocked_stage()
	GameManager.start_battle(target.chapter, target.stage)


func _on_chapter_pressed() -> void:
	GameManager.open_chapter_map()


func _add_siege_prototype_button() -> void:
	var container := get_node_or_null("ButtonContainer") as VBoxContainer
	if not container:
		return
	var siege_button := Button.new()
	siege_button.text = "Siege Prototype"
	siege_button.custom_minimum_size = Vector2(200, 50)
	siege_button.pressed.connect(_on_siege_pressed)
	container.add_child(siege_button)


func _on_siege_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle_siege.tscn")


func _on_character_pressed() -> void:
	GameManager.open_character_list()


func _find_latest_unlocked_stage() -> Dictionary:
	for chapter: int in range(1, 6):
		var stage_count := StageRegistry.get_stage_count(chapter)
		for stage: int in range(1, stage_count + 1):
			if SaveManager.get_stage_stars(chapter, stage) == 0:
				if StageRegistry.is_stage_unlocked(chapter, stage):
					return {"chapter": chapter, "stage": stage}
	return {"chapter": 5, "stage": StageRegistry.get_stage_count(5)}

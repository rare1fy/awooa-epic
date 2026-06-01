extends Control
## 角色列表界面
## 展示所有鱼人英雄，显示解锁状态、等级、碎片进度

signal character_selected(character_id: StringName)

var _characters: Array[Dictionary] = []
var _card_nodes: Array[Control] = []


func _ready() -> void:
	_characters = CharacterRegistry.get_all_characters()
	_build_ui()


func _build_ui() -> void:
	# 顶部栏
	var top_bar := _create_top_bar()
	add_child(top_bar)

	# 滚动容器
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 60.0
	scroll.offset_bottom = 0.0
	add_child(scroll)

	# 网格容器（2列）
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	# 生成角色卡片
	for char_data: Dictionary in _characters:
		var card := _create_character_card(char_data)
		grid.add_child(card)
		_card_nodes.append(card)


func _create_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	bar.offset_left = 0.0
	bar.offset_top = 0.0
	bar.offset_right = 480.0
	bar.offset_bottom = 50.0

	var back_btn := Button.new()
	back_btn.text = "< 返回"
	back_btn.custom_minimum_size = Vector2(80, 40)
	back_btn.pressed.connect(_on_back_pressed)
	bar.add_child(back_btn)

	var title := Label.new()
	title.text = "鱼人军团"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(title)

	var gold_label := Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "金币: %d" % SaveManager.get_currency("gold")
	gold_label.custom_minimum_size = Vector2(80, 40)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(gold_label)

	return bar


func _create_character_card(char_data: Dictionary) -> Control:
	var id: StringName = char_data.get("id", &"")
	var is_unlocked: bool = SaveManager.is_character_unlocked(id)
	var level: int = SaveManager.get_character_level(id)
	var fragments: int = SaveManager.get_character_fragments(id)
	var unlock_cost: int = char_data.get("unlock_cost", 10) as int
	var char_color: Color = char_data.get("color", Color.WHITE)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 160)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# 角色图标（用颜色方块代替）
	var icon_rect := ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(60, 60)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if is_unlocked:
		icon_rect.color = char_color
	else:
		icon_rect.color = Color(0.3, 0.3, 0.3, 0.8)
	vbox.add_child(icon_rect)

	# 名字
	var name_label := Label.new()
	name_label.text = char_data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not is_unlocked:
		name_label.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(name_label)

	# 稀有度星星
	var rarity: int = char_data.get("rarity", 1) as int
	var rarity_label := Label.new()
	rarity_label.text = "★".repeat(rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match rarity:
		1:
			rarity_label.modulate = Color(0.8, 0.8, 0.8)
		2:
			rarity_label.modulate = Color(0.3, 0.6, 1.0)
		3:
			rarity_label.modulate = Color(0.8, 0.4, 1.0)
	vbox.add_child(rarity_label)

	# 状态行
	var status_label := Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_unlocked:
		status_label.text = "Lv.%d" % level
	else:
		status_label.text = "碎片 %d/%d" % [fragments, unlock_cost]
		status_label.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(status_label)

	# 点击事件
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_on_card_clicked(id)
		elif event is InputEventScreenTouch and event.pressed:
			_on_card_clicked(id)
	)

	return card


func _on_card_clicked(character_id: StringName) -> void:
	GameManager.open_character_detail(character_id)


func _on_back_pressed() -> void:
	GameManager.return_to_menu()

extends Control
## 角色详情界面
## 展示角色属性、天赋选择、升级、解锁、出战设置

var _character_id: StringName = &""
var _char_data: Dictionary = {}
var _is_unlocked: bool = false
var _level: int = 1


func setup(character_id: StringName) -> void:
	_character_id = character_id
	_char_data = CharacterRegistry.get_character(character_id)
	_is_unlocked = SaveManager.is_character_unlocked(character_id)
	_level = SaveManager.get_character_level(character_id)


func _ready() -> void:
	if _character_id == &"":
		# 从 GameManager 获取
		_character_id = GameManager.viewing_character_id
		setup(_character_id)
	_build_ui()


func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.1, 0.16, 1)
	add_child(bg)

	# 顶部返回栏
	var top_bar := _create_top_bar()
	add_child(top_bar)

	# 主内容滚动
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 50.0
	add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	# 角色头部区域
	_build_header(content)
	# 属性面板
	_build_stats_panel(content)
	# 天赋选择
	_build_talent_panel(content)
	# 大招信息
	_build_ultimate_panel(content)
	# 妙具信息
	_build_gadget_panel(content)
	# 操作按钮
	_build_action_buttons(content)


func _create_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.offset_left = 8.0
	bar.offset_top = 4.0
	bar.offset_right = 472.0
	bar.offset_bottom = 44.0

	var back_btn := Button.new()
	back_btn.text = "< 返回"
	back_btn.custom_minimum_size = Vector2(80, 36)
	back_btn.pressed.connect(_on_back_pressed)
	bar.add_child(back_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	return bar


func _build_header(parent: Control) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	parent.add_child(header)

	# 角色图标
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	var char_color: Color = _char_data.get("color", Color.WHITE)
	icon.color = char_color if _is_unlocked else Color(0.3, 0.3, 0.3)
	header.add_child(icon)

	# 名字 + 稀有度 + 等级
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = _char_data.get("name", "???")
	info_vbox.add_child(name_label)

	var rarity: int = _char_data.get("rarity", 1) as int
	var rarity_label := Label.new()
	rarity_label.text = "★".repeat(rarity)
	match rarity:
		1:
			rarity_label.modulate = Color(0.8, 0.8, 0.8)
		2:
			rarity_label.modulate = Color(0.3, 0.6, 1.0)
		3:
			rarity_label.modulate = Color(0.8, 0.4, 1.0)
	info_vbox.add_child(rarity_label)

	var level_label := Label.new()
	if _is_unlocked:
		level_label.text = "等级 %d / 10" % _level
	else:
		var frags: int = SaveManager.get_character_fragments(_character_id)
		var cost: int = _char_data.get("unlock_cost", 10) as int
		level_label.text = "未解锁 (碎片 %d/%d)" % [frags, cost]
		level_label.modulate = Color(0.6, 0.6, 0.6)
	info_vbox.add_child(level_label)


func _build_stats_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— 属性 —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 计算等级加成
	var level_mult := 1.0 + (_level - 1) * 0.1
	var hp: float = _char_data.get("base_hp", 100.0) * level_mult
	var dmg: float = _char_data.get("base_damage", 10.0) * level_mult
	var spd: float = _char_data.get("base_speed", 180.0)
	var atk_interval: float = _char_data.get("attack_interval", 0.5)

	_add_stat_row(vbox, "生命值", "%.0f" % hp)
	_add_stat_row(vbox, "攻击力", "%.0f" % dmg)
	_add_stat_row(vbox, "移动速度", "%.0f" % spd)
	_add_stat_row(vbox, "攻击间隔", "%.2fs" % atk_interval)


func _add_stat_row(parent: Control, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)


func _build_talent_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— 天赋 (二选一) —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var selected_talent: String = SaveManager.get_selected_talent(_character_id)
	var unlock_level_talent: int = 5  # 5级解锁天赋选择

	# 天赋 A
	var btn_a := Button.new()
	btn_a.name = "TalentA"
	var ta_name: String = _char_data.get("talent_a_name", "天赋A")
	var ta_desc: String = _char_data.get("talent_a_desc", "")
	btn_a.text = "[A] %s\n%s" % [ta_name, ta_desc]
	btn_a.custom_minimum_size = Vector2(0, 60)
	if _level < unlock_level_talent:
		btn_a.disabled = true
		btn_a.text += "\n(Lv.%d 解锁)" % unlock_level_talent
	elif selected_talent == "a":
		btn_a.modulate = Color(0.5, 1.0, 0.5)
	btn_a.pressed.connect(_on_talent_selected.bind("a"))
	vbox.add_child(btn_a)

	# 天赋 B
	var btn_b := Button.new()
	btn_b.name = "TalentB"
	var tb_name: String = _char_data.get("talent_b_name", "天赋B")
	var tb_desc: String = _char_data.get("talent_b_desc", "")
	btn_b.text = "[B] %s\n%s" % [tb_name, tb_desc]
	btn_b.custom_minimum_size = Vector2(0, 60)
	if _level < unlock_level_talent:
		btn_b.disabled = true
		btn_b.text += "\n(Lv.%d 解锁)" % unlock_level_talent
	elif selected_talent == "b":
		btn_b.modulate = Color(0.5, 1.0, 0.5)
	btn_b.pressed.connect(_on_talent_selected.bind("b"))
	vbox.add_child(btn_b)


func _build_ultimate_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— 大招 —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var ult_name := Label.new()
	ult_name.text = _char_data.get("ultimate_name", "大招")
	ult_name.modulate = Color(1.0, 0.8, 0.2)
	vbox.add_child(ult_name)

	var ult_desc := Label.new()
	ult_desc.text = _char_data.get("ultimate_desc", "")
	ult_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(ult_desc)


func _build_gadget_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— 妙具 (Lv.7 解锁) —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var gadget_name := Label.new()
	gadget_name.text = _char_data.get("gadget_name", "妙具")
	if _level >= 7:
		gadget_name.modulate = Color(0.4, 0.9, 1.0)
	else:
		gadget_name.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(gadget_name)

	var gadget_desc := Label.new()
	gadget_desc.text = _char_data.get("gadget_desc", "")
	gadget_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _level < 7:
		gadget_desc.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(gadget_desc)


func _build_action_buttons(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	parent.add_child(hbox)

	if not _is_unlocked:
		# 解锁按钮
		var unlock_btn := Button.new()
		var frags: int = SaveManager.get_character_fragments(_character_id)
		var cost: int = _char_data.get("unlock_cost", 10) as int
		unlock_btn.text = "解锁 (%d/%d 碎片)" % [frags, cost]
		unlock_btn.custom_minimum_size = Vector2(200, 50)
		unlock_btn.disabled = frags < cost
		unlock_btn.pressed.connect(_on_unlock_pressed)
		hbox.add_child(unlock_btn)
	else:
		# 升级按钮
		var upgrade_btn := Button.new()
		var upgrade_cost: int = _level * 50
		var gold: int = SaveManager.get_currency("gold")
		upgrade_btn.text = "升级 (花费 %d 金币)" % upgrade_cost
		upgrade_btn.custom_minimum_size = Vector2(200, 50)
		upgrade_btn.disabled = gold < upgrade_cost or _level >= 10
		if _level >= 10:
			upgrade_btn.text = "已满级"
		upgrade_btn.pressed.connect(_on_upgrade_pressed)
		hbox.add_child(upgrade_btn)

		# 出战按钮
		var select_btn := Button.new()
		if GameManager.selected_character_id == _character_id:
			select_btn.text = "当前出战"
			select_btn.disabled = true
		else:
			select_btn.text = "设为出战"
		select_btn.custom_minimum_size = Vector2(120, 50)
		select_btn.pressed.connect(_on_select_pressed)
		hbox.add_child(select_btn)


func _on_talent_selected(talent: String) -> void:
	if not _is_unlocked:
		return
	if _level < 5:
		return
	SaveManager.set_selected_talent(_character_id, talent)
	# 刷新界面
	_refresh()


func _on_unlock_pressed() -> void:
	var frags: int = SaveManager.get_character_fragments(_character_id)
	var cost: int = _char_data.get("unlock_cost", 10) as int
	if frags >= cost:
		SaveManager.add_character_fragments(_character_id, -cost)
		SaveManager.unlock_character(_character_id)
		_is_unlocked = true
		_refresh()


func _on_upgrade_pressed() -> void:
	var upgrade_cost: int = _level * 50
	var gold: int = SaveManager.get_currency("gold")
	if gold >= upgrade_cost and _level < 10:
		SaveManager.add_currency("gold", -upgrade_cost)
		_level += 1
		SaveManager.set_character_level(_character_id, _level)
		_refresh()


func _on_select_pressed() -> void:
	if _is_unlocked:
		GameManager.selected_character_id = _character_id
		_refresh()


func _refresh() -> void:
	# 清除所有子节点重建
	for child: Node in get_children():
		child.queue_free()
	# 延迟一帧重建
	await get_tree().process_frame
	_build_ui()


func _on_back_pressed() -> void:
	GameManager.open_character_list()

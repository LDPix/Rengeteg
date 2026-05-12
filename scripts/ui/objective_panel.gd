extends MarginContainer

const _BASE_BOTTOM_OFFSET := 208.0
const _MATERIAL_LINE_HEIGHT := 26.0
const _COLLAPSED_BOTTOM_OFFSET := 68.0

@onready var panel: PanelContainer = $Panel
@onready var section_label: Label = $Panel/Padding/Content/SectionLabel
@onready var primary_label: Label = $Panel/Padding/Content/PrimaryLabel
@onready var secondary_label: Label = $Panel/Padding/Content/SecondaryLabel
@onready var secondary_list: VBoxContainer = $Panel/Padding/Content/SecondaryList

var _material_labels: Array[Control] = []
var _collapsed := false
var _toggle_button: Button
var _completion_check: Label
var _known_completed_ids := {}
var _has_seen_objectives := false
var _completion_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 16.0
	offset_top = 16.0
	offset_right = 456.0
	offset_bottom = 208.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inject_toggle_button()
	_apply_theme()
	if not GameState.objectives_updated.is_connected(_refresh):
		GameState.objectives_updated.connect(_refresh)
	if not GameState.objectives_started.is_connected(_refresh):
		GameState.objectives_started.connect(_refresh)
	if not GameState.primary_objective_completed.is_connected(_on_objective_completed):
		GameState.primary_objective_completed.connect(_on_objective_completed)
	_refresh()


func _exit_tree() -> void:
	if GameState.objectives_updated.is_connected(_refresh):
		GameState.objectives_updated.disconnect(_refresh)
	if GameState.objectives_started.is_connected(_refresh):
		GameState.objectives_started.disconnect(_refresh)
	if GameState.primary_objective_completed.is_connected(_on_objective_completed):
		GameState.primary_objective_completed.disconnect(_on_objective_completed)


func _inject_toggle_button() -> void:
	var content := section_label.get_parent()
	var idx := section_label.get_index()

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	content.remove_child(section_label)
	content.add_child(header_row)
	content.move_child(header_row, idx)
	header_row.add_child(section_label)
	section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_completion_check = Label.new()
	_completion_check.text = "✓"
	_completion_check.visible = false
	_completion_check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_completion_check.add_theme_font_size_override("font_size", 26)
	WorldUI.apply_label(_completion_check, "title", "verdant")
	_completion_check.add_theme_color_override("font_color", Color("8cff8a"))
	header_row.add_child(_completion_check)

	_toggle_button = Button.new()
	_toggle_button.text = "▼"
	_toggle_button.flat = true
	_toggle_button.focus_mode = Control.FOCUS_NONE
	_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_toggle_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toggle_button.pressed.connect(_on_toggle_pressed)
	header_row.add_child(_toggle_button)


func _on_toggle_pressed() -> void:
	_collapsed = not _collapsed
	_apply_collapsed_state()


func _apply_collapsed_state() -> void:
	var show_body := not _collapsed
	primary_label.visible = show_body
	secondary_label.visible = show_body and not secondary_list.get_child_count() == 0
	secondary_list.visible = show_body
	for lbl in _material_labels:
		if is_instance_valid(lbl):
			lbl.visible = show_body
	_toggle_button.text = "▶" if _collapsed else "▼"
	if _collapsed:
		offset_bottom = _COLLAPSED_BOTTOM_OFFSET
	else:
		offset_bottom = _BASE_BOTTOM_OFFSET + _material_labels.size() * _MATERIAL_LINE_HEIGHT


func _refresh(_objectives: Array = []) -> void:
	for lbl in _material_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_material_labels.clear()

	var objectives := GameState.get_current_objectives()
	visible = not objectives.is_empty()
	if objectives.is_empty():
		_known_completed_ids.clear()
		_has_seen_objectives = false
		return

	_apply_theme()
	var primary := {}
	var secondary: Array = []
	for objective in objectives:
		if bool(objective.get("is_primary", false)) and primary.is_empty():
			primary = objective
		else:
			secondary.append(objective)
	if primary.is_empty():
		primary = objectives[0]

	_maybe_flash_completed_objective(objectives)

	section_label.text = "CURRENT OBJECTIVE"
	var primary_type := str(primary.get("type", ""))
	var primary_completed := bool(primary.get("completed", false))
	if primary_type == GameData.OBJECTIVE_TYPE_GATHER and not primary_completed:
		primary_label.text = str(primary.get("title", "OBJECTIVE"))
	else:
		primary_label.text = GameState.get_objective_display_text(primary)

	if primary_type == GameData.OBJECTIVE_TYPE_GATHER_MULTI and not primary_completed:
		var target_mats: Dictionary = primary.get("target_materials", {})
		var current_mats: Dictionary = primary.get("current_materials", {})
		var content: VBoxContainer = primary_label.get_parent() as VBoxContainer
		var insert_index: int = primary_label.get_index() + 1
		for mat in target_mats:
			var mat_str := str(mat)
			var have: int = int(current_mats.get(mat_str, 0))
			var need: int = int(target_mats.get(mat_str, 0))
			var done := have >= need
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var icon_path := str(WorldUI.RESOURCE_META.get(mat_str, {}).get("icon_path", ""))
			if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
				var icon := TextureRect.new()
				icon.texture = load(icon_path)
				icon.custom_minimum_size = Vector2(24, 24)
				icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				row.add_child(icon)
			var lbl := Label.new()
			lbl.text = "  %s  %d / %d%s" % [mat_str.capitalize(), have, need, " ✓" if done else ""]
			lbl.add_theme_font_size_override("font_size", 19)
			WorldUI.apply_label(lbl, "body", "crystal")
			lbl.add_theme_color_override("font_color", Color("aaddaa") if done else Color("fff4cc"))
			lbl.add_theme_color_override("font_outline_color", Color("46351f"))
			lbl.add_theme_constant_override("outline_size", 1)
			row.add_child(lbl)
			content.add_child(row)
			content.move_child(row, insert_index + _material_labels.size())
			_material_labels.append(row)
	elif primary_type == GameData.OBJECTIVE_TYPE_GATHER and not primary_completed:
		var target_id := str(primary.get("target_id", ""))
		var have := int(primary.get("current_amount", 0))
		var need := maxi(1, int(primary.get("target_amount", 1)))
		var content: VBoxContainer = primary_label.get_parent() as VBoxContainer
		var insert_index: int = primary_label.get_index() + 1
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon_path := str(WorldUI.RESOURCE_META.get(target_id, {}).get("icon_path", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.texture = load(icon_path)
			icon.custom_minimum_size = Vector2(24, 24)
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
		var lbl := Label.new()
		lbl.text = "%d / %d" % [have, need]
		lbl.add_theme_font_size_override("font_size", 19)
		WorldUI.apply_label(lbl, "body", "crystal")
		lbl.add_theme_color_override("font_color", Color("fff4cc"))
		lbl.add_theme_color_override("font_outline_color", Color("46351f"))
		lbl.add_theme_constant_override("outline_size", 1)
		row.add_child(lbl)
		content.add_child(row)
		content.move_child(row, insert_index)
		_material_labels.append(row)

	secondary_label.text = "BONUS OBJECTIVES"
	for child in secondary_list.get_children():
		child.queue_free()
	for objective in secondary:
		var obj_type := str(objective.get("type", ""))
		var target_id := str(objective.get("target_id", ""))
		if obj_type == GameData.OBJECTIVE_TYPE_GATHER and not target_id.is_empty():
			var container := HBoxContainer.new()
			container.add_theme_constant_override("separation", 6)
			container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var icon_path := str(WorldUI.RESOURCE_META.get(target_id, {}).get("icon_path", ""))
			if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
				var icon := TextureRect.new()
				icon.texture = load(icon_path)
				icon.custom_minimum_size = Vector2(22, 22)
				icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				container.add_child(icon)
			var label := Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.text = GameState.get_objective_display_text(objective)
			label.add_theme_font_size_override("font_size", 19)
			WorldUI.apply_label(label, "body", "crystal")
			label.add_theme_color_override("font_color", Color("fff4cc"))
			label.add_theme_color_override("font_outline_color", Color("46351f"))
			label.add_theme_constant_override("outline_size", 1)
			container.add_child(label)
			secondary_list.add_child(container)
		else:
			var label := Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.text = GameState.get_objective_display_text(objective)
			label.add_theme_font_size_override("font_size", 19)
			WorldUI.apply_label(label, "body", "crystal")
			label.add_theme_color_override("font_color", Color("fff4cc"))
			label.add_theme_color_override("font_outline_color", Color("46351f"))
			label.add_theme_constant_override("outline_size", 1)
			secondary_list.add_child(label)

	_apply_collapsed_state()


func _maybe_flash_completed_objective(objectives: Array) -> void:
	var completed_now := {}
	for objective in objectives:
		if not (objective is Dictionary):
			continue
		var objective_dict: Dictionary = objective
		var objective_id := str(objective_dict.get("id", ""))
		if objective_id.is_empty() or not bool(objective_dict.get("completed", false)):
			continue
		completed_now[objective_id] = true
		if _has_seen_objectives and not _known_completed_ids.has(objective_id):
			_flash_completion()
	_known_completed_ids = completed_now
	_has_seen_objectives = true


func _on_objective_completed(_objective: Dictionary) -> void:
	_flash_completion()


func _flash_completion() -> void:
	if panel == null:
		return
	if _completion_tween != null and _completion_tween.is_valid():
		_completion_tween.kill()
	_completion_check.visible = true
	panel.modulate = Color(0.62, 1.0, 0.62, 1.0)
	_completion_tween = create_tween()
	_completion_tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_completion_tween.tween_interval(1.15)
	_completion_tween.tween_callback(func() -> void:
		if is_instance_valid(_completion_check):
			_completion_check.visible = false
	)


func _apply_theme() -> void:
	var variant := _get_variant()
	WorldUI.apply_panel(panel, variant, true)
	WorldUI.apply_label(section_label, "subtitle", "crystal")
	section_label.add_theme_color_override("font_color", Color("fff1b8"))
	section_label.add_theme_font_size_override("font_size", 20)
	WorldUI.apply_label(primary_label, "title", "crystal")
	primary_label.add_theme_color_override("font_color", Color("fffbe8"))
	primary_label.add_theme_color_override("font_outline_color", Color("4e3f24"))
	primary_label.add_theme_constant_override("outline_size", 1)
	primary_label.add_theme_font_size_override("font_size", 24)
	WorldUI.apply_label(secondary_label, "subtitle", "crystal")
	secondary_label.add_theme_color_override("font_color", Color("fff1b8"))
	secondary_label.add_theme_font_size_override("font_size", 17)
	if _toggle_button != null:
		WorldUI.apply_button(_toggle_button, variant)
		_toggle_button.add_theme_font_size_override("font_size", 18)


func _get_variant() -> String:
	var boss_config := GameData.get_boss_config(GameState.current_map_id)
	return str(boss_config.get("ui_variant", "wood"))

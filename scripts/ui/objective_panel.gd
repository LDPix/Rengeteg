extends MarginContainer

const _BASE_BOTTOM_OFFSET := 112.0
const _MATERIAL_LINE_HEIGHT := 20.0

@onready var panel: PanelContainer = $Panel
@onready var section_label: Label = $Panel/Padding/Content/SectionLabel
@onready var primary_label: Label = $Panel/Padding/Content/PrimaryLabel
@onready var secondary_label: Label = $Panel/Padding/Content/SecondaryLabel
@onready var secondary_list: VBoxContainer = $Panel/Padding/Content/SecondaryList

var _material_labels: Array[Label] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 16.0
	offset_top = 16.0
	offset_right = 236.0
	offset_bottom = 112.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme()
	if not GameState.objectives_updated.is_connected(_refresh):
		GameState.objectives_updated.connect(_refresh)
	if not GameState.objectives_started.is_connected(_refresh):
		GameState.objectives_started.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if GameState.objectives_updated.is_connected(_refresh):
		GameState.objectives_updated.disconnect(_refresh)
	if GameState.objectives_started.is_connected(_refresh):
		GameState.objectives_started.disconnect(_refresh)


func _refresh(_objectives: Array = []) -> void:
	for lbl in _material_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_material_labels.clear()

	var objectives := GameState.get_current_objectives()
	visible = not objectives.is_empty()
	if objectives.is_empty():
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

	section_label.text = "Current Objective"
	primary_label.text = GameState.get_objective_display_text(primary)

	if str(primary.get("type", "")) == GameData.OBJECTIVE_TYPE_GATHER_MULTI and not bool(primary.get("completed", false)):
		var target_mats: Dictionary = primary.get("target_materials", {})
		var current_mats: Dictionary = primary.get("current_materials", {})
		var content: VBoxContainer = primary_label.get_parent() as VBoxContainer
		var insert_index: int = primary_label.get_index() + 1
		for mat in target_mats:
			var mat_str := str(mat)
			var have: int = int(current_mats.get(mat_str, 0))
			var need: int = int(target_mats.get(mat_str, 0))
			var done := have >= need
			var lbl := Label.new()
			lbl.text = "  %s  %d / %d%s" % [mat_str.capitalize(), have, need, " ✓" if done else ""]
			lbl.add_theme_font_size_override("font_size", 15)
			WorldUI.apply_label(lbl, "body", "crystal")
			lbl.add_theme_color_override("font_color", Color("aaddaa") if done else Color("fff4cc"))
			lbl.add_theme_color_override("font_outline_color", Color("46351f"))
			lbl.add_theme_constant_override("outline_size", 1)
			content.add_child(lbl)
			content.move_child(lbl, insert_index + _material_labels.size())
			_material_labels.append(lbl)
	offset_bottom = _BASE_BOTTOM_OFFSET + _material_labels.size() * _MATERIAL_LINE_HEIGHT
	secondary_label.visible = not secondary.is_empty()
	secondary_list.visible = not secondary.is_empty()
	secondary_label.text = "Bonus Objectives"

	for child in secondary_list.get_children():
		child.queue_free()
	for objective in secondary:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = GameState.get_objective_display_text(objective)
		label.add_theme_font_size_override("font_size", 15)
		WorldUI.apply_label(label, "body", "crystal")
		label.add_theme_color_override("font_color", Color("fff4cc"))
		label.add_theme_color_override("font_outline_color", Color("46351f"))
		label.add_theme_constant_override("outline_size", 1)
		secondary_list.add_child(label)


func _apply_theme() -> void:
	var variant := _get_variant()
	WorldUI.apply_panel(panel, variant, true)
	WorldUI.apply_label(section_label, "subtitle", "crystal")
	section_label.add_theme_color_override("font_color", Color("fff1b8"))
	section_label.add_theme_font_size_override("font_size", 13)
	WorldUI.apply_label(primary_label, "title", "crystal")
	primary_label.add_theme_color_override("font_color", Color("fffbe8"))
	primary_label.add_theme_color_override("font_outline_color", Color("4e3f24"))
	primary_label.add_theme_constant_override("outline_size", 1)
	primary_label.add_theme_font_size_override("font_size", 18)
	WorldUI.apply_label(secondary_label, "subtitle", "crystal")
	secondary_label.add_theme_color_override("font_color", Color("fff1b8"))
	secondary_label.add_theme_font_size_override("font_size", 12)


func _get_variant() -> String:
	var boss_config := GameData.get_boss_config(GameState.current_map_id)
	return str(boss_config.get("ui_variant", "wood"))

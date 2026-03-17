extends MarginContainer

@onready var panel: PanelContainer = $Panel
@onready var section_label: Label = $Panel/Padding/Content/SectionLabel
@onready var primary_label: Label = $Panel/Padding/Content/PrimaryLabel
@onready var secondary_label: Label = $Panel/Padding/Content/SecondaryLabel
@onready var secondary_list: VBoxContainer = $Panel/Padding/Content/SecondaryList


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
	secondary_label.visible = not secondary.is_empty()
	secondary_list.visible = not secondary.is_empty()
	secondary_label.text = "Bonus Objectives"

	for child in secondary_list.get_children():
		child.queue_free()
	for objective in secondary:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = GameState.get_objective_display_text(objective)
		label.add_theme_font_size_override("font_size", 13)
		WorldUI.apply_label(label, "body", _get_variant())
		secondary_list.add_child(label)


func _apply_theme() -> void:
	var variant := _get_variant()
	WorldUI.apply_panel(panel, variant, true)
	WorldUI.apply_label(section_label, "subtitle", variant)
	WorldUI.apply_label(primary_label, "title", variant)
	WorldUI.apply_label(secondary_label, "subtitle", variant)


func _get_variant() -> String:
	var boss_config := GameData.get_boss_config(GameState.current_map_id)
	return str(boss_config.get("ui_variant", "wood"))

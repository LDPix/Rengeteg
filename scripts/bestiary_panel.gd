class_name BestiaryPanel
extends Node

const CELL_SIZE := 68
const CELL_GAP := 5

var _layer: CanvasLayer
var _panel: PanelContainer
var _tab_row: HBoxContainer
var _grid: HFlowContainer
var _detail_panel: PanelContainer
var _detail_portrait: TextureRect
var _detail_name: Label
var _detail_element: Label
var _detail_stats_row: HBoxContainer

var _current_map_id: String = ""
var _current_creature_id: String = ""
var _tab_buttons: Dictionary = {}


func _ready() -> void:
	_build_ui()


func open() -> void:
	var unlocked: Array = GameState.get_unlocked_map_ids()
	if unlocked.is_empty():
		return
	_play_sfx("bestiary_open")
	_layer.visible = true
	_rebuild_tabs(unlocked)
	var start_map: String = str(unlocked[0])
	if not _current_map_id.is_empty() and unlocked.has(_current_map_id):
		start_map = _current_map_id
	_select_map(start_map)


func close() -> void:
	_play_sfx("bestiary_close")
	_layer.visible = false


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	_layer.visible = false
	add_child(_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(580, 460)
	WorldUI.apply_panel(_panel, "stone", true)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "BESTIARY"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	WorldUI.apply_label(title, "title", "stone")
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
	WorldUI.apply_button(close_btn, "stone")
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	# Map tab row
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 6)
	vbox.add_child(_tab_row)

	# Creature grid inside a scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_grid = HFlowContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", CELL_GAP)
	_grid.add_theme_constant_override("v_separation", CELL_GAP)
	scroll.add_child(_grid)

	# Detail strip at the bottom
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(0, 108)
	_detail_panel.visible = false
	WorldUI.apply_panel(_detail_panel, "battle", true)
	vbox.add_child(_detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 10)
	detail_margin.add_theme_constant_override("margin_top", 8)
	detail_margin.add_theme_constant_override("margin_right", 10)
	detail_margin.add_theme_constant_override("margin_bottom", 8)
	_detail_panel.add_child(detail_margin)

	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 14)
	detail_margin.add_child(detail_row)

	_detail_portrait = TextureRect.new()
	_detail_portrait.custom_minimum_size = Vector2(84, 84)
	_detail_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_row.add_child(_detail_portrait)

	var detail_info := VBoxContainer.new()
	detail_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail_info.add_theme_constant_override("separation", 4)
	detail_row.add_child(detail_info)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 16)
	WorldUI.apply_label(_detail_name, "title", "battle")
	detail_info.add_child(_detail_name)

	_detail_element = Label.new()
	WorldUI.apply_label(_detail_element, "subtitle", "battle")
	detail_info.add_child(_detail_element)

	_detail_stats_row = HBoxContainer.new()
	_detail_stats_row.add_theme_constant_override("separation", 12)
	detail_info.add_child(_detail_stats_row)


func _rebuild_tabs(map_ids: Array) -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	_tab_buttons.clear()
	for map_id in map_ids:
		var map_data: Dictionary = GameData.maps.get(str(map_id), {})
		var btn := Button.new()
		btn.text = str(map_data.get("display_name", map_id))
		btn.pressed.connect(_select_map.bind(str(map_id)))
		_tab_row.add_child(btn)
		_tab_buttons[str(map_id)] = btn
	_update_tab_styles()


func _select_map(map_id: String) -> void:
	_current_map_id = map_id
	_current_creature_id = ""
	_detail_panel.visible = false
	_update_tab_styles()
	_rebuild_grid()


func _update_tab_styles() -> void:
	for map_id in _tab_buttons:
		var btn: Button = _tab_buttons[map_id]
		WorldUI.apply_button(btn, "stone", map_id == _current_map_id)


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	if _current_map_id.is_empty():
		return
	for creature_id in GameData.get_map_creature_ids(_current_map_id):
		_grid.add_child(_build_cell(creature_id))


func _build_cell(creature_id: String) -> Control:
	var encountered: bool = GameState.has_encountered_creature(creature_id)
	var is_selected: bool = creature_id == _current_creature_id

	if encountered:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		btn.clip_contents = true
		btn.text = ""
		WorldUI.apply_button(btn, "stone", is_selected)
		btn.pressed.connect(_select_creature.bind(creature_id))

		var creature_data: Dictionary = GameData.creatures.get(creature_id, {})
		var sprite_path := str(creature_data.get("sprite_path", ""))
		if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			var img := TextureRect.new()
			img.texture = load(sprite_path)
			img.set_anchors_preset(Control.PRESET_FULL_RECT)
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(img)
		return btn
	else:
		var cell := Panel.new()
		cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.05, 0.07)
		style.border_color = Color(0.18, 0.18, 0.22)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		cell.add_theme_stylebox_override("panel", style)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return cell


func _select_creature(creature_id: String) -> void:
	_current_creature_id = creature_id
	_rebuild_grid()
	_rebuild_detail()


func _rebuild_detail() -> void:
	if _current_creature_id.is_empty():
		_detail_panel.visible = false
		return
	var data: Dictionary = GameData.creatures.get(_current_creature_id, {})
	if data.is_empty():
		_detail_panel.visible = false
		return

	var sprite_path := str(data.get("sprite_path", ""))
	_detail_portrait.texture = load(sprite_path) if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path) else null

	_detail_name.text = str(data.get("name", _current_creature_id))
	_detail_element.text = str(data.get("element", "")).capitalize()

	for child: Node in _detail_stats_row.get_children():
		child.queue_free()

	const STAT_ICONS: Dictionary = {
		"base_hp": "res://assets/ui/stats/hp_icon.svg",
		"base_atk": "res://assets/ui/stats/atk_icon.svg",
		"base_def": "res://assets/ui/stats/def_icon.svg",
		"base_spd": "res://assets/ui/stats/spd_icon.svg",
		"base_mp": "res://assets/ui/stats/mp_icon.svg",
	}
	for stat_key: String in ["base_hp", "base_atk", "base_def", "base_spd", "base_mp"]:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)

		var icon_path: String = STAT_ICONS[stat_key]
		if ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.texture = load(icon_path)
			icon.custom_minimum_size = Vector2(18, 18)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			chip.add_child(icon)

		var val_label := Label.new()
		val_label.text = str(int(data.get(stat_key, 0)))
		WorldUI.apply_label(val_label, "body", "battle")
		chip.add_child(val_label)

		_detail_stats_row.add_child(chip)

	_detail_panel.visible = true


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


func _play_sfx(effect_id: String, volume_db: float = 0.0) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.call("play", effect_id, volume_db)

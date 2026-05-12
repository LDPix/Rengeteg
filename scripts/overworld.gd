extends Node2D

@export var encounter_chance := 0.12 # 12% per step
@export var object_tiles_block_movement := false

const OBJECTIVE_PANEL_SCENE := preload("res://scenes/ui/ObjectivePanel.tscn")
const VENTURE_CREATURE_ROW_SCRIPT := preload("res://scripts/ui/venture_creature_row.gd")
const _BestiaryPanelScript := preload("res://scripts/bestiary_panel.gd")
const BESTIARY_ICON_PATH := "res://assets/ui/bestiary_book.png"
const BACKPACK_ICON_PATH := "res://assets/ui/nav/backpack_icon.png"
const BACKPACK_ICON_FALLBACK_PATH := "res://assets/ui/camp/collection_icon.svg"
const STAT_ICONS := {
	"hp_max": "res://assets/ui/stats/hp_icon.svg",
	"mp_max": "res://assets/ui/stats/mp_icon.svg",
}
const INVENTORY_BUTTON_SIZE := Vector2(78, 78)
const INVENTORY_PANEL_WIDTH := 560.0
const INVENTORY_PANEL_HEIGHT := 700.0
const OBJECTIVE_ARROW_LAYER := 15
const OBJECTIVE_ARROW_MARGIN := 26.0
const OBJECTIVE_ARROW_SIZE := 62.0
const OBJECTIVE_ARROW_TARGET_OFFSET := 58.0
const OBJECTIVE_ARROW_CLOSE_DISTANCE := 12.0
const RESOURCE_NODE_TUTORIAL_STEPS: Array = [
	["Resource Nodes",
		"Glowing nodes scattered across the map hold materials. Walk up to one and press Interact to gather from it.",
		"objective_panel"],
	["Watch for Encounters",
		"Disturbing a resource node may attract wild creatures. Win the battle to keep what you've gathered — or run if you're not ready to fight.",
		"inventory_button"],
]
const TUTORIAL_POPUP_MARGIN := 14.0
const TUTORIAL_POPUP_WIDTH := 430.0
const TUTORIAL_POPUP_HEIGHT := 248.0

@onready var player := $Player
@onready var ground_layer := $TileMap_Ground
@onready var object_layer := $TileMap_Objects
@onready var encounter_layer := get_node_or_null("TileMap_Encounter")
@onready var encounter_zones := get_node_or_null("EncounterZones")

var _inventory_panel: PanelContainer
var _inventory_button: Button
var _inventory_content: VBoxContainer
var _bestiary_panel: Node
var _objective_arrow_layer: CanvasLayer
var _objective_arrow_fill: Polygon2D
var _objective_arrow_shadow: Polygon2D
var _resource_node_tutorial_running := false


func _process(_delta: float) -> void:
	_update_world_y_sort()
	_update_objective_arrow()


func _ready() -> void:
	randomize()
	GameState.ensure_starter()
	var spawn := get_node_or_null("PlayerSpawn")
	var current_scene_path := ""
	if get_tree().current_scene:
		current_scene_path = str(get_tree().current_scene.scene_file_path)
	if GameState.has_battle_return_position \
	and GameState.battle_return_map_id == GameState.current_map_id \
	and GameState.battle_return_scene_path == current_scene_path:
		player.global_position = GameState.battle_return_position
		player.reset_movement_state()
		GameState.clear_battle_return()
	elif spawn:
		player.global_position = spawn.global_position
		player.reset_movement_state()
	MapRunService.setup_current_map_run(self)
	_refresh_path_blockers()
	_ensure_objective_panel()
	_ensure_objective_arrow_hud()
	_ensure_inventory_hud()
	if not GameState.objectives_updated.is_connected(_refresh_objective_guidance):
		GameState.objectives_updated.connect(_refresh_objective_guidance)
	if not GameState.objectives_started.is_connected(_refresh_objective_guidance):
		GameState.objectives_started.connect(_refresh_objective_guidance)
	if not GameState.objectives_started.is_connected(_on_objectives_started):
		GameState.objectives_started.connect(_on_objectives_started)
	_refresh_objective_guidance()
	player.stepped.connect(_on_player_stepped)
	_maybe_show_resource_node_tutorial_for_objectives(GameState.get_current_objectives())


func _update_world_y_sort() -> void:
	_apply_y_sort_z(player)
	_apply_y_sort_z(get_node_or_null("ExitZone"))
	for node in get_tree().get_nodes_in_group("world_y_sort"):
		_apply_y_sort_z(node)
	var generated_root := get_node_or_null("GeneratedContent")
	if generated_root == null:
		return
	for container in generated_root.get_children():
		for child in container.get_children():
			_apply_y_sort_z(child)


func _apply_y_sort_z(node: Node) -> void:
	if not (node is Node2D):
		return
	var item := node as Node2D
	item.z_as_relative = false
	var origin := 0
	var origin_value: Variant = null
	if item.has_meta("world_y_sort_origin"):
		origin_value = item.get_meta("world_y_sort_origin")
	else:
		origin_value = item.get("world_sort_origin")
	if origin_value is int or origin_value is float:
		origin = int(origin_value)
	item.z_index = int(item.global_position.y) + origin

func _on_player_stepped() -> void:
	if not is_on_encounter_tile(player.global_position):
		return
	GameState.notify_entered_grass(get_encounter_tag_at_position(player.global_position))
	if randf() < encounter_chance:
		_start_battle()

func _start_battle() -> void:
	var map_id := GameState.current_map_id
	var encounter_tag := get_encounter_tag_at_position(player.global_position)
	var wild_id := GameData.pick_wild_for_map(map_id, encounter_tag)
	if wild_id.is_empty():
		return
	var scene_path := str(get_tree().current_scene.scene_file_path)
	GameState.set_battle_return(map_id, scene_path, player.global_position)
	GameState.set_pending_battle(wild_id, {
		"encounter_type": "wild",
		"encounter_tag": encounter_tag,
	})
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		GameState.save_game()
	elif event.is_action_pressed("load_game"):
		GameState.load_game()


func can_move_to_world_position(world_position: Vector2) -> bool:
	var tile := _world_to_tile(world_position)
	if not _is_inside_layout(tile):
		return false
	if object_tiles_block_movement and _is_object_tile_blocked(tile):
		return false
	return not _is_path_blocked(world_position)


func is_on_encounter_tile(world_position: Vector2) -> bool:
	return not get_encounter_tag_at_position(world_position).is_empty()


func get_encounter_tag_at_position(world_position: Vector2) -> String:
	var tile := _world_to_tile(world_position)
	var zone_tag := _get_encounter_zone_tag_at_position(world_position)
	if not zone_tag.is_empty():
		return zone_tag
	if _has_authored_encounter_tiles():
		return str(encounter_layer.get_tile_tag_at(tile))
	return ""


func _world_to_tile(world_position: Vector2) -> Vector2i:
	var local_position: Vector2 = ground_layer.to_local(world_position)
	var tile_size := int(ground_layer.tile_size)
	return Vector2i(
		int(floor(local_position.x / tile_size)),
		int(floor(local_position.y / tile_size))
	)


func _is_object_tile_blocked(tile: Vector2i) -> bool:
	if object_layer == null or not object_layer.has_tile_at(tile):
		return false
	return object_layer.has_tile_at(tile + Vector2i.LEFT) and object_layer.has_tile_at(tile + Vector2i.UP)


func _is_inside_layout(tile: Vector2i) -> bool:
	if tile.y < 0 or tile.y >= ground_layer.layout_rows.size():
		return false
	var row: String = ground_layer.layout_rows[tile.y]
	return tile.x >= 0 and tile.x < row.length()

func _has_authored_encounter_tiles() -> bool:
	return encounter_layer != null and encounter_layer.has_method("has_any_tiles") and encounter_layer.has_any_tiles()


func _get_encounter_zone_tag_at_position(world_position: Vector2) -> String:
	if encounter_zones == null:
		return ""
	for child in encounter_zones.get_children():
		if child is EncounterPatch:
			var patch_tag: String = child.get_encounter_tag_for_point(world_position)
			if not patch_tag.is_empty():
				return patch_tag
			continue
		if child is Area2D and _point_is_inside_area(child, world_position):
			return str(child.get_meta("encounter_tag", "zone"))
	return ""


func _point_is_inside_area(area: Area2D, world_position: Vector2) -> bool:
	for child in area.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var shape := child.shape as RectangleShape2D
			var local_position: Vector2 = child.to_local(world_position)
			var half_size := shape.size * 0.5
			if absf(local_position.x) <= half_size.x and absf(local_position.y) <= half_size.y:
				return true
	return false


func _is_path_blocked(world_position: Vector2) -> bool:
	for blocker in get_tree().get_nodes_in_group("path_blocker"):
		if blocker is PathBlocker and blocker.should_block_point(world_position):
			return true
	return false


func _refresh_path_blockers() -> void:
	var blockers_root := get_node_or_null("PathBlockers")
	if blockers_root == null:
		return
	for child in blockers_root.get_children():
		if not (child is PathBlocker):
			continue
		var blocker := child as PathBlocker
		var is_enabled := blocker.starts_enabled
		if not blocker.unlock_flag.is_empty() and GameState.has_run_flag(blocker.unlock_flag):
			is_enabled = false
		blocker.set_enabled_for_run(is_enabled)


func unlock_path_blockers(blocker_ids: Array) -> void:
	var blockers_root := get_node_or_null("PathBlockers")
	if blockers_root == null:
		return
	var lookup := {}
	for blocker_id in blocker_ids:
		lookup[str(blocker_id)] = true
	for child in blockers_root.get_children():
		if not (child is PathBlocker):
			continue
		var blocker := child as PathBlocker
		if lookup.has(blocker.get_blocker_id()):
			blocker.set_enabled_for_run(false)


func _ensure_objective_panel() -> void:
	if get_node_or_null("ObjectiveHudLayer/ObjectivePanel") != null:
		return
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "ObjectiveHudLayer"
	hud_layer.layer = 10
	add_child(hud_layer)
	var objective_panel := OBJECTIVE_PANEL_SCENE.instantiate()
	objective_panel.name = "ObjectivePanel"
	hud_layer.add_child(objective_panel)


func _ensure_objective_arrow_hud() -> void:
	if get_node_or_null("ObjectiveArrowLayer") != null:
		_objective_arrow_layer = get_node("ObjectiveArrowLayer") as CanvasLayer
		_objective_arrow_shadow = _objective_arrow_layer.get_node_or_null("ArrowShadow") as Polygon2D
		_objective_arrow_fill = _objective_arrow_layer.get_node_or_null("ArrowFill") as Polygon2D
		return
	_objective_arrow_layer = CanvasLayer.new()
	_objective_arrow_layer.name = "ObjectiveArrowLayer"
	_objective_arrow_layer.layer = OBJECTIVE_ARROW_LAYER
	add_child(_objective_arrow_layer)

	_objective_arrow_shadow = Polygon2D.new()
	_objective_arrow_shadow.name = "ArrowShadow"
	_objective_arrow_shadow.polygon = PackedVector2Array([
		Vector2(0, -32),
		Vector2(26, 22),
		Vector2(10, 14),
		Vector2(10, 32),
		Vector2(-10, 32),
		Vector2(-10, 14),
		Vector2(-26, 22),
	])
	_objective_arrow_shadow.color = Color(0.10, 0.05, 0.02, 0.72)
	_objective_arrow_shadow.visible = false
	_objective_arrow_layer.add_child(_objective_arrow_shadow)

	_objective_arrow_fill = Polygon2D.new()
	_objective_arrow_fill.name = "ArrowFill"
	_objective_arrow_fill.polygon = PackedVector2Array([
		Vector2(0, -26),
		Vector2(18, 16),
		Vector2(7, 10),
		Vector2(7, 26),
		Vector2(-7, 26),
		Vector2(-7, 10),
		Vector2(-18, 16),
	])
	_objective_arrow_fill.color = Color(0.98, 0.87, 0.38, 0.98)
	_objective_arrow_fill.visible = false
	_objective_arrow_layer.add_child(_objective_arrow_fill)


func _ensure_inventory_hud() -> void:
	if get_node_or_null("VentureInventoryLayer") != null:
		return
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "VentureInventoryLayer"
	hud_layer.layer = 20
	add_child(hud_layer)

	var hud_root := Control.new()
	hud_root.name = "Root"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud_root)

	_inventory_button = Button.new()
	_inventory_button.name = "InventoryButton"
	_inventory_button.tooltip_text = "Run inventory"
	_inventory_button.custom_minimum_size = INVENTORY_BUTTON_SIZE
	_inventory_button.anchor_left = 1.0
	_inventory_button.anchor_right = 1.0
	_inventory_button.offset_left = -98.0
	_inventory_button.offset_top = 16.0
	_inventory_button.offset_right = -20.0
	_inventory_button.offset_bottom = 94.0
	_inventory_button.expand_icon = true
	_inventory_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inventory_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_inventory_button.focus_mode = Control.FOCUS_ALL
	_inventory_button.set_meta("sfx_click_disabled", true)
	var icon_path := BACKPACK_ICON_PATH if ResourceLoader.exists(BACKPACK_ICON_PATH) else BACKPACK_ICON_FALLBACK_PATH
	_inventory_button.icon = load(icon_path)
	WorldUI.apply_button(_inventory_button, "wood", true)
	_inventory_button.pressed.connect(_toggle_inventory_panel)
	hud_root.add_child(_inventory_button)

	_bestiary_panel = _BestiaryPanelScript.new()
	_bestiary_panel.name = "BestiaryPanel"
	hud_root.add_child(_bestiary_panel)

	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.anchor_left = 1.0
	_inventory_panel.anchor_right = 1.0
	_inventory_panel.offset_left = -INVENTORY_PANEL_WIDTH - 20.0
	_inventory_panel.offset_top = 108.0
	_inventory_panel.offset_right = -20.0
	_inventory_panel.offset_bottom = 108.0 + INVENTORY_PANEL_HEIGHT
	_inventory_panel.visible = false
	_inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	WorldUI.apply_panel(_inventory_panel, "parchment", true)
	hud_root.add_child(_inventory_panel)

	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 14)
	padding.add_theme_constant_override("margin_top", 14)
	padding.add_theme_constant_override("margin_right", 14)
	padding.add_theme_constant_override("margin_bottom", 14)
	_inventory_panel.add_child(padding)

	_inventory_content = VBoxContainer.new()
	_inventory_content.add_theme_constant_override("separation", 12)
	padding.add_child(_inventory_content)


func _toggle_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	_inventory_panel.visible = not _inventory_panel.visible
	if _inventory_panel.visible:
		_play_sfx("inventory")
		_populate_inventory_panel()


func _populate_inventory_panel() -> void:
	for child in _inventory_content.get_children():
		child.queue_free()

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	_inventory_content.add_child(title_row)

	var title_icon := _build_icon(BACKPACK_ICON_PATH if ResourceLoader.exists(BACKPACK_ICON_PATH) else BACKPACK_ICON_FALLBACK_PATH, Vector2(44, 44))
	title_row.add_child(title_icon)
	var title := Label.new()
	title.text = "VENTURE PACK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_theme_font_size_override("font_size", 34)
	WorldUI.apply_label(title, "title", "parchment")
	title_row.add_child(title)

	var bestiary_btn := Button.new()
	bestiary_btn.text = "BESTIARY"
	bestiary_btn.custom_minimum_size = Vector2(130, 48)
	WorldUI.apply_button(bestiary_btn, "wood")
	bestiary_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bestiary_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bestiary_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	bestiary_btn.expand_icon = false
	bestiary_btn.add_theme_constant_override("h_separation", 10)
	if ResourceLoader.exists(BESTIARY_ICON_PATH):
		bestiary_btn.icon = load(BESTIARY_ICON_PATH)
	bestiary_btn.pressed.connect(func() -> void: _bestiary_panel.call("open"))
	title_row.add_child(bestiary_btn)

	_inventory_content.add_child(_build_separator())
	_add_team_section()
	_inventory_content.add_child(_build_separator())
	_add_resource_section()
	_inventory_content.add_child(_build_separator())
	_add_items_section()


func _add_team_section() -> void:
	_add_section_label("Team")
	if GameState.party.is_empty():
		_inventory_content.add_child(_build_empty_label("No creatures in the active team."))
		return
	for creature in GameState.party:
		if creature is Dictionary:
			_inventory_content.add_child(_build_creature_row(creature))


func _add_resource_section() -> void:
	_add_section_label("Resources gathered")
	var deltas := GameState.get_run_material_delta()
	if deltas.is_empty():
		_inventory_content.add_child(_build_empty_label("No resources gathered yet."))
		return
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 16)
	_inventory_content.add_child(chips)
	for resource_id in ["wood", "herb", "stone", "crystal", "core_shard", "species_mat"]:
		var amount := int(deltas.get(resource_id, 0))
		if amount > 0:
			chips.add_child(_build_resource_row(resource_id, amount))


func _add_items_section() -> void:
	_add_section_label("Items gathered")
	var deltas := GameState.get_run_item_delta()
	if deltas.is_empty():
		_inventory_content.add_child(_build_empty_label("No items gathered yet."))
		return
	for item_id in _sorted_item_ids(deltas):
		_inventory_content.add_child(_build_item_row(item_id, int(deltas.get(item_id, 0))))


func _add_section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	WorldUI.apply_label(label, "dark", "parchment")
	_inventory_content.add_child(label)


func _build_creature_row(creature: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.set_script(VENTURE_CREATURE_ROW_SCRIPT)
	row.call("configure_tooltip", creature)
	row.custom_minimum_size = Vector2(0, 76)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_theme_constant_override("separation", 12)
	var sprite_path := _get_creature_sprite_path(creature)
	var sprite_icon := _build_icon(sprite_path, Vector2(60, 60))
	sprite_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sprite_icon)

	var text_stack := VBoxContainer.new()
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 0)
	row.add_child(text_stack)

	var name_label := Label.new()
	name_label.text = "%s  Lv %d" % [str(creature.get("name", "Creature")), int(creature.get("level", 1))]
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 21)
	WorldUI.apply_label(name_label, "title", "parchment")
	text_stack.add_child(name_label)

	var held_item := GameState.get_creature_held_item(creature)
	var held_name := "No held item" if held_item.is_empty() else str(held_item.get("name", "Held item"))
	var summary_row := HBoxContainer.new()
	summary_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_row.add_theme_constant_override("separation", 10)
	text_stack.add_child(summary_row)
	summary_row.add_child(_build_stat_value("hp_max", "%d/%d" % [
		int(creature.get("hp", 0)),
		GameState.get_effective_creature_stat(creature, "hp_max"),
	]))
	summary_row.add_child(_build_stat_value("mp_max", "%d/%d" % [
		int(creature.get("mp", 0)),
		GameState.get_effective_creature_stat(creature, "mp_max"),
	]))
	var held_label := Label.new()
	held_label.text = held_name
	held_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held_label.add_theme_font_size_override("font_size", 17)
	WorldUI.apply_label(held_label, "subtitle", "parchment")
	summary_row.add_child(held_label)
	return row


func _build_resource_row(resource_id: String, amount: int) -> Control:
	var meta: Dictionary = WorldUI.RESOURCE_META.get(resource_id, {"icon_path": ""})
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_build_icon(str(meta.get("icon_path", "")), Vector2(44, 44)))
	var lbl := Label.new()
	lbl.text = "+%d" % amount
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	WorldUI.apply_label(lbl, "accent", "verdant")
	row.add_child(lbl)
	return row


func _build_item_row(item_id: String, amount: int) -> Control:
	var item_data := GameState.get_item_data(item_id)
	return _build_inventory_row(str(item_data.get("icon_path", "")), str(item_data.get("name", item_id.capitalize())), amount)


func _build_inventory_row(icon_path: String, label_text: String, amount: int) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	row.add_theme_constant_override("separation", 9)
	row.add_child(_build_icon(icon_path, Vector2(40, 40)))

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 19)
	WorldUI.apply_label(label, "dark", "parchment")
	row.add_child(label)

	var amount_label := Label.new()
	amount_label.text = "+%d" % amount
	amount_label.add_theme_font_size_override("font_size", 20)
	WorldUI.apply_label(amount_label, "accent", "verdant")
	row.add_child(amount_label)
	return row


func _build_icon(icon_path: String, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.custom_minimum_size = size
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	return icon


func _build_stat_value(stat_key: String, value: String) -> HBoxContainer:
	var chip := HBoxContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_constant_override("separation", 4)
	var icon_path := str(STAT_ICONS.get(stat_key, ""))
	var icon := _build_icon(icon_path, Vector2(22, 22))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(icon)
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 17)
	WorldUI.apply_label(label, "subtitle", "parchment")
	chip.add_child(label)
	return chip


func _build_empty_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	WorldUI.apply_label(label, "subtitle", "parchment")
	return label


func _build_separator() -> ColorRect:
	var separator := ColorRect.new()
	separator.custom_minimum_size = Vector2(0, 2)
	separator.color = Color("5c483066")
	return separator


func _sorted_item_ids(items: Dictionary) -> Array:
	var ids := items.keys()
	ids.sort_custom(func(a, b):
		var item_a := GameState.get_item_data(str(a))
		var item_b := GameState.get_item_data(str(b))
		return int(item_a.get("sort_order", 9999)) < int(item_b.get("sort_order", 9999))
	)
	return ids


func _get_creature_sprite_path(creature: Dictionary) -> String:
	var override_path := str(creature.get("sprite_path_override", ""))
	if not override_path.is_empty():
		return override_path
	var creature_id := str(creature.get("id", ""))
	var data := GameData.get_creature_data(creature_id)
	return str(data.get("sprite_path", ""))


func _show_resource_node_tutorial() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)

	var popup := PanelContainer.new()
	popup.custom_minimum_size = Vector2(TUTORIAL_POPUP_WIDTH, TUTORIAL_POPUP_HEIGHT)
	popup.visible = false
	WorldUI.apply_panel(popup, "battle", true)
	layer.add_child(popup)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_bottom", 14)
	popup.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	pad.add_child(vbox)

	var title_label := Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(title_label, "title", "crystal")
	vbox.add_child(title_label)

	var body_label := Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	WorldUI.apply_label(body_label, "body", "verdant")
	vbox.add_child(body_label)

	var cont_button := Button.new()
	cont_button.custom_minimum_size = Vector2(0, 40)
	cont_button.focus_mode = Control.FOCUS_NONE
	WorldUI.apply_button(cont_button, "verdant", true)
	vbox.add_child(cont_button)

	popup.top_level = true
	popup.z_index = 51

	var steps: Array = RESOURCE_NODE_TUTORIAL_STEPS
	for i: int in range(steps.size()):
		var step: Array = steps[i]
		var target_id: String = str(step[2])
		var is_last: bool = i == steps.size() - 1

		title_label.text = str(step[0])
		body_label.text = str(step[1])
		cont_button.text = "Got it!" if is_last else "Next  ›"
		popup.visible = true
		popup.modulate.a = 0.0

		await get_tree().process_frame

		var panel_size := Vector2(TUTORIAL_POPUP_WIDTH, TUTORIAL_POPUP_HEIGHT)
		var viewport_size: Vector2 = get_viewport_rect().size
		popup.size = panel_size
		var target: Control = _get_tutorial_target_overworld(target_id)
		if target != null:
			popup.global_position = _get_overworld_popup_position(
				target.global_position, target.size, panel_size, viewport_size
			)
		else:
			popup.global_position = Vector2(
				(viewport_size.x - panel_size.x) / 2.0,
				(viewport_size.y - panel_size.y) / 2.0
			)
		popup.modulate.a = 1.0
		await cont_button.pressed

	layer.queue_free()


func _on_objectives_started(objectives: Array) -> void:
	_maybe_show_resource_node_tutorial_for_objectives(objectives)


func _maybe_show_resource_node_tutorial_for_objectives(objectives: Array) -> void:
	if _resource_node_tutorial_running or not GameState.should_show_resource_node_tutorial():
		return
	if not _objectives_include_first_wood_gather(objectives):
		return
	_resource_node_tutorial_running = true
	await get_tree().process_frame
	await _show_resource_node_tutorial()
	GameState.mark_resource_node_tutorial_shown()
	_resource_node_tutorial_running = false


func _objectives_include_first_wood_gather(objectives: Array) -> bool:
	for objective in objectives:
		if not objective is Dictionary:
			continue
		var objective_dict: Dictionary = objective
		if str(objective_dict.get("id", "")) == "global_gather_wood" \
				and str(objective_dict.get("type", "")) == GameData.OBJECTIVE_TYPE_GATHER \
				and str(objective_dict.get("target_id", "")) == "wood" \
				and not bool(objective_dict.get("completed", false)):
			return true
	return false


func _get_tutorial_target_overworld(target_id: String) -> Control:
	match target_id:
		"objective_panel":
			return get_node_or_null("ObjectiveHudLayer/ObjectivePanel") as Control
		"inventory_button":
			return _inventory_button as Control
	return null


func _get_overworld_popup_position(target_pos: Vector2, target_size: Vector2, panel_size: Vector2, viewport_size: Vector2) -> Vector2:
	var right_pos := Vector2(target_pos.x + target_size.x + TUTORIAL_POPUP_MARGIN, target_pos.y)
	var left_pos := Vector2(target_pos.x - panel_size.x - TUTORIAL_POPUP_MARGIN, target_pos.y)
	var below_pos := Vector2(target_pos.x, target_pos.y + target_size.y + TUTORIAL_POPUP_MARGIN)
	var above_pos := Vector2(target_pos.x, target_pos.y - panel_size.y - TUTORIAL_POPUP_MARGIN)
	var candidates: Array[Vector2] = [right_pos, left_pos, below_pos, above_pos]
	for pos: Vector2 in candidates:
		if pos.x >= TUTORIAL_POPUP_MARGIN and pos.y >= TUTORIAL_POPUP_MARGIN \
				and pos.x + panel_size.x <= viewport_size.x - TUTORIAL_POPUP_MARGIN \
				and pos.y + panel_size.y <= viewport_size.y - TUTORIAL_POPUP_MARGIN:
			return pos
	return Vector2(
		clampf(right_pos.x, TUTORIAL_POPUP_MARGIN, maxf(TUTORIAL_POPUP_MARGIN, viewport_size.x - panel_size.x - TUTORIAL_POPUP_MARGIN)),
		clampf(right_pos.y, TUTORIAL_POPUP_MARGIN, maxf(TUTORIAL_POPUP_MARGIN, viewport_size.y - panel_size.y - TUTORIAL_POPUP_MARGIN))
	)


func _exit_tree() -> void:
	if GameState.objectives_updated.is_connected(_refresh_objective_guidance):
		GameState.objectives_updated.disconnect(_refresh_objective_guidance)
	if GameState.objectives_started.is_connected(_refresh_objective_guidance):
		GameState.objectives_started.disconnect(_refresh_objective_guidance)
	if GameState.objectives_started.is_connected(_on_objectives_started):
		GameState.objectives_started.disconnect(_on_objectives_started)


func _play_sfx(effect_id: String, volume_db: float = 0.0) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.call("play", effect_id, volume_db)


func _update_objective_arrow() -> void:
	if _objective_arrow_fill == null or _objective_arrow_shadow == null or player == null:
		return
	var primary: Dictionary = GameState.get_primary_objective()
	if primary.is_empty() or bool(primary.get("completed", false)):
		_set_objective_arrow_visible(false)
		return
	var target_world: Variant = _get_objective_target_world_position(primary)
	if not (target_world is Vector2):
		_set_objective_arrow_visible(false)
		return
	var target_position: Vector2 = target_world
	if player.global_position.distance_to(target_position) <= OBJECTIVE_ARROW_CLOSE_DISTANCE:
		_set_objective_arrow_visible(false)
		return

	var viewport_size := get_viewport_rect().size
	var safe_half := (viewport_size * 0.5) - Vector2(OBJECTIVE_ARROW_MARGIN, OBJECTIVE_ARROW_MARGIN)
	if safe_half.x <= 0.0 or safe_half.y <= 0.0:
		_set_objective_arrow_visible(false)
		return
	var screen_center := viewport_size * 0.5
	var player_screen := _project_world_to_screen(player.global_position)
	var target_screen := _project_world_to_screen(target_position)
	var screen_delta := target_screen - screen_center
	var direction := (target_screen - player_screen).normalized()
	if direction.length_squared() <= 0.0001:
		direction = screen_delta.normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.UP
	var on_screen_rect := Rect2(
		Vector2(OBJECTIVE_ARROW_MARGIN, OBJECTIVE_ARROW_MARGIN),
		viewport_size - Vector2(OBJECTIVE_ARROW_MARGIN * 2.0, OBJECTIVE_ARROW_MARGIN * 2.0)
	)
	var arrow_position := Vector2.ZERO
	if on_screen_rect.has_point(target_screen):
		arrow_position = target_screen - direction * OBJECTIVE_ARROW_TARGET_OFFSET
		arrow_position.x = clampf(
			arrow_position.x,
			OBJECTIVE_ARROW_MARGIN + OBJECTIVE_ARROW_SIZE * 0.5,
			viewport_size.x - OBJECTIVE_ARROW_MARGIN - OBJECTIVE_ARROW_SIZE * 0.5
		)
		arrow_position.y = clampf(
			arrow_position.y,
			OBJECTIVE_ARROW_MARGIN + OBJECTIVE_ARROW_SIZE * 0.5,
			viewport_size.y - OBJECTIVE_ARROW_MARGIN - OBJECTIVE_ARROW_SIZE * 0.5
		)
	else:
		var scale_x := safe_half.x / maxf(absf(screen_delta.x), 0.001)
		var scale_y := safe_half.y / maxf(absf(screen_delta.y), 0.001)
		var scale := minf(scale_x, scale_y)
		arrow_position = screen_center + screen_delta * scale
		arrow_position.x = clampf(
			arrow_position.x,
			OBJECTIVE_ARROW_MARGIN + OBJECTIVE_ARROW_SIZE * 0.5,
			viewport_size.x - OBJECTIVE_ARROW_MARGIN - OBJECTIVE_ARROW_SIZE * 0.5
		)
		arrow_position.y = clampf(
			arrow_position.y,
			OBJECTIVE_ARROW_MARGIN + OBJECTIVE_ARROW_SIZE * 0.5,
			viewport_size.y - OBJECTIVE_ARROW_MARGIN - OBJECTIVE_ARROW_SIZE * 0.5
		)
	var rotation := direction.angle() + PI * 0.5
	_objective_arrow_shadow.position = arrow_position + Vector2(0, 3)
	_objective_arrow_fill.position = arrow_position
	_objective_arrow_shadow.rotation = rotation
	_objective_arrow_fill.rotation = rotation
	_set_objective_arrow_visible(true)


func _set_objective_arrow_visible(is_visible: bool) -> void:
	if _objective_arrow_fill != null:
		_objective_arrow_fill.visible = is_visible
	if _objective_arrow_shadow != null:
		_objective_arrow_shadow.visible = is_visible


func _project_world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position


func _get_objective_target_world_position(primary: Dictionary) -> Variant:
	match str(primary.get("type", "")):
		GameData.OBJECTIVE_TYPE_GATHER:
			return _find_nearest_resource_target([str(primary.get("target_id", ""))])
		GameData.OBJECTIVE_TYPE_GATHER_MULTI:
			var needed_types: Array[String] = []
			var target_materials: Dictionary = primary.get("target_materials", {})
			var current_materials: Dictionary = primary.get("current_materials", {})
			for material_id in target_materials.keys():
				var material_key := str(material_id)
				if int(current_materials.get(material_key, 0)) < int(target_materials.get(material_key, 0)):
					needed_types.append(material_key)
			return _find_nearest_resource_target(needed_types)
		GameData.OBJECTIVE_TYPE_CAPTURE:
			return _find_nearest_encounter_target()
		GameData.OBJECTIVE_TYPE_TUTORIAL_BIND, GameData.OBJECTIVE_TYPE_BATTLE_WIN:
			return null
		GameData.OBJECTIVE_TYPE_BOSS_DEFEAT:
			return _find_boss_target_position()
		GameData.OBJECTIVE_TYPE_CRAFT:
			return _find_exit_target_position()
	return null


func _find_nearest_resource_target(resource_types: Array[String]) -> Variant:
	if resource_types.is_empty():
		return null
	var lookup := {}
	for resource_type in resource_types:
		if not resource_type.is_empty():
			lookup[resource_type] = true
	if lookup.is_empty():
		return null
	var best_position := Vector2.ZERO
	var best_distance := INF
	for child in get_tree().get_nodes_in_group("generated_resource_node"):
		if not (child is Node2D) or not is_ancestor_of(child):
			continue
		if not lookup.has(str(child.get("resource_type"))):
			continue
		var resource_position := (child as Node2D).global_position
		var distance: float = player.global_position.distance_squared_to(resource_position)
		if distance < best_distance:
			best_distance = distance
			best_position = resource_position
	return best_position if best_distance < INF else null


func _find_nearest_encounter_target() -> Variant:
	if encounter_zones == null:
		return null
	var best_position := Vector2.ZERO
	var best_distance := INF
	for child in encounter_zones.get_children():
		if child is EncounterPatch:
			var patch := child as EncounterPatch
			if not patch.is_active_for_run():
				continue
			var patch_center := _get_area_center(patch)
			var patch_distance: float = player.global_position.distance_squared_to(patch_center)
			if patch_distance < best_distance:
				best_distance = patch_distance
				best_position = patch_center
			continue
		if child is Area2D:
			var area_center := _get_area_center(child)
			var area_distance: float = player.global_position.distance_squared_to(area_center)
			if area_distance < best_distance:
				best_distance = area_distance
				best_position = area_center
	return best_position if best_distance < INF else null


func _find_boss_target_position() -> Variant:
	for boss_node in get_tree().get_nodes_in_group("generated_boss_node"):
		if boss_node is Node2D and is_ancestor_of(boss_node):
			return (boss_node as Node2D).global_position
	var run_data := GameState.get_current_map_run(GameState.current_map_id)
	var spawn_id := str(run_data.get("boss_spawn_id", ""))
	if spawn_id.is_empty():
		return null
	var boss_marker := MapRunService._find_boss_point(self, spawn_id)
	if boss_marker == null:
		return null
	return boss_marker.global_position


func _find_exit_target_position() -> Variant:
	var exit_zone := get_node_or_null("ExitZone")
	if exit_zone is Node2D:
		return (exit_zone as Node2D).global_position
	return null


func _get_area_center(area: Area2D) -> Vector2:
	for child in area.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			return child.global_position
	return area.global_position


func _refresh_objective_guidance(_objectives: Array = []) -> void:
	var primary: Dictionary = GameState.get_primary_objective()
	var highlighted_resource_type := ""
	var should_highlight_exit := str(primary.get("type", "")) == GameData.OBJECTIVE_TYPE_CRAFT \
		and not bool(primary.get("completed", false))
	MapRunService.refresh_boss_visibility(self)
	if str(primary.get("type", "")) == GameData.OBJECTIVE_TYPE_GATHER and not bool(primary.get("completed", false)):
		highlighted_resource_type = str(primary.get("target_id", ""))
	if str(primary.get("type", "")) == GameData.OBJECTIVE_TYPE_GATHER_MULTI and not bool(primary.get("completed", false)):
		var target_mats: Dictionary = primary.get("target_materials", {})
		var current_mats: Dictionary = primary.get("current_materials", {})
		for mat in target_mats:
			var mat_str := str(mat)
			if int(current_mats.get(mat_str, 0)) < int(target_mats.get(mat_str, 0)):
				MapRunService.ensure_objective_resource_node(self, mat_str)
				if highlighted_resource_type.is_empty():
					highlighted_resource_type = mat_str
	if not highlighted_resource_type.is_empty() and str(primary.get("type", "")) != GameData.OBJECTIVE_TYPE_GATHER_MULTI:
		MapRunService.ensure_objective_resource_node(self, highlighted_resource_type)
	for child in get_tree().get_nodes_in_group("generated_resource_node"):
		if not is_ancestor_of(child) or not child.has_method("set_objective_highlighted"):
			continue
		child.call("set_objective_highlighted", false)
	for exit_zone in get_tree().get_nodes_in_group("objective_exit_zone"):
		if exit_zone is Node and exit_zone.has_method("set_objective_highlighted"):
			exit_zone.call("set_objective_highlighted", should_highlight_exit)
	_update_objective_arrow()

extends Node2D

@export var encounter_chance := 0.12 # 12% per step

const OBJECTIVE_PANEL_SCENE := preload("res://scenes/ui/ObjectivePanel.tscn")

@onready var player := $Player
@onready var ground_layer := $TileMap_Ground
@onready var object_layer := $TileMap_Objects
@onready var encounter_layer := get_node_or_null("TileMap_Encounter")
@onready var encounter_zones := get_node_or_null("EncounterZones")

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
	_ensure_objective_panel()
	player.stepped.connect(_on_player_stepped)

func _on_player_stepped() -> void:
	if not is_on_encounter_tile(player.global_position):
		return
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
	return _is_inside_layout(tile)


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

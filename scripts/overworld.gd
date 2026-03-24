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
	_refresh_path_blockers()
	_ensure_objective_panel()
	if not GameState.objectives_updated.is_connected(_refresh_objective_guidance):
		GameState.objectives_updated.connect(_refresh_objective_guidance)
	if not GameState.objectives_started.is_connected(_refresh_objective_guidance):
		GameState.objectives_started.connect(_refresh_objective_guidance)
	_refresh_objective_guidance()
	player.stepped.connect(_on_player_stepped)

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
	return _is_inside_layout(tile) and not _is_path_blocked(world_position)


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


func _exit_tree() -> void:
	if GameState.objectives_updated.is_connected(_refresh_objective_guidance):
		GameState.objectives_updated.disconnect(_refresh_objective_guidance)
	if GameState.objectives_started.is_connected(_refresh_objective_guidance):
		GameState.objectives_started.disconnect(_refresh_objective_guidance)


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
	var resources_root := get_node_or_null("GeneratedContent/Resources")
	if resources_root != null:
		for child in resources_root.get_children():
			if not child.has_method("set_objective_highlighted"):
				continue
			var resource_node: Node = child
			var is_target := not highlighted_resource_type.is_empty() and str(resource_node.get("resource_type")) == highlighted_resource_type
			resource_node.call("set_objective_highlighted", is_target)
	for exit_zone in get_tree().get_nodes_in_group("objective_exit_zone"):
		if exit_zone is Node and exit_zone.has_method("set_objective_highlighted"):
			exit_zone.call("set_objective_highlighted", should_highlight_exit)

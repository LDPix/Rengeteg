extends Node2D

@export var encounter_chance := 0.12 # 12% per step

@onready var player := $Player
@onready var ground_layer := $TileMap_Ground
@onready var object_layer := $TileMap_Objects

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
	player.stepped.connect(_on_player_stepped)

func _on_player_stepped() -> void:
	if randf() < encounter_chance:
		_start_battle()

func _start_battle() -> void:
	var map_id := GameState.current_map_id
	var wild_id := GameData.pick_wild_for_map(map_id)
	var scene_path := str(get_tree().current_scene.scene_file_path)
	GameState.set_battle_return(map_id, scene_path, player.global_position)
	GameState.pending_wild_id = wild_id
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		GameState.save_game()
	elif event.is_action_pressed("load_game"):
		GameState.load_game()


func can_move_to_world_position(world_position: Vector2) -> bool:
	var tile := _world_to_tile(world_position)
	return _is_inside_layout(tile)


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

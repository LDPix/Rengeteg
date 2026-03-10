extends Node2D

@export var encounter_chance := 0.12 # 12% per step

@onready var player := $Player

func _ready() -> void:
	randomize()
	GameState.ensure_starter()
	player.stepped.connect(_on_player_stepped)

func _on_player_stepped() -> void:
	if randf() < encounter_chance:
		_start_battle()

func _start_battle() -> void:
	var map_id := GameState.current_map_id
	var wild_id := GameData.pick_wild_for_map(map_id)
	GameState.pending_wild_id = wild_id
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		GameState.save_game()
	elif event.is_action_pressed("load_game"):
		GameState.load_game()

@tool
class_name POISpawnPoint
extends Marker2D

@export var spawn_id: String = ""
@export var activation_weight := 1.0


func get_spawn_id() -> String:
	return spawn_id if not spawn_id.is_empty() else str(name).to_snake_case()

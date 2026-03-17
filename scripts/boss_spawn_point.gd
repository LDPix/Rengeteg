@tool
class_name BossSpawnPoint
extends Marker2D

@export var spawn_id: String = ""
@export var spawn_weight := 1.0


func get_spawn_id() -> String:
	return spawn_id if not spawn_id.is_empty() else str(name).to_snake_case()

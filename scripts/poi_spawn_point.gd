@tool
class_name POISpawnPoint
extends Marker2D

@export var spawn_id: String = ""
@export var activation_weight := 1.0
@export var allowed_poi_ids: PackedStringArray = []
@export var allowed_poi_types: PackedStringArray = []


func get_spawn_id() -> String:
	return spawn_id if not spawn_id.is_empty() else str(name).to_snake_case()


func supports_poi(poi_data: Dictionary) -> bool:
	var poi_id := str(poi_data.get("poi_id", ""))
	var poi_type := str(poi_data.get("poi_type", ""))
	if not allowed_poi_ids.is_empty() and not allowed_poi_ids.has(poi_id):
		return false
	if not allowed_poi_types.is_empty() and not allowed_poi_types.has(poi_type):
		return false
	return true

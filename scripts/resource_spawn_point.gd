@tool
class_name ResourceSpawnPoint
extends Marker2D

@export var spawn_id: String = ""
@export var allowed_resource_types: PackedStringArray = []
@export var spawn_weight := 1.0
@export var visual_type_override: String = ""
@export_enum("auto", "common", "uncommon", "rare") var rarity_override: String = "auto"
@export var min_amount_override := 0
@export var max_amount_override := 0
@export var rare_drop_table_id: String = ""


func get_spawn_id() -> String:
	return spawn_id if not spawn_id.is_empty() else str(name).to_snake_case()


func supports_resource(resource_type: String) -> bool:
	return allowed_resource_types.is_empty() or allowed_resource_types.has(resource_type)

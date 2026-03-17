@tool
class_name EncounterPatch
extends Area2D

@export var patch_id: String = ""
@export var encounter_tag: String = "zone"
@export var encounter_tile_key: String = "e"
@export var activation_weight := 1.0
@export var always_active := false
@export var patch_tags: PackedStringArray = []
@export var active_fill_color := Color(0.32, 0.72, 0.28, 0.24)
@export var inactive_outline_color := Color(1.0, 1.0, 1.0, 0.16)
@export var show_inactive_outline := false
@export var show_runtime_debug := false

var _active_for_run := false


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() and not show_runtime_debug:
		return
	var shape_node := _get_shape_node()
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return
	var rect_shape := shape_node.shape as RectangleShape2D
	var rect := Rect2(-rect_shape.size * 0.5, rect_shape.size)
	if _active_for_run:
		draw_rect(rect, active_fill_color, true)
		draw_rect(rect, active_fill_color.darkened(0.35), false, 2.0)
	elif show_inactive_outline or Engine.is_editor_hint():
		draw_rect(rect, inactive_outline_color, false, 1.0)


func get_patch_id() -> String:
	return patch_id if not patch_id.is_empty() else str(name).to_snake_case()


func set_active_for_run(is_active: bool) -> void:
	_active_for_run = is_active
	monitoring = is_active
	monitorable = is_active
	queue_redraw()


func is_active_for_run() -> bool:
	return _active_for_run


func get_encounter_tag_for_point(world_position: Vector2) -> String:
	if not _active_for_run:
		return ""
	return encounter_tag if contains_point(world_position) else ""


func contains_point(world_position: Vector2) -> bool:
	var shape_node := _get_shape_node()
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return false
	var rect_shape := shape_node.shape as RectangleShape2D
	var local_position := shape_node.to_local(world_position)
	var half_size := rect_shape.size * 0.5
	return absf(local_position.x) <= half_size.x and absf(local_position.y) <= half_size.y


func get_shape_size() -> Vector2:
	var shape_node := _get_shape_node()
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return Vector2.ZERO
	var rect_shape := shape_node.shape as RectangleShape2D
	return rect_shape.size


func _get_shape_node() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null

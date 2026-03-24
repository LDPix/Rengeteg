@tool
class_name PathBlocker
extends Area2D

@export var blocker_id: String = ""
@export var starts_enabled := true
@export var unlock_flag: String = ""
@export var active_fill_color := Color(0.21, 0.27, 0.16, 0.18)
@export var active_outline_color := Color(0.88, 0.94, 0.77, 0.3)
@export var show_runtime_debug := false

var _enabled_for_run := true


func _ready() -> void:
	add_to_group("path_blocker")
	_enabled_for_run = starts_enabled
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() and not show_runtime_debug:
		return
	var shape_node := _get_shape_node()
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return
	var rect_shape := shape_node.shape as RectangleShape2D
	var rect := Rect2(-rect_shape.size * 0.5, rect_shape.size)
	if _enabled_for_run:
		draw_rect(rect, active_fill_color, true)
		draw_rect(rect, active_outline_color, false, 2.0)
	elif Engine.is_editor_hint():
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.12), false, 1.0)


func get_blocker_id() -> String:
	return blocker_id if not blocker_id.is_empty() else str(name).to_snake_case()


func set_enabled_for_run(is_enabled: bool) -> void:
	_enabled_for_run = is_enabled
	monitoring = is_enabled
	monitorable = is_enabled
	queue_redraw()


func is_enabled_for_run() -> bool:
	return _enabled_for_run


func should_block_point(world_position: Vector2) -> bool:
	if not _enabled_for_run:
		return false
	var shape_node := _get_shape_node()
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return false
	var rect_shape := shape_node.shape as RectangleShape2D
	var local_position := shape_node.to_local(world_position)
	var half_size := rect_shape.size * 0.5
	return absf(local_position.x) <= half_size.x and absf(local_position.y) <= half_size.y


func _get_shape_node() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null

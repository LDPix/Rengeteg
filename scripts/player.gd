extends CharacterBody2D

@export var tile_size := 32
@export var move_speed := 10.0 # higher = snappier

var _moving := false
var _target_pos := Vector2.ZERO

signal stepped

func _ready() -> void:
	_target_pos = global_position

func _physics_process(delta: float) -> void:
	if not _moving:
		_handle_input()
	else:
		var to_target := _target_pos - global_position
		# move toward target
		global_position += to_target * min(1.0, delta * move_speed)
		if global_position.distance_to(_target_pos) < 0.5:
			global_position = _target_pos
			_moving = false
			stepped.emit()

func _handle_input() -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2.DOWN
	elif Input.is_action_pressed("ui_up"):
		dir = Vector2.UP

	if dir == Vector2.ZERO:
		return

	_target_pos = global_position + dir * tile_size
	_moving = true

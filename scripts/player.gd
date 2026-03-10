extends CharacterBody2D

@export var tile_size := 32
@export var move_speed := 10.0 # higher = snappier

var _moving := false
var _target_pos := Vector2.ZERO
var _facing := "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal stepped

func _ready() -> void:
	_target_pos = global_position
	if sprite:
		sprite.play("idle_down")

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
			_play_idle()
			stepped.emit()

func _handle_input() -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
		_facing = "right"
	elif Input.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
		_facing = "left"
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2.DOWN
		_facing = "down"
	elif Input.is_action_pressed("ui_up"):
		dir = Vector2.UP
		_facing = "up"

	if dir == Vector2.ZERO:
		return

	var target_position := global_position + dir * tile_size
	var overworld := get_parent()
	if overworld and overworld.has_method("can_move_to_world_position"):
		if not overworld.can_move_to_world_position(target_position):
			_play_idle()
			return

	_target_pos = target_position
	_moving = true
	if sprite:
		sprite.play("walk_%s" % _facing)


func _play_idle() -> void:
	if sprite:
		sprite.play("idle_%s" % _facing)


func reset_movement_state() -> void:
	_target_pos = global_position
	_moving = false
	_play_idle()

extends Area2D

@export var resource_type: String = "wood" # wood/herb/stone
@export var amount: int = 2

@onready var hint := $HintLabel
var _player_near := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_near = true
		hint.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_near = false
		hint.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_near and event.is_action_pressed("interact"):
		GameState.materials[resource_type] = GameState.materials.get(resource_type, 0) + amount
		queue_free()

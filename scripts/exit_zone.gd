extends Area2D

@onready var hint := get_node_or_null("HintLabel")
var _player_near := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if hint:
		hint.visible = false

func _process(_delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/Camp.tscn")

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_near = true
		if hint:
			hint.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_near = false
		if hint:
			hint.visible = false

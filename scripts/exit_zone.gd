extends Area2D

@export_file("*.tscn") var next_scene_path: String = "res://scenes/Camp.tscn"
@export_enum("forest", "cave") var marker_style: String = "forest"

@onready var hint: Label = $HintLabel
@onready var sprite: Sprite2D = $Sprite2D
var _player_near := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hint.visible = false
	_apply_marker()

func _process(_delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file(next_scene_path)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_near = true
		hint.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_near = false
		hint.visible = false


func _apply_marker() -> void:
	var texture_path: String = "res://assets/overworld/exit_forest.png"
	if marker_style == "cave":
		texture_path = "res://assets/overworld/exit_cave.png"
	sprite.texture = load(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

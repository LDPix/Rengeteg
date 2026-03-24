extends Area2D

@export_file("*.tscn") var next_scene_path: String = "res://scenes/Camp.tscn"
@export_enum("forest", "cave", "portal") var marker_style: String = "portal"
@export var show_interaction_prompt := true
@export var prompt_text := "E"
@export var show_prompt_action_text := true
@export var prompt_offset := Vector2.ZERO
@export var marker_scale := Vector2(1.8, 1.8)

@onready var hint_panel: PanelContainer = $HintPanel
@onready var hint: Label = $HintPanel/HintLabel
@onready var hint_anchor: Marker2D = $HintAnchor
@onready var sprite: Sprite2D = $Sprite2D

var _player_near := false
var _hint_strength := 0.0
var _presentation_time := 0.0
var _objective_highlighted := false

func _ready() -> void:
	add_to_group("objective_exit_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_configure_hint()
	_update_hint_visibility()
	_apply_marker()
	set_process(true)


func _process(delta: float) -> void:
	_presentation_time += delta
	_hint_strength = lerpf(_hint_strength, 1.0 if _player_near else 0.0, min(delta * 8.0, 1.0))
	_update_hint_presentation()
	if _player_near and Input.is_action_just_pressed("interact"):
		GameState.end_map_run()
		get_tree().change_scene_to_file(next_scene_path)


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_player_near = true
	_update_hint_visibility()


func _on_body_exited(body: Node) -> void:
	if body.name != "Player":
		return
	_player_near = false
	_update_hint_visibility()


func _apply_marker() -> void:
	var texture_path := "res://assets/overworld/exit_portal.svg"
	if marker_style == "forest":
		texture_path = "res://assets/overworld/exit_forest.png"
	elif marker_style == "cave":
		texture_path = "res://assets/overworld/exit_cave.png"
	sprite.texture = load(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = marker_scale


func _configure_hint() -> void:
	var hint_variant := "verdant"
	if marker_style == "cave":
		hint_variant = "ember"
	elif marker_style == "portal":
		hint_variant = "battle"
	WorldUI.apply_hint(hint_panel, hint, hint_variant)
	_update_hint_text()


func _update_hint_text() -> void:
	hint.text = prompt_text if not show_prompt_action_text else "%s  EXIT" % prompt_text


func _update_hint_visibility() -> void:
	_update_hint_text()
	hint_panel.visible = show_interaction_prompt and (_player_near or _objective_highlighted)
	hint_panel.position = hint_anchor.position + prompt_offset


func _update_hint_presentation() -> void:
	if not is_instance_valid(hint_panel):
		return
	var objective_strength: float = 0.72 if _objective_highlighted else 0.0
	var visible_strength: float = maxf(_hint_strength, objective_strength)
	var lift: float = sin(_presentation_time * 3.2) * 1.2
	hint_panel.modulate = Color(1.0, 1.0, 1.0, visible_strength)
	hint_panel.scale = Vector2.ONE * (0.94 + visible_strength * 0.06)
	hint_panel.position = hint_anchor.position + prompt_offset + Vector2(0, -4.0 - visible_strength * 6.0 + lift * visible_strength)
	var pulse: float = 1.0 + sin(_presentation_time * 2.8) * (0.04 + objective_strength * 0.05)
	sprite.scale = marker_scale * pulse
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(Color(1.0, 0.95, 0.72, 1.0), objective_strength * 0.45)


func set_objective_highlighted(is_active: bool) -> void:
	_objective_highlighted = is_active
	_update_hint_visibility()

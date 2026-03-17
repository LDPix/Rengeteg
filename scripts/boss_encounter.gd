extends Area2D

const MARKER_TEXTURE := preload("res://assets/overworld/boss_marker.svg")

@onready var hint_panel: PanelContainer = $HintPanel
@onready var hint_label: Label = $HintPanel/HintLabel
@onready var hint_anchor: Marker2D = $HintAnchor
@onready var marker_sprite: Sprite2D = $MarkerSprite

var _player_near := false
var _presentation_time := 0.0
var _hint_strength := 0.0
var _boss_data: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_visuals()
	_update_hint()
	set_process(true)


func configure(boss_data: Dictionary) -> void:
	_boss_data = boss_data.duplicate(true)
	if is_node_ready():
		_apply_visuals()
		_update_hint()


func _process(delta: float) -> void:
	_presentation_time += delta
	_hint_strength = lerpf(_hint_strength, 1.0 if _player_near else 0.0, min(delta * 8.0, 1.0))
	_update_hint_presentation()
	queue_redraw()
	if _player_near and Input.is_action_just_pressed("interact"):
		_start_boss_battle()


func _draw() -> void:
	draw_circle(Vector2(0, 24), 18.0, Color(0.12, 0.18, 0.08, 0.26))


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_player_near = true
	_update_hint()


func _on_body_exited(body: Node) -> void:
	if body.name != "Player":
		return
	_player_near = false
	_update_hint()


func _apply_visuals() -> void:
	WorldUI.apply_hint(hint_panel, hint_label, str(_boss_data.get("ui_variant", "ember")))
	marker_sprite.texture = MARKER_TEXTURE
	marker_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _update_hint() -> void:
	hint_label.text = "E  CHALLENGE"
	hint_panel.visible = _player_near
	hint_panel.position = hint_anchor.position


func _update_hint_presentation() -> void:
	if not is_instance_valid(hint_panel):
		return
	var lift := sin(_presentation_time * 3.6) * 1.2
	hint_panel.modulate = Color(1.0, 1.0, 1.0, _hint_strength)
	hint_panel.scale = Vector2.ONE * (0.94 + _hint_strength * 0.06)
	hint_panel.position = hint_anchor.position + Vector2(0, -4.0 - _hint_strength * 6.0 + lift * _hint_strength)
	var pulse := 1.0 + sin(_presentation_time * 2.8) * 0.04
	marker_sprite.scale = Vector2.ONE * pulse


func _start_boss_battle() -> void:
	var creature_id := str(_boss_data.get("creature_id", ""))
	if creature_id.is_empty():
		return
	var current_scene := get_tree().current_scene
	var scene_path := ""
	if current_scene != null:
		scene_path = str(current_scene.scene_file_path)
	GameState.set_battle_return(GameState.current_map_id, scene_path, global_position + Vector2(0, 24))
	GameState.set_pending_battle(creature_id, {
		"encounter_type": "boss",
		"boss_spawn_id": str(_boss_data.get("spawn_id", "")),
		"display_name": str(_boss_data.get("display_name", "")),
		"sprite_path": str(_boss_data.get("sprite_path", "")),
		"level_bonus": int(_boss_data.get("level_bonus", 0)),
		"stat_multiplier": float(_boss_data.get("stat_multiplier", 1.0)),
		"exp_multiplier": float(_boss_data.get("exp_multiplier", 1.0)),
		"reward_profile": "boss",
		"disable_run": bool(_boss_data.get("disable_run", true)),
	})
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

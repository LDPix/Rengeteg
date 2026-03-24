extends Area2D

const ICONS_BY_TYPE := {
	"rich_grove": "res://assets/resources/herb_flower_patch.svg",
	"predator_nest": "res://assets/resources/species_mat_cocoon.svg",
	"shrine": "res://assets/resources/core_shard_relic.svg",
	"expedition_cache": "res://assets/resources/wood_branch_pile.svg",
	"shortcut": "res://assets/overworld/exit_portal.svg",
}

@onready var hint_panel: PanelContainer = $HintPanel
@onready var hint_label: Label = $HintPanel/HintLabel
@onready var hint_anchor: Marker2D = $HintAnchor
@onready var icon_sprite: Sprite2D = $IconSprite
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultContent/ResultLabel
@onready var result_close_button: Button = $ResultPanel/ResultContent/ResultCloseButton

var _player_near := false
var _hint_strength := 0.0
var _presentation_time := 0.0
var _poi_data: Dictionary = {}
var _resolved_map_id := "verdant_wilds"
var _consumed := false
var _showing_result := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	result_close_button.pressed.connect(_close_feedback)
	_apply_visuals()
	_update_hint()
	set_process(true)


func configure(poi_data: Dictionary, map_id: String) -> void:
	_poi_data = poi_data.duplicate(true)
	_resolved_map_id = map_id
	if is_node_ready():
		_apply_visuals()
		_update_hint()


func _process(delta: float) -> void:
	_presentation_time += delta
	_hint_strength = lerpf(_hint_strength, 1.0 if _player_near and not _consumed else 0.0, min(delta * 8.0, 1.0))
	_update_hint_presentation()
	var pulse := 1.0 + sin(_presentation_time * 2.9) * 0.05
	if icon_sprite.visible:
		icon_sprite.scale = Vector2.ONE * pulse


func _on_body_entered(body: Node) -> void:
	if body.name != "Player" or _consumed:
		return
	_player_near = true
	_update_hint()


func _on_body_exited(body: Node) -> void:
	if body.name != "Player":
		return
	_player_near = false
	_update_hint()


func _unhandled_input(event: InputEvent) -> void:
	if _showing_result and event.is_action_pressed("interact"):
		_close_feedback()
		return
	if _consumed or not _player_near or not event.is_action_pressed("interact"):
		return
	_activate_poi()


func _activate_poi() -> void:
	var poi_id := str(_poi_data.get("poi_id", ""))
	if poi_id.is_empty():
		return
	_consumed = true
	_player_near = false
	GameState.mark_poi_interacted(poi_id)

	var feedback_parts: Array[String] = []
	var immediate_rewards: Dictionary = _poi_data.get("immediate_rewards", {})
	if immediate_rewards is Dictionary and not immediate_rewards.is_empty():
		var awarded: Dictionary = GameState.award_reward_bundle(immediate_rewards)
		var reward_text: String = GameData.format_reward_bundle(awarded)
		if not reward_text.is_empty():
			feedback_parts.append(reward_text)

	feedback_parts.append_array(_apply_effects())
	_update_hint()

	var encounter: Dictionary = _poi_data.get("encounter", {})
	if encounter is Dictionary and not encounter.is_empty():
		if not feedback_parts.is_empty():
			GameState.set_camp_notice("%s: %s" % [str(_poi_data.get("title", "POI")), " | ".join(feedback_parts)])
		_start_encounter(encounter)
		return

	var feedback_text := str(_poi_data.get("result_text", ""))
	if feedback_text.is_empty():
		feedback_text = str(_poi_data.get("title", "Explored"))
	if not feedback_parts.is_empty():
		feedback_text = "%s\n%s" % [feedback_text, " | ".join(feedback_parts)]
	_show_feedback(feedback_text)


func _apply_effects() -> Array[String]:
	var messages: Array[String] = []
	for raw_effect in _poi_data.get("effects", []):
		if not (raw_effect is Dictionary):
			continue
		var effect: Dictionary = raw_effect
		match str(effect.get("type", "")):
			"heal_party":
				var restored_hp := _heal_party_by_ratio(float(effect.get("ratio", 0.0)))
				if restored_hp > 0:
					messages.append("Party healed %d HP" % restored_hp)
			"restore_party_mp":
				var restored_mp := _restore_party_mp_by_ratio(float(effect.get("ratio", 0.0)))
				if restored_mp > 0:
					messages.append("Party recovered %d MP" % restored_mp)
			"run_bonus":
				var stat_id := str(effect.get("stat", ""))
				var amount := float(effect.get("amount", 0.0))
				if not stat_id.is_empty() and absf(amount) > 0.001:
					GameState.add_run_bonus(stat_id, amount)
					var label := str(effect.get("label", stat_id.capitalize()))
					messages.append("%s +%s" % [label, _format_bonus_amount(amount)])
			"unlock_blockers":
				var blocker_ids: Array = effect.get("blocker_ids", [])
				var overworld := get_tree().current_scene
				if overworld != null and overworld.has_method("unlock_path_blockers"):
					overworld.call("unlock_path_blockers", blocker_ids)
				var run_flag := str(effect.get("run_flag", ""))
				if not run_flag.is_empty():
					GameState.set_run_flag(run_flag, true)
				var unlock_message := str(effect.get("message", "A hidden path opens."))
				if not unlock_message.is_empty():
					messages.append(unlock_message)
	return messages


func _heal_party_by_ratio(ratio: float) -> int:
	var total_restored: int = 0
	if ratio <= 0.0:
		return total_restored
	for creature in GameState.party:
		var hp_max: int = maxi(1, GameState.get_effective_creature_stat(creature, "hp_max"))
		var amount: int = maxi(1, int(round(float(hp_max) * ratio)))
		var before := int(creature.get("hp", 0))
		GameState.restore_hp(creature, amount)
		total_restored += int(creature.get("hp", 0)) - before
	return total_restored


func _restore_party_mp_by_ratio(ratio: float) -> int:
	var total_restored: int = 0
	if ratio <= 0.0:
		return total_restored
	for creature in GameState.party:
		var mp_max: int = maxi(1, GameState.get_effective_creature_stat(creature, "mp_max"))
		var amount: int = maxi(1, int(round(float(mp_max) * ratio)))
		var before := int(creature.get("mp", 0))
		GameState.restore_mp(creature, amount)
		total_restored += int(creature.get("mp", 0)) - before
	return total_restored


func _start_encounter(encounter: Dictionary) -> void:
	var creature_id := _resolve_encounter_creature_id(encounter)
	if creature_id.is_empty():
		_show_feedback(str(_poi_data.get("title", "Nothing happens.")))
		return
	var current_scene := get_tree().current_scene
	var scene_path := ""
	if current_scene != null:
		scene_path = str(current_scene.scene_file_path)
	GameState.set_battle_return(GameState.current_map_id, scene_path, global_position)
	var battle_context := {
		"encounter_source": "poi",
		"poi_id": str(_poi_data.get("poi_id", "")),
		"poi_type": str(_poi_data.get("poi_type", "")),
		"intro_message": str(encounter.get("message", _poi_data.get("title", "Something stirs..."))),
		"ui_variant": str(encounter.get("ui_variant", _poi_data.get("ui_variant", "verdant"))),
		"level_bonus": int(encounter.get("level_bonus", 0)),
		"stat_multiplier": float(encounter.get("stat_multiplier", 1.0)),
		"exp_multiplier": float(encounter.get("exp_multiplier", 1.0)),
		"disable_run": bool(encounter.get("disable_run", false)),
		"bonus_reward_bundle": encounter.get("reward_bundle", {}).duplicate(true),
	}
	GameState.set_pending_battle(creature_id, battle_context)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")


func _resolve_encounter_creature_id(encounter: Dictionary) -> String:
	var explicit_pool: Array = encounter.get("pool", [])
	if not explicit_pool.is_empty():
		return str(explicit_pool[randi() % explicit_pool.size()])
	return GameData.pick_wild_for_map(_resolved_map_id, str(encounter.get("encounter_tag", "")))


func _apply_visuals() -> void:
	var poi_type := str(_poi_data.get("poi_type", "expedition_cache"))
	var ui_variant := str(_poi_data.get("ui_variant", "verdant"))
	WorldUI.apply_hint(hint_panel, hint_label, ui_variant)
	WorldUI.apply_hint(result_panel, result_label, ui_variant)
	WorldUI.apply_button(result_close_button, "wood")
	result_close_button.text = "Close"
	result_panel.visible = false
	var icon_path := str(_poi_data.get("icon_path", ICONS_BY_TYPE.get(poi_type, ICONS_BY_TYPE["expedition_cache"])))
	icon_sprite.texture = load(icon_path)
	icon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_sprite.modulate = _icon_modulate(poi_type)


func _icon_modulate(poi_type: String) -> Color:
	match poi_type:
		"rich_grove":
			return Color("f1ffd9")
		"predator_nest":
			return Color("ffe4c6")
		"shrine":
			return Color("f7ffe4")
		"shortcut":
			return Color("d4f5ff")
		_:
			return Color("fff7d7")


func _update_hint() -> void:
	var action_label := str(_poi_data.get("prompt_label", "EXPLORE"))
	hint_label.text = "E  %s" % action_label
	hint_panel.visible = _player_near and not _consumed
	hint_panel.position = hint_anchor.position


func _update_hint_presentation() -> void:
	var lift := sin(_presentation_time * 3.2) * 1.2
	hint_panel.modulate = Color(1.0, 1.0, 1.0, _hint_strength)
	hint_panel.scale = Vector2.ONE * (0.94 + _hint_strength * 0.06)
	hint_panel.position = hint_anchor.position + Vector2(0, -4.0 - _hint_strength * 6.0 + lift * _hint_strength)


func _show_feedback(text: String) -> void:
	result_label.text = text
	result_panel.visible = true
	result_panel.modulate = Color.WHITE
	_showing_result = true
	monitoring = false
	monitorable = false
	icon_sprite.visible = false
	hint_panel.visible = false
	set_process(true)


func _close_feedback() -> void:
	if not _showing_result:
		return
	_showing_result = false
	queue_free()


func _format_bonus_amount(amount: float) -> String:
	if absf(amount - round(amount)) < 0.001:
		return str(int(round(amount)))
	return "%.2f" % amount

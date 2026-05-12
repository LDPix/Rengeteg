extends Area2D

const ICONS_BY_TYPE := {
	"rich_grove": "res://assets/resources/herb_flower_patch.png",
	"predator_nest": "res://assets/resources/species_mat_cocoon.png",
	"shrine": "res://assets/resources/core_shard_relic.png",
	"expedition_cache": "res://assets/resources/wood_branch_pile.png",
	"shortcut": "res://assets/overworld/exit_portal.png",
}

const ANCIENT_TABLET_VARIANT_COUNT := 16
const POI_UI_LAYER := 80
const RESULT_PANEL_RAISE := 4.0
const HINT_PANEL_RAISE := 2.0
const CHOICE_PANEL_RAISE := 4.0
const TABLET_CHOICE_RAISE := 6.0
const RESULT_PANEL_ANCHOR_RATIO := 0.42
const HINT_PANEL_ANCHOR_RATIO := 0.5
const CHOICE_PANEL_ANCHOR_RATIO := 0.34
const TABLET_CHOICE_ANCHOR_RATIO := 0.32

# Fallback to SVG if the pixel-art PNG hasn't been generated yet.
const ICONS_FALLBACK := {
	"rich_grove": "res://assets/resources/herb_flower_patch.svg",
	"predator_nest": "res://assets/resources/species_mat_cocoon.svg",
	"shrine": "res://assets/resources/core_shard_relic.svg",
	"expedition_cache": "res://assets/resources/wood_branch_pile.svg",
	"shortcut": "res://assets/overworld/exit_portal.svg",
	"ancient_tablet": "res://assets/resources/core_shard_relic.svg",
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
var _showing_choice := false
var _choice_panel: PanelContainer = null
var _tablet_choice_panel: PanelContainer = null
var _tablet_layer: CanvasLayer = null
var _result_layer: CanvasLayer = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_result_layer = _build_world_ui_layer("PoiResultLayer")
	remove_child(hint_panel)
	_result_layer.add_child(hint_panel)
	remove_child(result_panel)
	_result_layer.add_child(result_panel)
	result_close_button.pressed.connect(_close_feedback)
	_choice_panel = _build_choice_panel()
	_tablet_choice_panel = _build_tablet_choice_panel()
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
	if _showing_result:
		_position_result_panel()


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
	if _showing_choice or _consumed or not _player_near or not event.is_action_pressed("interact"):
		return
	_activate_poi()


func _activate_poi() -> void:
	var poi_id := str(_poi_data.get("poi_id", ""))
	if poi_id.is_empty():
		return

	if str(_poi_data.get("poi_type", "")) == GameData.POI_TYPE_ANCIENT_TABLET:
		_handle_ancient_tablet()
		return
	_play_sfx("poi")

	var risk_choice: Dictionary = _poi_data.get("risk_choice", {})
	if risk_choice is Dictionary and not risk_choice.is_empty():
		_show_choice(risk_choice)
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


func _show_choice(risk_choice: Dictionary) -> void:
	_showing_choice = true
	_player_near = false
	_update_hint()
	if _choice_panel == null:
		return
	_choice_panel.set_size(Vector2(620.0, 360.0))
	_choice_panel.global_position = _position_panel_around_world(_choice_panel, global_position, CHOICE_PANEL_RAISE, CHOICE_PANEL_ANCHOR_RATIO)
	var safe_data: Dictionary = risk_choice.get("safe", {})
	var risky_data: Dictionary = risk_choice.get("risky", {})
	var safe_btn := _choice_panel.get_node_or_null("VBox/HBox/SafeOption/Button") as Button
	var safe_desc := _choice_panel.get_node_or_null("VBox/HBox/SafeOption/Description") as Label
	var risky_btn := _choice_panel.get_node_or_null("VBox/HBox/RiskyOption/Button") as Button
	var risky_desc := _choice_panel.get_node_or_null("VBox/HBox/RiskyOption/Description") as Label
	var cancel_btn := _choice_panel.get_node_or_null("VBox/CancelButton") as Button
	if safe_btn != null:
		safe_btn.text = str(safe_data.get("prompt", "TAKE WHAT'S VISIBLE"))
		if not safe_btn.pressed.is_connected(_on_safe_chosen):
			safe_btn.pressed.connect(_on_safe_chosen.bind(safe_data))
	if safe_desc != null:
		safe_desc.text = _format_choice_effects(safe_data)
	if risky_btn != null:
		risky_btn.text = str(risky_data.get("prompt", "SEARCH THOROUGHLY"))
		if not risky_btn.pressed.is_connected(_on_risky_chosen):
			risky_btn.pressed.connect(_on_risky_chosen.bind(risky_data))
	if risky_desc != null:
		risky_desc.text = _format_choice_effects(risky_data)
	if cancel_btn != null and not cancel_btn.pressed.is_connected(_on_cancel_chosen):
		cancel_btn.pressed.connect(_on_cancel_chosen)
	_choice_panel.visible = true


func _on_safe_chosen(safe_data: Dictionary) -> void:
	_showing_choice = false
	_choice_panel.visible = false
	_consumed = true
	var poi_id := str(_poi_data.get("poi_id", ""))
	GameState.mark_poi_interacted(poi_id)

	var rewards: Dictionary = safe_data.get("rewards", {})
	var feedback_parts: Array[String] = []
	if rewards is Dictionary and not rewards.is_empty():
		var awarded: Dictionary = GameState.award_reward_bundle(rewards)
		var reward_text: String = GameData.format_reward_bundle(awarded)
		if not reward_text.is_empty():
			feedback_parts.append(reward_text)

	var result_text := str(safe_data.get("result_text", str(_poi_data.get("title", "Done."))))
	if not feedback_parts.is_empty():
		result_text = "%s\n%s" % [result_text, " | ".join(feedback_parts)]
	_show_feedback(result_text)


func _on_risky_chosen(risky_data: Dictionary) -> void:
	_showing_choice = false
	_choice_panel.visible = false
	_consumed = true
	var poi_id := str(_poi_data.get("poi_id", ""))
	GameState.mark_poi_interacted(poi_id)

	var encounter: Dictionary = risky_data.get("encounter", {})
	if encounter is Dictionary and not encounter.is_empty():
		_start_encounter(encounter)
	else:
		_show_feedback(str(_poi_data.get("title", "Nothing happens.")))


func _on_cancel_chosen() -> void:
	_showing_choice = false
	_choice_panel.visible = false
	if _tablet_choice_panel != null:
		_tablet_choice_panel.visible = false
	_update_hint()


func _handle_ancient_tablet() -> void:
	var map_id := _resolved_map_id
	var poi_id := str(_poi_data.get("poi_id", ""))
	_play_sfx("tablet")
	if not GameState.has_interacted_with_map_tablet(map_id):
		_consumed = true
		_player_near = false
		GameState.mark_poi_interacted(poi_id)
		GameState.mark_map_tablet_interacted(map_id)
		var recipe_id := str(_poi_data.get("first_time_recipe", ""))
		var feedback := str(_poi_data.get("first_time_text", "Ancient knowledge stirs within you."))
		if not recipe_id.is_empty() and not GameState.has_recipe(recipe_id):
			GameState.unlock_recipe(recipe_id)
			var item_name := str(GameData.get_item_data(recipe_id).get("name", recipe_id))
			feedback = "%s\nRecipe unlocked: %s" % [feedback, item_name]
		_update_hint()
		_show_feedback(feedback)
	else:
		var option_pool: Array = _poi_data.get("tablet_option_pool", [])
		if option_pool.size() < 2:
			_consumed = true
			_player_near = false
			GameState.mark_poi_interacted(poi_id)
			_show_feedback("The runes are silent.")
			return
		var shuffled := option_pool.duplicate(true)
		shuffled.shuffle()
		_show_tablet_choice([shuffled[0], shuffled[1]])


func _show_tablet_choice(options: Array) -> void:
	_showing_choice = true
	_player_near = false
	_update_hint()
	if _tablet_choice_panel == null:
		return
	_tablet_choice_panel.set_size(Vector2(620.0, 390.0))
	_tablet_choice_panel.global_position = _position_panel_around_world(_tablet_choice_panel, global_position, TABLET_CHOICE_RAISE, TABLET_CHOICE_ANCHOR_RATIO)
	var opt_a: Dictionary = options[0]
	var opt_b: Dictionary = options[1]
	var btn_a := _tablet_choice_panel.get_node_or_null("VBox/HBox/OptionA/Button") as Button
	var desc_a := _tablet_choice_panel.get_node_or_null("VBox/HBox/OptionA/Description") as Label
	var btn_b := _tablet_choice_panel.get_node_or_null("VBox/HBox/OptionB/Button") as Button
	var desc_b := _tablet_choice_panel.get_node_or_null("VBox/HBox/OptionB/Description") as Label
	if btn_a != null:
		btn_a.text = str(opt_a.get("label", "OPTION A"))
		btn_a.pressed.connect(_on_tablet_option_chosen.bind(opt_a))
	if desc_a != null:
		desc_a.text = str(opt_a.get("description", ""))
	if btn_b != null:
		btn_b.text = str(opt_b.get("label", "OPTION B"))
		btn_b.pressed.connect(_on_tablet_option_chosen.bind(opt_b))
	if desc_b != null:
		desc_b.text = str(opt_b.get("description", ""))
	_tablet_choice_panel.visible = true


func _on_tablet_option_chosen(option: Dictionary) -> void:
	_showing_choice = false
	_tablet_choice_panel.visible = false
	_consumed = true
	_play_sfx("tablet")
	var poi_id := str(_poi_data.get("poi_id", ""))
	GameState.mark_poi_interacted(poi_id)

	var enemy_buff: Dictionary = option.get("enemy_buff", {})
	var stat_delta := float(enemy_buff.get("stat_multiplier_delta", 0.0))
	var level_bonus := int(enemy_buff.get("level_bonus", 0))
	if absf(stat_delta) > 0.001:
		GameState.add_run_bonus("tablet_enemy_stat_multiplier", stat_delta)
	if level_bonus > 0:
		GameState.add_run_bonus("tablet_enemy_level_bonus", float(level_bonus))

	var reward_upgrade: Dictionary = option.get("reward_upgrade", {})
	for material_id: String in reward_upgrade.keys():
		GameState.add_run_bonus("tablet_reward_%s" % material_id, float(int(reward_upgrade.get(material_id, 0))))

	var description := str(option.get("description", "The runes dim as the tablet's power flows into the land."))
	var buff_parts: Array[String] = []
	if absf(stat_delta) > 0.001:
		buff_parts.append("Enemies +%d%% stats" % int(round(stat_delta * 100.0)))
	if level_bonus > 0:
		buff_parts.append("Enemies +%d level" % level_bonus)
	var reward_text := ""
	if not reward_upgrade.is_empty():
		reward_text = GameData.format_reward_bundle({"materials": reward_upgrade})
	var feedback_lines: Array[String] = [description]
	if not buff_parts.is_empty():
		feedback_lines.append(" | ".join(buff_parts))
	if not reward_text.is_empty():
		feedback_lines.append("Battle rewards: +%s" % reward_text)
	_update_hint()
	_show_feedback("\n".join(feedback_lines))


func _build_choice_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.z_index = 4096
	panel.z_as_relative = false
	panel.offset_left = -178.0
	panel.offset_top = -178.0
	panel.offset_right = 178.0
	panel.offset_bottom = -24.0

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.name = "ChoiceTitle"
	title_lbl.text = "HOW DO YOU APPROACH?"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title_lbl)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	for col_name: String in ["SafeOption", "RiskyOption"]:
		var col := VBoxContainer.new()
		col.name = col_name
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		hbox.add_child(col)

		var btn := Button.new()
		btn.name = "Button"
		btn.custom_minimum_size = Vector2(0, 60)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(btn)

		var desc := Label.new()
		desc.name = "Description"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(desc)

	var cancel_btn := Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "LEAVE"
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(cancel_btn)

	_result_layer.add_child(panel)
	return panel


func _build_tablet_choice_panel() -> PanelContainer:
	_tablet_layer = _build_world_ui_layer("TabletChoiceLayer")

	var panel := PanelContainer.new()
	panel.visible = false

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.name = "TabletTitle"
	title_lbl.text = "THE TABLET OFFERS TWO PATHS"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title_lbl)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	for col_name: String in ["OptionA", "OptionB"]:
		var col := VBoxContainer.new()
		col.name = col_name
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		hbox.add_child(col)

		var btn := Button.new()
		btn.name = "Button"
		btn.custom_minimum_size = Vector2(0, 60)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(btn)

		var desc := Label.new()
		desc.name = "Description"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(desc)

	var cancel_btn := Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "LEAVE"
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	cancel_btn.pressed.connect(_on_cancel_chosen)
	vbox.add_child(cancel_btn)

	_tablet_layer.add_child(panel)
	return panel


func _apply_tablet_choice_panel_styles() -> void:
	if _tablet_choice_panel == null:
		return
	var ui_variant := str(_poi_data.get("ui_variant", "crystal"))
	WorldUI.apply_panel(_tablet_choice_panel, ui_variant, true)
	var title_lbl := _tablet_choice_panel.get_node_or_null("VBox/TabletTitle") as Label
	if title_lbl != null:
		WorldUI.apply_label(title_lbl, "subtitle", ui_variant)
		title_lbl.add_theme_font_size_override("font_size", 22)
	for col_name: String in ["OptionA", "OptionB"]:
		var btn := _tablet_choice_panel.get_node_or_null("VBox/HBox/%s/Button" % col_name) as Button
		if btn != null:
			WorldUI.apply_button(btn, ui_variant)
		var desc := _tablet_choice_panel.get_node_or_null("VBox/HBox/%s/Description" % col_name) as Label
		if desc != null:
			WorldUI.apply_label(desc, "body", ui_variant)
			desc.add_theme_font_size_override("font_size", 20)
	var cancel_btn := _tablet_choice_panel.get_node_or_null("VBox/CancelButton") as Button
	if cancel_btn != null:
		WorldUI.apply_button(cancel_btn, "stone")


func _apply_choice_panel_styles() -> void:
	if _choice_panel == null:
		return
	var ui_variant := str(_poi_data.get("ui_variant", "wood"))
	WorldUI.apply_panel(_choice_panel, ui_variant, true)
	var title_lbl := _choice_panel.get_node_or_null("VBox/ChoiceTitle") as Label
	if title_lbl != null:
		WorldUI.apply_label(title_lbl, "subtitle", ui_variant)
		title_lbl.add_theme_font_size_override("font_size", 22)
	for col_name: String in ["SafeOption", "RiskyOption"]:
		var col_variant := "ember" if col_name == "RiskyOption" else ui_variant
		var btn := _choice_panel.get_node_or_null("VBox/HBox/%s/Button" % col_name) as Button
		if btn != null:
			WorldUI.apply_button(btn, col_variant)
		var desc := _choice_panel.get_node_or_null("VBox/HBox/%s/Description" % col_name) as Label
		if desc != null:
			WorldUI.apply_label(desc, "body", col_variant)
			desc.add_theme_font_size_override("font_size", 20)
	var cancel_btn := _choice_panel.get_node_or_null("VBox/CancelButton") as Button
	if cancel_btn != null:
		WorldUI.apply_button(cancel_btn, "stone")


func _format_choice_effects(option_data: Dictionary) -> String:
	var lines: Array[String] = []
	var result_text := str(option_data.get("result_text", ""))
	if not result_text.is_empty():
		lines.append(result_text)

	var rewards: Dictionary = option_data.get("rewards", {})
	if rewards is Dictionary and not rewards.is_empty():
		var reward_text := GameData.format_reward_bundle(rewards)
		if not reward_text.is_empty():
			lines.append("Gain: %s" % reward_text)

	var encounter: Dictionary = option_data.get("encounter", {})
	if encounter is Dictionary and not encounter.is_empty():
		lines.append("Starts a battle")
		var encounter_rewards: Dictionary = encounter.get("reward_bundle", {})
		if encounter_rewards is Dictionary and not encounter_rewards.is_empty():
			var encounter_reward_text := GameData.format_reward_bundle(encounter_rewards)
			if not encounter_reward_text.is_empty():
				lines.append("Win: %s" % encounter_reward_text)
		var effect_parts: Array[String] = []
		var level_bonus := int(encounter.get("level_bonus", 0))
		if level_bonus > 0:
			effect_parts.append("Enemy +%d Lv" % level_bonus)
		var stat_multiplier := float(encounter.get("stat_multiplier", 1.0))
		if absf(stat_multiplier - 1.0) > 0.001:
			effect_parts.append("Enemy %d%% stats" % int(round(stat_multiplier * 100.0)))
		var exp_multiplier := float(encounter.get("exp_multiplier", 1.0))
		if absf(exp_multiplier - 1.0) > 0.001:
			effect_parts.append("%d%% EXP" % int(round(exp_multiplier * 100.0)))
		if bool(encounter.get("disable_run", false)):
			effect_parts.append("No fleeing")
		if not effect_parts.is_empty():
			lines.append(" | ".join(effect_parts))

	if lines.is_empty():
		return "No immediate effect."
	return "\n".join(lines)


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
	hint_panel.custom_minimum_size = Vector2(340.0, 78.0)
	hint_label.add_theme_font_size_override("font_size", 24)
	result_panel.custom_minimum_size = Vector2(600.0, 0.0)
	result_label.add_theme_font_size_override("font_size", 22)
	WorldUI.apply_button(result_close_button, "wood")
	result_close_button.text = "CLOSE"
	result_close_button.custom_minimum_size = Vector2(0.0, 54.0)
	result_panel.visible = false
	var preferred_path: String
	if poi_type == GameData.POI_TYPE_ANCIENT_TABLET:
		var variant_index := randi() % ANCIENT_TABLET_VARIANT_COUNT
		preferred_path = "res://assets/resources/ancient_tablet_%d.png" % variant_index
	else:
		preferred_path = str(_poi_data.get("icon_path", ICONS_BY_TYPE.get(poi_type, ICONS_BY_TYPE["expedition_cache"])))
	var icon_path := preferred_path if ResourceLoader.exists(preferred_path) \
		else str(ICONS_FALLBACK.get(poi_type, ICONS_FALLBACK.get("ancient_tablet", ICONS_FALLBACK["expedition_cache"])))
	icon_sprite.texture = load(icon_path)
	icon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_sprite.modulate = _icon_modulate(poi_type)
	_apply_choice_panel_styles()
	_apply_tablet_choice_panel_styles()


func _icon_modulate(poi_type: String) -> Color:
	var risk_choice: Dictionary = _poi_data.get("risk_choice", {})
	if risk_choice is Dictionary and not risk_choice.is_empty():
		return Color("ffd0a0")
	match poi_type:
		"rich_grove":
			return Color("f1ffd9")
		"predator_nest":
			return Color("ffe4c6")
		"shrine":
			return Color("f7ffe4")
		"shortcut":
			return Color("d4f5ff")
		"ancient_tablet":
			return Color("c8f0ff")
		_:
			return Color("fff7d7")


func _play_sfx(effect_id: String, volume_db: float = 0.0) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.call("play", effect_id, volume_db)


func _build_world_ui_layer(layer_name: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = layer_name
	layer.layer = POI_UI_LAYER
	add_child(layer)
	return layer


func _world_to_ui_position(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position


func _position_result_panel() -> void:
	result_panel.global_position = _position_panel_around_world(result_panel, global_position, RESULT_PANEL_RAISE, RESULT_PANEL_ANCHOR_RATIO)


func _update_hint() -> void:
	var action_label := str(_poi_data.get("prompt_label", "EXPLORE"))
	hint_label.text = "E  %s" % action_label
	hint_panel.visible = _player_near and not _consumed and not _showing_choice
	hint_panel.global_position = _position_panel_around_world(hint_panel, hint_anchor.global_position, HINT_PANEL_RAISE, HINT_PANEL_ANCHOR_RATIO)


func _update_hint_presentation() -> void:
	var lift := sin(_presentation_time * 3.2) * 1.2
	hint_panel.modulate = Color(1.0, 1.0, 1.0, _hint_strength)
	hint_panel.scale = Vector2.ONE * (0.94 + _hint_strength * 0.06)
	var extra_raise := 4.0 + _hint_strength * 6.0 - lift * _hint_strength
	hint_panel.global_position = _position_panel_around_world(hint_panel, hint_anchor.global_position, HINT_PANEL_RAISE + extra_raise, HINT_PANEL_ANCHOR_RATIO)


func _show_feedback(text: String) -> void:
	result_label.text = text
	_position_result_panel()
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


func _position_panel_around_world(panel: Control, world_position: Vector2, raise_amount: float, anchor_ratio: float) -> Vector2:
	var ui_position := _world_to_ui_position(world_position)
	var panel_size := panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = panel.get_combined_minimum_size()
	return Vector2(
		ui_position.x - panel_size.x * 0.5,
		ui_position.y - panel_size.y * anchor_ratio - raise_amount
	)

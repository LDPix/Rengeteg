extends Control

const ABILITY_BUTTON_SCENE := preload("res://scenes/ui/PrimaryActionButton.tscn")
const BATTLE_INTRO_STEPS: Array = [
	["YOUR CREATURE",
		"The card on the left is your active creature — its name, level, HP, and MP. This is who fights on your behalf.",
		"player_card", "below"],
	["ENEMY CREATURE",
		"The card on the right is the wild creature you've encountered. Reduce its HP to zero to win the battle.",
		"enemy_card", "below"],
	["HP - HEALTH",
		"HP is health. When a creature's HP hits zero it faints. If all your creatures faint, the expedition ends and gathered resources are lost.",
		"player_card", "below"],
	["MP - MANA",
		"MP is the energy used by abilities. Each ability costs MP. MP does not recover during battle — only back at camp.",
		"player_card", "below"],
	["ABILITIES",
		"Each turn choose an ability to attack. They differ in power, accuracy, and MP cost. Hover an icon to see its details.",
		"abilities_list", "above"],
	["INVENTORY",
		"Open Inventory to use consumables. Seals can bind wild creatures, and potions or tonics help your active creature in battle.",
		"btn_capture", "above"],
	["YOUR TEAM",
		"The panel on the left shows your full party. Click a creature to switch it in — but the enemy gets a free turn while you swap.",
		"party_bar", "right"],
	["RUNNING AWAY",
		"Use Run to flee. You keep any creatures already captured but forfeit battle rewards.",
		"btn_run", "above"],
]
const TUTORIAL_BIND_RETRY_TITLE := "BINDING FAILED"
const TUTORIAL_BIND_RETRY_BODY := "The creature broke free of the seal. Try binding it again with your Basic Seal."
const TUTORIAL_ABILITIES_TITLE := "USE ABILITIES"
const TUTORIAL_ABILITIES_BODY := "Use your creature's abilities during battle to deal damage and win the fight."
const TUTORIAL_BATTLE_REWARDS_TITLE := "BATTLE REWARDS"
const TUTORIAL_BATTLE_REWARDS_BODY := "Defeating wild creatures earns your party Exp and drops materials you can use for crafting."
const OBJECTIVE_HIGHLIGHT_COLOR := Color(1.0, 1.0, 0.82, 1.0)
const OBJECTIVE_HIGHLIGHT_BORDER_COLOR := Color(0.82, 0.25, 0.18, 1.0)
const MP_ICON_PATH := "res://assets/ui/stats/mp_icon.svg"
const EXP_ICON_PATH := "res://assets/ui/stats/exp_icon.svg"
const TUTORIAL_POPUP_WIDTH := 430.0
const BATTLE_ABILITY_BUTTON_SIZE := Vector2(196, 112)
const MATERIAL_ICON_PATHS := {
	"wood": "res://assets/resources/wood_node.svg",
	"herb": "res://assets/resources/herb_node.svg",
	"stone": "res://assets/resources/stone_node.svg",
	"crystal": "res://assets/resources/crystal_node.svg",
	"core_shard": "res://assets/resources/core_shard_node.svg",
	"species_mat": "res://assets/resources/species_mat_node.svg",
}

class BattleRules:
	const MIN_HIT_CHANCE := 35.0
	const MAX_HIT_CHANCE := 95.0
	const DEFENSE_SCALING := 25.0
	const CRIT_MULTIPLIER := 2
	const MIN_FLEE_CHANCE := 25.0
	const MAX_FLEE_CHANCE := 95.0
	const BASE_FLEE_CHANCE := 55.0
	const SPEED_FLEE_SCALING := 40.0
	const FAILED_FLEE_BONUS := 12.0

	static func get_turn_order(player_action: Dictionary, enemy_action: Dictionary, player_mon: Dictionary, wild_mon: Dictionary, battle_bonuses: Dictionary) -> Array[Dictionary]:
		var order: Array[Dictionary] = []
		if str(player_action.get("type", "")) == "switch":
			order.append({"side": "player", "action": player_action})
			order.append({"side": "enemy", "action": enemy_action})
			return order

		var player_speed: float = get_effective_stat(player_mon, "player", "spd", battle_bonuses)
		var enemy_speed: float = get_effective_stat(wild_mon, "enemy", "spd", battle_bonuses)
		var player_first := player_speed > enemy_speed or (player_speed == enemy_speed and randf() < 0.5)
		if player_first:
			order.append({"side": "player", "action": player_action})
			order.append({"side": "enemy", "action": enemy_action})
		else:
			order.append({"side": "enemy", "action": enemy_action})
			order.append({"side": "player", "action": player_action})
		return order

	static func execute_ability(user: Dictionary, user_side: String, target: Dictionary, target_side: String, ability_id: String, battle_bonuses: Dictionary) -> Dictionary:
		var ability: Dictionary = GameData.get_ability_data(ability_id)
		var messages: Array[String] = []
		if ability.is_empty():
			messages.append("But nothing happened.")
			return {"messages": messages, "defender_fainted": false}

		var ability_name := str(ability.get("name", ability_id))
		var user_name := _format_battle_log_name(user, user_side)
		messages.append("%s used %s!" % [user_name, ability_name])
		if not GameState.can_use_ability(user, ability_id):
			messages.append("%s does not have enough MP." % user_name)
			return {"messages": messages, "defender_fainted": false}

		GameState.spend_mp(user, int(ability.get("mp_cost", 0)))
		var hit_chance: float = get_hit_chance(user, user_side, target, target_side, float(ability.get("accuracy", 100.0)), battle_bonuses)
		if randf() * 100.0 >= hit_chance:
			messages.append("The ability missed!")
			return {"messages": messages, "defender_fainted": false, "hit": false}

		var damage: int = calculate_damage(user, user_side, target, target_side, float(ability.get("power", 0.0)), battle_bonuses)
		var is_crit: bool = randf() * 100.0 < float(get_effective_stat(user, user_side, "crit", battle_bonuses))
		if is_crit:
			damage *= CRIT_MULTIPLIER
			messages.append("Critical hit!")
		target["hp"] = max(0, int(target.get("hp", 0)) - damage)
		messages.append("%s took %d damage!" % [_format_battle_log_name(target, target_side), damage])
		return {
			"messages": messages,
			"defender_fainted": int(target.get("hp", 0)) <= 0,
			"hit": true,
		}

	static func _format_battle_log_name(creature: Dictionary, side: String) -> String:
		var creature_name := str(creature.get("name", "Creature"))
		return "Your %s" % creature_name if side == "player" else "Enemy %s" % creature_name

	static func get_hit_chance(attacker: Dictionary, attacker_side: String, defender: Dictionary, defender_side: String, move_accuracy: float, battle_bonuses: Dictionary) -> float:
		var attacker_acc: float = get_effective_stat(attacker, attacker_side, "acc", battle_bonuses)
		var defender_eva: float = max(1.0, get_effective_stat(defender, defender_side, "eva", battle_bonuses))
		return clampf(move_accuracy * (attacker_acc / defender_eva), MIN_HIT_CHANCE, MAX_HIT_CHANCE)

	static func calculate_damage(attacker: Dictionary, attacker_side: String, defender: Dictionary, defender_side: String, move_power: float, battle_bonuses: Dictionary) -> int:
		var defense: float = max(0.0, get_effective_stat(defender, defender_side, "def", battle_bonuses))
		var reduction: float = defense / (defense + DEFENSE_SCALING)
		var base_damage: float = (move_power + get_effective_stat(attacker, attacker_side, "atk", battle_bonuses)) * (1.0 - reduction)
		return max(1, int(round(base_damage)))

	static func get_effective_stat(creature: Dictionary, side: String, stat_name: String, battle_bonuses: Dictionary) -> float:
		var base_value := float(GameState.get_effective_creature_stat(creature, stat_name))
		var bonus_map: Dictionary = battle_bonuses.get(side, {})
		var bonus: float = float(bonus_map.get(stat_name, 0.0))
		return base_value + bonus

	static func get_flee_chance(player_mon: Dictionary, wild_mon: Dictionary, battle_bonuses: Dictionary, failed_attempts: int) -> float:
		var player_speed: float = max(1.0, get_effective_stat(player_mon, "player", "spd", battle_bonuses))
		var enemy_speed: float = max(1.0, get_effective_stat(wild_mon, "enemy", "spd", battle_bonuses))
		var speed_difference_ratio: float = (player_speed - enemy_speed) / max(1.0, player_speed + enemy_speed)
		var failed_attempt_bonus: float = float(maxi(0, failed_attempts)) * FAILED_FLEE_BONUS
		return clampf(BASE_FLEE_CHANCE + speed_difference_ratio * SPEED_FLEE_SCALING + failed_attempt_bonus, MIN_FLEE_CHANCE, MAX_FLEE_CHANCE)

@onready var background: ColorRect = $Background
@onready var party_bar: PanelContainer = $OuterMargin/MainRow/PartyBar
@onready var party_slots: VBoxContainer = $OuterMargin/MainRow/PartyBar/PartyBarPadding/PartySlots
@onready var title_label: Label = $OuterMargin/MainRow/Root/TopBar/TitleLabel
@onready var battle_card: PanelContainer = $OuterMargin/MainRow/Root/BattleCard
@onready var actions_card: PanelContainer = $OuterMargin/MainRow/Root/ActionsCard
@onready var info: RichTextLabel = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/LogColumn/BattleLog
@onready var log_toggle_button: Button = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/LogColumn/LogToggleButton
@onready var abilities_list: HBoxContainer = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/MiddleColumn/AbilitiesList
@onready var buttons_row: VBoxContainer = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow
@onready var btn_capture: Button = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/CaptureButton
@onready var btn_run: Button = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/RunButton
@onready var seal_chooser_panel: PanelContainer = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/MiddleColumn/SealChooserPanel
@onready var seal_chooser_title: Label = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/MiddleColumn/SealChooserPanel/SealChooserPadding/SealChooserVBox/SealChooserTitle
@onready var seal_options: Container = $OuterMargin/MainRow/Root/ActionsCard/ActionsPadding/ActionsVBox/MiddleColumn/SealChooserPanel/SealChooserPadding/SealChooserVBox/SealOptions
@onready var tutorial_popup: PanelContainer = $TutorialPopup
@onready var tutorial_popup_title: Label = $TutorialPopup/PopupPadding/PopupContent/PopupTitle
@onready var tutorial_popup_body: Label = $TutorialPopup/PopupPadding/PopupContent/PopupBody
@onready var tutorial_popup_button: Button = $TutorialPopup/PopupPadding/PopupContent/PopupButton
@onready var player_card = $OuterMargin/MainRow/Root/BattleCard/Padding/CreaturesRow/PlayerCard
@onready var enemy_card = $OuterMargin/MainRow/Root/BattleCard/Padding/CreaturesRow/EnemyCard

var player_mon: Dictionary
var wild_mon: Dictionary
var battle_context: Dictionary = {}
var battle_bonuses: Dictionary = {
	"player": {},
	"enemy": {},
}

var active_index := 0
var participant_indices: Dictionary = {}
var _log_has_content := false
var bind_highlight_time := 0.0
var highlighted_seal_button: Button = null
var showing_seal_chooser := false
var failed_flee_attempts := 0
var result_overlay: PanelContainer = null
var result_title_label: Label = null
var result_rewards_list: VBoxContainer = null
var result_log: RichTextLabel = null
var result_continue_button: Button = null
var result_log_button: Button = null
var battle_log_lines: Array[String] = []


func _ready() -> void:
	_apply_world_ui()
	active_index = _find_first_alive_index()
	if active_index == -1:
		_back_to_overworld_deferred()
		return
	player_mon = GameState.party[active_index]
	GameState.ensure_combat_fields(player_mon)
	battle_context = GameState.consume_pending_battle_context()
	btn_run.disabled = bool(battle_context.get("disable_run", false))
	wild_mon = GameState.build_wild_creature_instance(GameState.pending_wild_id, GameState.current_map_id, battle_context)
	if wild_mon.is_empty():
		_back_to_overworld_deferred()
		return
	GameState.ensure_combat_fields(wild_mon)
	GameState.mark_creature_encountered(str(wild_mon.get("id", "")))
	_mark_participant(active_index)
	GameState.note_opening_bind_battle_started()

	btn_capture.pressed.connect(_on_capture)
	btn_run.pressed.connect(_on_run)
	log_toggle_button.pressed.connect(_toggle_battle_log)
	tutorial_popup_button.pressed.connect(_hide_tutorial_popup)
	_build_result_overlay()

	_update_ui()
	await _play_battle_start_animation()
	if GameState.should_show_battle_mechanics_tutorial():
		GameState.mark_battle_mechanics_tutorial_shown()
		await _show_battle_mechanics_tutorial()
	await _apply_battle_start_passives()
	if GameState.should_show_battle_abilities_tutorial_popup():
		GameState.mark_battle_abilities_tutorial_popup_shown()
		_show_tutorial_popup(TUTORIAL_ABILITIES_TITLE, TUTORIAL_ABILITIES_BODY)
	set_process(true)


func _show_battle_mechanics_tutorial() -> void:
	var highlight: Panel = Panel.new()
	var highlight_style: StyleBoxFlat = StyleBoxFlat.new()
	highlight_style.draw_center = false
	highlight_style.border_width_left = 3
	highlight_style.border_width_top = 3
	highlight_style.border_width_right = 3
	highlight_style.border_width_bottom = 3
	highlight_style.border_color = Color(1.0, 0.75, 0.2, 1.0)
	highlight_style.corner_radius_top_left = 6
	highlight_style.corner_radius_top_right = 6
	highlight_style.corner_radius_bottom_left = 6
	highlight_style.corner_radius_bottom_right = 6
	highlight_style.shadow_color = Color(1.0, 0.75, 0.2, 0.45)
	highlight_style.shadow_size = 10
	highlight.add_theme_stylebox_override("panel", highlight_style)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 50
	add_child(highlight)
	highlight.top_level = true

	var pulse_tween: Tween = create_tween().set_loops()
	pulse_tween.tween_property(highlight, "modulate:a", 0.5, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(highlight, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tutorial_popup.top_level = true
	tutorial_popup.z_index = 51
	tutorial_popup.custom_minimum_size = Vector2(TUTORIAL_POPUP_WIDTH, 0.0)

	var steps: Array = BATTLE_INTRO_STEPS
	for i: int in range(steps.size()):
		var step: Array = steps[i]
		var target_id: String = str(step[2])
		var preferred_side: String = str(step[3])
		var is_last: bool = i == steps.size() - 1

		tutorial_popup_button.text = "LET'S GO!" if is_last else "NEXT  ›"
		tutorial_popup_title.text = str(step[0])
		tutorial_popup_body.text = str(step[1])
		tutorial_popup.visible = true
		tutorial_popup.modulate.a = 0.0
		tutorial_popup.size = Vector2(TUTORIAL_POPUP_WIDTH, 0.0)

		var target: Control = _get_tutorial_target(target_id)
		if target != null:
			highlight.global_position = target.global_position
			highlight.size = target.size
			highlight.visible = true
		else:
			highlight.visible = false

		await get_tree().process_frame

		var panel_min_size: Vector2 = tutorial_popup.get_combined_minimum_size()
		var panel_size := Vector2(TUTORIAL_POPUP_WIDTH, panel_min_size.y)
		var viewport_size: Vector2 = get_viewport_rect().size
		if target != null:
			tutorial_popup.size = panel_size
			tutorial_popup.global_position = _get_tutorial_popup_position(
				target.global_position, target.size, panel_size, viewport_size, preferred_side
			)
		tutorial_popup.modulate.a = 1.0
		await tutorial_popup_button.pressed

	pulse_tween.kill()
	highlight.queue_free()
	tutorial_popup_button.text = "Continue"
	tutorial_popup.modulate.a = 1.0
	tutorial_popup.top_level = false
	tutorial_popup.z_index = 0
	tutorial_popup.custom_minimum_size = Vector2.ZERO


func _get_tutorial_target(target_id: String) -> Control:
	match target_id:
		"player_card":
			return player_card as Control
		"enemy_card":
			return enemy_card as Control
		"abilities_list":
			return abilities_list as Control
		"btn_capture":
			return btn_capture as Control
		"party_bar":
			return party_bar as Control
		"btn_run":
			return btn_run as Control
	return null


func _get_tutorial_popup_position(target_pos: Vector2, target_size: Vector2, panel_size: Vector2, viewport_size: Vector2, preferred_side: String) -> Vector2:
	const MARGIN: float = 14.0
	var right_pos := Vector2(target_pos.x + target_size.x + MARGIN, target_pos.y)
	var left_pos := Vector2(target_pos.x - panel_size.x - MARGIN, target_pos.y)
	var below_pos := Vector2(target_pos.x, target_pos.y + target_size.y + MARGIN)
	var above_pos := Vector2(target_pos.x, target_pos.y - panel_size.y - MARGIN)
	var all_sides: Dictionary = {
		"right": right_pos, "left": left_pos, "below": below_pos, "above": above_pos
	}
	var order: Array[String] = [preferred_side]
	for key: String in ["right", "left", "below", "above"]:
		if key != preferred_side:
			order.append(key)
	for side_key: String in order:
		var pos: Vector2 = all_sides[side_key]
		if pos.x >= MARGIN and pos.y >= MARGIN \
				and pos.x + panel_size.x <= viewport_size.x - MARGIN \
				and pos.y + panel_size.y <= viewport_size.y - MARGIN:
			return pos
	var fallback: Vector2 = all_sides[preferred_side]
	return Vector2(
		clampf(fallback.x, MARGIN, maxf(MARGIN, viewport_size.x - panel_size.x - MARGIN)),
		clampf(fallback.y, MARGIN, maxf(MARGIN, viewport_size.y - panel_size.y - MARGIN))
	)


func _play_battle_start_animation() -> void:
	_play_sfx("battle_start")
	await get_tree().process_frame
	await get_tree().process_frame

	var top_bar := $OuterMargin/MainRow/Root/TopBar
	player_card.modulate = Color(1, 1, 1, 0)
	enemy_card.modulate = Color(1, 1, 1, 0)
	party_bar.modulate = Color(1, 1, 1, 0)
	top_bar.modulate = Color(1, 1, 1, 0)
	actions_card.modulate = Color(1, 1, 1, 0)

	player_card.pivot_offset = player_card.size / 2.0
	enemy_card.pivot_offset = enemy_card.size / 2.0
	player_card.scale = Vector2(0.8, 0.8)
	enemy_card.scale = Vector2(0.8, 0.8)

	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.92, 0.78, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 100
	add_child(flash)

	var vs_label := Label.new()
	vs_label.text = "VS"
	vs_label.add_theme_font_size_override("font_size", 88)
	vs_label.add_theme_color_override("font_color", Color(0.96, 0.72, 0.28))
	vs_label.add_theme_color_override("font_shadow_color", Color(0.4, 0.15, 0.0, 0.9))
	vs_label.add_theme_constant_override("shadow_offset_x", 4)
	vs_label.add_theme_constant_override("shadow_offset_y", 4)
	vs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vs_label.modulate.a = 0.0
	vs_label.z_index = 101
	# Fixed explicit size — font metrics aren't reliable immediately after add_child.
	# Text is centered within the box, so positioning only needs the box dimensions.
	var vs_w: float = 220.0
	var vs_h: float = 110.0
	vs_label.custom_minimum_size = Vector2(vs_w, vs_h)
	vs_label.size = Vector2(vs_w, vs_h)
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(vs_label)
	await get_tree().process_frame
	var root_node: Control = $OuterMargin/MainRow/Root as Control
	var gap_center_x: float = root_node.global_position.x + root_node.size.x / 2.0
	var cards_center_y: float = player_card.global_position.y + float(player_card.size.y) / 2.0
	vs_label.position = Vector2(gap_center_x - vs_w / 2.0, cards_center_y - vs_h / 2.0)
	vs_label.pivot_offset = Vector2(vs_w / 2.0, vs_h / 2.0)
	vs_label.scale = Vector2(1.6, 1.6)

	var ft := create_tween()
	ft.tween_property(flash, "color:a", 0.75, 0.15)
	ft.tween_property(flash, "color:a", 0.0, 0.3)

	create_tween().tween_property(party_bar, "modulate:a", 1.0, 0.4)
	create_tween().tween_property(top_bar, "modulate:a", 1.0, 0.4)

	var pt := create_tween().set_parallel()
	pt.tween_property(player_card, "modulate:a", 1.0, 0.35).set_delay(0.1)
	pt.tween_property(player_card, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.1)

	var et := create_tween().set_parallel()
	et.tween_property(enemy_card, "modulate:a", 1.0, 0.35).set_delay(0.2)
	et.tween_property(enemy_card, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.2)

	var vt := create_tween().set_parallel()
	vt.tween_property(vs_label, "modulate:a", 1.0, 0.2).set_delay(0.3)
	vt.tween_property(vs_label, "scale", Vector2(1.05, 1.05), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.3)

	await get_tree().create_timer(0.95).timeout

	var ot := create_tween().set_parallel()
	ot.tween_property(vs_label, "modulate:a", 0.0, 0.3)
	ot.tween_property(actions_card, "modulate:a", 1.0, 0.35)
	await ot.finished

	vs_label.queue_free()
	flash.queue_free()
	player_card.pivot_offset = Vector2.ZERO
	enemy_card.pivot_offset = Vector2.ZERO


func _apply_world_ui() -> void:
	WorldUI.apply_background(background, "battle")
	WorldUI.apply_label(title_label, "title", "ember")
	var _battle_colors: Dictionary = WorldUI.get_variant_colors("battle")
	info.add_theme_color_override("default_color", _battle_colors["text"])
	info.add_theme_color_override("font_outline_color", _battle_colors["border"])
	info.add_theme_constant_override("outline_size", 1)
	WorldUI.apply_panel(party_bar, "wood", true)
	battle_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	actions_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	WorldUI.apply_panel(seal_chooser_panel, "stone", true)
	WorldUI.apply_panel(tutorial_popup, "battle", true)
	WorldUI.apply_label(seal_chooser_title, "title", "crystal")
	WorldUI.apply_label(tutorial_popup_title, "title", "crystal")
	WorldUI.apply_label(tutorial_popup_body, "body", "verdant")
	player_card.apply_variant("wood")
	enemy_card.apply_variant("stone")
	WorldUI.apply_button(btn_capture, "ember", true)
	WorldUI.apply_button(btn_run, "battle")
	WorldUI.apply_button(log_toggle_button, "stone")
	WorldUI.apply_button(tutorial_popup_button, "verdant", true)


func _build_result_overlay() -> void:
	result_overlay = PanelContainer.new()
	result_overlay.name = "BattleResults"
	result_overlay.visible = false
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.z_index = 80
	WorldUI.apply_panel(result_overlay, "battle", true)
	add_child(result_overlay)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 72)
	outer_margin.add_theme_constant_override("margin_top", 56)
	outer_margin.add_theme_constant_override("margin_right", 72)
	outer_margin.add_theme_constant_override("margin_bottom", 56)
	result_overlay.add_child(outer_margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	outer_margin.add_child(content)

	result_title_label = Label.new()
	result_title_label.text = "VICTORY!"
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title_label.add_theme_font_size_override("font_size", 30)
	WorldUI.apply_label(result_title_label, "title", "crystal")
	content.add_child(result_title_label)

	result_rewards_list = VBoxContainer.new()
	result_rewards_list.alignment = BoxContainer.ALIGNMENT_CENTER
	result_rewards_list.add_theme_constant_override("separation", 10)
	content.add_child(result_rewards_list)

	result_log = RichTextLabel.new()
	result_log.visible = false
	result_log.custom_minimum_size = Vector2(0, 220)
	result_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_log.fit_content = false
	result_log.scroll_following = true
	result_log.bbcode_enabled = true
	result_log.add_theme_font_size_override("normal_font_size", 18)
	var colors: Dictionary = WorldUI.get_variant_colors("battle")
	result_log.add_theme_color_override("default_color", colors["text"])
	result_log.add_theme_color_override("font_outline_color", colors["border"])
	result_log.add_theme_constant_override("outline_size", 1)
	content.add_child(result_log)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	content.add_child(buttons)

	result_log_button = Button.new()
	result_log_button.text = "BATTLE LOG"
	result_log_button.custom_minimum_size = Vector2(180, 56)
	result_log_button.pressed.connect(_toggle_result_log)
	WorldUI.apply_button(result_log_button, "stone", true)
	buttons.add_child(result_log_button)

	result_continue_button = Button.new()
	result_continue_button.text = "CONTINUE"
	result_continue_button.custom_minimum_size = Vector2(180, 56)
	WorldUI.apply_button(result_continue_button, "verdant", true)
	buttons.add_child(result_continue_button)


func _update_ui() -> void:
	_hide_inventory_chooser()
	_rebuild_party_bar()
	player_card.set_details(
		"%s LV. %d" % [player_mon["name"], int(player_mon.get("level", 1))],
		int(player_mon.get("hp", 0)),
		GameState.get_effective_creature_stat(player_mon, "hp_max"),
		int(player_mon.get("mp", 0)),
		GameState.get_effective_creature_stat(player_mon, "mp_max"),
		_get_creature_sprite_path(player_mon)
	)
	enemy_card.set_details(
		"%s LV. %d" % [wild_mon["name"], int(wild_mon.get("level", 1))],
		int(wild_mon.get("hp", 0)),
		GameState.get_effective_creature_stat(wild_mon, "hp_max"),
		int(wild_mon.get("mp", 0)),
		GameState.get_effective_creature_stat(wild_mon, "mp_max"),
		_get_creature_sprite_path(wild_mon)
	)
	title_label.text = _battle_title()
	_refresh_capture_ui()
	_refresh_run_ui()
	_rebuild_ability_buttons()


func _refresh_capture_ui() -> void:
	var battle_items := _get_available_battle_items()
	var total_items := 0
	for item_id in battle_items:
		total_items += GameState.get_item_count(item_id)
	btn_capture.text = "INVENTORY" if total_items > 0 else "INVENTORY (EMPTY)"
	btn_capture.disabled = battle_items.is_empty()
	if battle_items.is_empty():
		_hide_inventory_chooser()


func _refresh_run_ui() -> void:
	if bool(battle_context.get("disable_run", false)):
		btn_run.text = "RUN"
		btn_run.disabled = true
		return
	btn_run.text = "RUN (%d%%)" % int(round(_get_flee_chance()))
	btn_run.disabled = false


func _rebuild_ability_buttons() -> void:
	for child in abilities_list.get_children():
		child.queue_free()
	if showing_seal_chooser:
		_rebuild_inventory_buttons()
		return

	var abilities: Array[String] = GameState.get_creature_abilities(player_mon)
	for ability_id in abilities:
		var ability_data: Dictionary = GameData.get_ability_data(ability_id)
		if ability_data.is_empty():
			continue
		var can_use := GameState.can_use_ability(player_mon, ability_id)
		var mp_cost := int(ability_data.get("mp_cost", 0))
		var ability_name := str(ability_data.get("name", ability_id)).to_upper()

		var slot := VBoxContainer.new()
		slot.custom_minimum_size = Vector2(BATTLE_ABILITY_BUTTON_SIZE.x, 0)
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.alignment = BoxContainer.ALIGNMENT_CENTER

		var btn := Button.new()
		btn.custom_minimum_size = BATTLE_ABILITY_BUTTON_SIZE
		btn.text = ability_name
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var icon_path := str(ability_data.get("icon_path", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			btn.icon = load(icon_path)
			btn.expand_icon = false
		btn.tooltip_text = GameData.format_ability_tooltip(ability_id)
		btn.disabled = not can_use
		btn.set_meta("sfx_click_enabled", true)
		WorldUI.apply_button(btn, "wood", true)
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_constant_override("h_separation", 12)
		for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			var sb: StyleBox = btn.get_theme_stylebox(state_name)
			if sb is StyleBoxFlat:
				var flat := (sb as StyleBoxFlat).duplicate()
				flat.content_margin_left = 18.0
				flat.content_margin_top = 14.0
				flat.content_margin_right = 18.0
				flat.content_margin_bottom = 14.0
				btn.add_theme_stylebox_override(state_name, flat)
		btn.pressed.connect(_on_ability_pressed.bind(ability_id))
		slot.add_child(btn)

		slot.add_child(_build_mp_cost_row(mp_cost))

		abilities_list.add_child(slot)


func _build_mp_cost_row(mp_cost: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)

	var icon := TextureRect.new()
	icon.texture = load(MP_ICON_PATH)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(icon)

	var cost_label := Label.new()
	cost_label.text = str(mp_cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 18)
	WorldUI.apply_label(cost_label, "subtitle", "wood")
	row.add_child(cost_label)
	return row


func _rebuild_inventory_buttons() -> void:
	highlighted_seal_button = null
	var battle_items := _get_available_battle_items()
	for item_id in battle_items:
		var item_data := GameData.get_item_data(item_id)
		var count := GameState.get_item_count(item_id)
		var button: Button = ABILITY_BUTTON_SCENE.instantiate()
		button.text = "%s x%d" % [str(item_data.get("name", item_id)).to_upper(), count]
		button.custom_minimum_size = Vector2(220, 88)
		button.add_theme_font_size_override("font_size", 24)
		button.tooltip_text = GameData.get_item_detail_text(item_id)
		var icon_path := GameData.get_item_icon_path(item_id)
		if not icon_path.is_empty():
			button.icon = load(icon_path)
			button.expand_icon = false
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_constant_override("h_separation", 12)
		WorldUI.apply_button(button, str(item_data.get("variant", "ember")), true)
		button.set_meta("sfx_click_enabled", true)
		button.pressed.connect(_use_inventory_item.bind(item_id))
		abilities_list.add_child(button)
		if GameState.is_opening_bind_tutorial_active() and item_id == "basic_seal":
			highlighted_seal_button = button
	var cancel_button: Button = ABILITY_BUTTON_SCENE.instantiate()
	cancel_button.text = "CANCEL"
	cancel_button.custom_minimum_size = Vector2(220, 88)
	cancel_button.add_theme_font_size_override("font_size", 24)
	WorldUI.apply_button(cancel_button, "battle")
	cancel_button.pressed.connect(_hide_inventory_chooser)
	abilities_list.add_child(cancel_button)


func _on_ability_pressed(ability_id: String) -> void:
	if tutorial_popup.visible:
		return
	if not GameState.can_use_ability(player_mon, ability_id):
		_log("%s does not have enough MP." % str(player_mon.get("name", "Creature")))
		_rebuild_ability_buttons()
		return
	_set_actions_locked(true)
	var player_action: Dictionary = {"type": "ability", "ability_id": ability_id}
	var enemy_action: Dictionary = _choose_enemy_action(wild_mon)
	if not await _process_round(player_action, enemy_action):
		return
	_update_ui()
	_set_actions_locked(false)


func _choose_enemy_action(creature: Dictionary) -> Dictionary:
	var available_abilities: Array[String] = []
	for ability_id in GameState.get_creature_abilities(creature):
		if GameState.can_use_ability(creature, ability_id):
			available_abilities.append(ability_id)
	if not available_abilities.is_empty():
		return {"type": "ability", "ability_id": available_abilities[randi() % available_abilities.size()]}
	return {"type": "none"}


func _process_round(player_action: Dictionary, enemy_action: Dictionary) -> bool:
	var skip_player_action := false
	for turn in BattleRules.get_turn_order(player_action, enemy_action, player_mon, wild_mon, battle_bonuses):
		var side := str(turn.get("side", ""))
		var action: Dictionary = turn.get("action", {})
		var battler: Dictionary = player_mon if side == "player" else wild_mon
		if int(battler.get("hp", 0)) <= 0:
			continue
		if side == "player" and skip_player_action:
			skip_player_action = false
			continue
		var action_type := str(action.get("type", "none"))
		if action_type != "ability":
			continue

		var ability_id := str(action.get("ability_id", ""))
		if ability_id.is_empty():
			continue
		var target: Dictionary = wild_mon if side == "player" else player_mon
		var target_side := "enemy" if side == "player" else "player"
		var result: Dictionary = BattleRules.execute_ability(battler, side, target, target_side, ability_id, battle_bonuses)
		var result_messages: Array = result.get("messages", [])
		var attacker_card = player_card if side == "player" else enemy_card
		var defender_card = enemy_card if side == "player" else player_card
		await attacker_card.play_attack_animation()
		if bool(result.get("hit", false)):
			_play_sfx("hit", -2.0)
			defender_card.play_hit_animation()
		elif result.has("hit"):
			_play_sfx("miss")
		await _show_battle_messages(result_messages)
		if bool(result.get("defender_fainted", false)):
			if side == "player":
				await _win_battle()
				return false
			if not await _auto_switch_if_needed():
				return false
			skip_player_action = true
	return true


func _apply_battle_start_passives() -> void:
	var messages: Array[String] = []
	messages.append_array(_apply_passive_hook(player_mon, "player", "battle_start"))
	messages.append_array(_apply_passive_hook(wild_mon, "enemy", "battle_start"))
	if not messages.is_empty():
		await _show_battle_messages(messages, 0.45)
	_update_ui()


func _apply_passive_hook(creature: Dictionary, side: String, hook_name: String) -> Array[String]:
	var passive_id := str(creature.get("passive_id", ""))
	if passive_id.is_empty():
		var empty_messages: Array[String] = []
		return empty_messages
	var passive: Dictionary = GameData.get_passive_data(passive_id)
	if passive.is_empty() or hook_name != "battle_start":
		var empty_messages: Array[String] = []
		return empty_messages

	var messages: Array[String] = []
	var effect_type := str(passive.get("effect_type", ""))
	var passive_name := str(passive.get("name", passive_id))
	match effect_type:
		"battle_stat_bonus":
			var stat_name := str(passive.get("stat", ""))
			if stat_name.is_empty():
				return messages
			var side_bonuses: Dictionary = battle_bonuses.get(side, {}).duplicate(true)
			side_bonuses[stat_name] = float(side_bonuses.get(stat_name, 0.0)) + float(passive.get("amount", 0))
			battle_bonuses[side] = side_bonuses
			messages.append("%s's %s takes effect!" % [str(creature.get("name", "Creature")), passive_name])
		"battle_start_restore_mp":
			var restore_amount := int(passive.get("amount", 0))
			if restore_amount <= 0:
				return messages
			var before_mp := int(creature.get("mp", 0))
			GameState.restore_mp(creature, restore_amount)
			var restored := int(creature.get("mp", 0)) - before_mp
			if restored > 0:
				messages.append("%s's %s restored %d MP!" % [str(creature.get("name", "Creature")), passive_name, restored])
	return messages


func _log(text: String) -> void:
	battle_log_lines.append(text)
	if _log_has_content:
		info.append_text("\n" + text)
	else:
		info.append_text(text)
		_log_has_content = true
	info.scroll_to_line(info.get_line_count() - 1)


func _show_battle_messages(lines: Array, delay: float = 0.55) -> void:
	for line in lines:
		_log(str(line))
		await get_tree().create_timer(delay).timeout


func _show_battle_results(summary: Dictionary, victory: bool = true) -> void:
	if result_overlay == null:
		return
	_set_actions_locked(true)
	for child in result_rewards_list.get_children():
		child.queue_free()

	var exp_rows: Array = summary.get("exp", [])
	for raw_entry in exp_rows:
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			var amount := int(entry.get("amount", 0))
			if amount > 0:
				result_rewards_list.add_child(_build_result_reward_row(EXP_ICON_PATH, amount, str(entry.get("name", "Creature")), true))
			if int(entry.get("levels_gained", 0)) > 0:
				result_rewards_list.add_child(_build_result_text_row("%s reached Lv. %d!" % [
					str(entry.get("name", "Creature")),
					int(entry.get("new_level", 1)),
				]))

	var materials: Dictionary = summary.get("materials", {})
	for material_id in _sorted_reward_keys(materials):
		var amount := int(materials.get(material_id, 0))
		if amount > 0:
			result_rewards_list.add_child(_build_result_reward_row(_get_material_icon_path(material_id), amount, GameData.get_material_display_name(material_id)))

	var items: Dictionary = summary.get("items", {})
	for item_id in _sorted_reward_keys(items):
		var amount := int(items.get(item_id, 0))
		if amount > 0:
			result_rewards_list.add_child(_build_result_reward_row(GameData.get_item_icon_path(item_id), amount, str(GameData.get_item_data(item_id).get("name", item_id.capitalize()))))

	var recipes: Array = summary.get("recipes", [])
	for recipe_id in recipes:
		var item_id := str(recipe_id)
		result_rewards_list.add_child(_build_result_reward_row(GameData.get_item_icon_path(item_id), 1, "Recipe: %s" % str(GameData.get_item_data(item_id).get("name", item_id.capitalize()))))

	if result_rewards_list.get_child_count() == 0:
		var no_rewards := Label.new()
		no_rewards.text = "NO REWARDS"
		no_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_rewards.add_theme_font_size_override("font_size", 20)
		WorldUI.apply_label(no_rewards, "subtitle", "stone")
		result_rewards_list.add_child(no_rewards)

	result_title_label.text = "VICTORY!" if victory else "DEFEAT"
	result_log.text = "\n".join(battle_log_lines)
	result_log.visible = false
	result_log_button.text = "BATTLE LOG"
	result_overlay.visible = true
	await result_continue_button.pressed


func _build_result_reward_row(icon_path: String, amount: int, tooltip_text: String, show_label: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.tooltip_text = tooltip_text

	var icon := TextureRect.new()
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(48, 48)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(icon)

	var amount_label := Label.new()
	amount_label.text = "x%d" % amount
	amount_label.add_theme_font_size_override("font_size", 24)
	WorldUI.apply_label(amount_label, "title", "wood")
	row.add_child(amount_label)
	if show_label:
		var name_label := Label.new()
		name_label.text = tooltip_text
		name_label.add_theme_font_size_override("font_size", 20)
		WorldUI.apply_label(name_label, "subtitle", "wood")
		row.add_child(name_label)
	return row


func _build_result_text_row(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	WorldUI.apply_label(label, "title", "verdant")
	return label


func _toggle_result_log() -> void:
	if result_log == null:
		return
	result_log.visible = not result_log.visible
	result_log.text = "\n".join(battle_log_lines)
	result_log_button.text = "HIDE LOG" if result_log.visible else "BATTLE LOG"
	if result_log.visible:
		result_log.scroll_to_line(result_log.get_line_count() - 1)


func _sorted_reward_keys(rewards: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in rewards.keys():
		keys.append(str(key))
	keys.sort()
	return keys


func _get_material_icon_path(material_id: String) -> String:
	return str(MATERIAL_ICON_PATHS.get(material_id, ""))


func _rebuild_party_bar() -> void:
	for child in party_slots.get_children():
		child.queue_free()
	for i in range(GameState.party.size()):
		var creature: Dictionary = GameState.party[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(72, 80)
		btn.expand_icon = true
		var sprite_path := _get_creature_sprite_path(creature)
		if not sprite_path.is_empty():
			btn.icon = load(sprite_path)
		var is_active := i == active_index
		var is_fainted := int(creature.get("hp", 0)) <= 0
		btn.disabled = is_active or is_fainted
		if is_active:
			WorldUI.apply_button(btn, "wood", true)
		elif is_fainted:
			WorldUI.apply_button(btn, "battle")
			btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
		else:
			WorldUI.apply_button(btn, "stone")
			btn.pressed.connect(_on_party_slot_pressed.bind(i))
		party_slots.add_child(btn)


func _on_party_slot_pressed(party_index: int) -> void:
	if tutorial_popup.visible:
		return
	_set_actions_locked(true)
	active_index = party_index
	player_mon = GameState.party[active_index]
	GameState.ensure_combat_fields(player_mon)
	_mark_participant(active_index)
	_log("Go, %s!" % player_mon["name"])
	await get_tree().create_timer(0.5).timeout
	if not await _process_round({"type": "switch"}, _choose_enemy_action(wild_mon)):
		return
	_update_ui()
	_set_actions_locked(false)


func _find_next_alive_index(from_index: int) -> int:
	var n := GameState.party.size()
	for step in range(1, n + 1):
		var i := (from_index + step) % n
		var mon: Dictionary = GameState.party[i]
		if int(mon.get("hp", 0)) > 0:
			return i
	return from_index


func _find_first_alive_index() -> int:
	for i in range(GameState.party.size()):
		var mon: Dictionary = GameState.party[i]
		if int(mon.get("hp", 0)) > 0:
			return i
	return -1


func _on_capture() -> void:
	if tutorial_popup.visible:
		return
	if _get_available_battle_items().is_empty():
		_log("No battle consumables available.")
		_refresh_capture_ui()
		return
	if _is_inventory_chooser_open():
		_hide_inventory_chooser()
	else:
		_show_inventory_chooser()


func _use_inventory_item(item_id: String) -> void:
	var item_data := GameData.get_item_data(item_id)
	var use_contexts: Array = item_data.get("use_contexts", [])
	if use_contexts.has("battle_capture"):
		_use_capture_item(item_id)
		return
	if use_contexts.has("battle_active_creature"):
		await _use_active_creature_consumable(item_id)
		return
	_log("%s cannot be used in battle." % str(item_data.get("name", item_id)))
	_refresh_capture_ui()
	_show_inventory_chooser()


func _use_active_creature_consumable(item_id: String) -> void:
	var item_data := GameData.get_item_data(item_id)
	var item_name := str(item_data.get("name", item_id))
	var creature_name := str(player_mon.get("name", "Creature"))
	var before_hp := int(player_mon.get("hp", 0))
	var before_mp := int(player_mon.get("mp", 0))
	if not GameState.use_consumable_on_creature(item_id, player_mon):
		_log("%s would have no effect on %s right now." % [item_name, creature_name])
		_refresh_capture_ui()
		_show_inventory_chooser()
		return
	_hide_inventory_chooser()
	_refresh_capture_ui()
	var restored_parts: Array[String] = []
	var restored_hp := int(player_mon.get("hp", 0)) - before_hp
	var restored_mp := int(player_mon.get("mp", 0)) - before_mp
	if restored_hp > 0:
		restored_parts.append("%d HP" % restored_hp)
	if restored_mp > 0:
		restored_parts.append("%d MP" % restored_mp)
	var effect_summary := ""
	if not restored_parts.is_empty():
		effect_summary = " Restored %s." % ", ".join(restored_parts)
	_log("%s used %s.%s" % [creature_name, item_name, effect_summary])
	_set_actions_locked(true)
	await get_tree().create_timer(0.35).timeout
	if not await _process_round({"type": "none"}, _choose_enemy_action(wild_mon)):
		return
	_update_ui()
	_set_actions_locked(false)


func _use_capture_item(item_id: String) -> void:
	if GameState.get_item_count(item_id) <= 0:
		_log("That seal is no longer available.")
		_refresh_capture_ui()
		_show_inventory_chooser()
		return
	GameState.remove_item(item_id, 1)
	_hide_inventory_chooser()
	_refresh_capture_ui()

	var hp_ratio: float = float(wild_mon["hp"]) / float(max(1, GameState.get_effective_creature_stat(wild_mon, "hp_max")))
	var chance: float = clampf(0.25 + (0.60 * (1.0 - hp_ratio)), 0.25, 0.85)
	chance = clampf(chance + GameState.get_run_bonus("capture_chance_bonus", 0.0), 0.25, 0.95)
	var tutorial_result := GameState.resolve_opening_bind_attempt()
	if tutorial_result == "forced_fail":
		chance = -1.0
	elif tutorial_result == "forced_success":
		chance = 2.0
	_set_actions_locked(true)
	var captured := randf() < chance
	await enemy_card.play_bind_attempt_animation()
	if captured:
		_play_sfx("bind_success")
		await enemy_card.play_bind_success_animation()
		var went_to_party: bool = GameState.add_creature_to_collection(wild_mon)
		GameState.notify_creature_captured(wild_mon)
		var item_name := str(GameData.get_item_data(item_id).get("name", item_id))
		if went_to_party:
			_log("Bound %s! Added to team. 1 %s used." % [wild_mon["name"], item_name])
		else:
			_log("Bound %s! Sent to storage. 1 %s used." % [wild_mon["name"], item_name])
		await get_tree().create_timer(0.8).timeout
		var result_summary := _award_drops(true)
		await _show_battle_results(result_summary, true)
		_back_to_overworld()
	else:
		await enemy_card.play_bind_fail_animation()
		_log("Binding failed! 1 %s was used." % str(GameData.get_item_data(item_id).get("name", item_id)))
		await get_tree().create_timer(0.4).timeout
		if not await _process_round({"type": "none"}, _choose_enemy_action(wild_mon)):
			return
		_update_ui()
		_set_actions_locked(false)
		if GameState.is_opening_bind_tutorial_active():
			_show_tutorial_popup(TUTORIAL_BIND_RETRY_TITLE, TUTORIAL_BIND_RETRY_BODY)


func _on_run() -> void:
	if tutorial_popup.visible:
		return
	if bool(battle_context.get("disable_run", false)):
		_log("You cannot flee from a boss encounter.")
		return
	_set_actions_locked(true)
	var flee_chance := _get_flee_chance()
	if randf() * 100.0 < flee_chance:
		_log("You escaped safely.")
		await get_tree().create_timer(0.45).timeout
		_back_to_overworld()
		return
	failed_flee_attempts += 1
	_log("Could not escape!")
	await get_tree().create_timer(0.45).timeout
	if not await _process_round({"type": "none"}, _choose_enemy_action(wild_mon)):
		return
	_update_ui()
	_set_actions_locked(false)


func _win_battle() -> void:
	_log("You defeated %s!" % wild_mon["name"])
	await get_tree().create_timer(0.8).timeout
	GameState.notify_battle_won({
		"is_boss": _is_boss_battle(),
		"map_id": GameState.current_map_id,
	})
	var exp_summary := await _award_victory_exp()
	var result_summary := _award_drops(false)
	result_summary["exp"] = exp_summary
	await get_tree().create_timer(1.0).timeout
	if GameState.should_show_battle_rewards_tutorial_popup():
		GameState.mark_battle_rewards_tutorial_popup_shown()
		_show_tutorial_popup(TUTORIAL_BATTLE_REWARDS_TITLE, TUTORIAL_BATTLE_REWARDS_BODY)
		await tutorial_popup_button.pressed
	await _show_battle_results(result_summary, true)
	_back_to_overworld()


func _lose_battle() -> void:
	_log("Your %s fainted..." % player_mon["name"])
	await get_tree().create_timer(0.8).timeout
	await _show_battle_results({}, false)
	GameState.forfeit_current_map_run()
	GameState.queue_first_defeat_popup()
	GameState.set_camp_notice("Your whole team fainted. You were carried back to camp and lost all resources gathered on that run.")
	get_tree().change_scene_to_file("res://scenes/Camp.tscn")


func _award_drops(captured: bool) -> Dictionary:
	var rewards := GameData.get_battle_reward_roll(GameState.current_map_id, captured, battle_context)
	GameState.award_materials(rewards)
	var node_rewards := GameState.claim_resource_node_reward(battle_context.get("resource_node_reward", {}))
	var total_rewards := GameData.merge_materials(rewards, node_rewards)
	var tablet_bonus := GameState.get_tablet_reward_bonus()
	if not tablet_bonus.is_empty():
		GameState.award_materials(tablet_bonus)
		total_rewards = GameData.merge_materials(total_rewards, tablet_bonus)
	var bonus_bundle: Dictionary = battle_context.get("bonus_reward_bundle", {})
	var bonus_items := {}
	var bonus_recipes: Array = []
	if not bonus_bundle.is_empty():
		var awarded_bonus := GameState.award_reward_bundle(bonus_bundle)
		var bonus_materials: Dictionary = awarded_bonus.get("materials", {})
		total_rewards = GameData.merge_materials(total_rewards, bonus_materials)
		bonus_items = awarded_bonus.get("items", {})
		bonus_recipes = awarded_bonus.get("recipes", [])
	if _is_boss_battle():
		GameState.mark_boss_cleared(str(battle_context.get("boss_spawn_id", "")))
		GameState.notify_boss_defeated(GameState.current_map_id)
	return {
		"materials": total_rewards,
		"items": bonus_items,
		"recipes": bonus_recipes,
	}


func _auto_switch_if_needed() -> bool:
	if player_mon["hp"] > 0:
		return true

	var fainted_name := str(player_mon["name"])
	player_mon["hp"] = 0
	var next := _find_next_alive_index(active_index)
	if next == active_index:
		await _lose_battle()
		return false

	active_index = next
	player_mon = GameState.party[active_index]
	GameState.ensure_combat_fields(player_mon)
	_mark_participant(active_index)
	_log("%s fainted! Go, %s!" % [fainted_name, player_mon["name"]])
	await get_tree().create_timer(0.8).timeout
	return true


func _mark_participant(party_index: int) -> void:
	if party_index < 0 or party_index >= GameState.party.size():
		return
	participant_indices[party_index] = true


func _award_victory_exp() -> Array[Dictionary]:
	var exp_results: Array[Dictionary] = []
	var total_exp_reward := GameData.get_exp_reward_for_creature(wild_mon)
	total_exp_reward = int(round(float(total_exp_reward) * float(battle_context.get("exp_multiplier", 1.0))))
	if total_exp_reward <= 0:
		return exp_results
	var participant_list := _get_participant_indices()
	if participant_list.is_empty():
		return exp_results
	var exp_reward: int = max(1, int(floor(float(total_exp_reward) / float(participant_list.size()))))
	for party_index in participant_list:
		var creature: Dictionary = GameState.party[party_index]
		var result: Dictionary = GameState.add_exp_to_creature(creature, exp_reward)
		exp_results.append({
			"name": str(creature.get("name", "Creature")),
			"amount": int(result.get("exp_gained", 0)),
			"levels_gained": int(result.get("levels_gained", 0)),
			"new_level": int(result.get("new_level", creature.get("level", 1))),
		})
		if party_index == active_index:
			player_mon = creature
			_update_ui()
		_log("%s gained %d EXP." % [creature["name"], int(result.get("exp_gained", 0))])
		await get_tree().create_timer(0.8).timeout
		if int(result.get("levels_gained", 0)) > 0:
			if party_index == active_index:
				player_mon = creature
				_update_ui()
			_log("%s grew to Lv. %d!" % [creature["name"], int(result.get("new_level", creature.get("level", 1)))])
			await get_tree().create_timer(0.9).timeout
	return exp_results


func _get_participant_indices() -> Array[int]:
	var indices: Array[int] = []
	for party_index in participant_indices.keys():
		indices.append(int(party_index))
	indices.sort()
	return indices


func _back_to_overworld() -> void:
	var map_id := GameState.current_map_id
	var scene_path := GameState.battle_return_scene_path
	if scene_path.is_empty():
		scene_path = str(GameData.maps[map_id].get("scene_path", "res://scenes/overworld/Overworld_Verdant.tscn"))
	GameState.pending_wild_id = ""
	get_tree().change_scene_to_file(scene_path)


func _back_to_overworld_deferred() -> void:
	call_deferred("_back_to_overworld")


func _is_boss_battle() -> bool:
	return str(battle_context.get("reward_profile", "")) == "boss"


func _play_sfx(effect_id: String, volume_db: float = 0.0) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.call("play", effect_id, volume_db)


func _battle_title() -> String:
	return "BATTLE"


func _get_available_battle_items() -> Array[String]:
	var available: Array[String] = []
	for item_id in GameData.get_item_ids_by_category(GameData.ITEM_CATEGORY_CONSUMABLE):
		var item_data := GameData.get_item_data(item_id)
		if GameState.get_item_count(item_id) <= 0:
			continue
		var use_contexts: Array = item_data.get("use_contexts", [])
		if use_contexts.has("battle_capture") or use_contexts.has("battle_active_creature"):
			available.append(item_id)
	return available


func _get_available_capture_items() -> Array[String]:
	var available: Array[String] = []
	for item_id in GameData.get_item_ids_by_category(GameData.ITEM_CATEGORY_CONSUMABLE):
		var item_data := GameData.get_item_data(item_id)
		if not item_data.get("use_contexts", []).has("battle_capture"):
			continue
		if GameState.get_item_count(item_id) > 0:
			available.append(item_id)
	return available


func _show_inventory_chooser() -> void:
	var battle_items := _get_available_battle_items()
	if battle_items.is_empty():
		_log("No battle consumables available.")
		_hide_inventory_chooser()
		return
	showing_seal_chooser = true
	buttons_row.visible = false
	_rebuild_ability_buttons()


func _hide_inventory_chooser() -> void:
	showing_seal_chooser = false
	highlighted_seal_button = null
	buttons_row.visible = true
	_rebuild_ability_buttons()


func _is_inventory_chooser_open() -> bool:
	return showing_seal_chooser


func _set_actions_locked(locked: bool) -> void:
	btn_run.disabled = locked or bool(battle_context.get("disable_run", false))
	log_toggle_button.disabled = locked
	if locked:
		btn_capture.disabled = true
		for child in abilities_list.get_children():
			var btn := _get_slot_button(child)
			if btn != null:
				btn.disabled = true
		for child in party_slots.get_children():
			if child is Button:
				(child as Button).disabled = true


func _get_flee_chance() -> float:
	return BattleRules.get_flee_chance(player_mon, wild_mon, battle_bonuses, failed_flee_attempts)


func _show_tutorial_popup(title: String, body: String) -> void:
	tutorial_popup_title.text = title.to_upper()
	tutorial_popup_body.text = body
	tutorial_popup.visible = true


func _hide_tutorial_popup() -> void:
	tutorial_popup.visible = false


func _get_slot_button(node: Node) -> Button:
	if node is Button:
		return node as Button
	if node.get_child_count() > 0 and node.get_child(0) is Button:
		return node.get_child(0) as Button
	return null


func _should_highlight_bind_tutorial() -> bool:
	return GameState.is_opening_bind_tutorial_active() and not _is_inventory_chooser_open() and not tutorial_popup.visible


func _should_highlight_ability_tutorial() -> bool:
	return GameState.is_battle_abilities_tutorial_active() and not _is_inventory_chooser_open() and not tutorial_popup.visible


func _process(delta: float) -> void:
	bind_highlight_time += delta
	var pulse := 1.0 + sin(bind_highlight_time * 4.4) * 0.04
	var highlight_color := OBJECTIVE_HIGHLIGHT_COLOR
	if _should_highlight_bind_tutorial():
		_set_objective_highlight(btn_capture, true, pulse)
	else:
		_set_objective_highlight(btn_capture, false)
	if _should_highlight_ability_tutorial():
		for child in abilities_list.get_children():
			var ability_button := _get_slot_button(child)
			if ability_button != null:
				_set_objective_highlight(ability_button, true, pulse)
	else:
		for child in abilities_list.get_children():
			var idle_button := _get_slot_button(child)
			if idle_button != null and idle_button != highlighted_seal_button:
				_set_objective_highlight(idle_button, false)
	if highlighted_seal_button != null and is_instance_valid(highlighted_seal_button):
		_set_objective_highlight(highlighted_seal_button, true, pulse)


func _toggle_battle_log() -> void:
	info.visible = not info.visible
	log_toggle_button.text = "HIDE LOG" if info.visible else "SHOW LOG"


func _set_objective_highlight(button: Button, enabled: bool, pulse: float = 1.0) -> void:
	if enabled:
		button.scale = Vector2.ONE * pulse
		button.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(OBJECTIVE_HIGHLIGHT_COLOR, 0.28)
		_apply_objective_border(button)
	else:
		button.scale = Vector2.ONE
		button.modulate = Color(1, 1, 1, 1)
		_restore_objective_border(button)


func _apply_objective_border(button: Button) -> void:
	if bool(button.get_meta("_objective_border_active", false)):
		return
	var original_styles := {}
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style_box := button.get_theme_stylebox(style_name)
		if style_box == null:
			continue
		original_styles[style_name] = style_box
		if style_box is StyleBoxFlat:
			var highlighted_style: StyleBoxFlat = (style_box as StyleBoxFlat).duplicate()
			highlighted_style.border_width_left = 3
			highlighted_style.border_width_top = 3
			highlighted_style.border_width_right = 3
			highlighted_style.border_width_bottom = 3
			highlighted_style.border_color = OBJECTIVE_HIGHLIGHT_BORDER_COLOR
			button.add_theme_stylebox_override(style_name, highlighted_style)
	button.set_meta("_objective_original_styles", original_styles)
	button.set_meta("_objective_border_active", true)


func _restore_objective_border(button: Button) -> void:
	if not bool(button.get_meta("_objective_border_active", false)):
		return
	var original_styles: Dictionary = button.get_meta("_objective_original_styles", {})
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		if original_styles.has(style_name):
			button.add_theme_stylebox_override(style_name, original_styles[style_name])
		else:
			button.remove_theme_stylebox_override(style_name)
	button.set_meta("_objective_original_styles", {})
	button.set_meta("_objective_border_active", false)


func _get_creature_sprite_path(creature: Dictionary) -> String:
	var override_path := str(creature.get("sprite_path_override", ""))
	if not override_path.is_empty():
		return override_path
	return str(GameData.creatures[creature["id"]].get("sprite_path", ""))

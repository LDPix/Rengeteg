extends Control

const ABILITY_BUTTON_SCENE := preload("res://scenes/ui/PrimaryActionButton.tscn")
const MIN_HIT_CHANCE := 35.0
const MAX_HIT_CHANCE := 95.0
const DEFENSE_SCALING := 25.0
const CRIT_MULTIPLIER := 2
const TUTORIAL_BIND_RETRY_TITLE := "Binding Failed"
const TUTORIAL_BIND_RETRY_BODY := "The creature broke free of the seal. Try binding it again with your Basic Seal."
const TUTORIAL_ABILITIES_TITLE := "Use Abilities"
const TUTORIAL_ABILITIES_BODY := "Use your creature's abilities during battle to deal damage and win the fight."
const TUTORIAL_BATTLE_REWARDS_TITLE := "Battle Rewards"
const TUTORIAL_BATTLE_REWARDS_BODY := "Defeating wild creatures earns your party Exp and drops materials you can use for crafting."
const OBJECTIVE_HIGHLIGHT_COLOR := Color(1.0, 1.0, 0.82, 1.0)
const OBJECTIVE_HIGHLIGHT_BORDER_COLOR := Color(0.82, 0.25, 0.18, 1.0)

@onready var background: ColorRect = $Background
@onready var title_label: Label = $OuterMargin/Root/TopBar/TitleLabel
@onready var info: Label = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/BattleLog
@onready var abilities_list: VBoxContainer = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/AbilitiesList
@onready var btn_switch: Button = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/SwitchButton
@onready var btn_capture: Button = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/CaptureButton
@onready var btn_run: Button = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/RunButton
@onready var seal_chooser_panel: PanelContainer = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/SealChooserPanel
@onready var seal_chooser_title: Label = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/SealChooserPanel/SealChooserPadding/SealChooserVBox/SealChooserTitle
@onready var seal_options: Container = $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/SealChooserPanel/SealChooserPadding/SealChooserVBox/SealOptions
@onready var tutorial_popup: PanelContainer = $TutorialPopup
@onready var tutorial_popup_title: Label = $TutorialPopup/PopupPadding/PopupContent/PopupTitle
@onready var tutorial_popup_body: Label = $TutorialPopup/PopupPadding/PopupContent/PopupBody
@onready var tutorial_popup_button: Button = $TutorialPopup/PopupPadding/PopupContent/PopupButton
@onready var player_card = $OuterMargin/Root/BattleCard/Padding/CreaturesRow/PlayerCard
@onready var enemy_card = $OuterMargin/Root/BattleCard/Padding/CreaturesRow/EnemyCard

var player_mon: Dictionary
var wild_mon: Dictionary
var battle_context: Dictionary = {}
var battle_bonuses: Dictionary = {
	"player": {},
	"enemy": {},
}

var active_index := 0
var participant_indices: Dictionary = {}
var bind_highlight_time := 0.0
var highlighted_seal_button: Button = null
var showing_seal_chooser := false


func _ready() -> void:
	_apply_world_ui()
	active_index = _find_first_alive_index()
	if active_index == -1:
		_back_to_overworld()
		return
	player_mon = GameState.party[active_index]
	GameState.ensure_combat_fields(player_mon)
	battle_context = GameState.consume_pending_battle_context()
	btn_run.disabled = bool(battle_context.get("disable_run", false))
	wild_mon = GameState.build_wild_creature_instance(GameState.pending_wild_id, GameState.current_map_id, battle_context)
	if wild_mon.is_empty():
		_back_to_overworld()
		return
	GameState.ensure_combat_fields(wild_mon)
	_mark_participant(active_index)
	GameState.note_opening_bind_battle_started()

	btn_switch.pressed.connect(_on_switch)
	btn_capture.pressed.connect(_on_capture)
	btn_run.pressed.connect(_on_run)
	tutorial_popup_button.pressed.connect(_hide_tutorial_popup)

	_update_ui()
	await _apply_battle_start_passives()
	var intro_message := str(battle_context.get("intro_message", ""))
	if not intro_message.is_empty():
		info.text = intro_message
	if GameState.should_show_battle_abilities_tutorial_popup():
		GameState.mark_battle_abilities_tutorial_popup_shown()
		_show_tutorial_popup(TUTORIAL_ABILITIES_TITLE, TUTORIAL_ABILITIES_BODY)
	set_process(true)


func _apply_world_ui() -> void:
	WorldUI.apply_background(background, "battle")
	WorldUI.apply_label(title_label, "title", "ember")
	WorldUI.apply_label(info, "body", "battle")
	WorldUI.apply_panel($OuterMargin/Root/BattleCard, "stone", true)
	WorldUI.apply_panel($OuterMargin/Root/ActionsCard, "battle", true)
	WorldUI.apply_panel(seal_chooser_panel, "stone", true)
	WorldUI.apply_panel(tutorial_popup, "battle", true)
	WorldUI.apply_label(seal_chooser_title, "title", "crystal")
	WorldUI.apply_label(tutorial_popup_title, "title", "crystal")
	WorldUI.apply_label(tutorial_popup_body, "body", "verdant")
	player_card.apply_variant("wood")
	enemy_card.apply_variant("stone")
	WorldUI.apply_button(btn_switch, "stone")
	WorldUI.apply_button(btn_capture, "ember", true)
	WorldUI.apply_button(btn_run, "battle")
	WorldUI.apply_button(tutorial_popup_button, "verdant", true)


func _update_ui() -> void:
	info.text = _default_battle_prompt()
	_hide_seal_chooser()
	player_card.set_details(
		"%s Lv. %d" % [player_mon["name"], int(player_mon.get("level", 1))],
		"HP %d / %d\nMP %d / %d" % [
			int(player_mon.get("hp", 0)),
			GameState.get_effective_creature_stat(player_mon, "hp_max"),
			int(player_mon.get("mp", 0)),
			GameState.get_effective_creature_stat(player_mon, "mp_max"),
		],
		_get_creature_sprite_path(player_mon)
	)
	enemy_card.set_details(
		"%s Lv. %d" % [wild_mon["name"], int(wild_mon.get("level", 1))],
		"HP %d / %d\nMP %d / %d" % [
			int(wild_mon.get("hp", 0)),
			GameState.get_effective_creature_stat(wild_mon, "hp_max"),
			int(wild_mon.get("mp", 0)),
			GameState.get_effective_creature_stat(wild_mon, "mp_max"),
		],
		_get_creature_sprite_path(wild_mon)
	)
	title_label.text = _battle_title()
	_refresh_capture_ui()
	_rebuild_ability_buttons()


func _refresh_capture_ui() -> void:
	var capture_items := _get_available_capture_items()
	var total_seals := 0
	for item_id in capture_items:
		total_seals += GameState.get_item_count(item_id)
	btn_capture.text = "Bind" if total_seals > 0 else "Bind (No Seals)"
	btn_capture.disabled = capture_items.is_empty()
	if capture_items.is_empty():
		_hide_seal_chooser()


func _rebuild_ability_buttons() -> void:
	for child in abilities_list.get_children():
		child.queue_free()
	if showing_seal_chooser:
		_rebuild_seal_buttons()
		return

	var abilities: Array[String] = GameState.get_creature_abilities(player_mon)
	for ability_id in abilities:
		var ability_data: Dictionary = GameData.get_ability_data(ability_id)
		if ability_data.is_empty():
			continue
		var button: Button = ABILITY_BUTTON_SCENE.instantiate()
		button.text = _format_ability_button_text(ability_id)
		button.tooltip_text = GameData.format_ability_tooltip(ability_id)
		button.disabled = not GameState.can_use_ability(player_mon, ability_id)
		WorldUI.apply_button(button, "wood", true)
		button.pressed.connect(_on_ability_pressed.bind(ability_id))
		abilities_list.add_child(button)


func _rebuild_seal_buttons() -> void:
	highlighted_seal_button = null
	var capture_items := _get_available_capture_items()
	for item_id in capture_items:
		var item_data := GameData.get_item_data(item_id)
		var count := GameState.get_item_count(item_id)
		var button: Button = ABILITY_BUTTON_SCENE.instantiate()
		button.text = "%s x%d" % [str(item_data.get("name", item_id)), count]
		button.tooltip_text = str(item_data.get("description", ""))
		var icon_path := GameData.get_item_icon_path(item_id)
		if not icon_path.is_empty():
			button.icon = load(icon_path)
			button.expand_icon = true
		WorldUI.apply_button(button, str(item_data.get("variant", "ember")), true)
		button.pressed.connect(_use_capture_item.bind(item_id))
		abilities_list.add_child(button)
		if GameState.is_opening_bind_tutorial_active() and item_id == "basic_seal":
			highlighted_seal_button = button
	var cancel_button: Button = ABILITY_BUTTON_SCENE.instantiate()
	cancel_button.text = "Cancel"
	WorldUI.apply_button(cancel_button, "battle")
	cancel_button.pressed.connect(_hide_seal_chooser)
	abilities_list.add_child(cancel_button)


func _format_ability_button_text(ability_id: String) -> String:
	var ability: Dictionary = GameData.get_ability_data(ability_id)
	if ability.is_empty():
		return "Unknown Ability"
	return "%s (%d MP)" % [str(ability.get("name", ability_id)), int(ability.get("mp_cost", 0))]


func _on_ability_pressed(ability_id: String) -> void:
	if tutorial_popup.visible:
		return
	if not GameState.can_use_ability(player_mon, ability_id):
		info.text = "%s does not have enough MP." % str(player_mon.get("name", "Creature"))
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
	for ability_id in GameState.get_creature_abilities(creature):
		if GameState.can_use_ability(creature, ability_id):
			return {"type": "ability", "ability_id": ability_id}
	return {"type": "none"}


func _process_round(player_action: Dictionary, enemy_action: Dictionary) -> bool:
	var skip_player_action := false
	for turn in _get_turn_order(player_action, enemy_action):
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
		var result: Dictionary = _execute_ability(battler, side, target, target_side, ability_id)
		var result_messages: Array = result.get("messages", [])
		await _show_battle_messages(result_messages)
		if bool(result.get("defender_fainted", false)):
			if side == "player":
				await _win_battle()
				return false
			if not await _auto_switch_if_needed():
				return false
			skip_player_action = true
	return true


func _get_turn_order(player_action: Dictionary, enemy_action: Dictionary) -> Array[Dictionary]:
	var order: Array[Dictionary] = []
	if str(player_action.get("type", "")) == "switch":
		order.append({"side": "player", "action": player_action})
		order.append({"side": "enemy", "action": enemy_action})
		return order

	var player_speed: float = _get_effective_stat(player_mon, "player", "spd")
	var enemy_speed: float = _get_effective_stat(wild_mon, "enemy", "spd")
	var player_first := player_speed > enemy_speed or (player_speed == enemy_speed and randf() < 0.5)
	if player_first:
		order.append({"side": "player", "action": player_action})
		order.append({"side": "enemy", "action": enemy_action})
	else:
		order.append({"side": "enemy", "action": enemy_action})
		order.append({"side": "player", "action": player_action})
	return order


func _execute_ability(user: Dictionary, user_side: String, target: Dictionary, target_side: String, ability_id: String) -> Dictionary:
	var ability: Dictionary = GameData.get_ability_data(ability_id)
	var messages: Array[String] = []
	if ability.is_empty():
		messages.append("But nothing happened.")
		return {"messages": messages, "defender_fainted": false}

	var ability_name := str(ability.get("name", ability_id))
	var user_name := str(user.get("name", "Creature"))
	messages.append("%s used %s!" % [user_name, ability_name])
	if not GameState.can_use_ability(user, ability_id):
		messages.append("%s does not have enough MP." % user_name)
		return {"messages": messages, "defender_fainted": false}

	GameState.spend_mp(user, int(ability.get("mp_cost", 0)))
	var hit_chance: float = _get_hit_chance(user, user_side, target, target_side, float(ability.get("accuracy", 100.0)))
	if randf() * 100.0 >= hit_chance:
		messages.append("The ability missed!")
		return {"messages": messages, "defender_fainted": false}

	var damage: int = _calculate_damage(user, user_side, target, target_side, float(ability.get("power", 0.0)))
	var is_crit: bool = randf() * 100.0 < float(_get_effective_stat(user, user_side, "crit"))
	if is_crit:
		damage *= CRIT_MULTIPLIER
		messages.append("Critical hit!")
	target["hp"] = max(0, int(target.get("hp", 0)) - damage)
	messages.append("%s took %d damage!" % [str(target.get("name", "Creature")), damage])
	return {
		"messages": messages,
		"defender_fainted": int(target.get("hp", 0)) <= 0,
	}


func _get_hit_chance(attacker: Dictionary, attacker_side: String, defender: Dictionary, defender_side: String, move_accuracy: float) -> float:
	var attacker_acc: float = _get_effective_stat(attacker, attacker_side, "acc")
	var defender_eva: float = max(1.0, _get_effective_stat(defender, defender_side, "eva"))
	return clampf(move_accuracy * (attacker_acc / defender_eva), MIN_HIT_CHANCE, MAX_HIT_CHANCE)


func _calculate_damage(attacker: Dictionary, attacker_side: String, defender: Dictionary, defender_side: String, move_power: float) -> int:
	var defense: float = max(0.0, _get_effective_stat(defender, defender_side, "def"))
	var reduction: float = defense / (defense + DEFENSE_SCALING)
	var base_damage: float = (move_power + _get_effective_stat(attacker, attacker_side, "atk")) * (1.0 - reduction)
	return max(1, int(round(base_damage)))


func _get_effective_stat(creature: Dictionary, side: String, stat_name: String) -> float:
	var base_value := float(GameState.get_effective_creature_stat(creature, stat_name))
	var bonus_map: Dictionary = battle_bonuses.get(side, {})
	var bonus: float = float(bonus_map.get(stat_name, 0.0))
	return base_value + bonus


func _get_stat_default(stat_name: String) -> int:
	match stat_name:
		"mp_max":
			return GameData.get_default_mp()
		"acc":
			return GameData.get_default_acc()
		"eva":
			return GameData.get_default_eva()
		"crit":
			return GameData.get_default_crit()
		_:
			return 0


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


func _show_battle_messages(lines: Array, delay: float = 0.55) -> void:
	var message_lines: Array[String] = []
	for line in lines:
		message_lines.append(str(line))
		info.text = "\n".join(message_lines)
		await get_tree().create_timer(delay).timeout


func _on_switch() -> void:
	if tutorial_popup.visible:
		return
	_set_actions_locked(true)
	if GameState.party.size() <= 1:
		info.text = "No other creatures to switch to."
		await get_tree().create_timer(0.5).timeout
		_update_ui()
		_set_actions_locked(false)
		return

	var next := _find_next_alive_index(active_index)
	if next == active_index:
		info.text = "No healthy creatures left!"
		await get_tree().create_timer(0.5).timeout
		_update_ui()
		_set_actions_locked(false)
		return

	active_index = next
	player_mon = GameState.party[active_index]
	GameState.ensure_combat_fields(player_mon)
	_mark_participant(active_index)
	info.text = "Go, %s!" % player_mon["name"]
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
	if _get_available_capture_items().is_empty():
		info.text = "No binding seals left. Craft more at camp."
		_refresh_capture_ui()
		return
	if _is_seal_chooser_open():
		_hide_seal_chooser()
	else:
		_show_seal_chooser()


func _use_capture_item(item_id: String) -> void:
	if GameState.get_item_count(item_id) <= 0:
		info.text = "That seal is no longer available."
		_refresh_capture_ui()
		_show_seal_chooser()
		return
	GameState.remove_item(item_id, 1)
	_hide_seal_chooser()
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
	if randf() < chance:
		var went_to_party: bool = GameState.add_creature_to_collection(wild_mon)
		GameState.notify_creature_captured(wild_mon)
		var item_name := str(GameData.get_item_data(item_id).get("name", item_id))
		if went_to_party:
			info.text = "Bound %s! Added to team. 1 %s used." % [wild_mon["name"], item_name]
		else:
			info.text = "Bound %s! Sent to storage. 1 %s used." % [wild_mon["name"], item_name]
		await get_tree().create_timer(0.8).timeout
		_award_drops(true)
		_back_to_overworld()
	else:
		info.text = "Binding failed! 1 %s was used." % str(GameData.get_item_data(item_id).get("name", item_id))
		await get_tree().create_timer(0.4).timeout
		if not await _process_round({"type": "none"}, _choose_enemy_action(wild_mon)):
			return
		_update_ui()
		_set_actions_locked(false)
		if tutorial_result == "forced_fail":
			_show_tutorial_popup(TUTORIAL_BIND_RETRY_TITLE, TUTORIAL_BIND_RETRY_BODY)


func _on_run() -> void:
	if tutorial_popup.visible:
		return
	if bool(battle_context.get("disable_run", false)):
		info.text = "You cannot flee from a boss encounter."
		return
	_back_to_overworld()


func _win_battle() -> void:
	info.text = "You defeated %s!" % wild_mon["name"]
	await get_tree().create_timer(0.8).timeout
	var show_rewards_popup := GameState.should_show_battle_rewards_tutorial_popup()
	if show_rewards_popup:
		GameState.mark_battle_rewards_tutorial_popup_shown()
	GameState.notify_battle_won({
		"is_boss": _is_boss_battle(),
		"map_id": GameState.current_map_id,
	})
	await _award_victory_exp()
	_award_drops(false)
	if show_rewards_popup:
		_show_tutorial_popup(TUTORIAL_BATTLE_REWARDS_TITLE, TUTORIAL_BATTLE_REWARDS_BODY)
		await tutorial_popup_button.pressed
	else:
		await get_tree().create_timer(1.0).timeout
	_back_to_overworld()


func _lose_battle() -> void:
	info.text = "Your %s fainted..." % player_mon["name"]
	await get_tree().create_timer(0.8).timeout
	GameState.forfeit_current_map_run()
	GameState.queue_first_defeat_popup()
	GameState.set_camp_notice("Your whole team fainted. You were carried back to camp and lost all resources gathered on that run.")
	get_tree().change_scene_to_file("res://scenes/Camp.tscn")


func _award_drops(captured: bool) -> void:
	var rewards := GameData.get_battle_reward_roll(GameState.current_map_id, captured, battle_context)
	GameState.award_materials(rewards)
	var node_rewards := GameState.claim_resource_node_reward(battle_context.get("resource_node_reward", {}))
	var total_rewards := GameData.merge_materials(rewards, node_rewards)
	var bonus_bundle: Dictionary = battle_context.get("bonus_reward_bundle", {})
	var bonus_rewards_text := ""
	if not bonus_bundle.is_empty():
		var awarded_bonus := GameState.award_reward_bundle(bonus_bundle)
		bonus_rewards_text = GameData.format_reward_bundle(awarded_bonus)
	if _is_boss_battle():
		GameState.mark_boss_cleared(str(battle_context.get("boss_spawn_id", "")))
		GameState.notify_boss_defeated(GameState.current_map_id)
	var outcome: String = "Boss capture rewards" if captured and _is_boss_battle() else "Boss victory rewards" if _is_boss_battle() else "Capture rewards" if captured else "Victory rewards"
	if captured:
		outcome = "Boss bind rewards" if _is_boss_battle() else "Bind rewards"
	var reward_text := _format_material_rewards(total_rewards)
	if not bonus_rewards_text.is_empty():
		reward_text = "%s | %s" % [reward_text, bonus_rewards_text] if not reward_text.is_empty() else bonus_rewards_text
	info.text = "%s: %s" % [outcome, reward_text]


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
	info.text = "%s fainted! Go, %s!" % [fainted_name, player_mon["name"]]
	await get_tree().create_timer(0.8).timeout
	return true


func _mark_participant(party_index: int) -> void:
	if party_index < 0 or party_index >= GameState.party.size():
		return
	participant_indices[party_index] = true


func _award_victory_exp() -> void:
	var total_exp_reward := GameData.get_exp_reward_for_creature(wild_mon)
	total_exp_reward = int(round(float(total_exp_reward) * float(battle_context.get("exp_multiplier", 1.0))))
	if total_exp_reward <= 0:
		return
	var participant_list := _get_participant_indices()
	if participant_list.is_empty():
		return
	var exp_reward: int = max(1, int(floor(float(total_exp_reward) / float(participant_list.size()))))
	for party_index in participant_list:
		var creature: Dictionary = GameState.party[party_index]
		var result: Dictionary = GameState.add_exp_to_creature(creature, exp_reward)
		info.text = "%s gained %d EXP." % [creature["name"], int(result.get("exp_gained", 0))]
		if party_index == active_index:
			player_mon = creature
			_update_ui()
			info.text = "%s gained %d EXP." % [creature["name"], int(result.get("exp_gained", 0))]
		await get_tree().create_timer(0.8).timeout
		if int(result.get("levels_gained", 0)) > 0:
			info.text = "%s grew to Lv. %d!" % [creature["name"], int(result.get("new_level", creature.get("level", 1)))]
			if party_index == active_index:
				player_mon = creature
				_update_ui()
				info.text = "%s grew to Lv. %d!" % [creature["name"], int(result.get("new_level", creature.get("level", 1)))]
			await get_tree().create_timer(0.9).timeout


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


func _is_boss_battle() -> bool:
	return str(battle_context.get("reward_profile", "")) == "boss"


func _is_resource_node_battle() -> bool:
	return str(battle_context.get("encounter_source", "")) == "resource_node"


func _is_poi_battle() -> bool:
	return str(battle_context.get("encounter_source", "")) == "poi"


func _battle_title() -> String:
	if _is_boss_battle():
		return "Boss Encounter"
	if _is_resource_node_battle():
		return "Node Encounter"
	if _is_poi_battle():
		return "Point of Interest"
	return "Wild Encounter"


func _default_battle_prompt() -> String:
	if _is_resource_node_battle():
		return "A disturbed creature attacks!"
	if _is_poi_battle():
		return "A point of interest turns dangerous."
	return "Choose an ability."


func _get_available_capture_items() -> Array[String]:
	var available: Array[String] = []
	for item_id in GameData.get_item_ids_by_category(GameData.ITEM_CATEGORY_CONSUMABLE):
		var item_data := GameData.get_item_data(item_id)
		if not item_data.get("use_contexts", []).has("battle_capture"):
			continue
		if GameState.get_item_count(item_id) > 0:
			available.append(item_id)
	return available


func _show_seal_chooser() -> void:
	var capture_items := _get_available_capture_items()
	if capture_items.is_empty():
		info.text = "No binding seals left. Craft more at camp."
		_hide_seal_chooser()
		return
	showing_seal_chooser = true
	_rebuild_ability_buttons()
	info.text = "Choose a binding seal."


func _hide_seal_chooser() -> void:
	showing_seal_chooser = false
	highlighted_seal_button = null
	_rebuild_ability_buttons()


func _is_seal_chooser_open() -> bool:
	return showing_seal_chooser


func _set_actions_locked(locked: bool) -> void:
	btn_switch.disabled = locked
	btn_run.disabled = locked or bool(battle_context.get("disable_run", false))
	if locked:
		btn_capture.disabled = true
		for child in abilities_list.get_children():
			if child is Button:
				(child as Button).disabled = true


func _show_tutorial_popup(title: String, body: String) -> void:
	tutorial_popup_title.text = title
	tutorial_popup_body.text = body
	tutorial_popup.visible = true


func _hide_tutorial_popup() -> void:
	tutorial_popup.visible = false


func _should_highlight_bind_tutorial() -> bool:
	return GameState.is_opening_bind_tutorial_active() and not _is_seal_chooser_open() and not tutorial_popup.visible


func _should_highlight_ability_tutorial() -> bool:
	return GameState.is_battle_abilities_tutorial_active() and not _is_seal_chooser_open() and not tutorial_popup.visible


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
			if child is Button:
				var ability_button: Button = child
				_set_objective_highlight(ability_button, true, pulse)
	else:
		for child in abilities_list.get_children():
			if child is Button:
				var idle_button: Button = child
				if idle_button != highlighted_seal_button:
					_set_objective_highlight(idle_button, false)
	if highlighted_seal_button != null and is_instance_valid(highlighted_seal_button):
		_set_objective_highlight(highlighted_seal_button, true, pulse)


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


func _format_material_rewards(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return "no drops"
	var parts: Array[String] = []
	for material in rewards.keys():
		parts.append("+%d %s" % [int(rewards.get(material, 0)), _pretty_material_name(str(material))])
	parts.sort()
	return ", ".join(parts)


func _pretty_material_name(material_type: String) -> String:
	match material_type:
		"core_shard":
			return "Core Shards"
		"species_mat":
			return "Species Mat"
		_:
			return material_type.capitalize()


func _get_creature_sprite_path(creature: Dictionary) -> String:
	var override_path := str(creature.get("sprite_path_override", ""))
	if not override_path.is_empty():
		return override_path
	return str(GameData.creatures[creature["id"]].get("sprite_path", ""))

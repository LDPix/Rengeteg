extends Control

@onready var info := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/BattleLog
@onready var btn_attack := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/AttackButton
@onready var btn_switch := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/SwitchButton
@onready var btn_capture := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/CaptureButton
@onready var btn_run := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/RunButton
@onready var hud_area_label := $OuterMargin/Root/TopBar/StatusRow/BattleAreaLabel
@onready var hud_status_label := $OuterMargin/Root/TopBar/StatusRow/BattleStatusLabel
@onready var hud_seal_label := $OuterMargin/Root/TopBar/StatusRow/SealCountLabel
@onready var player_card := $OuterMargin/Root/BattleCard/Padding/CreaturesRow/PlayerCard
@onready var enemy_card := $OuterMargin/Root/BattleCard/Padding/CreaturesRow/EnemyCard

var player_mon: Dictionary
var wild_mon: Dictionary

var active_index := 0

func _ready() -> void:
	active_index = _find_first_alive_index()
	if active_index == -1:
		_back_to_overworld()
		return
	player_mon = GameState.party[active_index]
	wild_mon = GameState.new_creature_instance(GameState.pending_wild_id)
	_update_ui()

	btn_attack.pressed.connect(_on_attack)
	btn_switch.pressed.connect(_on_switch)
	btn_capture.pressed.connect(_on_capture)
	btn_run.pressed.connect(_on_run)

func _update_ui() -> void:
	info.text = "Choose an action."
	player_card.set_details(
		"%s" % player_mon["name"],
		"HP %d / %d" % [player_mon["hp"], player_mon["hp_max"]],
		str(GameData.creatures[player_mon["id"]].get("sprite_path", ""))
	)
	enemy_card.set_details(
		"%s" % wild_mon["name"],
		"HP %d / %d" % [wild_mon["hp"], wild_mon["hp_max"]],
		str(GameData.creatures[wild_mon["id"]].get("sprite_path", ""))
	)
	var map_id := GameState.current_map_id
	var display_name = str(GameData.maps[map_id].get("display_name", map_id))
	hud_area_label.text = display_name
	hud_status_label.text = "%s vs %s" % [player_mon["name"], wild_mon["name"]]
	_refresh_capture_ui()


func _refresh_capture_ui() -> void:
	hud_seal_label.text = "Seals: %d" % GameState.seals
	btn_capture.text = "Capture (No Seals)" if GameState.seals <= 0 else "Capture (%d)" % GameState.seals
	btn_capture.disabled = false

func _damage(attacker: Dictionary, defender: Dictionary) -> int:
	# Simple MVP formula
	var raw = attacker["atk"] - int(defender["def"] * 0.5)
	return max(1, raw)

func _on_attack() -> void:
	# Player hits
	wild_mon["hp"] -= _damage(player_mon, wild_mon)
	if wild_mon["hp"] <= 0:
		_win_battle()
		return

	# Wild hits back
	player_mon["hp"] -= _damage(wild_mon, player_mon)
	if not await _auto_switch_if_needed():
		return

	_update_ui()
	
func _on_switch() -> void:
	if GameState.party.size() <= 1:
		info.text = "No other creatures to switch to."
		await get_tree().create_timer(0.5).timeout
		_update_ui()
		return

	var next := _find_next_alive_index(active_index)
	if next == active_index:
		info.text = "No healthy creatures left!"
		await get_tree().create_timer(0.5).timeout
		_update_ui()
		return

	active_index = next
	player_mon = GameState.party[active_index]
	info.text = "Go, %s!" % player_mon["name"]
	await get_tree().create_timer(0.5).timeout

	# Switching uses your turn: wild attacks once
	player_mon["hp"] -= _damage(wild_mon, player_mon)
	if not await _auto_switch_if_needed():
		return

	_update_ui()

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
	if GameState.seals <= 0:
		info.text = "No Seals left. Craft more at camp."
		_refresh_capture_ui()
		return

	GameState.seals -= 1
	_refresh_capture_ui()

	# Capture chance increases as HP lowers
	var hp_ratio = float(wild_mon["hp"]) / float(wild_mon["hp_max"])
	var chance = clamp(0.25 + (0.60 * (1.0 - hp_ratio)), 0.25, 0.85)

	if randf() < chance:
		var went_to_party := GameState.add_creature_to_collection(wild_mon)
		if went_to_party:
			info.text = "Captured %s! Added to team. 1 Seal used." % wild_mon["name"]
		else:
			info.text = "Captured %s! Sent to storage. 1 Seal used." % wild_mon["name"]
		await get_tree().create_timer(0.8).timeout
		_award_drops(true)
		_back_to_overworld()
	else:
		info.text = "Capture failed! 1 Seal was used."
		await get_tree().create_timer(0.4).timeout
		# Wild gets a free hit on fail
		player_mon["hp"] -= _damage(wild_mon, player_mon)
		if not await _auto_switch_if_needed():
			return
		_update_ui()

func _on_run() -> void:
	_back_to_overworld()

func _win_battle() -> void:
	info.text = "You defeated %s!" % wild_mon["name"]
	await get_tree().create_timer(0.8).timeout
	_award_drops(false)
	_back_to_overworld()

func _lose_battle() -> void:
	info.text = "Your %s fainted..." % player_mon["name"]
	await get_tree().create_timer(0.8).timeout
	GameState.forfeit_current_map_run()
	GameState.set_camp_notice("Your whole team fainted. You were carried back to camp and lost all resources gathered on that run.")
	get_tree().change_scene_to_file("res://scenes/Camp.tscn")

func _award_drops(captured: bool) -> void:
	var core_shards: int = randi_range(1, 2)
	var species_material: int = randi_range(1, 2)
	var extra_material_amount: int = randi_range(1, 2)
	var extra_material_type: String = _pick_map_reward_material()

	if not captured:
		extra_material_amount += 1

	GameState.materials["core_shard"] += core_shards
	GameState.materials["species_mat"] += species_material
	GameState.materials[extra_material_type] = GameState.materials.get(extra_material_type, 0) + extra_material_amount

	var outcome: String = "Capture rewards" if captured else "Victory rewards"
	info.text = "%s: +%d Core, +%d Species, +%d %s" % [
		outcome,
		core_shards,
		species_material,
		extra_material_amount,
		_pretty_material_name(extra_material_type),
	]
		
func _auto_switch_if_needed() -> bool:
	if player_mon["hp"] > 0:
		return true

	var fainted_name := str(player_mon["name"])
	player_mon["hp"] = 0

	var next := _find_next_alive_index(active_index)
	if next == active_index:
		_lose_battle()
		return false

	active_index = next
	player_mon = GameState.party[active_index]
	info.text = "%s fainted! Go, %s!" % [fainted_name, player_mon["name"]]
	await get_tree().create_timer(0.8).timeout
	return true


func _back_to_overworld() -> void:
	var map_id := GameState.current_map_id
	var scene_path := GameState.battle_return_scene_path
	if scene_path.is_empty():
		scene_path = str(GameData.maps[map_id].get("scene_path", "res://scenes/overworld/Overworld_Verdant.tscn"))
	get_tree().change_scene_to_file(scene_path)


func _pick_map_reward_material() -> String:
	match GameState.current_map_id:
		"verdant_wilds":
			return "wood" if randf() < 0.5 else "herb"
		"ember_caves":
			return "stone" if randf() < 0.5 else "crystal"
		_:
			return "wood"


func _pretty_material_name(material_type: String) -> String:
	match material_type:
		"core_shard":
			return "Core Shards"
		"species_mat":
			return "Species Mat"
		"crystal":
			return "Crystal"
		_:
			return material_type.capitalize()

extends Control

@onready var info := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/BattleLog
@onready var btn_attack := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/AttackButton
@onready var btn_switch := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/SwitchButton
@onready var btn_capture := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/CaptureButton
@onready var btn_run := $OuterMargin/Root/ActionsCard/ActionsPadding/ActionsVBox/ButtonsRow/RunButton
@onready var hud_area_label := $OuterMargin/Root/TopBar/StatusRow/BattleAreaLabel
@onready var hud_status_label := $OuterMargin/Root/TopBar/StatusRow/BattleStatusLabel
@onready var player_card := $OuterMargin/Root/BattleCard/Padding/CreaturesRow/PlayerCard
@onready var enemy_card := $OuterMargin/Root/BattleCard/Padding/CreaturesRow/EnemyCard

var player_mon: Dictionary
var wild_mon: Dictionary

var active_index := 0

func _ready() -> void:
	active_index = 0
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
		"HP %d / %d" % [player_mon["hp"], player_mon["hp_max"]]
	)
	enemy_card.set_details(
		"%s" % wild_mon["name"],
		"HP %d / %d" % [wild_mon["hp"], wild_mon["hp_max"]]
	)
	var map_id := GameState.current_map_id
	var display_name = str(GameData.maps[map_id].get("display_name", map_id))
	hud_area_label.text = display_name
	hud_status_label.text = "%s vs %s" % [player_mon["name"], wild_mon["name"]]

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
	
func _on_capture() -> void:
	# Capture chance increases as HP lowers
	var hp_ratio = float(wild_mon["hp"]) / float(wild_mon["hp_max"])
	var chance = clamp(0.25 + (0.60 * (1.0 - hp_ratio)), 0.25, 0.85)

	if randf() < chance:
		var went_to_party := GameState.add_creature_to_collection(wild_mon)
		if went_to_party:
			info.text = "Captured %s! Added to team." % wild_mon["name"]
		else:
			info.text = "Captured %s! Sent to storage." % wild_mon["name"]
		await get_tree().create_timer(0.8).timeout
		_award_drops(true)
		_back_to_overworld()
	else:
		info.text = "Capture failed!"
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
	# MVP penalty: lose 50% materials
	for k in GameState.materials.keys():
		GameState.materials[k] = int(GameState.materials[k] * 0.5)
	# heal for now so loop continues
	for m in GameState.party:
		m["hp"] = m["hp_max"]
	_back_to_overworld()

func _award_drops(captured: bool) -> void:
	# MVP: always give a little
	GameState.materials["core_shard"] += 1
	GameState.materials["species_mat"] += 1
	# Small bonus if you defeat instead of capture (tunable)
	if not captured:
		GameState.materials["stone"] += 1
		
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
	var scene_path = str(GameData.maps[map_id].get("scene_path", "res://scenes/overworld/Overworld.tscn"))
	get_tree().change_scene_to_file(scene_path)

extends Control

const CREATURE_CHIP_SCENE := preload("res://scenes/ui/CreatureChip.tscn")
const MAP_OPTION_BUTTON_SCENE := preload("res://scenes/ui/MapOptionButton.tscn")

@onready var creature_chips := $Panel/CenterRow/VBoxContainer/TeamCard/Padding/Content/CreatureChips
@onready var party_label := $Panel/CenterRow/VBoxContainer/TeamCard/Padding/Content/PartyLabel
@onready var mats_label := $Panel/CenterRow/VBoxContainer/UpgradesCard/Padding/Content/MatsLabel
@onready var hp_btn := $Panel/CenterRow/VBoxContainer/UpgradesCard/Padding/Content/UpgradeButtons/HpButton
@onready var atk_btn := $Panel/CenterRow/VBoxContainer/UpgradesCard/Padding/Content/UpgradeButtons/AtkButton
@onready var def_btn := $Panel/CenterRow/VBoxContainer/UpgradesCard/Padding/Content/UpgradeButtons/DefButton
@onready var map_label := $Panel/CenterRow/VBoxContainer/MapCard/Padding/Content/MapLabel
@onready var map_list := $Panel/CenterRow/VBoxContainer/MapCard/Padding/Content/MapList
@onready var venture_btn := $Panel/CenterRow/VBoxContainer/PrimaryAction/VentureButton

func _ready() -> void:
	hp_btn.pressed.connect(_upgrade_hp)
	atk_btn.pressed.connect(_upgrade_atk)
	def_btn.pressed.connect(_upgrade_def)
	venture_btn.pressed.connect(_venture)
	hp_btn.text = "+HP (6 Core, 5 Herb)"
	atk_btn.text = "+ATK (6 Core, 5 Wood)"
	def_btn.text = "+DEF (6 Core, 5 Stone)"
	hp_btn.tooltip_text = "Upgrade HP: 6 Core Shards, 5 Herb"
	atk_btn.tooltip_text = "Upgrade ATK: 6 Core Shards, 5 Wood"
	def_btn.tooltip_text = "Upgrade DEF: 6 Core Shards, 5 Stone"
	GameState.ensure_starter()
	_build_map_buttons()
	_refresh()
	
func _build_map_buttons() -> void:
	for child in map_list.get_children():
		child.queue_free()

	for map_id in GameData.maps.keys():
		var display_name = str(GameData.maps[map_id].get("display_name", map_id))
		var btn := MAP_OPTION_BUTTON_SCENE.instantiate()
		btn.name = "%sButton" % map_id.capitalize()
		btn.text = display_name
		btn.pressed.connect(_select_map.bind(map_id))
		map_list.add_child(btn)

func _select_map(map_id: String) -> void:
	GameState.current_map_id = map_id
	_refresh()
	
func _venture() -> void:
	var map_id := GameState.current_map_id
	var scene_path = str(GameData.maps[map_id].get("scene_path", ""))

	if scene_path == "":
		get_tree().change_scene_to_file("res://scenes/overworld/Overworld_Verdant.tscn")
		return

	get_tree().change_scene_to_file(scene_path)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camp") or event.is_action_pressed("ui_cancel"):
		_close()
		
func _party_text() -> String:
	if GameState.party.is_empty():
		return "No active creature."
	var first: Dictionary = GameState.party[0]
	return "%d creature%s ready. Lead: %s" % [
		GameState.party.size(),
		"" if GameState.party.size() == 1 else "s",
		first["name"],
	]

func _refresh() -> void:
	if GameState.party.is_empty():
		_rebuild_party_chips()
		party_label.text = "No active creature."
		party_label.visible = true
		venture_btn.disabled = true
		return

	_rebuild_party_chips()
	party_label.text = _party_text()
	party_label.visible = false
	venture_btn.disabled = false

	var m := GameState.materials
	mats_label.text = "Core %d   Herb %d   Wood %d   Stone %d   Crystal %d   Species %d" % [
		m["core_shard"], m["herb"], m["wood"], m["stone"], m["crystal"], m["species_mat"]
	]

	var map_id := GameState.current_map_id
	var display_name = str(GameData.maps[map_id].get("display_name", map_id))
	map_label.text = "Selected map: %s" % display_name
	for child in map_list.get_children():
		if child.has_method("set_selected"):
			child.set_selected(child.text == display_name)

func _has(cost: Dictionary) -> bool:
	for k in cost.keys():
		if GameState.materials.get(k, 0) < int(cost[k]):
			return false
	return true

func _pay(cost: Dictionary) -> void:
	for k in cost.keys():
		GameState.materials[k] -= int(cost[k])

func _upgrade_hp() -> void:
	var cost = {"core_shard": 6, "herb": 5}
	if not _has(cost):
		mats_label.text = "%s   Not enough materials for +HP." % mats_label.text
		return
	_pay(cost)
	var mon = GameState.party[0]
	mon["hp_max"] += 5
	mon["hp"] = mon["hp_max"] # heal on upgrade (nice for MVP)
	_refresh()

func _upgrade_atk() -> void:
	var cost = {"core_shard": 6, "wood": 5}
	if not _has(cost):
		mats_label.text = "%s   Not enough materials for +ATK." % mats_label.text
		return
	_pay(cost)
	var mon = GameState.party[0]
	mon["atk"] += 1
	_refresh()

func _upgrade_def() -> void:
	var cost = {"core_shard": 6, "stone": 5}
	if not _has(cost):
		mats_label.text = "%s   Not enough materials for +DEF." % mats_label.text
		return
	_pay(cost)
	var mon = GameState.party[0]
	mon["def"] += 1
	_refresh()

func _close() -> void:
	queue_free()


func _rebuild_party_chips() -> void:
	for child in creature_chips.get_children():
		child.queue_free()

	for mon in GameState.party:
		var chip = CREATURE_CHIP_SCENE.instantiate()
		creature_chips.add_child(chip)
		chip.configure(str(mon["name"]), _palette_for_element(str(mon.get("element", ""))))


func _palette_for_element(element: String) -> String:
	match element:
		"grass":
			return "grass"
		"fire":
			return "fire"
		_:
			return "neutral"

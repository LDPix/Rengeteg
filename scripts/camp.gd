extends Control

@onready var party_label := $Panel/VBoxContainer/PartyLabel
@onready var mats_label := $Panel/VBoxContainer/MatsLabel
@onready var hp_btn := $Panel/VBoxContainer/HpButton
@onready var atk_btn := $Panel/VBoxContainer/AtkButton
@onready var def_btn := $Panel/VBoxContainer/DefButton
@onready var back_btn := $Panel/VBoxContainer/BackButton
@onready var map_label := $Panel/VBoxContainer/MapLabel
@onready var map_list := $Panel/VBoxContainer/MapList
@onready var venture_btn := $Panel/VBoxContainer/VentureButton
@onready var top_area_label := $TopBar/AreaLabel
@onready var top_resource_label := $TopBar/ResourceSummary

func _ready() -> void:
	hp_btn.pressed.connect(_upgrade_hp)
	atk_btn.pressed.connect(_upgrade_atk)
	def_btn.pressed.connect(_upgrade_def)
	back_btn.pressed.connect(_close)
	venture_btn.pressed.connect(_venture)
	_build_map_buttons()
	_refresh()
	GameState.ensure_starter()
	
func _build_map_buttons() -> void:
	# Clear old buttons (if any)
	for child in map_list.get_children():
		child.queue_free()

	# Create one button per map in GameData.maps
	for map_id in GameData.maps.keys():
		var display_name = str(GameData.maps[map_id].get("display_name", map_id))

		var btn := Button.new()
		btn.text = display_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _select_map(map_id))
		map_list.add_child(btn)

func _select_map(map_id: String) -> void:
	GameState.current_map_id = map_id
	_refresh()
	
func _venture() -> void:
	var map_id := GameState.current_map_id
	var scene_path = str(GameData.maps[map_id].get("scene_path", ""))

	if scene_path == "":
		# fallback: if you haven't made separate scenes yet
		get_tree().change_scene_to_file("res://scenes/overworld/Overworld.tscn")
		return

	get_tree().change_scene_to_file(scene_path)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camp") or event.is_action_pressed("ui_cancel"):
		_close()
		
func _party_text() -> String:
	if GameState.party.is_empty():
		return "Team: (empty)"
	var lines: Array[String] = []
	lines.append("Team:")
	for i in range(GameState.party.size()):
		var mon: Dictionary = GameState.party[i]
		lines.append("%d) %s  HP %d/%d  ATK %d  DEF %d" % [
			i + 1, mon["name"], mon["hp"], mon["hp_max"], mon["atk"], mon["def"]
		])
	return "\n".join(lines)
	
func _refresh() -> void:
	if GameState.party.is_empty():
		party_label.text = "No active creature."
		return
	var first = GameState.party[0]
	party_label.text = _party_text()

	var m := GameState.materials
	mats_label.text = "Materials: Core %d | Herb %d | Wood %d | Stone %d | Species %d" % [
		m["core_shard"], m["herb"], m["wood"], m["stone"], m["species_mat"]
	]
	top_resource_label.text = "Core %d • Herb %d • Wood %d • Stone %d" % [
		m["core_shard"], m["herb"], m["wood"], m["stone"]
	]

	var map_id := GameState.current_map_id
	var display_name = str(GameData.maps[map_id].get("display_name", map_id))
	map_label.text = "Map (Selected: %s)" % display_name
	top_area_label.text = display_name

func _has(cost: Dictionary) -> bool:
	for k in cost.keys():
		if GameState.materials.get(k, 0) < int(cost[k]):
			return false
	return true

func _pay(cost: Dictionary) -> void:
	for k in cost.keys():
		GameState.materials[k] -= int(cost[k])

func _upgrade_hp() -> void:
	var cost = {"core_shard": 3, "herb": 2}
	if not _has(cost):
		mats_label.text += "\nNot enough materials."
		return
	_pay(cost)
	var mon = GameState.party[0]
	mon["hp_max"] += 5
	mon["hp"] = mon["hp_max"] # heal on upgrade (nice for MVP)
	_refresh()

func _upgrade_atk() -> void:
	var cost = {"core_shard": 3, "wood": 2}
	if not _has(cost):
		mats_label.text += "\nNot enough materials."
		return
	_pay(cost)
	var mon = GameState.party[0]
	mon["atk"] += 1
	_refresh()

func _upgrade_def() -> void:
	var cost = {"core_shard": 3, "stone": 2}
	if not _has(cost):
		mats_label.text += "\nNot enough materials."
		return
	_pay(cost)
	var mon = GameState.party[0]
	mon["def"] += 1
	_refresh()

func _close() -> void:
	queue_free()

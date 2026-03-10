extends Control

const CREATURE_CHIP_SCENE := preload("res://scenes/ui/CreatureChip.tscn")
const MAP_OPTION_BUTTON_SCENE := preload("res://scenes/ui/MapOptionButton.tscn")
const HP_UPGRADE_COST := {"core_shard": 6, "herb": 5}
const ATK_UPGRADE_COST := {"core_shard": 6, "wood": 5}
const DEF_UPGRADE_COST := {"core_shard": 6, "stone": 5}
const SEAL_CRAFT_COST := {"core_shard": 2, "crystal": 1}

enum CampView {
	MAIN,
	COLLECTION,
	MAPS,
	CRAFTING,
	UPGRADES,
}

@onready var main_camp_panel := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel
@onready var creature_collection_panel := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel
@onready var maps_panel := $Panel/CenterRow/ContentColumn/Panels/MapsPanel
@onready var crafting_panel := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel
@onready var upgrades_panel := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel

@onready var main_team_chips := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/CreatureChips
@onready var main_party_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/PartyLabel
@onready var main_map_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/MapSummaryCard/Padding/Content/MapLabel
@onready var main_resources_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/ResourcesCard/Padding/Content/ResourcesLabel
@onready var main_status_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/MainStatusLabel
@onready var collection_nav_button := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationButtons/CollectionButton
@onready var maps_nav_button := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationButtons/MapsButton
@onready var crafting_nav_button := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationButtons/CraftingButton
@onready var upgrades_nav_button := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationButtons/UpgradesButton
@onready var venture_btn := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/ActionRow/VentureButton

@onready var collection_back_button := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/Header/BackButton
@onready var collection_team_chips := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/CreatureChips
@onready var collection_party_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/PartyLabel
@onready var collection_selected_name_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureName
@onready var collection_selected_stats_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureStats
@onready var collection_selected_portrait := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureRow/SelectedCreaturePortrait
@onready var collection_summary_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/CollectionCard/Padding/Content/CollectionSummaryLabel

@onready var maps_back_button := $Panel/CenterRow/ContentColumn/Panels/MapsPanel/Header/BackButton
@onready var maps_selected_label := $Panel/CenterRow/ContentColumn/Panels/MapsPanel/MapSelectionCard/Padding/Content/MapLabel
@onready var map_list := $Panel/CenterRow/ContentColumn/Panels/MapsPanel/MapSelectionCard/Padding/Content/MapList

@onready var crafting_back_button := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/Header/BackButton
@onready var crafting_mats_label := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/MatsLabel
@onready var crafting_status_label := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/CraftingStatusLabel
@onready var seal_btn := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/SealButton

@onready var upgrades_back_button := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/Header/BackButton
@onready var upgrades_team_chips := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/CreatureChips
@onready var upgrades_party_label := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/PartyLabel
@onready var upgrades_selected_name_label := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureName
@onready var upgrades_selected_stats_label := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureStats
@onready var upgrades_selected_portrait := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureRow/SelectedCreaturePortrait
@onready var upgrades_mats_label := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/MatsLabel
@onready var upgrade_status_label := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/UpgradeStatusLabel
@onready var hp_btn := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/UpgradeButtons/HpButton
@onready var atk_btn := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/UpgradeButtons/AtkButton
@onready var def_btn := $Panel/CenterRow/ContentColumn/Panels/UpgradesPanel/UpgradeCard/Padding/Content/UpgradeButtons/DefButton

var current_view: int = CampView.MAIN
var selected_creature_index := -1


func _ready() -> void:
	collection_nav_button.pressed.connect(show_creature_collection_menu)
	maps_nav_button.pressed.connect(show_maps_menu)
	crafting_nav_button.pressed.connect(show_crafting_menu)
	upgrades_nav_button.pressed.connect(show_upgrades_menu)
	collection_back_button.pressed.connect(show_main_camp)
	maps_back_button.pressed.connect(show_main_camp)
	crafting_back_button.pressed.connect(show_main_camp)
	upgrades_back_button.pressed.connect(show_main_camp)
	hp_btn.pressed.connect(_upgrade_hp)
	atk_btn.pressed.connect(_upgrade_atk)
	def_btn.pressed.connect(_upgrade_def)
	seal_btn.pressed.connect(_craft_seal)
	venture_btn.pressed.connect(_venture)

	hp_btn.text = "+HP (6 Core, 5 Herb)"
	atk_btn.text = "+ATK (6 Core, 5 Wood)"
	def_btn.text = "+DEF (6 Core, 5 Stone)"
	seal_btn.text = "+1 Seal (2 Core, 1 Crystal)"
	hp_btn.tooltip_text = "Upgrade HP: 6 Core Shards, 5 Herb"
	atk_btn.tooltip_text = "Upgrade ATK: 6 Core Shards, 5 Wood"
	def_btn.tooltip_text = "Upgrade DEF: 6 Core Shards, 5 Stone"
	seal_btn.tooltip_text = "Craft Seal: 2 Core Shards, 1 Crystal"

	GameState.ensure_starter()
	_build_map_buttons()
	_heal_team_on_entry()
	show_main_camp()
	_refresh()


func show_main_camp() -> void:
	_set_view(CampView.MAIN)


func show_creature_collection_menu() -> void:
	_set_view(CampView.COLLECTION)


func show_maps_menu() -> void:
	_set_view(CampView.MAPS)


func show_crafting_menu() -> void:
	_set_view(CampView.CRAFTING)


func show_upgrades_menu() -> void:
	_set_view(CampView.UPGRADES)


func _set_view(view: int) -> void:
	current_view = view
	main_camp_panel.visible = view == CampView.MAIN
	creature_collection_panel.visible = view == CampView.COLLECTION
	maps_panel.visible = view == CampView.MAPS
	crafting_panel.visible = view == CampView.CRAFTING
	upgrades_panel.visible = view == CampView.UPGRADES


func _build_map_buttons() -> void:
	for child in map_list.get_children():
		child.queue_free()

	for map_id in GameData.maps.keys():
		var display_name := str(GameData.maps[map_id].get("display_name", map_id))
		var btn := MAP_OPTION_BUTTON_SCENE.instantiate()
		btn.name = "%sButton" % map_id.capitalize()
		btn.text = display_name
		btn.pressed.connect(_select_map.bind(map_id))
		map_list.add_child(btn)


func _select_map(map_id: String) -> void:
	GameState.current_map_id = map_id
	main_status_label.text = "Selected %s for the next venture." % _selected_map_display_name()
	_refresh()


func _venture() -> void:
	var map_id := GameState.current_map_id
	var scene_path := str(GameData.maps[map_id].get("scene_path", ""))
	GameState.begin_map_run()

	if scene_path == "":
		get_tree().change_scene_to_file("res://scenes/overworld/Overworld_Verdant.tscn")
		return

	get_tree().change_scene_to_file(scene_path)


func _heal_team_on_entry() -> void:
	if GameState.party.is_empty():
		main_status_label.text = "No creatures available in camp."
		return

	for mon in GameState.party:
		mon["hp"] = int(mon.get("hp_max", 0))

	var notice := GameState.consume_camp_notice()
	if not notice.is_empty():
		main_status_label.text = notice
	else:
		main_status_label.text = "Your team rests and heals automatically at camp."


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camp") or event.is_action_pressed("ui_cancel"):
		if current_view == CampView.MAIN:
			_close()
		else:
			show_main_camp()


func _party_text() -> String:
	if GameState.party.is_empty():
		return "No creatures available."
	var first: Dictionary = GameState.party[0]
	return "%d creature%s ready. Lead: %s" % [
		GameState.party.size(),
		"" if GameState.party.size() == 1 else "s",
		first["name"],
	]


func _refresh() -> void:
	_normalize_selected_creature_index()
	refresh_main_camp_summary()
	_refresh_collection_menu()
	_refresh_maps_menu()
	_refresh_crafting_menu()
	_refresh_upgrades_menu()
	venture_btn.disabled = GameState.party.is_empty()


func refresh_main_camp_summary() -> void:
	refresh_team_summary()
	refresh_map_summary()
	refresh_resources_summary()


func refresh_team_summary() -> void:
	_rebuild_party_chips(main_team_chips)
	main_party_label.text = _party_text()
	main_party_label.visible = GameState.party.is_empty()


func refresh_map_summary() -> void:
	main_map_label.text = _selected_map_summary_text()


func refresh_resources_summary() -> void:
	main_resources_label.text = _materials_summary_text()


func _refresh_collection_menu() -> void:
	_rebuild_party_chips(collection_team_chips)
	collection_party_label.text = _party_text()
	collection_party_label.visible = GameState.party.is_empty()
	_refresh_selected_creature_card(
		collection_selected_name_label,
		collection_selected_stats_label,
		collection_selected_portrait,
		"Capture a creature to unlock camp upgrades."
	)
	collection_summary_label.text = _collection_summary_text()


func _refresh_maps_menu() -> void:
	maps_selected_label.text = "Selected map: %s" % _selected_map_display_name()
	for child in map_list.get_children():
		if child.has_method("set_selected"):
			child.set_selected(child.text == _selected_map_display_name())


func _refresh_crafting_menu() -> void:
	crafting_mats_label.text = _materials_summary_text()
	if crafting_status_label.text.is_empty():
		crafting_status_label.text = "Craft a Seal with 2 Core Shards and 1 Crystal."
	seal_btn.disabled = false


func _refresh_upgrades_menu() -> void:
	_rebuild_party_chips(upgrades_team_chips)
	upgrades_party_label.text = _party_text()
	upgrades_party_label.visible = GameState.party.is_empty()
	_refresh_selected_creature_card(
		upgrades_selected_name_label,
		upgrades_selected_stats_label,
		upgrades_selected_portrait,
		"Capture a creature to unlock camp upgrades."
	)
	upgrades_mats_label.text = _materials_summary_text()
	_refresh_upgrade_buttons()


func _has(cost: Dictionary) -> bool:
	for key in cost.keys():
		if GameState.materials.get(key, 0) < int(cost[key]):
			return false
	return true


func _pay(cost: Dictionary) -> void:
	for key in cost.keys():
		GameState.materials[key] -= int(cost[key])


func _upgrade_hp() -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		upgrade_status_label.text = "Select a creature to upgrade."
		return
	if not _has(HP_UPGRADE_COST):
		upgrade_status_label.text = "Not enough materials for +HP."
		return
	_pay(HP_UPGRADE_COST)
	mon["hp_max"] += 5
	mon["hp"] = mon["hp_max"]
	upgrade_status_label.text = "%s gained +5 Max HP." % str(mon.get("name", "Creature"))
	_refresh()


func _upgrade_atk() -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		upgrade_status_label.text = "Select a creature to upgrade."
		return
	if not _has(ATK_UPGRADE_COST):
		upgrade_status_label.text = "Not enough materials for +ATK."
		return
	_pay(ATK_UPGRADE_COST)
	mon["atk"] += 1
	upgrade_status_label.text = "%s gained +1 ATK." % str(mon.get("name", "Creature"))
	_refresh()


func _upgrade_def() -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		upgrade_status_label.text = "Select a creature to upgrade."
		return
	if not _has(DEF_UPGRADE_COST):
		upgrade_status_label.text = "Not enough materials for +DEF."
		return
	_pay(DEF_UPGRADE_COST)
	mon["def"] += 1
	upgrade_status_label.text = "%s gained +1 DEF." % str(mon.get("name", "Creature"))
	_refresh()


func _close() -> void:
	queue_free()


func _craft_seal() -> void:
	if not _has(SEAL_CRAFT_COST):
		crafting_status_label.text = "Not enough materials to craft a Seal."
		return
	_pay(SEAL_CRAFT_COST)
	GameState.seals += 1
	crafting_status_label.text = "Crafted 1 Seal."
	main_status_label.text = "Seal stock increased to %d." % GameState.seals
	_refresh()


func _rebuild_party_chips(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

	for index in range(GameState.party.size()):
		var mon: Dictionary = GameState.party[index]
		var chip = CREATURE_CHIP_SCENE.instantiate()
		container.add_child(chip)
		chip.configure(
			str(mon.get("name", "Creature")),
			_palette_for_element(str(mon.get("element", ""))),
			index == selected_creature_index
		)
		chip.pressed.connect(select_creature.bind(index))


func _refresh_selected_creature_card(
	name_label: Label,
	stats_label: Label,
	portrait: TextureRect,
	empty_text: String
) -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		name_label.text = "No creatures available"
		stats_label.text = empty_text
		portrait.texture = null
		portrait.visible = false
		return

	name_label.text = str(mon.get("name", "Creature"))
	stats_label.text = "HP %d / %d\nATK %d\nDEF %d" % [
		int(mon.get("hp", 0)),
		int(mon.get("hp_max", 0)),
		int(mon.get("atk", 0)),
		int(mon.get("def", 0)),
	]
	var texture := _load_creature_portrait(mon)
	portrait.texture = texture
	portrait.visible = texture != null


func _refresh_upgrade_buttons() -> void:
	var has_selection := not get_selected_creature().is_empty()
	hp_btn.disabled = not has_selection
	atk_btn.disabled = not has_selection
	def_btn.disabled = not has_selection
	if not has_selection:
		upgrade_status_label.text = "No creature selected for upgrades."
	elif upgrade_status_label.text.is_empty() or upgrade_status_label.text == "No creature selected for upgrades.":
		upgrade_status_label.text = "Choose an upgrade for the selected creature."


func select_creature(index: int) -> void:
	if index < 0 or index >= GameState.party.size():
		return
	selected_creature_index = index
	upgrade_status_label.text = "Choose an upgrade for the selected creature."
	_refresh()


func get_selected_creature() -> Dictionary:
	if selected_creature_index < 0 or selected_creature_index >= GameState.party.size():
		return {}
	return GameState.party[selected_creature_index]


func _normalize_selected_creature_index() -> void:
	if GameState.party.is_empty():
		selected_creature_index = -1
		return
	if selected_creature_index < 0 or selected_creature_index >= GameState.party.size():
		selected_creature_index = 0


func _selected_map_display_name() -> String:
	var map_id := GameState.current_map_id
	return str(GameData.maps.get(map_id, {}).get("display_name", map_id))


func _selected_map_summary_text() -> String:
	return "%s is ready for the next venture." % _selected_map_display_name()


func _materials_summary_text() -> String:
	var materials := GameState.materials
	return "Seals %d   Core %d   Herb %d   Wood %d   Stone %d   Crystal %d   Species %d" % [
		GameState.seals,
		int(materials.get("core_shard", 0)),
		int(materials.get("herb", 0)),
		int(materials.get("wood", 0)),
		int(materials.get("stone", 0)),
		int(materials.get("crystal", 0)),
		int(materials.get("species_mat", 0)),
	]


func _collection_summary_text() -> String:
	var party_count := GameState.party.size()
	var storage_count := GameState.box.size()
	return "Party %d / %d\nStorage %d creatures" % [party_count, GameState.PARTY_MAX, storage_count]


func _load_creature_portrait(mon: Dictionary) -> Texture2D:
	var creature_id := str(mon.get("id", ""))
	if creature_id.is_empty():
		return null
	var data: Dictionary = GameData.creatures.get(creature_id, {})
	var sprite_path := str(data.get("sprite_path", ""))
	if sprite_path.is_empty():
		return null
	return load(sprite_path) as Texture2D


func _palette_for_element(element: String) -> String:
	match element:
		"grass":
			return "grass"
		"fire":
			return "fire"
		"earth":
			return "earth"
		_:
			return "neutral"

extends Control

const CREATURE_CHIP_SCENE := preload("res://scenes/ui/CreatureChip.tscn")
const MAP_OPTION_BUTTON_SCENE := preload("res://scenes/ui/MapOptionButton.tscn")
const SEAL_ITEM_ID := "basic_seal"

enum CampView {
	MAIN,
	COLLECTION,
	MAPS,
	CRAFTING,
}

@onready var background: ColorRect = $Background
@onready var title_label: Label = $Panel/CenterRow/ContentColumn/Header/TitleLabel
@onready var subtitle_label: Label = $Panel/CenterRow/ContentColumn/Header/SubtitleLabel
@onready var main_camp_panel := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel
@onready var creature_collection_panel := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel
@onready var maps_panel := $Panel/CenterRow/ContentColumn/Panels/MapsPanel
@onready var crafting_panel := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel

@onready var main_team_chips := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/CreatureChips
@onready var main_selected_name_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureInfo/SelectedCreatureName
@onready var main_selected_stats_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureInfo/SelectedCreatureStats
@onready var main_selected_portrait := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreaturePortrait
@onready var main_party_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/PartyLabel
@onready var main_map_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/MapSummaryCard/Padding/Content/MapLabel
@onready var main_resources_chips := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/ResourcesCard/Padding/Content/ResourcesChips
@onready var main_status_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/MainStatusLabel
@onready var collection_nav_button := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationButtons/CollectionButton
@onready var maps_nav_button := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationButtons/MapsButton
@onready var crafting_nav_button := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationButtons/CraftingButton
@onready var venture_btn := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/ActionRow/VentureButton

@onready var collection_back_button := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/Header/BackButton
@onready var collection_team_chips := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/CreatureChips
@onready var collection_party_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/PartyLabel
@onready var collection_selected_name_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureName
@onready var collection_selected_stats_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureStats
@onready var collection_selected_abilities_container: VBoxContainer = $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/SelectedCreatureAbilities
@onready var collection_selected_portrait := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/SelectedCreatureRow/SelectedCreaturePortrait
@onready var collection_held_item_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/HeldItemLabel
@onready var collection_equip_button := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/LoadoutButtons/EquipHeldItemButton
@onready var collection_unequip_button := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/LoadoutButtons/UnequipHeldItemButton
@onready var collection_held_items_list := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/HeldItemList
@onready var collection_consumables_list := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/ConsumableList
@onready var collection_status_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/CollectionStatusLabel
@onready var inventory_summary_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/InventorySummaryLabel
@onready var inventory_hint_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/InventoryHintLabel
@onready var inventory_camp_items_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/CampItemsLabel

@onready var maps_back_button := $Panel/CenterRow/ContentColumn/Panels/MapsPanel/Header/BackButton
@onready var maps_selected_label := $Panel/CenterRow/ContentColumn/Panels/MapsPanel/MapSelectionCard/Padding/Content/MapLabel
@onready var map_list := $Panel/CenterRow/ContentColumn/Panels/MapsPanel/MapSelectionCard/Padding/Content/MapList

@onready var crafting_back_button := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/Header/BackButton
@onready var crafting_mats_chips := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/MatsChips
@onready var crafting_status_label := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/CraftingStatusLabel
@onready var crafting_search_label := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/SearchRow/SearchLabel
@onready var crafting_search_box: LineEdit = $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/SearchRow/SearchBox
@onready var crafting_recipe_scroll: ScrollContainer = $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/RecipesScroll
@onready var crafting_recipe_list := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/RecipesScroll/RecipesList
@onready var crafting_camp_items_label := $Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/CampItemsLabel

var current_view: int = CampView.MAIN
var selected_creature_index := -1
var collection_mode := GameData.ITEM_CATEGORY_HELD
var collection_status_message := ""
var crafting_search_text := ""
var crafting_category := GameData.ITEM_CATEGORY_CONSUMABLE
var crafting_owned_only := false
var crafting_craftable_only := false
var selected_crafting_item_id := ""
var selected_collection_item_id := ""
var crafting_browser := {}
var collection_browser := {}


func _ready() -> void:
	_apply_world_ui()
	main_status_label.visible = false
	collection_nav_button.pressed.connect(show_creature_collection_menu)
	maps_nav_button.pressed.connect(show_maps_menu)
	crafting_nav_button.pressed.connect(show_crafting_menu)
	collection_back_button.pressed.connect(show_main_camp)
	maps_back_button.pressed.connect(show_main_camp)
	crafting_back_button.pressed.connect(show_main_camp)
	collection_equip_button.pressed.connect(_set_collection_mode.bind(GameData.ITEM_CATEGORY_HELD))
	collection_unequip_button.pressed.connect(_unequip_selected_held_item)
	crafting_search_box.text_changed.connect(_on_crafting_search_changed)
	venture_btn.pressed.connect(_venture)

	GameState.ensure_starter()
	_setup_item_browsers()
	_build_map_buttons()
	_heal_team_on_entry()
	show_main_camp()
	_refresh()


func _apply_world_ui() -> void:
	WorldUI.apply_background(background, "verdant")
	WorldUI.apply_label(title_label, "title", "verdant")
	WorldUI.apply_label(subtitle_label, "subtitle", "verdant")

	for panel_path in [
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/MapSummaryCard",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/ResourcesCard",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard",
		"Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard",
	]:
		WorldUI.apply_panel(get_node(panel_path), "wood", true)

	WorldUI.apply_panel($Panel/CenterRow/ContentColumn/Panels/MapsPanel/MapSelectionCard, "stone", true)

	for label_path in [
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/TeamTitle",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureInfo/SelectedCreatureName",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/MapSummaryCard/Padding/Content/MapTitle",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/ResourcesCard/Padding/Content/ResourcesTitle",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/NavigationCard/Padding/Content/NavigationTitle",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/TeamTitle",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/SelectedCreatureTitle",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/HeldItemsTitle",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/ConsumablesTitle",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/InventoryTitle",
		"Panel/CenterRow/ContentColumn/Panels/MapsPanel/MapSelectionCard/Padding/Content/MapTitle",
		"Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/CraftingTitle",
	]:
		WorldUI.apply_label(get_node(label_path), "title", "wood")
	WorldUI.apply_label(crafting_search_label, "subtitle", "wood")

	for label_path in [
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/TeamSubtitle",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/MapSummaryCard/Padding/Content/MapHintLabel",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/InventoryHintLabel",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/Header/TitleColumn/SubtitleLabel",
		"Panel/CenterRow/ContentColumn/Panels/MapsPanel/Header/TitleColumn/SubtitleLabel",
		"Panel/CenterRow/ContentColumn/Panels/CraftingPanel/Header/TitleColumn/SubtitleLabel",
		"Panel/CenterRow/ContentColumn/Panels/CraftingPanel/CraftingCard/Padding/Content/CraftingStatusLabel",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/CollectionStatusLabel",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/CampItemsLabel",
	]:
		WorldUI.apply_label(get_node(label_path), "subtitle", "verdant")

	for label_path in [
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/MainStatusLabel",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/MapSummaryCard/Padding/Content/MapLabel",
		"Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureContent/SelectedCreatureInfo/SelectedCreatureStats",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureName",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/SelectedCreatureRow/SelectedCreatureInfo/SelectedCreatureStats",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/HeldItemLabel",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/InventorySummaryLabel",
	]:
		WorldUI.apply_label(get_node(label_path), "body", "wood")

	for label_path in [
		"Panel/CenterRow/ContentColumn/Panels/MapsPanel/MapSelectionCard/Padding/Content/MapLabel",
		"Panel/CenterRow/ContentColumn/Panels/CraftingPanel/Header/TitleColumn/TitleLabel",
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/Header/TitleColumn/TitleLabel",
		"Panel/CenterRow/ContentColumn/Panels/MapsPanel/Header/TitleColumn/TitleLabel",
	]:
		WorldUI.apply_label(get_node(label_path), "title", "verdant")

	for btn in [
		collection_nav_button,
		maps_nav_button,
		crafting_nav_button,
		collection_back_button,
		maps_back_button,
		crafting_back_button,
		collection_equip_button,
		collection_unequip_button,
	]:
		WorldUI.apply_button(btn, "wood")

	WorldUI.apply_button(venture_btn, "verdant", true)
	crafting_search_box.add_theme_font_size_override("font_size", 15)


func _setup_item_browsers() -> void:
	collection_equip_button.text = "Change Held Item"
	collection_held_items_list.visible = false
	collection_consumables_list.visible = false
	collection_held_items_list.get_parent().get_node("HeldItemsTitle").visible = false
	collection_consumables_list.get_parent().get_node("ConsumablesTitle").visible = false
	crafting_browser = _setup_crafting_browser()
	collection_browser = _setup_collection_browser()


func _setup_crafting_browser() -> Dictionary:
	var content: VBoxContainer = crafting_camp_items_label.get_parent()
	var category_row := HBoxContainer.new()
	category_row.name = "CraftingCategoryRow"
	category_row.add_theme_constant_override("separation", 8)
	content.add_child(category_row)
	content.move_child(category_row, crafting_search_box.get_parent().get_index())
	var category_buttons := {}
	for category in [GameData.ITEM_CATEGORY_CONSUMABLE, GameData.ITEM_CATEGORY_HELD, GameData.ITEM_CATEGORY_CAMP]:
		var button := Button.new()
		button.text = GameData.format_item_category(category)
		button.custom_minimum_size = Vector2(0, 38)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		WorldUI.apply_button(button, str(GameData.get_item_category_data(category).get("variant", "wood")))
		button.pressed.connect(_set_crafting_category.bind(category))
		category_row.add_child(button)
		category_buttons[category] = button

	var filter_row := HBoxContainer.new()
	filter_row.name = "CraftingFilterRow"
	filter_row.add_theme_constant_override("separation", 8)
	content.add_child(filter_row)
	content.move_child(filter_row, category_row.get_index() + 1)

	var owned_toggle := Button.new()
	owned_toggle.text = "Owned Only: Off"
	owned_toggle.custom_minimum_size = Vector2(0, 34)
	WorldUI.apply_button(owned_toggle, "wood")
	owned_toggle.pressed.connect(_toggle_crafting_owned_only)
	filter_row.add_child(owned_toggle)

	var craftable_toggle := Button.new()
	craftable_toggle.text = "Craftable Only: Off"
	craftable_toggle.custom_minimum_size = Vector2(0, 34)
	WorldUI.apply_button(craftable_toggle, "verdant")
	craftable_toggle.pressed.connect(_toggle_crafting_craftable_only)
	filter_row.add_child(craftable_toggle)

	var browser_row := HBoxContainer.new()
	browser_row.name = "CraftingBrowserRow"
	browser_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser_row.add_theme_constant_override("separation", 12)
	var recipe_scroll_parent: Control = crafting_recipe_scroll.get_parent()
	var recipe_scroll_index := crafting_recipe_scroll.get_index()
	recipe_scroll_parent.remove_child(crafting_recipe_scroll)
	browser_row.add_child(crafting_recipe_scroll)
	var detail := _create_item_detail_panel("wood")
	browser_row.add_child(detail["panel"])
	content.add_child(browser_row)
	content.move_child(browser_row, recipe_scroll_index)
	detail["action_button"].pressed.connect(_on_crafting_detail_action)

	return {
		"category_buttons": category_buttons,
		"owned_toggle": owned_toggle,
		"craftable_toggle": craftable_toggle,
		"detail": detail,
	}


func _setup_collection_browser() -> Dictionary:
	var content: VBoxContainer = inventory_summary_label.get_parent()
	var mode_row := HBoxContainer.new()
	mode_row.name = "CollectionModeRow"
	mode_row.add_theme_constant_override("separation", 8)
	content.add_child(mode_row)

	var mode_buttons := {}
	for category in [GameData.ITEM_CATEGORY_HELD, GameData.ITEM_CATEGORY_CONSUMABLE, GameData.ITEM_CATEGORY_CAMP]:
		var button := Button.new()
		button.text = GameData.format_item_category(category)
		button.custom_minimum_size = Vector2(0, 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		WorldUI.apply_button(button, str(GameData.get_item_category_data(category).get("variant", "wood")))
		button.pressed.connect(_set_collection_mode.bind(category))
		mode_row.add_child(button)
		mode_buttons[category] = button

	var search_row := HBoxContainer.new()
	search_row.name = "CollectionSearchRow"
	search_row.add_theme_constant_override("separation", 8)
	var search_label := Label.new()
	search_label.text = "Search"
	WorldUI.apply_label(search_label, "subtitle", "wood")
	search_row.add_child(search_label)
	var search_box := LineEdit.new()
	search_box.custom_minimum_size = Vector2(0, 38)
	search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_box.placeholder_text = "Filter item names"
	search_box.add_theme_font_size_override("font_size", 15)
	search_box.text_changed.connect(_on_collection_search_changed)
	search_row.add_child(search_box)
	content.add_child(search_row)

	var browser_row := HBoxContainer.new()
	browser_row.name = "CollectionBrowserRow"
	browser_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser_row.add_theme_constant_override("separation", 12)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 300)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	browser_row.add_child(scroll)
	var detail := _create_item_detail_panel("wood")
	browser_row.add_child(detail["panel"])
	detail["action_button"].pressed.connect(_on_collection_detail_action)
	content.add_child(browser_row)

	return {
		"mode_buttons": mode_buttons,
		"search_box": search_box,
		"search_text": "",
		"list": list,
		"scroll": scroll,
		"detail": detail,
	}


func _create_item_detail_panel(variant: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	WorldUI.apply_panel(panel, variant, true)

	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 14)
	padding.add_theme_constant_override("margin_top", 14)
	padding.add_theme_constant_override("margin_right", 14)
	padding.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(padding)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	padding.add_child(content)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 20)
	WorldUI.apply_label(title, "title", variant)
	content.add_child(title)

	var meta := Label.new()
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(meta, "subtitle", variant)
	content.add_child(meta)

	var description := Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(description, "body", variant)
	content.add_child(description)

	var owned := Label.new()
	owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(owned, "body", variant)
	content.add_child(owned)

	var effect := Label.new()
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(effect, "body", variant)
	content.add_child(effect)

	var recipe := Label.new()
	recipe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(recipe, "body", variant)
	content.add_child(recipe)

	var action_button := Button.new()
	action_button.custom_minimum_size = Vector2(0, 42)
	WorldUI.apply_button(action_button, variant, true)
	content.add_child(action_button)

	return {
		"panel": panel,
		"title": title,
		"meta": meta,
		"description": description,
		"owned": owned,
		"effect": effect,
		"recipe": recipe,
		"action_button": action_button,
	}


func show_main_camp() -> void:
	_set_view(CampView.MAIN)


func show_creature_collection_menu() -> void:
	_set_view(CampView.COLLECTION)


func show_maps_menu() -> void:
	_set_view(CampView.MAPS)


func show_crafting_menu() -> void:
	_set_view(CampView.CRAFTING)


func _set_view(view: int) -> void:
	current_view = view
	main_camp_panel.visible = view == CampView.MAIN
	creature_collection_panel.visible = view == CampView.COLLECTION
	maps_panel.visible = view == CampView.MAPS
	crafting_panel.visible = view == CampView.CRAFTING


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
		mon["hp"] = GameState.get_effective_creature_stat(mon, "hp_max")
		mon["mp"] = GameState.get_effective_creature_stat(mon, "mp_max")

	var has_healing_tent := GameState.has_camp_item("healing_tent")
	if has_healing_tent:
		for mon in GameState.box:
			GameState.ensure_creature_progression_fields(mon)
			mon["hp"] = GameState.get_effective_creature_stat(mon, "hp_max")
			mon["mp"] = GameState.get_effective_creature_stat(mon, "mp_max")

	var notice := GameState.consume_camp_notice()
	if not notice.is_empty():
		main_status_label.text = notice
	elif has_healing_tent:
		main_status_label.text = "Your Healing Tent restored the whole collection while the party rested."
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
	venture_btn.disabled = GameState.party.is_empty()


func refresh_main_camp_summary() -> void:
	_rebuild_party_chips(main_team_chips)
	main_party_label.text = _party_text()
	main_party_label.visible = GameState.party.is_empty()
	_refresh_selected_creature_card(
		main_selected_name_label,
		main_selected_stats_label,
		main_selected_portrait,
		"Choose a creature to inspect."
	)
	main_map_label.text = _selected_map_summary_text()
	WorldUI.populate_resource_chips(main_resources_chips, GameState.get_item_count(SEAL_ITEM_ID), GameState.materials, "wood")


func _refresh_collection_menu() -> void:
	_rebuild_party_chips(collection_team_chips)
	collection_party_label.text = _party_text()
	collection_party_label.visible = GameState.party.is_empty()
	_refresh_selected_creature_card(
		collection_selected_name_label,
		collection_selected_stats_label,
		collection_selected_portrait,
		"Capture a creature to start building held-item loadouts.",
		collection_selected_abilities_container,
		collection_held_item_label
	)
	var selected_creature := get_selected_creature()
	collection_equip_button.disabled = selected_creature.is_empty()
	collection_unequip_button.disabled = selected_creature.is_empty() or str(selected_creature.get("held_item_id", "")).is_empty()
	if collection_status_message.is_empty():
		_set_collection_mode(collection_mode)
	else:
		collection_status_label.text = collection_status_message
	_refresh_inventory_summary()
	_refresh_collection_browser()


func _refresh_maps_menu() -> void:
	maps_selected_label.text = "Selected map: %s" % _selected_map_display_name()
	for child in map_list.get_children():
		if child.has_method("set_selected"):
			child.set_selected(child.text == _selected_map_display_name())


func _refresh_crafting_menu() -> void:
	WorldUI.populate_resource_chips(crafting_mats_chips, GameState.get_item_count(SEAL_ITEM_ID), GameState.materials, "wood")
	if crafting_status_label.text.is_empty():
		crafting_status_label.text = "Craft supplies into consumables, held items, and camp items."
	_refresh_crafting_browser()
	crafting_recipe_scroll.scroll_vertical = 0
	var camp_items := GameState.get_owned_camp_items()
	crafting_camp_items_label.text = "Installed camp items: %s" % (", ".join(_item_name_list(camp_items)) if not camp_items.is_empty() else "None")


func _refresh_crafting_browser() -> void:
	if crafting_browser.is_empty():
		return
	for category in crafting_browser["category_buttons"].keys():
		var button: Button = crafting_browser["category_buttons"][category]
		button.disabled = category == crafting_category
	crafting_browser["owned_toggle"].text = "Owned Only: %s" % ("On" if crafting_owned_only else "Off")
	crafting_browser["craftable_toggle"].text = "Craftable Only: %s" % ("On" if crafting_craftable_only else "Off")

	var item_ids := _get_crafting_browser_item_ids()
	if not item_ids.has(selected_crafting_item_id):
		selected_crafting_item_id = item_ids[0] if not item_ids.is_empty() else ""
	_rebuild_browser_list(crafting_recipe_list, item_ids, selected_crafting_item_id, _select_crafting_item, _format_crafting_browser_row)
	_refresh_crafting_detail()


func _refresh_collection_browser() -> void:
	if collection_browser.is_empty():
		return
	for category in collection_browser["mode_buttons"].keys():
		var button: Button = collection_browser["mode_buttons"][category]
		button.disabled = category == collection_mode
	match collection_mode:
		GameData.ITEM_CATEGORY_HELD:
			inventory_hint_label.text = "Browse crafted held items here, then equip them from the detail panel."
		GameData.ITEM_CATEGORY_CONSUMABLE:
			inventory_hint_label.text = "Use camp-safe consumables on the selected creature from the detail panel."
		_:
			inventory_hint_label.text = "Camp items are persistent upgrades. They stay visible here as the item pool grows."

	var item_ids := _get_collection_browser_item_ids()
	if not item_ids.has(selected_collection_item_id):
		selected_collection_item_id = item_ids[0] if not item_ids.is_empty() else ""
	_rebuild_browser_list(collection_browser["list"], item_ids, selected_collection_item_id, _select_collection_item, _format_collection_browser_row)
	_refresh_collection_detail()


func _get_crafting_browser_item_ids() -> Array[String]:
	var item_ids: Array[String] = []
	for item_id in GameData.get_item_ids_by_category(crafting_category):
		if crafting_owned_only and GameState.get_item_count(item_id) <= 0:
			continue
		if crafting_craftable_only and not GameState.can_craft(item_id):
			continue
		if not crafting_search_text.is_empty() and str(GameData.get_item_data(item_id).get("name", item_id)).to_lower().find(crafting_search_text) == -1:
			continue
		item_ids.append(item_id)
	item_ids.sort_custom(func(a: String, b: String) -> bool:
		var a_craftable := GameState.can_craft(a)
		var b_craftable := GameState.can_craft(b)
		if a_craftable != b_craftable:
			return a_craftable
		var a_owned := GameState.get_item_count(a) > 0
		var b_owned := GameState.get_item_count(b) > 0
		if a_owned != b_owned:
			return a_owned
		var a_data := GameData.get_item_data(a)
		var b_data := GameData.get_item_data(b)
		var a_sort := int(a_data.get("sort_order", 0))
		var b_sort := int(b_data.get("sort_order", 0))
		if a_sort == b_sort:
			return str(a_data.get("name", a)).nocasecmp_to(str(b_data.get("name", b))) < 0
		return a_sort < b_sort
	)
	return item_ids


func _get_collection_browser_item_ids() -> Array[String]:
	var search_text := str(collection_browser.get("search_text", ""))
	var item_ids: Array[String] = []
	for item_id in GameData.get_item_ids_by_category(collection_mode):
		if collection_mode == GameData.ITEM_CATEGORY_HELD and GameState.get_item_count(item_id) <= 0 and str(get_selected_creature().get("held_item_id", "")) != item_id:
			continue
		if collection_mode == GameData.ITEM_CATEGORY_CONSUMABLE and not GameData.get_item_data(item_id).get("use_contexts", []).has("camp_creature"):
			continue
		if not search_text.is_empty() and str(GameData.get_item_data(item_id).get("name", item_id)).to_lower().find(search_text) == -1:
			continue
		item_ids.append(item_id)
	item_ids.sort_custom(func(a: String, b: String) -> bool:
		var selected_creature := get_selected_creature()
		var a_equipped := str(selected_creature.get("held_item_id", "")) == a
		var b_equipped := str(selected_creature.get("held_item_id", "")) == b
		if a_equipped != b_equipped:
			return a_equipped
		var a_owned := GameState.get_item_count(a) > 0
		var b_owned := GameState.get_item_count(b) > 0
		if a_owned != b_owned:
			return a_owned
		var a_data := GameData.get_item_data(a)
		var b_data := GameData.get_item_data(b)
		var a_sort := int(a_data.get("sort_order", 0))
		var b_sort := int(b_data.get("sort_order", 0))
		if a_sort == b_sort:
			return str(a_data.get("name", a)).nocasecmp_to(str(b_data.get("name", b))) < 0
		return a_sort < b_sort
	)
	return item_ids


func _rebuild_browser_list(container: VBoxContainer, item_ids: Array[String], selected_item_id: String, on_select: Callable, formatter: Callable) -> void:
	for child in container.get_children():
		child.queue_free()
	if item_ids.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items match the current filters."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		WorldUI.apply_label(empty_label, "subtitle", "verdant")
		container.add_child(empty_label)
		return
	for item_id in item_ids:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 38)
		button.add_theme_font_size_override("font_size", 14)
		button.text = formatter.call(item_id, item_id == selected_item_id)
		button.tooltip_text = GameData.get_item_detail_text(item_id)
		WorldUI.apply_button(button, GameData.get_item_variant(item_id), item_id == selected_item_id)
		button.pressed.connect(on_select.bind(item_id))
		container.add_child(button)


func _format_crafting_browser_row(item_id: String, selected: bool) -> String:
	var item_data := GameData.get_item_data(item_id)
	var parts: Array[String] = [str(item_data.get("name", item_id))]
	parts.append("x%d" % GameState.get_item_count(item_id))
	if GameState.can_craft(item_id):
		parts.append("Ready")
	return ("> " if selected else "") + "  ".join(parts)


func _format_collection_browser_row(item_id: String, selected: bool) -> String:
	var item_data := GameData.get_item_data(item_id)
	var parts: Array[String] = [str(item_data.get("name", item_id))]
	if collection_mode == GameData.ITEM_CATEGORY_CAMP:
		parts.append("Owned" if GameState.get_item_count(item_id) > 0 else "Not Owned")
	else:
		parts.append("x%d" % GameState.get_item_count(item_id))
	var selected_creature := get_selected_creature()
	if collection_mode == GameData.ITEM_CATEGORY_HELD and str(selected_creature.get("held_item_id", "")) == item_id:
		parts.append("Equipped")
	return ("> " if selected else "") + "  ".join(parts)


func _refresh_crafting_detail() -> void:
	_refresh_item_detail_panel(crafting_browser["detail"], selected_crafting_item_id, "craft")


func _refresh_collection_detail() -> void:
	_refresh_item_detail_panel(collection_browser["detail"], selected_collection_item_id, collection_mode)


func _refresh_item_detail_panel(detail: Dictionary, item_id: String, context: String) -> void:
	if item_id.is_empty():
		detail["title"].text = "No Item Selected"
		detail["meta"].text = ""
		detail["description"].text = "Select an item from the list."
		detail["owned"].text = ""
		detail["effect"].text = ""
		detail["recipe"].text = ""
		detail["action_button"].text = "Unavailable"
		detail["action_button"].disabled = true
		return
	var item_data := GameData.get_item_data(item_id)
	detail["title"].text = str(item_data.get("name", item_id))
	detail["meta"].text = "%s  |  %s" % [
		GameData.format_item_category(str(item_data.get("category", ""))),
		str(item_data.get("rarity", "common")).capitalize(),
	]
	detail["description"].text = str(item_data.get("description", ""))
	detail["owned"].text = "Owned: %d" % GameState.get_item_count(item_id)
	detail["effect"].text = "Effects: %s\nTags: %s" % [
		GameData.get_item_effect_summary(item_id),
		", ".join(GameData.get_item_tags(item_id)),
	]
	var recipe := GameData.get_item_recipe(item_id)
	detail["recipe"].text = "Recipe: %s" % (GameData.format_material_cost(recipe) if not recipe.is_empty() else "None")
	match context:
		"craft":
			detail["action_button"].text = "Craft"
			detail["action_button"].disabled = not GameState.can_craft(item_id)
		GameData.ITEM_CATEGORY_HELD:
			var creature := get_selected_creature()
			var equipped := str(creature.get("held_item_id", "")) == item_id
			detail["action_button"].text = "Equipped" if equipped else "Equip"
			detail["action_button"].disabled = creature.is_empty() or equipped or GameState.get_item_count(item_id) <= 0
		GameData.ITEM_CATEGORY_CONSUMABLE:
			detail["action_button"].text = "Use"
			detail["action_button"].disabled = get_selected_creature().is_empty() or GameState.get_item_count(item_id) <= 0
		_:
			detail["action_button"].text = "View"
			detail["action_button"].disabled = true


func _rebuild_party_chips(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

	for index in range(GameState.party.size()):
		var mon: Dictionary = GameState.party[index]
		var chip = CREATURE_CHIP_SCENE.instantiate()
		container.add_child(chip)
		chip.configure(
			_creature_chip_text(mon),
			_palette_for_element(str(mon.get("element", ""))),
			index == selected_creature_index
		)
		chip.pressed.connect(select_creature.bind(index))


func _refresh_selected_creature_card(
	name_label: Label,
	stats_label: Label,
	portrait: TextureRect,
	empty_text: String,
	abilities_container: VBoxContainer = null,
	held_item_label: Label = null
) -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		name_label.text = "No creatures available"
		stats_label.text = empty_text
		if abilities_container != null:
			_populate_creature_abilities(abilities_container, {}, empty_text)
		if held_item_label != null:
			held_item_label.text = "Held Item: None"
		portrait.texture = null
		portrait.visible = false
		return

	var stats := GameState.get_effective_creature_stats(mon)
	name_label.text = "%s  Lv. %d" % [
		str(mon.get("name", "Creature")),
		int(mon.get("level", GameData.DEFAULT_LEVEL)),
	]
	stats_label.text = "HP %d / %d   MP %d / %d\nATK %d   DEF %d   SPD %d\nACC %d   EVA %d   CRIT %d%%\nEXP %d / %d" % [
		int(mon.get("hp", 0)),
		int(stats.get("hp_max", 0)),
		int(mon.get("mp", 0)),
		int(stats.get("mp_max", GameData.get_default_mp())),
		int(stats.get("atk", 0)),
		int(stats.get("def", 0)),
		int(stats.get("spd", 0)),
		int(stats.get("acc", GameData.get_default_acc())),
		int(stats.get("eva", GameData.get_default_eva())),
		int(stats.get("crit", GameData.get_default_crit())),
		int(mon.get("exp", 0)),
		GameData.get_total_exp_for_level(min(int(mon.get("level", GameData.DEFAULT_LEVEL)) + 1, GameData.MAX_LEVEL)),
	]
	if abilities_container != null:
		_populate_creature_abilities(abilities_container, mon, empty_text)
	if held_item_label != null:
		var held_item := GameState.get_creature_held_item(mon)
		held_item_label.text = "Held Item: %s" % str(held_item.get("name", "None"))
		held_item_label.tooltip_text = str(held_item.get("description", "No held item equipped."))
	var texture := _load_creature_portrait(mon)
	portrait.texture = texture
	portrait.visible = texture != null


func _populate_creature_abilities(container: VBoxContainer, creature: Dictionary, empty_text: String) -> void:
	for child in container.get_children():
		child.queue_free()

	if creature.is_empty():
		var empty_label := Label.new()
		empty_label.text = empty_text
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		WorldUI.apply_label(empty_label, "subtitle", "verdant")
		container.add_child(empty_label)
		return

	var passive_id := str(creature.get("passive_id", ""))
	_add_ability_section_title(container, "Passive")
	_add_ability_box(
		container,
		str(GameData.get_passive_data(passive_id).get("name", "No passive")),
		GameData.format_passive_summary(passive_id),
		GameData.format_passive_tooltip(passive_id),
		"verdant"
	)

	_add_ability_section_title(container, "Active Abilities")
	var ability_ids := GameState.get_creature_abilities(creature)
	if ability_ids.is_empty():
		_add_ability_box(container, "None", "No active abilities learned yet.", "No active abilities learned yet.", "stone")
		return
	for ability_id in ability_ids:
		var ability_data := GameData.get_ability_data(ability_id)
		_add_ability_box(
			container,
			str(ability_data.get("name", ability_id)),
			GameData.format_ability_summary(ability_id),
			GameData.format_ability_tooltip(ability_id),
			"wood"
		)


func _add_ability_section_title(container: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	WorldUI.apply_label(label, "subtitle", "wood")
	container.add_child(label)


func _add_ability_box(container: VBoxContainer, title_text: String, summary_text: String, tooltip_text: String, variant: String) -> void:
	var panel := PanelContainer.new()
	panel.tooltip_text = tooltip_text
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	WorldUI.apply_panel(panel, variant, true)
	container.add_child(panel)

	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 10)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 10)
	padding.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(padding)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	padding.add_child(content)

	var title := Label.new()
	title.text = title_text
	title.tooltip_text = tooltip_text
	title.add_theme_font_size_override("font_size", 15)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(title, "title", variant)
	content.add_child(title)

	var summary := Label.new()
	summary.text = summary_text
	summary.tooltip_text = tooltip_text
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WorldUI.apply_label(summary, "body", variant)
	content.add_child(summary)


func _refresh_inventory_summary() -> void:
	var spare_held := 0
	var consumables := 0
	for item_id in GameData.get_all_item_ids():
		var item_data := GameData.get_item_data(item_id)
		var count := GameState.get_item_count(item_id)
		match str(item_data.get("category", "")):
			GameData.ITEM_CATEGORY_HELD:
				spare_held += count
			GameData.ITEM_CATEGORY_CONSUMABLE:
				consumables += count
	inventory_summary_label.text = "Party %d / %d\nStorage %d creatures\nConsumables %d\nSpare held items %d" % [
		GameState.party.size(),
		GameState.PARTY_MAX,
		GameState.box.size(),
		consumables,
		spare_held,
	]
	var camp_items := GameState.get_owned_camp_items()
	inventory_camp_items_label.text = "Camp items\n%s" % (", ".join(_item_name_list(camp_items)) if not camp_items.is_empty() else "None installed yet.")


func _equip_selected_held_item(item_id: String) -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		return
	if GameState.equip_held_item(mon, item_id):
		var item_name := str(GameData.get_item_data(item_id).get("name", item_id))
		collection_status_message = "%s equipped %s." % [str(mon.get("name", "Creature")), item_name]
		_refresh()


func _unequip_selected_held_item() -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		return
	if GameState.unequip_held_item(mon):
		collection_status_message = "%s's held item was returned to inventory." % str(mon.get("name", "Creature"))
		_refresh()


func _use_consumable_on_selected(item_id: String) -> void:
	var mon := get_selected_creature()
	if mon.is_empty():
		return
	var item_name := str(GameData.get_item_data(item_id).get("name", item_id))
	if GameState.use_consumable_on_creature(item_id, mon):
		collection_status_message = "Used %s on %s." % [item_name, str(mon.get("name", "Creature"))]
	else:
		collection_status_message = "%s had no effect." % item_name
	_refresh()


func _craft_item(item_id: String) -> void:
	if not GameState.craft_item(item_id):
		crafting_status_label.text = "Not enough materials to craft %s." % str(GameData.get_item_data(item_id).get("name", item_id))
		return
	var item_data := GameData.get_item_data(item_id)
	crafting_status_label.text = "Crafted %s." % str(item_data.get("name", item_id))
	main_status_label.text = "%s added to your supplies." % str(item_data.get("name", item_id))
	_refresh()


func _set_collection_mode(mode: String) -> void:
	collection_mode = mode
	if mode == GameData.ITEM_CATEGORY_HELD:
		collection_status_message = "Choose a held item from the browser."
	elif mode == GameData.ITEM_CATEGORY_CONSUMABLE:
		collection_status_message = "Choose a camp consumable to use on the selected creature."
	else:
		collection_status_message = "Camp items are tracked here for future progression hooks."
	collection_status_label.text = collection_status_message
	_refresh_collection_browser()


func _on_crafting_search_changed(new_text: String) -> void:
	crafting_search_text = new_text.strip_edges().to_lower()
	_refresh_crafting_browser()
	crafting_recipe_scroll.scroll_vertical = 0


func _on_collection_search_changed(new_text: String) -> void:
	collection_browser["search_text"] = new_text.strip_edges().to_lower()
	_refresh_collection_browser()
	collection_browser["scroll"].scroll_vertical = 0


func _set_crafting_category(category: String) -> void:
	crafting_category = category
	_refresh_crafting_browser()


func _toggle_crafting_owned_only() -> void:
	crafting_owned_only = not crafting_owned_only
	_refresh_crafting_browser()


func _toggle_crafting_craftable_only() -> void:
	crafting_craftable_only = not crafting_craftable_only
	_refresh_crafting_browser()


func _select_crafting_item(item_id: String) -> void:
	selected_crafting_item_id = item_id
	_refresh_crafting_detail()


func _select_collection_item(item_id: String) -> void:
	selected_collection_item_id = item_id
	_refresh_collection_detail()


func _on_crafting_detail_action() -> void:
	if not selected_crafting_item_id.is_empty():
		_craft_item(selected_crafting_item_id)


func _on_collection_detail_action() -> void:
	if selected_collection_item_id.is_empty():
		return
	match collection_mode:
		GameData.ITEM_CATEGORY_HELD:
			_equip_selected_held_item(selected_collection_item_id)
		GameData.ITEM_CATEGORY_CONSUMABLE:
			_use_consumable_on_selected(selected_collection_item_id)


func _close() -> void:
	queue_free()


func select_creature(index: int) -> void:
	if index < 0 or index >= GameState.party.size():
		return
	selected_creature_index = index
	collection_status_message = ""
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
	var map_id := GameState.current_map_id
	var next_objective := GameState.get_next_map_objective(map_id)
	if next_objective.is_empty():
		return "%s is ready for the next venture." % _selected_map_display_name()
	return "%s\nNext objective: %s" % [
		_selected_map_display_name(),
		GameState.get_objective_display_text(next_objective),
	]


func _creature_chip_text(mon: Dictionary) -> String:
	return "%s Lv.%d" % [
		str(mon.get("name", "Creature")),
		int(mon.get("level", GameData.DEFAULT_LEVEL)),
	]


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


func _format_held_effects(item_data: Dictionary) -> String:
	var parts: Array[String] = []
	var effects: Array = item_data.get("held_effects", [])
	for raw_effect in effects:
		if not (raw_effect is Dictionary):
			continue
		var effect: Dictionary = raw_effect
		if str(effect.get("type", "")) != "flat_stat":
			continue
		parts.append("+%d %s" % [int(effect.get("amount", 0)), str(effect.get("stat", "")).to_upper()])
	return ", ".join(parts)


func _item_name_list(item_ids: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for item_id in item_ids:
		names.append(str(GameData.get_item_data(item_id).get("name", item_id)))
	return names

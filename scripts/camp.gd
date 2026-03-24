extends Control

const CREATURE_CHIP_SCENE := preload("res://scenes/ui/CreatureChip.tscn")
const MAP_OPTION_BUTTON_SCENE := preload("res://scenes/ui/MapOptionButton.tscn")
const SEAL_ITEM_ID := "basic_seal"
const INTRO_TITLE_REALM := "A New Realm"
const INTRO_BODY_REALM := "A newly discovered realm, rich with untapped resources and unknown life, has opened its gates to exploration.\n\nScholars from your world have developed a powerful new technology — magical seals capable of binding creatures to your command. With their help, even the wildest beings of this realm can become allies.\n\nAs one of the first expeditioners, you are sent into these uncharted lands.\nGather resources, study strange ecosystems, and build your team of bound creatures.\n\nBut the deeper you go, the more dangerous the world becomes."
const INTRO_TITLE_CAMP := "Welcome to Camp"
const INTRO_BODY_CAMP := "Welcome to Camp.\n\nThis will be your base of operations while we explore the newly discovered realm. From here, you can prepare your team, craft supplies, and plan your next expedition.\n\nBefore we send you deeper into the unknown, we should start with something simple.\n\nTake your first venture into the wilds. Gather some materials, familiarize yourself with the terrain, and try binding a creature.\n\nLet’s see how you handle your first expedition."
const INTRO_DOCKED_OBJECTIVE := "Venture into Verdant Wilds!"
const FIRST_DEFEAT_TITLE := "Driven Back to Camp"
const FIRST_DEFEAT_BODY := "Your whole team was defeated in the wilds, so the expedition was forced to end.\n\nYou were brought back to camp safely, but any resources gathered during that venture were lost.\n\nUse camp to recover, adjust your team, and prepare before heading out again."
const EMBER_UNLOCK_TITLE := "New Area Unlocked"
const EMBER_UNLOCK_BODY := "Defeating the Mossking has opened the path to Ember Caves — a hotter, more dangerous region with new creatures and resources to discover.\n\nHead there whenever you feel ready."
const OBJECTIVE_HIGHLIGHT_COLOR := Color(1.0, 1.0, 0.82, 1.0)
const OBJECTIVE_HIGHLIGHT_BORDER_COLOR := Color(0.82, 0.25, 0.18, 1.0)

enum CampView {
	MAIN,
	COLLECTION,
	MAPS,
	CRAFTING,
}

enum IntroStep {
	NONE,
	REALM,
	CAMP_BRIEFING,
	FIRST_DEFEAT,
	EMBER_UNLOCK,
}

@onready var background: ColorRect = $Background
@onready var intro_overlay: CanvasLayer = $IntroOverlay
@onready var intro_dim: ColorRect = $IntroOverlay/Root/Dim
@onready var intro_panel: PanelContainer = $IntroOverlay/Root/Center/IntroPanel
@onready var intro_title_label: Label = $IntroOverlay/Root/Center/IntroPanel/Padding/Content/TitleLabel
@onready var intro_body_label: Label = $IntroOverlay/Root/Center/IntroPanel/Padding/Content/BodyLabel
@onready var intro_continue_button: Button = $IntroOverlay/Root/Center/IntroPanel/Padding/Content/ContinueButton
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
@onready var main_map_hint_label := $Panel/CenterRow/ContentColumn/Panels/MainCampPanel/SummaryRow/RightColumn/MapSummaryCard/Padding/Content/MapHintLabel
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
@onready var collection_transfer_button := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/LoadoutButtons/TransferButton
@onready var collection_equip_button := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/LoadoutButtons/EquipHeldItemButton
@onready var collection_unequip_button := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/LoadoutButtons/UnequipHeldItemButton
@onready var collection_held_items_list := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/HeldItemList
@onready var collection_consumables_list := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/ConsumableList
@onready var collection_status_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/TeamCard/Padding/Content/SelectedCreatureCard/Padding/SelectedCreatureScroll/SelectedCreatureContent/CollectionStatusLabel
@onready var inventory_summary_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/InventorySummaryLabel
@onready var storage_title_label := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/StorageTitle
@onready var storage_chips := $Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/StorageChips
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
var selected_creature_source := "party"
var collection_mode := GameData.ITEM_CATEGORY_HELD
var collection_status_message := ""
var crafting_search_text := ""
var crafting_category := GameData.ITEM_CATEGORY_CONSUMABLE
var crafting_owned_only := false
var crafting_craftable_only := false
var selected_collection_item_id := ""
var crafting_browser := {}
var collection_browser := {}
var crafting_card_nodes := {}
var collection_browser_item_nodes := {}
var intro_step: int = IntroStep.NONE
var intro_guidance_active := false
var venture_highlight_time := 0.0
var tutorial_highlight_time := 0.0
var highlight_crafting_back_button := false
var highlight_collection_back_button := false


func _ready() -> void:
	_apply_world_ui()
	if GameState.intro_popup_seen_this_session:
		intro_overlay.visible = false
	else:
		intro_step = IntroStep.REALM
		_show_intro_step()
	main_status_label.visible = false
	collection_nav_button.pressed.connect(show_creature_collection_menu)
	maps_nav_button.pressed.connect(show_maps_menu)
	crafting_nav_button.pressed.connect(show_crafting_menu)
	collection_back_button.pressed.connect(show_main_camp)
	maps_back_button.pressed.connect(show_main_camp)
	crafting_back_button.pressed.connect(show_main_camp)
	intro_continue_button.pressed.connect(_advance_intro_flow)
	collection_transfer_button.pressed.connect(_transfer_selected_creature)
	collection_equip_button.pressed.connect(_set_collection_mode.bind(GameData.ITEM_CATEGORY_HELD))
	collection_unequip_button.pressed.connect(_unequip_selected_held_item)
	crafting_search_box.text_changed.connect(_on_crafting_search_changed)
	venture_btn.pressed.connect(_venture)
	if not GameState.map_completion_changed.is_connected(_on_map_completion_changed):
		GameState.map_completion_changed.connect(_on_map_completion_changed)

	GameState.ensure_starter()
	GameState.ensure_current_map_is_unlocked()
	_setup_item_browsers()
	_build_map_buttons()
	_heal_team_on_entry()
	_maybe_show_first_defeat_popup()
	_maybe_show_ember_unlock_popup()
	show_main_camp()
	_refresh()
	set_process(true)


func _apply_world_ui() -> void:
	WorldUI.apply_background(background, "verdant")
	WorldUI.apply_panel(intro_panel, "battle", true)
	WorldUI.apply_label(intro_title_label, "title", "verdant")
	WorldUI.apply_label(intro_body_label, "body", "verdant")
	WorldUI.apply_button(intro_continue_button, "verdant", true)
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
		"Panel/CenterRow/ContentColumn/Panels/CreatureCollectionPanel/SummaryRow/InventoryCard/Padding/Content/StorageTitle",
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
	main_map_label.add_theme_color_override("font_color", Color("fffbe8"))
	main_map_label.add_theme_color_override("font_outline_color", Color("5b4126"))
	main_map_label.add_theme_constant_override("outline_size", 1)
	main_map_label.add_theme_font_size_override("font_size", 20)
	main_map_hint_label.add_theme_color_override("font_color", Color("fff1b8"))
	main_map_hint_label.add_theme_color_override("font_outline_color", Color("4d3824"))
	main_map_hint_label.add_theme_constant_override("outline_size", 1)
	main_map_hint_label.add_theme_font_size_override("font_size", 15)

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
		collection_transfer_button,
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

	return {
		"category_buttons": category_buttons,
		"owned_toggle": owned_toggle,
		"craftable_toggle": craftable_toggle,
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
	scroll.custom_minimum_size = Vector2(280, 280)
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
	if not GameState.party.is_empty():
		selected_creature_source = "party"
		if selected_creature_index < 0 or selected_creature_index >= GameState.party.size():
			selected_creature_index = 0
	_set_view(CampView.MAIN)


func show_creature_collection_menu() -> void:
	if _is_sharp_fang_equip_tutorial_active():
		collection_mode = GameData.ITEM_CATEGORY_HELD
		selected_collection_item_id = "sharp_fang"
		if not collection_browser.is_empty():
			collection_browser["search_text"] = ""
			var search_box_variant = collection_browser.get("search_box", null)
			if search_box_variant is LineEdit:
				var search_box: LineEdit = search_box_variant
				search_box.text = ""
	_set_view(CampView.COLLECTION)


func show_maps_menu() -> void:
	_set_view(CampView.MAPS)


func show_crafting_menu() -> void:
	var tutorial_target_item := _get_crafting_tutorial_target_item()
	if not tutorial_target_item.is_empty():
		crafting_category = _get_crafting_tutorial_target_category(tutorial_target_item)
		crafting_owned_only = false
		crafting_craftable_only = false
		crafting_search_text = ""
		crafting_search_box.text = ""
	_set_view(CampView.CRAFTING)


func _set_view(view: int) -> void:
	current_view = view
	main_camp_panel.visible = view == CampView.MAIN
	creature_collection_panel.visible = view == CampView.COLLECTION
	maps_panel.visible = view == CampView.MAPS
	crafting_panel.visible = view == CampView.CRAFTING
	if view != CampView.CRAFTING:
		highlight_crafting_back_button = false
	if view != CampView.COLLECTION:
		highlight_collection_back_button = false


func _build_map_buttons() -> void:
	for child in map_list.get_children():
		child.queue_free()

	for map_id in GameState.get_unlocked_map_ids():
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
	_stop_venture_highlight()
	GameState.ensure_current_map_is_unlocked()
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

	var notice := GameState.consume_camp_notice()
	if not notice.is_empty():
		main_status_label.text = notice
	else:
		main_status_label.text = "Your team rests and heals automatically at camp."


func _show_intro_step() -> void:
	intro_overlay.visible = intro_step != IntroStep.NONE
	if intro_step == IntroStep.NONE:
		return
	intro_panel.top_level = false
	intro_panel.scale = Vector2.ONE
	intro_panel.modulate = Color(1, 1, 1, 1)
	intro_panel.visible = true
	match intro_step:
		IntroStep.REALM:
			intro_title_label.text = INTRO_TITLE_REALM
			intro_body_label.text = INTRO_BODY_REALM
			intro_continue_button.text = "Continue"
		IntroStep.CAMP_BRIEFING:
			intro_title_label.text = INTRO_TITLE_CAMP
			intro_body_label.text = INTRO_BODY_CAMP
			intro_continue_button.text = "Show Objective"
		IntroStep.FIRST_DEFEAT:
			intro_title_label.text = FIRST_DEFEAT_TITLE
			intro_body_label.text = FIRST_DEFEAT_BODY
			intro_continue_button.text = "Continue"
		IntroStep.EMBER_UNLOCK:
			intro_title_label.text = EMBER_UNLOCK_TITLE
			intro_body_label.text = EMBER_UNLOCK_BODY
			intro_continue_button.text = "Continue"


func _exit_tree() -> void:
	if GameState.map_completion_changed.is_connected(_on_map_completion_changed):
		GameState.map_completion_changed.disconnect(_on_map_completion_changed)


func _on_map_completion_changed(_map_id: String, _completed: bool) -> void:
	GameState.ensure_current_map_is_unlocked()
	_build_map_buttons()
	_refresh()
	_maybe_show_ember_unlock_popup()


func _minimize_intro_to_objectives() -> void:
	intro_guidance_active = true
	show_main_camp()
	await get_tree().process_frame
	var start_pos: Vector2 = intro_panel.global_position
	var start_size: Vector2 = intro_panel.size
	var target_pos: Vector2 = main_map_label.global_position + Vector2(0, 26)
	var target_scale: Vector2 = Vector2(
		clampf(main_map_label.size.x / maxf(start_size.x, 1.0), 0.4, 0.82),
		0.42
	)
	intro_panel.top_level = true
	intro_panel.global_position = start_pos
	intro_panel.size = start_size
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(intro_panel, "global_position", target_pos, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(intro_panel, "scale", target_scale, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(intro_panel, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(intro_dim, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	intro_panel.top_level = false
	intro_panel.scale = Vector2.ONE
	intro_panel.modulate = Color(1, 1, 1, 1)
	intro_overlay.visible = false
	intro_dim.modulate = Color(1, 1, 1, 1)
	_refresh_intro_guidance()


func _refresh_intro_guidance() -> void:
	if not intro_guidance_active:
		main_map_hint_label.self_modulate = Color(1, 1, 1, 1)
		return
	if current_view != CampView.MAIN:
		return
	main_map_label.text = _selected_map_summary_text()
	main_map_hint_label.self_modulate = Color(1, 0.96, 0.84, 1)


func _stop_venture_highlight() -> void:
	intro_guidance_active = false
	venture_highlight_time = 0.0
	_set_objective_highlight(venture_btn, false)
	main_map_hint_label.self_modulate = Color(1, 1, 1, 1)


func _advance_intro_flow() -> void:
	match intro_step:
		IntroStep.REALM:
			intro_step = IntroStep.CAMP_BRIEFING
			_show_intro_step()
		IntroStep.CAMP_BRIEFING:
			GameState.intro_popup_seen_this_session = true
			intro_step = IntroStep.NONE
			_minimize_intro_to_objectives()
		IntroStep.FIRST_DEFEAT:
			intro_step = IntroStep.NONE
			intro_overlay.visible = false
		IntroStep.EMBER_UNLOCK:
			intro_step = IntroStep.NONE
			intro_overlay.visible = false
		_:
			intro_overlay.visible = false


func _maybe_show_first_defeat_popup() -> void:
	if not GameState.consume_first_defeat_popup():
		return
	intro_guidance_active = false
	intro_step = IntroStep.FIRST_DEFEAT
	_show_intro_step()


func _maybe_show_ember_unlock_popup() -> void:
	if not GameState.consume_ember_unlock_notification():
		return
	intro_guidance_active = false
	intro_step = IntroStep.EMBER_UNLOCK
	_show_intro_step()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camp") or event.is_action_pressed("ui_cancel"):
		if current_view == CampView.MAIN:
			_close()
		else:
			show_main_camp()


func _process(delta: float) -> void:
	tutorial_highlight_time += delta
	if not _should_highlight_venture_button():
		_set_objective_highlight(venture_btn, false)
	else:
		venture_highlight_time += delta
		var pulse := 1.0 + sin(venture_highlight_time * 3.8) * 0.035
		_set_objective_highlight(venture_btn, true, pulse)
		if not highlight_collection_back_button:
			return
	_update_crafting_tutorial_highlights(delta)
	_update_collection_tutorial_highlights(delta)


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
	_refresh_intro_guidance()
	_refresh_crafting_tutorial_state()


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
	_refresh_intro_guidance()


func _refresh_collection_menu() -> void:
	if _is_sharp_fang_equip_tutorial_active():
		collection_mode = GameData.ITEM_CATEGORY_HELD
	_rebuild_party_chips(collection_team_chips)
	_rebuild_storage_chips()
	collection_party_label.text = _party_text()
	collection_party_label.visible = GameState.party.is_empty()
	_refresh_selected_creature_card(
		collection_selected_name_label,
		collection_selected_stats_label,
		collection_selected_portrait,
			"Bind a creature to start building held-item loadouts.",
		collection_selected_abilities_container,
		collection_held_item_label
	)
	var selected_creature := get_selected_creature()
	_refresh_collection_transfer_button(selected_creature)
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
	crafting_status_label.visible = true
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
	_rebuild_crafting_grid(crafting_recipe_list, item_ids)
	_refresh_crafting_tutorial_state()


func _refresh_collection_browser() -> void:
	if collection_browser.is_empty():
		return
	if _is_sharp_fang_equip_tutorial_active():
		collection_mode = GameData.ITEM_CATEGORY_HELD
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
	if _is_sharp_fang_equip_tutorial_active() and item_ids.has("sharp_fang"):
		selected_collection_item_id = "sharp_fang"
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
	collection_browser_item_nodes.clear()
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
		collection_browser_item_nodes[item_id] = button


func _rebuild_crafting_grid(container: GridContainer, item_ids: Array[String]) -> void:
	crafting_card_nodes.clear()
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
		var card := _create_crafting_card(item_id)
		crafting_card_nodes[item_id] = card
		container.add_child(card)


func _create_crafting_card(item_id: String) -> Button:
	var item_data := GameData.get_item_data(item_id)
	var variant := GameData.get_item_variant(item_id)
	var recipe := GameData.get_item_recipe(item_id)
	var can_craft := GameState.can_craft(item_id)
	var button := Button.new()
	button.custom_minimum_size = Vector2(210, 164)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	button.tooltip_text = GameData.get_item_detail_text(item_id)
	WorldUI.apply_button(button, variant, can_craft, "battle")
	button.pressed.connect(_craft_item.bind(item_id))

	var padding := MarginContainer.new()
	padding.set_anchors_preset(Control.PRESET_FULL_RECT)
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(padding)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padding.add_child(content)

	var title := Label.new()
	title.text = str(item_data.get("name", item_id))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 14)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	WorldUI.apply_label(title, "title", variant)
	content.add_child(title)

	var icon_holder := PanelContainer.new()
	icon_holder.custom_minimum_size = Vector2(0, 60)
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	WorldUI.apply_panel(icon_holder, "parchment")
	content.add_child(icon_holder)

	var icon_padding := MarginContainer.new()
	icon_padding.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_padding.add_theme_constant_override("margin_left", 10)
	icon_padding.add_theme_constant_override("margin_top", 10)
	icon_padding.add_theme_constant_override("margin_right", 10)
	icon_padding.add_theme_constant_override("margin_bottom", 10)
	icon_padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(icon_padding)

	var icon_path := GameData.get_item_icon_path(item_id)
	if not icon_path.is_empty():
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_padding.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.text = "?"
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 28)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		WorldUI.apply_label(fallback, "dark", "parchment")
		icon_padding.add_child(fallback)

	var recipe_label := Label.new()
	recipe_label.text = GameData.format_material_cost(recipe) if not recipe.is_empty() else "No recipe"
	recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipe_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_label.add_theme_font_size_override("font_size", 11)
	WorldUI.apply_label(recipe_label, "body", variant)
	content.add_child(recipe_label)

	return button


func _get_crafting_tutorial_target_item() -> String:
	var primary := GameState.get_active_or_next_primary_objective()
	if GameState.map_run_active:
		return ""
	if str(primary.get("type", "")) != GameData.OBJECTIVE_TYPE_CRAFT:
		return ""
	var target_id := str(primary.get("target_id", ""))
	if bool(primary.get("completed", false)):
		return ""
	return target_id if target_id == "small_potion" or target_id == "sharp_fang" or target_id == "party_tent" else ""


func _get_crafting_tutorial_target_category(item_id: String) -> String:
	var item_data := GameData.get_item_data(item_id)
	return str(item_data.get("category", GameData.ITEM_CATEGORY_CONSUMABLE))


func _is_small_potion_tutorial_active() -> bool:
	return _get_crafting_tutorial_target_item() == "small_potion"


func _clear_crafting_tutorial_visuals() -> void:
	_set_objective_highlight(crafting_nav_button, false)
	_set_objective_highlight(crafting_back_button, false)
	for button_variant in crafting_browser.get("category_buttons", {}).values():
		if button_variant is Button:
			var category_button: Button = button_variant
			_set_objective_highlight(category_button, false)
	for card_variant in crafting_card_nodes.values():
		if card_variant is Button:
			var card_button: Button = card_variant
			_set_objective_highlight(card_button, false)


func _clear_collection_tutorial_visuals() -> void:
	_set_objective_highlight(collection_nav_button, false)
	_set_objective_highlight(collection_back_button, false)
	for button_variant in collection_browser.get("mode_buttons", {}).values():
		if button_variant is Button:
			var mode_button: Button = button_variant
			_set_objective_highlight(mode_button, false)
	for item_button_variant in collection_browser_item_nodes.values():
		if item_button_variant is Button:
			var item_button: Button = item_button_variant
			_set_objective_highlight(item_button, false)
	if not collection_browser.is_empty():
		var detail_action_variant = collection_browser.get("detail", {}).get("action_button", null)
		if detail_action_variant is Button:
			var detail_action_button: Button = detail_action_variant
			_set_objective_highlight(detail_action_button, false)


func _is_sharp_fang_equip_tutorial_active() -> bool:
	if GameState.map_run_active:
		return false
	var primary := GameState.get_active_or_next_primary_objective()
	return str(primary.get("id", "")) == "global_equip_sharp_fang" and not bool(primary.get("completed", false))


func _should_highlight_venture_button() -> bool:
	if intro_guidance_active:
		return true
	if GameState.map_run_active:
		return false
	var primary := GameState.get_active_or_next_primary_objective()
	if bool(primary.get("completed", false)):
		return false
	var obj_id := str(primary.get("id", ""))
	var obj_type := str(primary.get("type", ""))
	return obj_id == "global_win_verdant_battle" or obj_type == GameData.OBJECTIVE_TYPE_GATHER_MULTI


func _refresh_crafting_tutorial_state() -> void:
	var tutorial_target_item := _get_crafting_tutorial_target_item()
	if tutorial_target_item.is_empty():
		if not highlight_crafting_back_button:
			_clear_crafting_tutorial_visuals()
		return
	if current_view == CampView.CRAFTING:
		crafting_category = _get_crafting_tutorial_target_category(tutorial_target_item)


func _update_crafting_tutorial_highlights(delta: float) -> void:
	var tutorial_target_item := _get_crafting_tutorial_target_item()
	if tutorial_target_item.is_empty() and not highlight_crafting_back_button:
		_clear_crafting_tutorial_visuals()
		return
	var pulse := 1.0 + sin(tutorial_highlight_time * 3.9) * 0.035
	_clear_crafting_tutorial_visuals()
	if current_view == CampView.MAIN and not highlight_crafting_back_button and not tutorial_target_item.is_empty():
		_set_objective_highlight(crafting_nav_button, true, pulse)
	if current_view == CampView.CRAFTING and highlight_crafting_back_button:
		_set_objective_highlight(crafting_back_button, true, pulse)
	if current_view == CampView.CRAFTING and not tutorial_target_item.is_empty() and not highlight_crafting_back_button:
		var target_category := _get_crafting_tutorial_target_category(tutorial_target_item)
		var category_button_variant = crafting_browser.get("category_buttons", {}).get(target_category, null)
		if category_button_variant is Button:
			var category_button: Button = category_button_variant
			_set_objective_highlight(category_button, true, pulse)
		var target_card_variant = crafting_card_nodes.get(tutorial_target_item, null)
		if target_card_variant is Button:
			var target_card: Button = target_card_variant
			_set_objective_highlight(target_card, true, pulse)


func _update_collection_tutorial_highlights(delta: float) -> void:
	if not _is_sharp_fang_equip_tutorial_active() and not highlight_collection_back_button:
		_clear_collection_tutorial_visuals()
		return
	_clear_collection_tutorial_visuals()
	var pulse := 1.0 + sin(tutorial_highlight_time * 3.9) * 0.035
	if highlight_collection_back_button:
		if current_view == CampView.COLLECTION:
			_set_objective_highlight(collection_back_button, true, pulse)
		return
	if current_view == CampView.MAIN:
		_set_objective_highlight(collection_nav_button, true, pulse)
		return
	if current_view != CampView.COLLECTION:
		return
	var held_mode_variant = collection_browser.get("mode_buttons", {}).get(GameData.ITEM_CATEGORY_HELD, null)
	if held_mode_variant is Button:
		var held_mode_button: Button = held_mode_variant
		_set_objective_highlight(held_mode_button, true, pulse)
	var sharp_fang_variant = collection_browser_item_nodes.get("sharp_fang", null)
	if sharp_fang_variant is Button:
		var sharp_fang_button: Button = sharp_fang_variant
		_set_objective_highlight(sharp_fang_button, true, pulse)
	var action_variant = collection_browser.get("detail", {}).get("action_button", null)
	if action_variant is Button:
		var equip_button: Button = action_variant
		_set_objective_highlight(equip_button, true, pulse)


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
			selected_creature_source == "party" and index == selected_creature_index
		)
		chip.pressed.connect(select_creature.bind(index, "party"))


func _rebuild_storage_chips() -> void:
	for child in storage_chips.get_children():
		child.queue_free()
	storage_title_label.visible = not GameState.box.is_empty()
	storage_chips.visible = not GameState.box.is_empty()
	if GameState.box.is_empty():
		return
	for index in range(GameState.box.size()):
		var mon: Dictionary = GameState.box[index]
		var chip = CREATURE_CHIP_SCENE.instantiate()
		storage_chips.add_child(chip)
		chip.configure(
			_creature_chip_text(mon),
			_palette_for_element(str(mon.get("element", ""))),
			selected_creature_source == "box" and index == selected_creature_index
		)
		chip.pressed.connect(select_creature.bind(index, "box"))


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


func _refresh_collection_transfer_button(mon: Dictionary) -> void:
	if mon.is_empty():
		collection_transfer_button.text = "Move"
		collection_transfer_button.disabled = true
		return
	if selected_creature_source == "party":
		collection_transfer_button.text = "Move to Storage"
		collection_transfer_button.disabled = false
		return
	collection_transfer_button.text = "Add to Team"
	collection_transfer_button.disabled = GameState.party.size() >= GameState.get_party_limit()


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
		GameState.get_party_limit(),
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
	var was_sharp_fang_tutorial := _is_sharp_fang_equip_tutorial_active() and item_id == "sharp_fang"
	if GameState.equip_held_item(mon, item_id):
		GameState.notify_held_item_equipped(item_id, mon)
		var item_name := str(GameData.get_item_data(item_id).get("name", item_id))
		collection_status_message = "%s equipped %s." % [str(mon.get("name", "Creature")), item_name]
		if was_sharp_fang_tutorial:
			highlight_collection_back_button = true
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


func _transfer_selected_creature() -> void:
	var mon: Dictionary = get_selected_creature()
	if mon.is_empty():
		return
	var creature_name := str(mon.get("name", "Creature"))
	if selected_creature_source == "party":
		var moved: Dictionary = GameState.party.pop_at(selected_creature_index)
		GameState.box.append(moved)
		selected_creature_source = "box"
		selected_creature_index = GameState.box.size() - 1
		collection_status_message = "%s was moved to storage." % creature_name
		_refresh()
		return
	if GameState.party.size() >= GameState.get_party_limit():
		collection_status_message = "Active team is full. Move a team creature to storage first."
		collection_status_label.text = collection_status_message
		return
	var added: Dictionary = GameState.box.pop_at(selected_creature_index)
	GameState.party.append(added)
	selected_creature_source = "party"
	selected_creature_index = GameState.party.size() - 1
	collection_status_message = "%s joined the active team." % creature_name
	_refresh()


func _craft_item(item_id: String) -> void:
	var tutorial_target_item := _get_crafting_tutorial_target_item()
	if not GameState.craft_item(item_id):
		crafting_status_label.text = "Not enough materials to craft %s." % str(GameData.get_item_data(item_id).get("name", item_id))
		crafting_status_label.visible = true
		return
	var item_data := GameData.get_item_data(item_id)
	crafting_status_label.text = "Crafted %s." % str(item_data.get("name", item_id))
	crafting_status_label.visible = true
	main_status_label.text = "%s added to your supplies." % str(item_data.get("name", item_id))
	highlight_crafting_back_button = item_id == tutorial_target_item and not tutorial_target_item.is_empty()
	_refresh()
	if highlight_crafting_back_button and current_view == CampView.CRAFTING:
		var pulse := 1.0 + sin(tutorial_highlight_time * 3.9) * 0.035
		_set_objective_highlight(crafting_back_button, true, pulse)


func _set_collection_mode(mode: String) -> void:
	if _is_sharp_fang_equip_tutorial_active():
		mode = GameData.ITEM_CATEGORY_HELD
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


func _select_collection_item(item_id: String) -> void:
	if _is_sharp_fang_equip_tutorial_active() and item_id != "sharp_fang":
		return
	selected_collection_item_id = item_id
	_refresh_collection_detail()


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


func select_creature(index: int, source: String = "party") -> void:
	var creatures := GameState.party if source == "party" else GameState.box
	if index < 0 or index >= creatures.size():
		return
	selected_creature_source = source
	selected_creature_index = index
	collection_status_message = ""
	_refresh()


func get_selected_creature() -> Dictionary:
	var creatures := GameState.party if selected_creature_source == "party" else GameState.box
	if selected_creature_index < 0 or selected_creature_index >= creatures.size():
		return {}
	return creatures[selected_creature_index]


func _normalize_selected_creature_index() -> void:
	if GameState.party.is_empty() and GameState.box.is_empty():
		selected_creature_index = -1
		return
	if selected_creature_source == "box":
		if GameState.box.is_empty():
			selected_creature_source = "party"
			selected_creature_index = 0 if not GameState.party.is_empty() else -1
			return
		if selected_creature_index < 0 or selected_creature_index >= GameState.box.size():
			selected_creature_index = 0
		return
	if GameState.party.is_empty():
		selected_creature_source = "box"
		selected_creature_index = 0 if not GameState.box.is_empty() else -1
		return
	if selected_creature_index < 0 or selected_creature_index >= GameState.party.size():
		selected_creature_index = 0


func _selected_map_display_name() -> String:
	var map_id := GameState.current_map_id
	return str(GameData.maps.get(map_id, {}).get("display_name", map_id))


func _selected_map_summary_text() -> String:
	if intro_guidance_active:
		return "%s\n%s" % [
			"Global venture objectives",
			INTRO_DOCKED_OBJECTIVE,
		]
	var next_objective := GameState.get_next_global_objective()
	if next_objective.is_empty():
		return "%s is ready for the next venture." % _selected_map_display_name()
	return "%s\nNext objective: %s" % [
		"Global venture objectives",
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

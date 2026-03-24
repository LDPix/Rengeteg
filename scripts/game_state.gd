extends Node

signal objectives_started(objectives: Array)
signal objectives_updated(objectives: Array)
signal primary_objective_completed(objective: Dictionary)
signal map_completion_changed(map_id: String, completed: bool)

# Party: array of creature instances (dicts).
var party: Array = []
var pending_wild_id: String = ""

var current_map_id: String = "verdant_wilds"
var starter_given := false
var battle_return_position: Vector2 = Vector2.ZERO
var battle_return_scene_path: String = ""
var battle_return_map_id: String = ""
var has_battle_return_position := false
var camp_notice: String = ""
var intro_popup_seen_this_session := false
var map_run_active := false
var map_run_materials_snapshot := {}
var current_map_run := {}
var pending_battle_context := {}
var map_completion_state := {}
var objective_completion_history := {}
var global_objective_progression := 0
var first_defeat_explainer_shown := false
var pending_first_defeat_popup := false
var first_boss_warning_shown := false
var ember_unlock_notification_shown := false
var pending_ember_unlock_notification := false
var tutorial_state := {
	"opening_bind_battle_started": false,
	"opening_bind_attempts": 0,
	"opening_bind_completed": false,
	"battle_abilities_popup_shown": false,
}

const BASE_PARTY_LIMIT := 2
const PARTY_MAX := 3
var box: Array = [] # extra captured creatures

# Materials (drops/crafting)
var materials := {
	"wood": 0,
	"herb": 0,
	"stone": 0,
	"crystal": 0,
	"core_shard": 0,
	"species_mat": 0,
}

var item_inventory := {
	"basic_seal": 5,
}
var owned_camp_items := {}

func ensure_starter() -> void:
	if starter_given:
		_normalize_creature_array(party)
		_normalize_creature_array(box)
		_enforce_party_limit()
		return
	if party.is_empty():
		party.append(new_creature_instance("mossling")) # pick your starter id
	_normalize_creature_array(party)
	_normalize_creature_array(box)
	_enforce_party_limit()
	starter_given = true
	
func add_creature_to_collection(mon: Dictionary) -> bool:
	# returns true if it went to party, false if it went to box
	normalize_creature_stats(mon)
	if party.size() < get_party_limit():
		party.append(mon)
		return true
	box.append(mon)
	return false
	
func new_creature_instance(id: String, level: int = GameData.DEFAULT_LEVEL) -> Dictionary:
	return GameData.build_creature_instance(id, level)


func new_wild_creature_instance(id: String, map_id: String = "") -> Dictionary:
	if map_id.is_empty():
		map_id = current_map_id
	return build_wild_creature_instance(id, map_id, pending_battle_context)


func build_wild_creature_instance(id: String, map_id: String = "", context: Dictionary = {}) -> Dictionary:
	if map_id.is_empty():
		map_id = current_map_id
	var level := get_wild_level_for_map(map_id) + int(context.get("level_bonus", 0))
	var creature := new_creature_instance(id, clampi(level, GameData.DEFAULT_LEVEL, GameData.MAX_LEVEL))
	if creature.is_empty():
		return creature
	var stat_multiplier := float(context.get("stat_multiplier", 1.0))
	if stat_multiplier > 0.0 and absf(stat_multiplier - 1.0) > 0.001:
		creature["hp_max"] = max(1, int(round(float(creature["hp_max"]) * stat_multiplier)))
		creature["mp_max"] = max(1, int(round(float(creature.get("mp_max", GameData.get_default_mp())) * stat_multiplier)))
		creature["atk"] = max(1, int(round(float(creature["atk"]) * stat_multiplier)))
		creature["def"] = max(1, int(round(float(creature["def"]) * stat_multiplier)))
		creature["spd"] = max(1, int(round(float(creature.get("spd", 1)) * stat_multiplier)))
		creature["hp"] = creature["hp_max"]
		creature["mp"] = creature["mp_max"]
	var display_name := str(context.get("display_name", ""))
	if not display_name.is_empty():
		creature["name"] = display_name
	var sprite_path := str(context.get("sprite_path", ""))
	if not sprite_path.is_empty():
		creature["sprite_path_override"] = sprite_path
	return creature
	
const SAVE_PATH := "user://savegame.json"

func to_save_dict() -> Dictionary:
	return {
		"party": party,
		"box": box,
		"materials": materials,
		"items": item_inventory,
		"camp_items": owned_camp_items.keys(),
		"map_completion_state": map_completion_state,
		"objective_completion_history": objective_completion_history,
		"global_objective_progression": global_objective_progression,
		"first_defeat_explainer_shown": first_defeat_explainer_shown,
		"first_boss_warning_shown": first_boss_warning_shown,
		"ember_unlock_notification_shown": ember_unlock_notification_shown,
		"tutorial_state": tutorial_state,
	}

func from_save_dict(d: Dictionary) -> void:
	party = d.get("party", [])
	box = d.get("box", [])
	var saved_materials: Dictionary = d.get("materials", {})
	materials = materials.duplicate(true)
	for key in saved_materials.keys():
		materials[key] = saved_materials[key]
	item_inventory = {"basic_seal": 0}
	var saved_items: Dictionary = d.get("items", {})
	for item_id in saved_items.keys():
		item_inventory[str(item_id)] = max(0, int(saved_items.get(item_id, 0)))
	var legacy_seals := int(d.get("seals", 0))
	if legacy_seals > 0:
		item_inventory["basic_seal"] = int(item_inventory.get("basic_seal", 0)) + legacy_seals
	owned_camp_items = {}
	var saved_camp_items: Array = d.get("camp_items", [])
	for item_id in saved_camp_items:
		var resolved_item_id := str(item_id)
		if resolved_item_id == "healing_tent":
			resolved_item_id = "party_tent"
		owned_camp_items[resolved_item_id] = true
	map_completion_state = d.get("map_completion_state", {}).duplicate(true)
	objective_completion_history = d.get("objective_completion_history", {}).duplicate(true)
	global_objective_progression = int(d.get("global_objective_progression", 0))
	first_defeat_explainer_shown = bool(d.get("first_defeat_explainer_shown", false))
	first_boss_warning_shown = bool(d.get("first_boss_warning_shown", false))
	ember_unlock_notification_shown = bool(d.get("ember_unlock_notification_shown", false))
	pending_first_defeat_popup = false
	pending_ember_unlock_notification = false
	tutorial_state = _default_tutorial_state()
	var saved_tutorial_state: Dictionary = d.get("tutorial_state", {})
	for key in saved_tutorial_state.keys():
		tutorial_state[str(key)] = saved_tutorial_state[key]
	if global_objective_progression <= 0:
		var legacy_progression: Dictionary = d.get("map_objective_progression", {})
		global_objective_progression = maxi(
			int(legacy_progression.get("verdant_wilds", 0)),
			int(legacy_progression.get("ember_caves", 0))
		)
	if global_objective_progression > 0:
		tutorial_state["opening_bind_completed"] = true
	_normalize_creature_array(party)
	_normalize_creature_array(box)
	_enforce_party_limit()

func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_save_dict()))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	from_save_dict(parsed)
	return true


func ensure_creature_progression_fields(creature: Dictionary) -> void:
	normalize_creature_stats(creature)


func ensure_combat_fields(creature: Dictionary) -> void:
	normalize_creature_stats(creature)


func ensure_creature_ability_fields(creature: Dictionary) -> void:
	normalize_creature_stats(creature)


func normalize_creature_stats(creature: Dictionary) -> void:
	var creature_id := str(creature.get("id", ""))
	var base_data := GameData.get_creature_data(creature_id)
	if base_data.is_empty():
		return

	var previous_hp_max := int(creature.get("hp_max", int(base_data.get("base_hp", 1))))
	var previous_hp := int(creature.get("hp", previous_hp_max))
	var missing_hp: int = max(0, previous_hp_max - previous_hp)
	var level := clampi(int(creature.get("level", GameData.DEFAULT_LEVEL)), GameData.DEFAULT_LEVEL, GameData.MAX_LEVEL)
	var initial_stats := GameData.get_stats_for_level(creature_id, level)
	var previous_mp_max := int(creature.get("mp_max", int(initial_stats.get("mp_max", base_data.get("base_mp", GameData.get_default_mp())))))
	var previous_mp := int(creature.get("mp", previous_mp_max))
	var missing_mp: int = max(0, previous_mp_max - previous_mp)
	var min_exp := GameData.get_total_exp_for_level(level)
	var exp: int = max(int(creature.get("exp", min_exp)), min_exp)
	while level < GameData.MAX_LEVEL and exp >= GameData.get_total_exp_for_level(level + 1):
		level += 1

	var stats := GameData.get_stats_for_level(creature_id, level)
	var normalized_abilities: Array[String] = []
	var raw_abilities: Array = creature.get("abilities", GameData.get_default_ability_ids(creature_id))
	for ability_id in raw_abilities:
		var resolved_ability_id := str(ability_id)
		if not resolved_ability_id.is_empty():
			normalized_abilities.append(resolved_ability_id)
	creature["id"] = creature_id
	creature["name"] = str(base_data.get("name", creature.get("name", creature_id.capitalize())))
	creature["element"] = str(base_data.get("element", creature.get("element", "neutral")))
	creature["level"] = level
	creature["exp"] = exp
	creature["passive_id"] = str(creature.get("passive_id", GameData.get_default_passive_id(creature_id)))
	creature["abilities"] = normalized_abilities if not normalized_abilities.is_empty() else GameData.get_default_ability_ids(creature_id)
	creature["held_item_id"] = _sanitize_held_item_id(str(creature.get("held_item_id", "")))
	creature["hp_max"] = int(stats.get("hp_max", previous_hp_max))
	creature["mp_max"] = int(stats.get("mp_max", previous_mp_max))
	creature["atk"] = int(stats.get("atk", int(base_data.get("base_atk", 1))))
	creature["def"] = int(stats.get("def", int(base_data.get("base_def", 1))))
	creature["spd"] = int(stats.get("spd", int(base_data.get("base_spd", 8))))
	creature["acc"] = int(stats.get("acc", GameData.get_default_acc()))
	creature["eva"] = int(stats.get("eva", GameData.get_default_eva()))
	creature["crit"] = int(stats.get("crit", GameData.get_default_crit()))
	creature["hp"] = clampi(int(creature["hp_max"]) - missing_hp, 0, get_effective_creature_stat(creature, "hp_max"))
	creature["mp"] = clampi(int(creature["mp_max"]) - missing_mp, 0, get_effective_creature_stat(creature, "mp_max"))


func get_wild_level_for_map(map_id: String) -> int:
	var map_data: Dictionary = GameData.maps.get(map_id, {})
	var configured_range: Vector2i = map_data.get("wild_level_range", Vector2i(GameData.DEFAULT_LEVEL, GameData.DEFAULT_LEVEL))
	var min_level := clampi(configured_range.x, GameData.DEFAULT_LEVEL, GameData.MAX_LEVEL)
	var max_level := clampi(max(configured_range.x, configured_range.y), min_level, GameData.MAX_LEVEL)
	if min_level == max_level:
		return min_level
	return randi_range(min_level, max_level)


func add_exp_to_creature(creature: Dictionary, amount: int) -> Dictionary:
	ensure_creature_progression_fields(creature)
	if amount <= 0:
		return {
			"exp_gained": 0,
			"levels_gained": 0,
			"new_level": int(creature.get("level", GameData.DEFAULT_LEVEL)),
			"exp_to_next": GameData.get_exp_to_next_level(int(creature.get("level", GameData.DEFAULT_LEVEL))),
		}

	var old_level := int(creature.get("level", GameData.DEFAULT_LEVEL))
	creature["exp"] = int(creature.get("exp", 0)) + amount
	var new_level := old_level
	while new_level < GameData.MAX_LEVEL and int(creature["exp"]) >= GameData.get_total_exp_for_level(new_level + 1):
		new_level += 1
	if new_level != old_level:
		creature["level"] = new_level
		_refresh_creature_stats(creature)

	return {
		"exp_gained": amount,
		"levels_gained": new_level - old_level,
		"new_level": new_level,
		"exp_to_next": max(0, GameData.get_total_exp_for_level(min(new_level + 1, GameData.MAX_LEVEL)) - int(creature["exp"])),
	}


func apply_level_up(creature: Dictionary) -> void:
	if not (creature is Dictionary):
		return
	var creature_id := str(creature.get("id", ""))
	if GameData.get_creature_data(creature_id).is_empty():
		return
	var next_level: int = min(int(creature["level"]) + 1, GameData.MAX_LEVEL)
	if next_level == int(creature["level"]):
		return
	creature["level"] = next_level
	_refresh_creature_stats(creature)


func _refresh_creature_stats(creature: Dictionary) -> void:
	var creature_id := str(creature.get("id", ""))
	var stats := GameData.get_stats_for_level(creature_id, int(creature.get("level", GameData.DEFAULT_LEVEL)))
	if stats.is_empty():
		return
	var old_hp_max := int(creature.get("hp_max", stats["hp_max"]))
	var missing_hp: int = max(0, old_hp_max - int(creature.get("hp", old_hp_max)))
	var old_mp_max := int(creature.get("mp_max", stats.get("mp_max", GameData.get_default_mp())))
	var missing_mp: int = max(0, old_mp_max - int(creature.get("mp", old_mp_max)))
	creature["hp_max"] = int(stats["hp_max"])
	creature["mp_max"] = int(stats.get("mp_max", creature.get("mp_max", GameData.get_default_mp())))
	creature["atk"] = int(stats["atk"])
	creature["def"] = int(stats["def"])
	creature["spd"] = int(stats.get("spd", creature.get("spd", 1)))
	creature["acc"] = int(stats.get("acc", creature.get("acc", GameData.get_default_acc())))
	creature["eva"] = int(stats.get("eva", creature.get("eva", GameData.get_default_eva())))
	creature["crit"] = int(stats.get("crit", creature.get("crit", GameData.get_default_crit())))
	creature["held_item_id"] = _sanitize_held_item_id(str(creature.get("held_item_id", "")))
	creature["hp"] = clampi(int(creature["hp_max"]) - missing_hp, 0, get_effective_creature_stat(creature, "hp_max"))
	creature["mp"] = clampi(int(creature["mp_max"]) - missing_mp, 0, get_effective_creature_stat(creature, "mp_max"))


func get_creature_abilities(creature: Dictionary) -> Array[String]:
	ensure_creature_ability_fields(creature)
	var result: Array[String] = []
	for ability_id in creature.get("abilities", []):
		result.append(str(ability_id))
	return result


func can_use_ability(creature: Dictionary, ability_id: String) -> bool:
	ensure_creature_ability_fields(creature)
	var ability := GameData.get_ability_data(ability_id)
	if ability.is_empty():
		return false
	return int(creature.get("mp", 0)) >= int(ability.get("mp_cost", 0))


func spend_mp(creature: Dictionary, amount: int) -> void:
	ensure_creature_ability_fields(creature)
	creature["mp"] = max(0, int(creature.get("mp", 0)) - amount)


func restore_mp(creature: Dictionary, amount: int) -> void:
	ensure_creature_ability_fields(creature)
	creature["mp"] = clampi(int(creature.get("mp", 0)) + amount, 0, get_effective_creature_stat(creature, "mp_max"))


func restore_hp(creature: Dictionary, amount: int) -> void:
	ensure_creature_ability_fields(creature)
	creature["hp"] = clampi(int(creature.get("hp", 0)) + amount, 0, get_effective_creature_stat(creature, "hp_max"))


func get_item_data(item_id: String) -> Dictionary:
	return GameData.get_item_data(item_id)


func get_all_items() -> Dictionary:
	return GameData.get_all_items()


func get_item_count(item_id: String) -> int:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return 0
	if str(item_data.get("category", "")) == GameData.ITEM_CATEGORY_CAMP:
		return 1 if owned_camp_items.has(item_id) else 0
	return max(0, int(item_inventory.get(item_id, 0)))


func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return false
	if str(item_data.get("category", "")) == GameData.ITEM_CATEGORY_CAMP:
		owned_camp_items[item_id] = true
		return true
	item_inventory[item_id] = get_item_count(item_id) + amount
	return true


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return false
	if str(item_data.get("category", "")) == GameData.ITEM_CATEGORY_CAMP:
		if not owned_camp_items.has(item_id):
			return false
		owned_camp_items.erase(item_id)
		return true
	if get_item_count(item_id) < amount:
		return false
	item_inventory[item_id] = get_item_count(item_id) - amount
	if int(item_inventory.get(item_id, 0)) <= 0:
		item_inventory.erase(item_id)
	return true


func get_recipe(item_id: String) -> Dictionary:
	return GameData.get_item_recipe(item_id)


func can_craft(item_id: String) -> bool:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return false
	if str(item_data.get("category", "")) == GameData.ITEM_CATEGORY_CAMP and owned_camp_items.has(item_id):
		return false
	var recipe := get_recipe(item_id)
	if recipe.is_empty():
		return false
	for material_id in recipe.keys():
		if int(materials.get(material_id, 0)) < int(recipe.get(material_id, 0)):
			return false
	return true


func craft_item(item_id: String) -> bool:
	if not can_craft(item_id):
		return false
	var recipe := get_recipe(item_id)
	for material_id in recipe.keys():
		materials[material_id] = int(materials.get(material_id, 0)) - int(recipe.get(material_id, 0))
	add_item(item_id, 1)
	notify_item_crafted(item_id, 1)
	return true


func get_creature_held_item(creature: Dictionary) -> Dictionary:
	var item_id := _sanitize_held_item_id(str(creature.get("held_item_id", "")))
	return get_item_data(item_id)


func equip_held_item(creature: Dictionary, item_id: String) -> bool:
	var item_data := get_item_data(item_id)
	if item_data.is_empty() or str(item_data.get("category", "")) != GameData.ITEM_CATEGORY_HELD:
		return false
	if get_item_count(item_id) <= 0:
		return false
	var previous_effective_hp_max := get_effective_creature_stat(creature, "hp_max")
	var previous_effective_mp_max := get_effective_creature_stat(creature, "mp_max")
	var previous_item_id := _sanitize_held_item_id(str(creature.get("held_item_id", "")))
	if not previous_item_id.is_empty():
		add_item(previous_item_id, 1)
	remove_item(item_id, 1)
	creature["held_item_id"] = item_id
	_adjust_creature_resources_after_loadout_change(creature, previous_effective_hp_max, previous_effective_mp_max)
	return true


func unequip_held_item(creature: Dictionary) -> bool:
	var previous_item_id := _sanitize_held_item_id(str(creature.get("held_item_id", "")))
	if previous_item_id.is_empty():
		return false
	var previous_effective_hp_max := get_effective_creature_stat(creature, "hp_max")
	var previous_effective_mp_max := get_effective_creature_stat(creature, "mp_max")
	add_item(previous_item_id, 1)
	creature["held_item_id"] = ""
	_adjust_creature_resources_after_loadout_change(creature, previous_effective_hp_max, previous_effective_mp_max)
	return true


func apply_held_item_modifiers(creature: Dictionary) -> Dictionary:
	var modifiers := {}
	var item_data := get_creature_held_item(creature)
	if item_data.is_empty():
		return modifiers
	var effects: Array = item_data.get("held_effects", [])
	for raw_effect in effects:
		if not (raw_effect is Dictionary):
			continue
		var effect: Dictionary = raw_effect
		if str(effect.get("type", "")) != "flat_stat":
			continue
		var stat_name := str(effect.get("stat", ""))
		if stat_name.is_empty():
			continue
		modifiers[stat_name] = int(modifiers.get(stat_name, 0)) + int(effect.get("amount", 0))
	return modifiers


func get_effective_creature_stat(creature: Dictionary, stat_name: String) -> int:
	var base_value := int(creature.get(stat_name, _get_stat_default(stat_name)))
	var held_modifiers := apply_held_item_modifiers(creature)
	return max(0, base_value + int(held_modifiers.get(stat_name, 0)))


func get_effective_creature_stats(creature: Dictionary) -> Dictionary:
	var result := {
		"hp_max": get_effective_creature_stat(creature, "hp_max"),
		"mp_max": get_effective_creature_stat(creature, "mp_max"),
		"atk": get_effective_creature_stat(creature, "atk"),
		"def": get_effective_creature_stat(creature, "def"),
		"spd": get_effective_creature_stat(creature, "spd"),
		"acc": get_effective_creature_stat(creature, "acc"),
		"eva": get_effective_creature_stat(creature, "eva"),
		"crit": get_effective_creature_stat(creature, "crit"),
	}
	return result


func use_consumable_on_creature(item_id: String, creature: Dictionary) -> bool:
	var item_data := get_item_data(item_id)
	if item_data.is_empty() or str(item_data.get("category", "")) != GameData.ITEM_CATEGORY_CONSUMABLE:
		return false
	if get_item_count(item_id) <= 0:
		return false
	var effects: Array = item_data.get("use_effects", [])
	var changed := false
	for raw_effect in effects:
		if not (raw_effect is Dictionary):
			continue
		var effect: Dictionary = raw_effect
		match str(effect.get("type", "")):
			"restore_hp":
				var before_hp := int(creature.get("hp", 0))
				restore_hp(creature, int(effect.get("amount", 0)))
				changed = changed or int(creature.get("hp", 0)) != before_hp
			"restore_mp":
				var before_mp := int(creature.get("mp", 0))
				restore_mp(creature, int(effect.get("amount", 0)))
				changed = changed or int(creature.get("mp", 0)) != before_mp
	if not changed:
		return false
	return remove_item(item_id, 1)


func get_owned_camp_items() -> Array[String]:
	var owned: Array[String] = []
	for item_id in owned_camp_items.keys():
		owned.append(str(item_id))
	owned.sort()
	return owned


func get_owned_items_by_category(category: String, owned_only: bool = true) -> Array[String]:
	var item_ids := GameData.get_item_ids_by_category(category)
	var results: Array[String] = []
	for item_id in item_ids:
		if not owned_only or get_item_count(item_id) > 0:
			results.append(item_id)
	return results


func get_craftable_items_by_category(category: String, craftable_only: bool = true) -> Array[String]:
	var item_ids := GameData.get_item_ids_by_category(category)
	var results: Array[String] = []
	for item_id in item_ids:
		if not craftable_only or can_craft(item_id):
			results.append(item_id)
	return results


func has_camp_item(item_id: String) -> bool:
	return owned_camp_items.has(item_id)


func get_party_limit() -> int:
	return clampi(BASE_PARTY_LIMIT + get_camp_effect_value("party_limit"), BASE_PARTY_LIMIT, PARTY_MAX)


func get_camp_effect_value(effect_type: String) -> int:
	var total := 0
	for item_id in get_owned_camp_items():
		var item_data := get_item_data(item_id)
		var effects: Array = item_data.get("camp_effects", [])
		for raw_effect in effects:
			if not (raw_effect is Dictionary):
				continue
			var effect: Dictionary = raw_effect
			if str(effect.get("type", "")) == effect_type:
				total += int(effect.get("amount", 0))
	return total


func _normalize_creature_array(creatures: Array) -> void:
	for creature in creatures:
		if creature is Dictionary:
			ensure_creature_progression_fields(creature)


func _enforce_party_limit() -> void:
	while party.size() > get_party_limit():
		box.insert(0, party.pop_back())


func set_battle_return(map_id: String, scene_path: String, world_position: Vector2) -> void:
	battle_return_map_id = map_id
	battle_return_scene_path = scene_path
	battle_return_position = world_position
	has_battle_return_position = true


func clear_battle_return() -> void:
	battle_return_map_id = ""
	battle_return_scene_path = ""
	battle_return_position = Vector2.ZERO
	has_battle_return_position = false


func begin_map_run() -> void:
	map_run_active = true
	map_run_materials_snapshot = materials.duplicate(true)
	current_map_run = {}
	pending_battle_context = {}
	clear_battle_return()
	pending_wild_id = ""


func end_map_run() -> void:
	map_run_active = false
	map_run_materials_snapshot = {}
	current_map_run = {}
	pending_battle_context = {}
	clear_battle_return()
	pending_wild_id = ""
	_emit_objectives_updated()


func forfeit_current_map_run() -> void:
	if map_run_active:
		materials = map_run_materials_snapshot.duplicate(true)
	end_map_run()


func set_camp_notice(message: String) -> void:
	camp_notice = message


func consume_camp_notice() -> String:
	var message := camp_notice
	camp_notice = ""
	return message


func queue_first_defeat_popup() -> void:
	if first_defeat_explainer_shown:
		return
	pending_first_defeat_popup = true


func consume_first_defeat_popup() -> bool:
	if not pending_first_defeat_popup:
		return false
	pending_first_defeat_popup = false
	first_defeat_explainer_shown = true
	return true


func queue_ember_unlock_notification() -> void:
	if ember_unlock_notification_shown:
		return
	pending_ember_unlock_notification = true


func consume_ember_unlock_notification() -> bool:
	if not pending_ember_unlock_notification:
		return false
	pending_ember_unlock_notification = false
	ember_unlock_notification_shown = true
	return true


func set_current_map_run(map_id: String, run_data: Dictionary) -> void:
	var previous_objectives: Array = current_map_run.get("objectives", []).duplicate(true)
	var previous_metadata: Dictionary = current_map_run.get("objective_metadata", {}).duplicate(true)
	current_map_run = run_data.duplicate(true)
	current_map_run["map_id"] = map_id
	if not current_map_run.has("harvested_spawn_ids"):
		current_map_run["harvested_spawn_ids"] = []
	if not current_map_run.has("cleared_boss_ids"):
		current_map_run["cleared_boss_ids"] = []
	if not current_map_run.has("interacted_poi_ids"):
		current_map_run["interacted_poi_ids"] = []
	if not current_map_run.has("run_flags"):
		current_map_run["run_flags"] = {}
	if not current_map_run.has("run_bonuses"):
		current_map_run["run_bonuses"] = {}
	if previous_objectives.is_empty():
		start_objectives_for_map(map_id)
	else:
		current_map_run["objectives"] = previous_objectives
		current_map_run["objective_metadata"] = previous_metadata
		_emit_objectives_updated()


func get_current_map_run(map_id: String = "") -> Dictionary:
	if map_id.is_empty():
		map_id = current_map_id
	if str(current_map_run.get("map_id", "")) != map_id:
		return {}
	return current_map_run


func mark_resource_spawn_harvested(spawn_id: String) -> void:
	if spawn_id.is_empty():
		return
	var harvested: Array = current_map_run.get("harvested_spawn_ids", [])
	if not harvested.has(spawn_id):
		harvested.append(spawn_id)
		current_map_run["harvested_spawn_ids"] = harvested


func is_resource_spawn_harvested(spawn_id: String) -> bool:
	var harvested: Array = current_map_run.get("harvested_spawn_ids", [])
	return harvested.has(spawn_id)


func mark_boss_cleared(boss_spawn_id: String) -> void:
	if boss_spawn_id.is_empty():
		return
	var cleared: Array = current_map_run.get("cleared_boss_ids", [])
	if not cleared.has(boss_spawn_id):
		cleared.append(boss_spawn_id)
		current_map_run["cleared_boss_ids"] = cleared


func is_boss_cleared(boss_spawn_id: String) -> bool:
	var cleared: Array = current_map_run.get("cleared_boss_ids", [])
	return cleared.has(boss_spawn_id)


func mark_poi_interacted(poi_id: String) -> void:
	if poi_id.is_empty():
		return
	var interacted: Array = current_map_run.get("interacted_poi_ids", [])
	if not interacted.has(poi_id):
		interacted.append(poi_id)
		current_map_run["interacted_poi_ids"] = interacted


func is_poi_interacted(poi_id: String) -> bool:
	var interacted: Array = current_map_run.get("interacted_poi_ids", [])
	return interacted.has(poi_id)


func set_run_flag(flag_id: String, value) -> void:
	if flag_id.is_empty():
		return
	var flags: Dictionary = current_map_run.get("run_flags", {}).duplicate(true)
	flags[flag_id] = value
	current_map_run["run_flags"] = flags


func get_run_flag(flag_id: String, default_value = null):
	var flags: Dictionary = current_map_run.get("run_flags", {})
	return flags.get(flag_id, default_value)


func has_run_flag(flag_id: String) -> bool:
	return bool(get_run_flag(flag_id, false))


func add_run_bonus(bonus_id: String, amount: float) -> void:
	if bonus_id.is_empty() or absf(amount) <= 0.001:
		return
	var bonuses: Dictionary = current_map_run.get("run_bonuses", {}).duplicate(true)
	bonuses[bonus_id] = float(bonuses.get(bonus_id, 0.0)) + amount
	current_map_run["run_bonuses"] = bonuses


func get_run_bonus(bonus_id: String, default_value: float = 0.0) -> float:
	var bonuses: Dictionary = current_map_run.get("run_bonuses", {})
	return float(bonuses.get(bonus_id, default_value))


func set_pending_battle(wild_id: String, context: Dictionary = {}) -> void:
	pending_wild_id = wild_id
	pending_battle_context = context.duplicate(true)


func consume_pending_battle_context() -> Dictionary:
	var context := pending_battle_context.duplicate(true)
	pending_battle_context = {}
	return context


func award_materials(material_drops: Dictionary) -> void:
	for material in material_drops.keys():
		materials[material] = int(materials.get(material, 0)) + int(material_drops.get(material, 0))


func award_gathered_materials(material_drops: Dictionary) -> void:
	award_materials(material_drops)
	for material in material_drops.keys():
		var amount := int(material_drops.get(material, 0))
		if amount > 0:
			notify_material_gathered(str(material), amount)


func award_reward_bundle(reward_bundle: Dictionary) -> Dictionary:
	var awarded := {
		"materials": {},
		"items": {},
	}
	if reward_bundle.is_empty():
		return awarded
	var material_drops: Dictionary = reward_bundle.get("materials", {})
	if not material_drops.is_empty():
		award_gathered_materials(material_drops)
		awarded["materials"] = material_drops.duplicate(true)
	var item_drops: Dictionary = reward_bundle.get("items", {})
	if not item_drops.is_empty():
		var awarded_items: Dictionary = {}
		for item_id in item_drops.keys():
			var amount: int = maxi(0, int(item_drops.get(item_id, 0)))
			if amount <= 0:
				continue
			if add_item(str(item_id), amount):
				awarded_items[str(item_id)] = amount
		awarded["items"] = awarded_items
	return awarded


func claim_resource_node_reward(reward_data: Dictionary) -> Dictionary:
	if reward_data.is_empty():
		return {}
	var rewards: Dictionary = reward_data.get("materials", {}).duplicate(true)
	if not rewards.is_empty():
		award_gathered_materials(rewards)
	var spawn_id := str(reward_data.get("spawn_id", ""))
	if not spawn_id.is_empty():
		mark_resource_spawn_harvested(spawn_id)
	return rewards


func start_objectives_for_map(map_id: String) -> void:
	var progression_index := get_global_objective_progression()
	var objective_set := GameData.get_global_objective_set(progression_index, map_id)
	var objectives: Array = []
	for definition in objective_set.get("objectives", []):
		if not (definition is Dictionary):
			continue
		var objective: Dictionary = GameData.build_objective_definition(definition)
		objective["current_amount"] = 0
		objective["completed"] = false
		objective["completed_at"] = ""
		if str(objective.get("type", "")) == GameData.OBJECTIVE_TYPE_GATHER_MULTI:
			var target_mats: Dictionary = objective.get("target_materials", {})
			var current_mats: Dictionary = {}
			var satisfied: int = 0
			for mat in target_mats:
				var mat_str := str(mat)
				var have: int = mini(int(target_mats.get(mat_str, 0)), int(materials.get(mat_str, 0)))
				current_mats[mat_str] = have
				if have >= int(target_mats.get(mat_str, 0)):
					satisfied += 1
			objective["current_materials"] = current_mats
			objective["current_amount"] = satisfied
		objectives.append(objective)
	current_map_run["objectives"] = objectives
	current_map_run["objective_metadata"] = {
		"set_id": str(objective_set.get("id", "")),
		"source": str(objective_set.get("source", "")),
		"progression_index": progression_index,
	}
	for i in range(objectives.size()):
		var obj: Dictionary = objectives[i]
		if str(obj.get("type", "")) == GameData.OBJECTIVE_TYPE_GATHER_MULTI:
			if int(obj.get("current_amount", 0)) >= int(obj.get("target_amount", 1)):
				_complete_objective_at_index(i, obj)
	emit_signal("objectives_started", get_current_objectives())
	_emit_objectives_updated()


func reset_run_objectives() -> void:
	if current_map_run.has("objectives"):
		current_map_run.erase("objectives")
	if current_map_run.has("objective_metadata"):
		current_map_run.erase("objective_metadata")
	_emit_objectives_updated()


func get_current_objectives() -> Array:
	var objectives: Array = current_map_run.get("objectives", [])
	var result: Array = []
	for objective in objectives:
		if objective is Dictionary:
			var objective_dict: Dictionary = objective
			result.append(objective_dict.duplicate(true))
	return result


func get_primary_objective() -> Dictionary:
	for objective in current_map_run.get("objectives", []):
		if objective is Dictionary and bool(objective.get("is_primary", false)):
			var objective_dict: Dictionary = objective
			return objective_dict.duplicate(true)
	return {}


func is_primary_objective_complete() -> bool:
	var primary := get_primary_objective()
	return not primary.is_empty() and bool(primary.get("completed", false))


func get_objective_display_text(objective: Dictionary) -> String:
	var title := str(objective.get("title", "Objective"))
	var current_amount := int(objective.get("current_amount", 0))
	var target_amount: int = maxi(1, int(objective.get("target_amount", 1)))
	var objective_type := str(objective.get("type", ""))
	if objective_type == GameData.OBJECTIVE_TYPE_BOSS_DEFEAT or objective_type == GameData.OBJECTIVE_TYPE_ENTER_GRASS or objective_type == GameData.OBJECTIVE_TYPE_TUTORIAL_BIND or objective_type == GameData.OBJECTIVE_TYPE_GATHER_MULTI:
		return "%s%s" % [title, " Complete" if bool(objective.get("completed", false)) else ""]
	return "%s %d/%d%s" % [
		title,
		current_amount,
		target_amount,
		" Complete" if bool(objective.get("completed", false)) else "",
	]


func complete_objective(objective_id: String) -> void:
	var objectives: Array = current_map_run.get("objectives", [])
	for index in range(objectives.size()):
		var objective: Dictionary = objectives[index]
		if str(objective.get("id", "")) != objective_id:
			continue
		_complete_objective_at_index(index, objective)
		return


func notify_material_gathered(material_id: String, amount: int) -> void:
	update_objective_progress("material_gathered", {
		"material_id": material_id,
		"amount": amount,
	})


func notify_item_crafted(item_id: String, amount: int) -> void:
	update_objective_progress("item_crafted", {
		"item_id": item_id,
		"amount": amount,
	})
	_try_advance_off_run_objective("item_crafted", {
		"item_id": item_id,
		"amount": amount,
	})


func notify_creature_captured(creature_data: Dictionary) -> void:
	if is_opening_bind_tutorial_active():
		tutorial_state["opening_bind_completed"] = true
	update_objective_progress("creature_captured", {
		"creature_id": str(creature_data.get("id", "")),
		"amount": 1,
	})


func notify_entered_grass(encounter_tag: String) -> void:
	update_objective_progress("entered_grass", {
		"encounter_tag": encounter_tag,
		"amount": 1,
	})


func notify_battle_won(battle_result: Dictionary = {}) -> void:
	update_objective_progress("battle_won", {
		"amount": int(battle_result.get("amount", 1)),
		"is_boss": bool(battle_result.get("is_boss", false)),
		"map_id": str(battle_result.get("map_id", current_map_id)),
	})


func notify_held_item_equipped(item_id: String, creature_data: Dictionary = {}) -> void:
	update_objective_progress("held_item_equipped", {
		"amount": 1,
		"item_id": item_id,
		"creature_id": str(creature_data.get("id", "")),
	})
	_try_advance_off_run_objective("held_item_equipped", {
		"amount": 1,
		"item_id": item_id,
		"creature_id": str(creature_data.get("id", "")),
	})


func notify_boss_defeated(map_id: String) -> void:
	update_objective_progress("boss_defeated", {
		"amount": 1,
		"map_id": map_id,
	})
	_mark_map_completed(map_id)


func update_objective_progress(event_type: String, payload: Dictionary = {}) -> void:
	var objectives: Array = current_map_run.get("objectives", [])
	if objectives.is_empty():
		return
	var changed := false
	for index in range(objectives.size()):
		var objective: Dictionary = objectives[index]
		if bool(objective.get("completed", false)):
			continue
		if not _objective_matches_event(objective, event_type, payload):
			continue
		var previous_amount := int(objective.get("current_amount", 0))
		var target_amount: int = int(objective.get("target_amount", 1))
		var next_amount: int = mini(target_amount, previous_amount + int(payload.get("amount", 1)))
		if str(objective.get("type", "")) == GameData.OBJECTIVE_TYPE_GATHER_MULTI:
			var mat_id := str(payload.get("material_id", ""))
			var target_mats: Dictionary = objective.get("target_materials", {})
			var current_mats: Dictionary = objective.get("current_materials", {}).duplicate(true)
			var mat_target: int = int(target_mats.get(mat_id, 0))
			var mat_current: int = int(current_mats.get(mat_id, 0))
			current_mats[mat_id] = mini(mat_target, mat_current + int(payload.get("amount", 1)))
			objective["current_materials"] = current_mats
			var satisfied: int = 0
			for mat in target_mats:
				if int(current_mats.get(str(mat), 0)) >= int(target_mats.get(str(mat), 0)):
					satisfied += 1
			next_amount = satisfied
		if str(objective.get("type", "")) == GameData.OBJECTIVE_TYPE_TUTORIAL_BIND:
			next_amount = _get_tutorial_bind_progress(objective, event_type)
			if event_type == "entered_grass":
				objective["entered_grass_done"] = true
			elif event_type == "creature_captured":
				objective["bound_creature_done"] = true
		objective["current_amount"] = next_amount
		objectives[index] = objective
		changed = changed or next_amount != previous_amount
		if next_amount >= int(objective.get("target_amount", 1)):
			_complete_objective_at_index(index, objective)
			changed = true
	current_map_run["objectives"] = objectives
	if changed:
		_emit_objectives_updated()


func has_completed_objective_before(objective_id: String) -> bool:
	return int(objective_completion_history.get(objective_id, 0)) > 0


func get_global_objective_progression() -> int:
	return maxi(0, global_objective_progression)


func is_map_completed(map_id: String) -> bool:
	var state: Dictionary = map_completion_state.get(map_id, {})
	return bool(state.get("completed", false))


func has_completed_map_boss_before(map_id: String) -> bool:
	return is_map_completed(map_id)


func is_map_unlocked(map_id: String) -> bool:
	var unlock_condition: Dictionary = GameData.get_map_unlock_condition(map_id)
	match str(unlock_condition.get("type", "always")):
		"always":
			return true
		"map_boss_defeated":
			return has_completed_map_boss_before(str(unlock_condition.get("map_id", "")))
	return true


func get_unlocked_map_ids() -> Array[String]:
	var unlocked: Array[String] = []
	for map_id in GameData.maps.keys():
		var resolved_map_id := str(map_id)
		if is_map_unlocked(resolved_map_id):
			unlocked.append(resolved_map_id)
	return unlocked


func ensure_current_map_is_unlocked() -> void:
	if is_map_unlocked(current_map_id):
		return
	var unlocked_maps := get_unlocked_map_ids()
	current_map_id = "verdant_wilds" if unlocked_maps.is_empty() else unlocked_maps[0]


func get_next_global_objective() -> Dictionary:
	var objective_set := GameData.get_global_objective_set(get_global_objective_progression(), current_map_id)
	var objectives: Array = objective_set.get("objectives", [])
	if objectives.is_empty():
		return {}
	return GameData.build_objective_definition(objectives[0])


func get_active_or_next_primary_objective() -> Dictionary:
	if map_run_active:
		var current_primary := get_primary_objective()
		if not current_primary.is_empty():
			return current_primary
	return get_next_global_objective()


func should_suppress_resource_node_encounter(resource_type: String) -> bool:
	var primary := get_active_or_next_primary_objective()
	if str(primary.get("type", "")) != GameData.OBJECTIVE_TYPE_GATHER:
		return false
	var target_id := str(primary.get("target_id", ""))
	return (target_id == "wood" and resource_type == "wood") or (target_id == "herb" and resource_type == "herb")


func _objective_matches_event(objective: Dictionary, event_type: String, payload: Dictionary) -> bool:
	match str(objective.get("type", "")):
		GameData.OBJECTIVE_TYPE_GATHER:
			return event_type == "material_gathered" and str(objective.get("target_id", "")) == str(payload.get("material_id", ""))
		GameData.OBJECTIVE_TYPE_GATHER_MULTI:
			return event_type == "material_gathered" and objective.get("target_materials", {}).has(str(payload.get("material_id", "")))
		GameData.OBJECTIVE_TYPE_CRAFT:
			return event_type == "item_crafted" and str(objective.get("target_id", "")) == str(payload.get("item_id", ""))
		GameData.OBJECTIVE_TYPE_EQUIP_HELD_ITEM:
			return event_type == "held_item_equipped" and str(objective.get("target_id", "")) == str(payload.get("item_id", ""))
		GameData.OBJECTIVE_TYPE_CAPTURE:
			return event_type == "creature_captured"
		GameData.OBJECTIVE_TYPE_TUTORIAL_BIND:
			return event_type == "entered_grass" or event_type == "creature_captured"
		GameData.OBJECTIVE_TYPE_ENTER_GRASS:
			return event_type == "entered_grass"
		GameData.OBJECTIVE_TYPE_BATTLE_WIN:
			return event_type == "battle_won" \
				and not bool(payload.get("is_boss", false)) \
				and (
					str(objective.get("target_map_id", "")).is_empty() \
					or str(objective.get("target_map_id", "")) == str(payload.get("map_id", current_map_id))
				)
		GameData.OBJECTIVE_TYPE_BOSS_DEFEAT:
			return event_type == "boss_defeated"
	return false


func _complete_objective_at_index(index: int, objective: Dictionary) -> void:
	if bool(objective.get("completed", false)):
		return
	objective["current_amount"] = int(objective.get("target_amount", 1))
	objective["completed"] = true
	objective["completed_at"] = Time.get_datetime_string_from_system()
	var objectives: Array = current_map_run.get("objectives", [])
	objectives[index] = objective
	current_map_run["objectives"] = objectives
	var objective_id := str(objective.get("id", ""))
	if not objective_id.is_empty():
		objective_completion_history[objective_id] = int(objective_completion_history.get(objective_id, 0)) + 1
	if bool(objective.get("is_primary", false)):
		advance_objective_progression_for_current_run()
		emit_signal("primary_objective_completed", objective.duplicate(true))
		if map_run_active:
			call_deferred("_start_next_objective_set_for_active_run")


func _start_next_objective_set_for_active_run() -> void:
	if not map_run_active:
		return
	var map_id := str(current_map_run.get("map_id", current_map_id))
	if map_id.is_empty():
		map_id = current_map_id
	var next_set := GameData.get_global_objective_set(get_global_objective_progression(), map_id)
	if str(next_set.get("source", "")) != "global_sequence":
		return
	start_objectives_for_map(map_id)


func advance_objective_progression_for_current_run() -> void:
	var metadata: Dictionary = current_map_run.get("objective_metadata", {})
	if str(metadata.get("source", "")) != "global_sequence":
		return
	var next_index := int(metadata.get("progression_index", 0)) + 1
	if next_index > get_global_objective_progression():
		global_objective_progression = next_index


func _mark_map_completed(map_id: String) -> void:
	if map_id.is_empty():
		return
	var state: Dictionary = map_completion_state.get(map_id, {}).duplicate(true)
	var was_completed := bool(state.get("completed", false))
	state["completed"] = true
	if not state.has("first_completed_at"):
		state["first_completed_at"] = Time.get_datetime_string_from_system()
	state["boss_objective_completed"] = true
	map_completion_state[map_id] = state
	if not was_completed:
		emit_signal("map_completion_changed", map_id, true)
		if map_id == "verdant_wilds":
			queue_ember_unlock_notification()


func _emit_objectives_updated() -> void:
	emit_signal("objectives_updated", get_current_objectives())


func _try_advance_off_run_objective(event_type: String, payload: Dictionary) -> void:
	if map_run_active:
		return
	var objective := get_next_global_objective()
	if objective.is_empty():
		return
	if not bool(objective.get("is_primary", false)):
		return
	if not _objective_matches_event(objective, event_type, payload):
		return
	var objective_id := str(objective.get("id", ""))
	if not objective_id.is_empty():
		objective_completion_history[objective_id] = int(objective_completion_history.get(objective_id, 0)) + 1
	global_objective_progression = get_global_objective_progression() + 1


func _sanitize_held_item_id(item_id: String) -> String:
	if item_id.is_empty():
		return ""
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return ""
	return item_id if str(item_data.get("category", "")) == GameData.ITEM_CATEGORY_HELD else ""


func is_opening_bind_tutorial_active() -> bool:
	return get_global_objective_progression() == 0 and not bool(tutorial_state.get("opening_bind_completed", false))


func should_show_battle_abilities_tutorial_popup() -> bool:
	var primary := get_primary_objective()
	return (
		not bool(tutorial_state.get("battle_abilities_popup_shown", false))
		and str(primary.get("id", "")) == "global_win_verdant_battle"
		and not bool(primary.get("completed", false))
	)


func mark_battle_abilities_tutorial_popup_shown() -> void:
	tutorial_state["battle_abilities_popup_shown"] = true


func should_show_battle_rewards_tutorial_popup() -> bool:
	var primary := get_primary_objective()
	return (
		not bool(tutorial_state.get("battle_rewards_popup_shown", false))
		and str(primary.get("id", "")) == "global_win_verdant_battle"
		and not bool(primary.get("completed", false))
	)


func mark_battle_rewards_tutorial_popup_shown() -> void:
	tutorial_state["battle_rewards_popup_shown"] = true


func is_battle_abilities_tutorial_active() -> bool:
	var primary := get_primary_objective()
	return str(primary.get("id", "")) == "global_win_verdant_battle" and not bool(primary.get("completed", false))


func note_opening_bind_battle_started() -> void:
	if is_opening_bind_tutorial_active():
		tutorial_state["opening_bind_battle_started"] = true


func resolve_opening_bind_attempt() -> String:
	if not is_opening_bind_tutorial_active():
		return "normal"
	var attempts := int(tutorial_state.get("opening_bind_attempts", 0)) + 1
	tutorial_state["opening_bind_attempts"] = attempts
	if attempts <= 1:
		return "forced_fail"
	tutorial_state["opening_bind_completed"] = true
	return "forced_success"


func _default_tutorial_state() -> Dictionary:
	return {
		"opening_bind_battle_started": false,
		"opening_bind_attempts": 0,
		"opening_bind_completed": false,
		"battle_abilities_popup_shown": false,
	}


func _get_tutorial_bind_progress(objective: Dictionary, event_type: String) -> int:
	var entered_grass_done := bool(objective.get("entered_grass_done", false)) or event_type == "entered_grass"
	var bound_creature_done := bool(objective.get("bound_creature_done", false)) or event_type == "creature_captured"
	return int(entered_grass_done) + int(bound_creature_done)


func _adjust_creature_resources_after_loadout_change(creature: Dictionary, previous_hp_max: int, previous_mp_max: int) -> void:
	var hp_missing: int = max(0, previous_hp_max - int(creature.get("hp", previous_hp_max)))
	var mp_missing: int = max(0, previous_mp_max - int(creature.get("mp", previous_mp_max)))
	var new_hp_max: int = get_effective_creature_stat(creature, "hp_max")
	var new_mp_max: int = get_effective_creature_stat(creature, "mp_max")
	creature["hp"] = clampi(new_hp_max - hp_missing, 0, new_hp_max)
	creature["mp"] = clampi(new_mp_max - mp_missing, 0, new_mp_max)


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

extends Node

const DEFAULT_LEVEL := 1
const MAX_LEVEL := 50
const HP_PER_LEVEL := 6
const MP_PER_LEVEL := 2
const ATK_PER_LEVEL := 2
const DEF_PER_LEVEL := 2
const SPD_PER_LEVEL := 1
const DEFAULT_MP := 10
const DEFAULT_ACC := 100
const DEFAULT_EVA := 100
const DEFAULT_CRIT := 5

const ITEM_CATEGORY_CONSUMABLE := "consumable"
const ITEM_CATEGORY_HELD := "held"
const ITEM_CATEGORY_CAMP := "camp"

const OBJECTIVE_TYPE_GATHER := "gather"
const OBJECTIVE_TYPE_CRAFT := "craft"
const OBJECTIVE_TYPE_CAPTURE := "capture"
const OBJECTIVE_TYPE_BATTLE_WIN := "battle_win"
const OBJECTIVE_TYPE_BOSS_DEFEAT := "boss_defeat"

var materials_meta := {
	"wood": {"name": "Wood"},
	"herb": {"name": "Herb"},
	"stone": {"name": "Stone"},
	"crystal": {"name": "Crystal"},
	"core_shard": {"name": "Core Shard"},
	"species_mat": {"name": "Species Material"},
}

var item_categories := {
	ITEM_CATEGORY_CONSUMABLE: {
		"name": "Consumable",
		"variant": "wood",
	},
	ITEM_CATEGORY_HELD: {
		"name": "Held Item",
		"variant": "ember",
	},
	ITEM_CATEGORY_CAMP: {
		"name": "Camp Item",
		"variant": "stone",
	},
}

var items := {
	"basic_seal": {
		"id": "basic_seal",
		"name": "Basic Seal",
		"description": "A capture seal used to bind weakened wild creatures.",
		"category": ITEM_CATEGORY_CONSUMABLE,
		"tags": ["capture", "utility"],
		"rarity": "common",
		"sort_order": 10,
		"stackable": true,
		"max_stack": 99,
		"variant": "ember",
		"icon_path": "res://assets/resources/magical_seal.svg",
		"use_contexts": ["battle_capture"],
		"use_effects": [{"type": "capture_tool"}],
		"recipe": {"core_shard": 2, "crystal": 1},
	},
	"small_potion": {
		"id": "small_potion",
		"name": "Small Potion",
		"description": "Restore a little HP to one creature.",
		"category": ITEM_CATEGORY_CONSUMABLE,
		"tags": ["healing"],
		"rarity": "common",
		"sort_order": 20,
		"stackable": true,
		"max_stack": 20,
		"variant": "verdant",
		"use_contexts": ["camp_creature"],
		"use_effects": [{"type": "restore_hp", "amount": 18}],
		"recipe": {"herb": 3, "wood": 1},
	},
	"focus_tonic": {
		"id": "focus_tonic",
		"name": "Focus Tonic",
		"description": "Restore a little MP to one creature.",
		"category": ITEM_CATEGORY_CONSUMABLE,
		"tags": ["mp_restore", "utility"],
		"rarity": "common",
		"sort_order": 30,
		"stackable": true,
		"max_stack": 20,
		"variant": "crystal",
		"use_contexts": ["camp_creature"],
		"use_effects": [{"type": "restore_mp", "amount": 8}],
		"recipe": {"herb": 1, "crystal": 2},
	},
	"moss_charm": {
		"id": "moss_charm",
		"name": "Moss Charm",
		"description": "A soft charm that raises max HP.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["defensive", "healing"],
		"rarity": "common",
		"sort_order": 110,
		"stackable": true,
		"max_stack": 10,
		"variant": "verdant",
		"held_effects": [{"type": "flat_stat", "stat": "hp_max", "amount": 10}],
		"recipe": {"herb": 4, "species_mat": 1},
	},
	"sharp_fang": {
		"id": "sharp_fang",
		"name": "Sharp Fang",
		"description": "A carved fang that sharpens attacks.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["offensive"],
		"rarity": "common",
		"sort_order": 120,
		"stackable": true,
		"max_stack": 10,
		"variant": "ember",
		"held_effects": [{"type": "flat_stat", "stat": "atk", "amount": 3}],
		"recipe": {"wood": 2, "core_shard": 2, "species_mat": 1},
	},
	"stone_ring": {
		"id": "stone_ring",
		"name": "Stone Ring",
		"description": "A heavy ring that improves defense.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["defensive"],
		"rarity": "common",
		"sort_order": 130,
		"stackable": true,
		"max_stack": 10,
		"variant": "stone",
		"held_effects": [{"type": "flat_stat", "stat": "def", "amount": 3}],
		"recipe": {"stone": 3, "core_shard": 1},
	},
	"fleet_feather": {
		"id": "fleet_feather",
		"name": "Fleet Feather",
		"description": "A light feather that raises speed.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["speed", "utility"],
		"rarity": "common",
		"sort_order": 140,
		"stackable": true,
		"max_stack": 10,
		"variant": "wood",
		"held_effects": [{"type": "flat_stat", "stat": "spd", "amount": 3}],
		"recipe": {"wood": 2, "herb": 2},
	},
	"hunter_lens": {
		"id": "hunter_lens",
		"name": "Hunter Lens",
		"description": "A polished lens that improves accuracy.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["utility"],
		"rarity": "uncommon",
		"sort_order": 150,
		"stackable": true,
		"max_stack": 10,
		"variant": "crystal",
		"held_effects": [{"type": "flat_stat", "stat": "acc", "amount": 8}],
		"recipe": {"crystal": 2, "wood": 1, "core_shard": 1},
	},
	"mist_cloak": {
		"id": "mist_cloak",
		"name": "Mist Cloak",
		"description": "A thin shroud that improves evasion.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["defensive", "utility"],
		"rarity": "uncommon",
		"sort_order": 160,
		"stackable": true,
		"max_stack": 10,
		"variant": "battle",
		"held_effects": [{"type": "flat_stat", "stat": "eva", "amount": 8}],
		"recipe": {"herb": 2, "crystal": 1, "species_mat": 1},
	},
	"ember_idol": {
		"id": "ember_idol",
		"name": "Ember Idol",
		"description": "A fired idol that slightly raises crit chance.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["offensive", "crit"],
		"rarity": "uncommon",
		"sort_order": 170,
		"stackable": true,
		"max_stack": 10,
		"variant": "ember",
		"held_effects": [{"type": "flat_stat", "stat": "crit", "amount": 4}],
		"recipe": {"core_shard": 2, "crystal": 1},
	},
	"mana_bead": {
		"id": "mana_bead",
		"name": "Mana Bead",
		"description": "A humming bead that raises max MP.",
		"category": ITEM_CATEGORY_HELD,
		"tags": ["mp_restore", "utility"],
		"rarity": "uncommon",
		"sort_order": 180,
		"stackable": true,
		"max_stack": 10,
		"variant": "crystal",
		"held_effects": [{"type": "flat_stat", "stat": "mp_max", "amount": 6}],
		"recipe": {"crystal": 3, "species_mat": 1},
	},
	"healing_tent": {
		"id": "healing_tent",
		"name": "Healing Tent",
		"description": "A camp installation that restores every creature when you return to camp.",
		"category": ITEM_CATEGORY_CAMP,
		"tags": ["expedition", "utility"],
		"rarity": "uncommon",
		"sort_order": 210,
		"stackable": false,
		"max_stack": 1,
		"variant": "stone",
		"camp_effects": [{"type": "full_collection_restoration"}],
		"recipe": {"wood": 6, "herb": 4, "stone": 3},
	},
}

var passives := {
	"verdant_focus": {
		"name": "Verdant Focus",
		"description": "Restore a little MP at the start of battle.",
		"effect_type": "battle_start_restore_mp",
		"amount": 3,
	},
	"ember_instinct": {
		"name": "Ember Instinct",
		"description": "Gain +5 crit chance during battle.",
		"effect_type": "battle_stat_bonus",
		"stat": "crit",
		"amount": 5,
	},
	"stonehide": {
		"name": "Stonehide",
		"description": "Gain +3 DEF during battle.",
		"effect_type": "battle_stat_bonus",
		"stat": "def",
		"amount": 3,
	},
}

var abilities := {
	"strike": {
		"id": "strike",
		"name": "Strike",
		"description": "A simple attack that costs no MP.",
		"ability_type": "damage",
		"mp_cost": 0,
		"power": 5.0,
		"accuracy": 95.0,
		"target": "enemy",
	},
	"leaf_strike": {
		"id": "leaf_strike",
		"name": "Leaf Strike",
		"description": "A sharp leaf slash with steady accuracy.",
		"ability_type": "damage",
		"mp_cost": 3,
		"power": 7.0,
		"accuracy": 95.0,
		"target": "enemy",
	},
	"ember_bite": {
		"id": "ember_bite",
		"name": "Ember Bite",
		"description": "A fast fiery bite that hits a little harder.",
		"ability_type": "damage",
		"mp_cost": 4,
		"power": 8.0,
		"accuracy": 92.0,
		"target": "enemy",
	},
	"horn_bash": {
		"id": "horn_bash",
		"name": "Horn Bash",
		"description": "A solid charging blow with reliable impact.",
		"ability_type": "damage",
		"mp_cost": 4,
		"power": 9.0,
		"accuracy": 90.0,
		"target": "enemy",
	},
}

var creatures := {
	"mossling": {
		"name": "Mossling",
		"element": "grass",
		"base_hp": 30,
		"base_mp": 12,
		"base_atk": 8,
		"base_def": 6,
		"base_spd": 8,
		"passive_id": "verdant_focus",
		"abilities": ["leaf_strike"],
		"base_exp_reward": 12,
		"sprite_path": "res://assets/creatures/mossling.png",
	},
	"cinder_pup": {
		"name": "Cinder Pup",
		"element": "fire",
		"base_hp": 22,
		"base_mp": 10,
		"base_atk": 11,
		"base_def": 4,
		"base_spd": 12,
		"passive_id": "ember_instinct",
		"abilities": ["ember_bite"],
		"base_exp_reward": 14,
		"sprite_path": "res://assets/creatures/cinder_pup.png",
	},
	"shellhorn": {
		"name": "Shellhorn",
		"element": "earth",
		"base_hp": 36,
		"base_mp": 8,
		"base_atk": 6,
		"base_def": 9,
		"base_spd": 6,
		"passive_id": "stonehide",
		"abilities": ["horn_bash"],
		"base_exp_reward": 16,
		"sprite_path": "res://assets/creatures/shellhorn.png",
	},
}

var maps := {
	"verdant_wilds": {
		"display_name": "Verdant Wilds",
		"scene_path": "res://scenes/overworld/Overworld_Verdant.tscn",
		"wild_level_range": Vector2i(1, 4),
		"wild_pool": ["mossling", "shellhorn", "cinder_pup"],
		"encounter_pools": {
			"forest": ["mossling", "mossling", "shellhorn", "cinder_pup"],
			"high_risk_patch": ["shellhorn", "cinder_pup", "cinder_pup"],
		},
		"run_config": {
			"resource_counts": {
				"wood": 4,
				"herb": 3,
				"stone": 1,
			},
			"resource_node_encounters": {
				"wood": {
					"chance": 0.18,
					"pool": ["mossling", "mossling", "shellhorn"],
					"message": "Something was hiding in the wood!",
					"ui_variant": "verdant",
				},
				"herb": {
					"chance": 0.14,
					"pool": ["mossling", "mossling"],
					"message": "A creature was disturbed in the herb patch!",
					"ui_variant": "verdant",
				},
				"stone": {
					"chance": 0.22,
					"pool": ["shellhorn", "mossling"],
					"message": "A creature burst out from the stones!",
					"ui_variant": "stone",
				},
				"crystal": {
					"chance": 0.28,
					"pool": ["shellhorn", "cinder_pup"],
					"message": "The crystal cluster shimmered and drew in a creature!",
					"ui_variant": "crystal",
					"exp_multiplier": 1.1,
				},
				"core_shard": {
					"chance": 0.4,
					"pool": ["cinder_pup", "shellhorn", "cinder_pup"],
					"message": "A guardian creature appeared from the shard's energy!",
					"ui_variant": "ember",
					"level_bonus": 1,
					"stat_multiplier": 1.1,
					"exp_multiplier": 1.15,
				},
			},
			"active_patch_count": 2,
			"resource_rare_drops": {
				"wood": [
					{"material": "species_mat", "min": 1, "max": 1, "chance": 0.08},
				],
				"herb": [
					{"material": "species_mat", "min": 1, "max": 1, "chance": 0.05},
					{"material": "herb", "min": 1, "max": 2, "chance": 0.16},
				],
			},
			"battle_rewards": {
				"capture": [
					{"material": "core_shard", "min": 1, "max": 1},
					{"material": "species_mat", "min": 1, "max": 2},
					{"material": "wood", "min": 1, "max": 2},
				],
				"victory": [
					{"material": "core_shard", "min": 1, "max": 2},
					{"material": "species_mat", "min": 1, "max": 2},
					{"material": "wood", "min": 2, "max": 3},
					{"material": "herb", "min": 1, "max": 2},
				],
				"rare": [
					{"material": "species_mat", "min": 1, "max": 1, "chance": 0.1},
					{"material": "herb", "min": 1, "max": 2, "chance": 0.18},
				],
				"boss_capture": [
					{"material": "core_shard", "min": 2, "max": 2},
					{"material": "species_mat", "min": 2, "max": 3},
					{"material": "wood", "min": 2, "max": 4},
					{"material": "herb", "min": 2, "max": 3},
				],
				"boss_victory": [
					{"material": "core_shard", "min": 2, "max": 3},
					{"material": "species_mat", "min": 2, "max": 4},
					{"material": "wood", "min": 3, "max": 5},
					{"material": "herb", "min": 2, "max": 4},
				],
				"boss_rare": [
					{"material": "species_mat", "min": 1, "max": 2, "chance": 0.4},
				],
			},
			"boss": {
				"creature_id": "mossling",
				"display_name": "Alpha Mossling",
				"sprite_path": "res://assets/creatures/alpha_mossling.svg",
				"level_bonus": 2,
				"stat_multiplier": 1.35,
				"exp_multiplier": 1.8,
				"disable_run": true,
				"ui_variant": "verdant",
				"ring_color": Color("f0d36c"),
				"body_color": Color("47633f"),
			},
		},
		"objective_sets": {
			"starter_sequence": [
				[
					{
						"id": "verdant_gather_wood",
						"type": OBJECTIVE_TYPE_GATHER,
						"title": "Gather Wood",
						"description": "Gather 3 wood in Verdant Wilds.",
						"target_id": "wood",
						"target_amount": 3,
						"is_primary": true,
					},
				],
				[
					{
						"id": "verdant_craft_basic_seal",
						"type": OBJECTIVE_TYPE_CRAFT,
						"title": "Craft Basic Seal",
						"description": "Craft 1 Basic Seal at camp before your next clear.",
						"target_id": "basic_seal",
						"target_amount": 1,
						"is_primary": true,
					},
				],
				[
					{
						"id": "verdant_capture_creature",
						"type": OBJECTIVE_TYPE_CAPTURE,
						"title": "Capture Creature",
						"description": "Capture 1 creature in Verdant Wilds.",
						"target_amount": 1,
						"is_primary": true,
					},
				],
				[
					{
						"id": "verdant_defeat_boss",
						"type": OBJECTIVE_TYPE_BOSS_DEFEAT,
						"title": "Defeat the Boss",
						"description": "Defeat the Verdant Wilds boss.",
						"target_id": "verdant_wilds",
						"target_amount": 1,
						"is_primary": true,
					},
				],
			],
			"default_run": [
				{
					"id": "verdant_repeat_boss",
					"type": OBJECTIVE_TYPE_BOSS_DEFEAT,
					"title": "Defeat the Boss",
					"description": "Defeat the Verdant Wilds boss.",
					"target_id": "verdant_wilds",
					"target_amount": 1,
					"is_primary": true,
				},
				{
					"id": "verdant_bonus_battles",
					"type": OBJECTIVE_TYPE_BATTLE_WIN,
					"title": "Win 2 Battles",
					"description": "Win 2 battles during this venture.",
					"target_amount": 2,
					"is_primary": false,
					"is_bonus": true,
				},
			],
		},
	},
	"ember_caves": {
		"display_name": "Ember Caves",
		"scene_path": "res://scenes/overworld/Overworld_Ember.tscn",
		"wild_level_range": Vector2i(2, 6),
		"wild_pool": ["cinder_pup", "cinder_pup", "shellhorn"],
		"encounter_pools": {
			"cave": ["cinder_pup", "cinder_pup", "shellhorn"],
			"high_risk_patch": ["shellhorn", "cinder_pup", "shellhorn"],
		},
		"run_config": {
			"resource_counts": {
				"stone": 4,
				"crystal": 2,
				"core_shard": 1,
			},
			"resource_node_encounters": {
				"wood": {
					"chance": 0.16,
					"pool": ["cinder_pup"],
					"message": "Something skittered out of the charred roots!",
					"ui_variant": "ember",
				},
				"herb": {
					"chance": 0.18,
					"pool": ["cinder_pup"],
					"message": "A cave creature was feeding on the fungi!",
					"ui_variant": "ember",
				},
				"stone": {
					"chance": 0.24,
					"pool": ["shellhorn", "cinder_pup", "shellhorn"],
					"message": "The basalt pile cracked open!",
					"ui_variant": "stone",
				},
				"crystal": {
					"chance": 0.34,
					"pool": ["cinder_pup", "shellhorn", "cinder_pup"],
					"message": "The crystal cluster flared and a creature lunged out!",
					"ui_variant": "crystal",
					"level_bonus": 1,
					"exp_multiplier": 1.1,
				},
				"core_shard": {
					"chance": 0.48,
					"pool": ["cinder_pup", "shellhorn", "shellhorn"],
					"message": "A guardian was drawn to the core shard!",
					"ui_variant": "ember",
					"level_bonus": 1,
					"stat_multiplier": 1.15,
					"exp_multiplier": 1.2,
				},
			},
			"active_patch_count": 2,
			"resource_rare_drops": {
				"stone": [
					{"material": "core_shard", "min": 1, "max": 1, "chance": 0.08},
				],
				"crystal": [
					{"material": "crystal", "min": 1, "max": 2, "chance": 0.18},
				],
				"core_shard": [
					{"material": "species_mat", "min": 1, "max": 1, "chance": 0.08},
				],
			},
			"battle_rewards": {
				"capture": [
					{"material": "core_shard", "min": 1, "max": 2},
					{"material": "species_mat", "min": 1, "max": 2},
					{"material": "stone", "min": 1, "max": 2},
				],
				"victory": [
					{"material": "core_shard", "min": 1, "max": 2},
					{"material": "species_mat", "min": 1, "max": 2},
					{"material": "stone", "min": 2, "max": 3},
					{"material": "crystal", "min": 1, "max": 2},
				],
				"rare": [
					{"material": "core_shard", "min": 1, "max": 1, "chance": 0.12},
					{"material": "species_mat", "min": 1, "max": 1, "chance": 0.1},
				],
				"boss_capture": [
					{"material": "core_shard", "min": 2, "max": 3},
					{"material": "species_mat", "min": 2, "max": 3},
					{"material": "stone", "min": 2, "max": 4},
					{"material": "crystal", "min": 2, "max": 3},
				],
				"boss_victory": [
					{"material": "core_shard", "min": 3, "max": 4},
					{"material": "species_mat", "min": 2, "max": 4},
					{"material": "stone", "min": 3, "max": 5},
					{"material": "crystal", "min": 2, "max": 4},
				],
				"boss_rare": [
					{"material": "core_shard", "min": 1, "max": 2, "chance": 0.45},
				],
			},
			"boss": {
				"creature_id": "cinder_pup",
				"display_name": "Alpha Cinder Pup",
				"sprite_path": "res://assets/creatures/alpha_cinder.svg",
				"level_bonus": 2,
				"stat_multiplier": 1.4,
				"exp_multiplier": 1.85,
				"disable_run": true,
				"ui_variant": "ember",
				"ring_color": Color("ffb35c"),
				"body_color": Color("6b2e26"),
			},
		},
		"objective_sets": {
			"default_run": [
				{
					"id": "ember_defeat_boss",
					"type": OBJECTIVE_TYPE_BOSS_DEFEAT,
					"title": "Defeat the Boss",
					"description": "Defeat the Ember Caves boss.",
					"target_id": "ember_caves",
					"target_amount": 1,
					"is_primary": true,
				},
				{
					"id": "ember_bonus_crystal",
					"type": OBJECTIVE_TYPE_GATHER,
					"title": "Gather Crystal",
					"description": "Gather 2 crystal during this venture.",
					"target_id": "crystal",
					"target_amount": 2,
					"is_primary": false,
					"is_bonus": true,
				},
			],
		},
	},
}


func pick_wild_for_map(map_id: String, encounter_tag: String = "") -> String:
	var map_data: Dictionary = maps.get(map_id, {})
	var encounter_pools: Dictionary = map_data.get("encounter_pools", {})
	var pool: Array = encounter_pools.get(encounter_tag, map_data.get("wild_pool", []))
	if pool.is_empty():
		return ""
	return str(pool[randi() % pool.size()])


func get_map_run_config(map_id: String) -> Dictionary:
	var map_data: Dictionary = maps.get(map_id, {})
	return map_data.get("run_config", {})


func get_boss_config(map_id: String) -> Dictionary:
	var run_config := get_map_run_config(map_id)
	return run_config.get("boss", {})


func get_resource_rare_drops(map_id: String, resource_type: String) -> Dictionary:
	var run_config := get_map_run_config(map_id)
	var rare_tables: Dictionary = run_config.get("resource_rare_drops", {})
	return roll_material_table(rare_tables.get(resource_type, []))


func get_resource_node_encounter_data(map_id: String, resource_type: String) -> Dictionary:
	var run_config := get_map_run_config(map_id)
	var node_config: Dictionary = run_config.get("resource_node_encounters", {})
	var data: Dictionary = node_config.get(resource_type, {})
	if data.is_empty():
		return {}
	var resolved := data.duplicate(true)
	var pool: Array = resolved.get("pool", [])
	if pool.is_empty():
		pool = maps.get(map_id, {}).get("wild_pool", [])
	resolved["pool"] = pool.duplicate(true)
	resolved["chance"] = clampf(float(resolved.get("chance", 0.0)), 0.0, 1.0)
	resolved["resource_type"] = resource_type
	resolved["map_id"] = map_id
	return resolved


func roll_resource_node_encounter(map_id: String, resource_type: String) -> Dictionary:
	var encounter_data := get_resource_node_encounter_data(map_id, resource_type)
	if encounter_data.is_empty():
		return {}
	var pool: Array = encounter_data.get("pool", [])
	if pool.is_empty():
		return {}
	if randf() > float(encounter_data.get("chance", 0.0)):
		return {}
	var creature_id := str(pool[randi() % pool.size()])
	if creature_id.is_empty():
		return {}
	encounter_data["creature_id"] = creature_id
	return encounter_data


func get_battle_reward_roll(map_id: String, captured: bool, battle_context: Dictionary = {}) -> Dictionary:
	var run_config := get_map_run_config(map_id)
	var reward_config: Dictionary = run_config.get("battle_rewards", {})
	var is_boss := str(battle_context.get("reward_profile", "")) == "boss"
	var primary_key := "victory"
	if captured:
		primary_key = "capture"
	if is_boss:
		primary_key = "boss_capture" if captured else "boss_victory"
	var rare_key := "boss_rare" if is_boss else "rare"
	var rewards := roll_material_table(reward_config.get(primary_key, []))
	return merge_materials(rewards, roll_material_table(reward_config.get(rare_key, [])))


func merge_materials(base_materials: Dictionary, extra_materials: Dictionary) -> Dictionary:
	var merged := base_materials.duplicate(true)
	for material in extra_materials.keys():
		merged[material] = int(merged.get(material, 0)) + int(extra_materials.get(material, 0))
	return merged


func roll_material_table(entries: Array) -> Dictionary:
	var rewards := {}
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var chance := float(entry.get("chance", 1.0))
		if randf() > chance:
			continue
		var material := str(entry.get("material", ""))
		if material.is_empty():
			continue
		var min_amount := int(entry.get("min", 1))
		var max_amount := int(entry.get("max", min_amount))
		var amount := randi_range(min_amount, max(min_amount, max_amount))
		rewards[material] = int(rewards.get(material, 0)) + amount
	return rewards


func get_creature_data(creature_id: String) -> Dictionary:
	return creatures.get(creature_id, {})


func get_ability_data(ability_id: String) -> Dictionary:
	return abilities.get(ability_id, {})


func get_passive_data(passive_id: String) -> Dictionary:
	return passives.get(passive_id, {})


func get_item_data(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_all_items() -> Dictionary:
	return items


func get_all_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for item_id in items.keys():
		ids.append(str(item_id))
	ids.sort()
	return ids


func get_item_ids_by_category(category: String) -> Array[String]:
	var ids: Array[String] = []
	for item_id in get_all_item_ids():
		var item_data := get_item_data(item_id)
		if str(item_data.get("category", "")) == category:
			ids.append(item_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var a_data := get_item_data(a)
		var b_data := get_item_data(b)
		var a_sort := int(a_data.get("sort_order", 0))
		var b_sort := int(b_data.get("sort_order", 0))
		if a_sort == b_sort:
			return str(a_data.get("name", a)).nocasecmp_to(str(b_data.get("name", b))) < 0
		return a_sort < b_sort
	)
	return ids


func get_items_by_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in get_item_ids_by_category(category):
		result.append(get_item_data(item_id))
	return result


func get_item_category_data(category: String) -> Dictionary:
	return item_categories.get(category, {"name": category.capitalize(), "variant": "wood"})


func format_item_category(category: String) -> String:
	return str(get_item_category_data(category).get("name", category.capitalize()))


func get_item_variant(item_id: String) -> String:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return "wood"
	return str(item_data.get("variant", get_item_category_data(str(item_data.get("category", ""))).get("variant", "wood")))


func get_item_icon_path(item_id: String) -> String:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return ""
	return str(item_data.get("icon_path", ""))


func get_material_display_name(material_id: String) -> String:
	var meta: Dictionary = materials_meta.get(material_id, {})
	return str(meta.get("name", material_id.capitalize()))


func get_objective_set_for_map(map_id: String, progression_index: int = 0) -> Dictionary:
	var map_data: Dictionary = maps.get(map_id, {})
	var objective_sets: Dictionary = map_data.get("objective_sets", {})
	var starter_sequence: Array = objective_sets.get("starter_sequence", [])
	if progression_index >= 0 and progression_index < starter_sequence.size():
		return {
			"id": "%s_starter_%d" % [map_id, progression_index],
			"source": "starter_sequence",
			"progression_index": progression_index,
			"objectives": _duplicate_objectives(starter_sequence[progression_index]),
		}
	return {
		"id": "%s_default" % map_id,
		"source": "default_run",
		"progression_index": progression_index,
		"objectives": _duplicate_objectives(objective_sets.get("default_run", [])),
	}


func build_objective_definition(raw_objective: Dictionary) -> Dictionary:
	var objective := raw_objective.duplicate(true)
	objective["id"] = str(objective.get("id", "objective_%d" % randi()))
	objective["type"] = str(objective.get("type", OBJECTIVE_TYPE_GATHER))
	objective["title"] = str(objective.get("title", objective["id"].capitalize()))
	objective["description"] = str(objective.get("description", ""))
	objective["target_id"] = str(objective.get("target_id", ""))
	objective["target_amount"] = max(1, int(objective.get("target_amount", 1)))
	objective["is_primary"] = bool(objective.get("is_primary", false))
	objective["is_bonus"] = bool(objective.get("is_bonus", false))
	return objective


func get_objective_target_name(objective_type: String, target_id: String) -> String:
	match objective_type:
		OBJECTIVE_TYPE_GATHER:
			return get_material_display_name(target_id)
		OBJECTIVE_TYPE_CRAFT:
			return str(get_item_data(target_id).get("name", target_id.capitalize()))
		OBJECTIVE_TYPE_BOSS_DEFEAT:
			return str(maps.get(target_id, {}).get("display_name", target_id.capitalize()))
		_:
			return target_id.capitalize()


func _duplicate_objectives(raw_objectives: Array) -> Array:
	var objectives: Array = []
	for raw_objective in raw_objectives:
		if raw_objective is Dictionary:
			objectives.append(build_objective_definition(raw_objective))
	return objectives


func get_item_recipe(item_id: String) -> Dictionary:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return {}
	return item_data.get("recipe", {}).duplicate(true)


func get_item_tags(item_id: String) -> Array[String]:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return []
	var tags: Array[String] = []
	for tag in item_data.get("tags", []):
		tags.append(str(tag))
	return tags


func get_item_effect_summary(item_id: String) -> String:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return "No effect data."
	var parts: Array[String] = []
	for effect in item_data.get("held_effects", []):
		if effect is Dictionary and str(effect.get("type", "")) == "flat_stat":
			parts.append("+%d %s" % [int(effect.get("amount", 0)), str(effect.get("stat", "")).to_upper()])
	for effect in item_data.get("use_effects", []):
		if not (effect is Dictionary):
			continue
		match str(effect.get("type", "")):
			"restore_hp":
				parts.append("Restore %d HP" % int(effect.get("amount", 0)))
			"restore_mp":
				parts.append("Restore %d MP" % int(effect.get("amount", 0)))
			"capture_tool":
				parts.append("Used for capture")
	for effect in item_data.get("camp_effects", []):
		if effect is Dictionary and str(effect.get("type", "")) == "full_collection_restoration":
			parts.append("Restores the full collection at camp")
	return ", ".join(parts) if not parts.is_empty() else "No effect data."


func format_item_summary(item_id: String) -> String:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return "Unknown item"
	return "%s [%s]\n%s" % [
		str(item_data.get("name", item_id)),
		format_item_category(str(item_data.get("category", ""))),
		str(item_data.get("description", "")),
	]


func get_item_detail_text(item_id: String) -> String:
	var item_data := get_item_data(item_id)
	if item_data.is_empty():
		return "Unknown item"
	var tags := get_item_tags(item_id)
	var recipe := get_item_recipe(item_id)
	var lines: Array[String] = [
		str(item_data.get("description", "")),
		"",
		"Effect: %s" % get_item_effect_summary(item_id),
	]
	if not tags.is_empty():
		lines.append("Tags: %s" % ", ".join(tags))
	if not recipe.is_empty():
		lines.append("Recipe: %s" % format_material_cost(recipe))
	return "\n".join(lines)


func format_material_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost.keys():
		var display_name := str(key).capitalize()
		match str(key):
			"core_shard":
				display_name = "Core"
			"species_mat":
				display_name = "Species"
		parts.append("%d %s" % [int(cost[key]), display_name])
	return ", ".join(parts)


func get_default_mp() -> int:
	return DEFAULT_MP


func get_default_acc() -> int:
	return DEFAULT_ACC


func get_default_eva() -> int:
	return DEFAULT_EVA


func get_default_crit() -> int:
	return DEFAULT_CRIT


func get_default_ability_ids(creature_id: String) -> Array[String]:
	var creature_data := get_creature_data(creature_id)
	var raw_abilities: Array = creature_data.get("abilities", [])
	var normalized: Array[String] = ["strike"]
	for ability_id in raw_abilities:
		var resolved_ability_id := str(ability_id)
		if not resolved_ability_id.is_empty() and not normalized.has(resolved_ability_id):
			normalized.append(resolved_ability_id)
	return normalized


func get_default_passive_id(creature_id: String) -> String:
	return str(get_creature_data(creature_id).get("passive_id", ""))


func format_ability_summary(ability_id: String) -> String:
	var ability := get_ability_data(ability_id)
	if ability.is_empty():
		return "Unknown ability"
	return "%s (%d MP): %s" % [
		str(ability.get("name", ability_id)),
		int(ability.get("mp_cost", 0)),
		str(ability.get("description", "")),
	]


func format_ability_tooltip(ability_id: String) -> String:
	var ability := get_ability_data(ability_id)
	if ability.is_empty():
		return "Unknown ability"
	return "%s\n%s\nMP Cost: %d\nPower: %d\nAccuracy: %d" % [
		str(ability.get("name", ability_id)),
		str(ability.get("description", "")),
		int(ability.get("mp_cost", 0)),
		int(round(float(ability.get("power", 0.0)))),
		int(round(float(ability.get("accuracy", 100.0)))),
	]


func format_passive_summary(passive_id: String) -> String:
	var passive := get_passive_data(passive_id)
	if passive.is_empty():
		return "No passive"
	return "%s: %s" % [
		str(passive.get("name", passive_id)),
		str(passive.get("description", "")),
	]


func format_passive_tooltip(passive_id: String) -> String:
	var passive := get_passive_data(passive_id)
	if passive.is_empty():
		return "No passive"
	return "%s\n%s" % [
		str(passive.get("name", passive_id)),
		str(passive.get("description", "")),
	]


func get_total_exp_for_level(level: int) -> int:
	var target_level := clampi(level, DEFAULT_LEVEL, MAX_LEVEL)
	var tier := target_level - 1
	return (12 * tier * tier) + (8 * tier)


func get_exp_to_next_level(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return get_total_exp_for_level(level + 1) - get_total_exp_for_level(level)


func get_stats_for_level(creature_id: String, level: int) -> Dictionary:
	var base_stats := get_creature_data(creature_id)
	if base_stats.is_empty():
		return {}
	var tier := clampi(level, DEFAULT_LEVEL, MAX_LEVEL) - 1
	return {
		"hp_max": int(base_stats.get("base_hp", 1)) + (tier * HP_PER_LEVEL),
		"mp_max": int(base_stats.get("base_mp", DEFAULT_MP)) + (tier * MP_PER_LEVEL),
		"atk": int(base_stats.get("base_atk", 1)) + (tier * ATK_PER_LEVEL),
		"def": int(base_stats.get("base_def", 1)) + (tier * DEF_PER_LEVEL),
		"spd": int(base_stats.get("base_spd", 8)) + (tier * SPD_PER_LEVEL),
		"acc": int(base_stats.get("base_acc", DEFAULT_ACC)),
		"eva": int(base_stats.get("base_eva", DEFAULT_EVA)),
		"crit": int(base_stats.get("base_crit", DEFAULT_CRIT)),
	}


func build_creature_instance(creature_id: String, level: int = DEFAULT_LEVEL) -> Dictionary:
	var base_data := get_creature_data(creature_id)
	var normalized_level := clampi(level, DEFAULT_LEVEL, MAX_LEVEL)
	var stats := get_stats_for_level(creature_id, normalized_level)
	if base_data.is_empty() or stats.is_empty():
		return {}
	return {
		"id": creature_id,
		"name": str(base_data.get("name", creature_id.capitalize())),
		"element": str(base_data.get("element", "neutral")),
		"level": normalized_level,
		"exp": get_total_exp_for_level(normalized_level),
		"passive_id": str(base_data.get("passive_id", "")),
		"abilities": get_default_ability_ids(creature_id),
		"held_item_id": "",
		"hp_max": int(stats.get("hp_max", 1)),
		"mp_max": int(stats.get("mp_max", DEFAULT_MP)),
		"atk": int(stats.get("atk", 1)),
		"def": int(stats.get("def", 1)),
		"spd": int(stats.get("spd", 1)),
		"acc": int(stats.get("acc", DEFAULT_ACC)),
		"eva": int(stats.get("eva", DEFAULT_EVA)),
		"crit": int(stats.get("crit", DEFAULT_CRIT)),
		"hp": int(stats.get("hp_max", 1)),
		"mp": int(stats.get("mp_max", DEFAULT_MP)),
	}


func get_exp_reward_for_creature(creature: Dictionary) -> int:
	var creature_id := str(creature.get("id", ""))
	var base_data := get_creature_data(creature_id)
	if base_data.is_empty():
		return 0
	var creature_level := clampi(int(creature.get("level", DEFAULT_LEVEL)), DEFAULT_LEVEL, MAX_LEVEL)
	return int(base_data.get("base_exp_reward", 10)) + (creature_level * 8)

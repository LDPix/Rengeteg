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
const OBJECTIVE_TYPE_TUTORIAL_BIND := "tutorial_bind"
const OBJECTIVE_TYPE_BATTLE_WIN := "battle_win"
const OBJECTIVE_TYPE_EQUIP_HELD_ITEM := "equip_held_item"
const OBJECTIVE_TYPE_BOSS_DEFEAT := "boss_defeat"
const OBJECTIVE_TYPE_ENTER_GRASS := "enter_grass"
const OBJECTIVE_TYPE_GATHER_MULTI := "gather_multi"

const POI_TYPE_RICH_GROVE := "rich_grove"
const POI_TYPE_PREDATOR_NEST := "predator_nest"
const POI_TYPE_SHRINE := "shrine"
const POI_TYPE_EXPEDITION_CACHE := "expedition_cache"
const POI_TYPE_SHORTCUT := "shortcut"

var materials_meta := {
	"wood": {"name": "Wood"},
	"herb": {"name": "Herb"},
	"stone": {"name": "Stone"},
	"crystal": {"name": "Crystal"},
	"core_shard": {"name": "Core Shard"},
	"species_mat": {"name": "Species Material"},
}

var poi_definitions := {
	"verdant_entry_cache": {
		"poi_type": POI_TYPE_EXPEDITION_CACHE,
		"title": "Abandoned Supply Satchel",
		"prompt_label": "SCAVENGE",
		"result_text": "You sort through a weathered satchel.",
		"ui_variant": "wood",
		"immediate_rewards": {
			"materials": {"wood": 2, "herb": 1},
			"items": {"basic_seal": 1},
		},
	},
	"verdant_waystone_shrine": {
		"poi_type": POI_TYPE_SHRINE,
		"title": "Waystone Shrine",
		"prompt_label": "ATTUNE",
		"result_text": "The shrine's moss-lit runes stir your party onward.",
		"ui_variant": "crystal",
		"effects": [
			{"type": "heal_party", "ratio": 0.35},
			{"type": "restore_party_mp", "ratio": 0.5},
			{"type": "run_bonus", "stat": "capture_chance_bonus", "amount": 0.12, "label": "Bind chance"},
		],
	},
	"verdant_rich_grove": {
		"poi_type": POI_TYPE_RICH_GROVE,
		"title": "Overgrown Grove",
		"prompt_label": "FORAGE",
		"result_text": "The grove is rich, but something prowls beneath the roots.",
		"ui_variant": "verdant",
		"encounter": {
			"encounter_tag": "high_risk_patch",
			"message": "You push into the grove and startle a territorial creature!",
			"ui_variant": "verdant",
			"level_bonus": 1,
			"stat_multiplier": 1.12,
			"exp_multiplier": 1.12,
			"reward_bundle": {
				"materials": {"herb": 4, "wood": 2, "species_mat": 1},
			},
		},
	},
	"verdant_predator_nest": {
		"poi_type": POI_TYPE_PREDATOR_NEST,
		"title": "Predator Nest",
		"prompt_label": "PROVOKE",
		"result_text": "Tracks, broken bark, and old bones mark a hunting den.",
		"ui_variant": "ember",
		"encounter": {
			"pool": ["shellhorn", "cinder_pup", "cinder_pup"],
			"message": "The nest erupts as an alpha predator lunges at you!",
			"ui_variant": "ember",
			"level_bonus": 2,
			"stat_multiplier": 1.2,
			"exp_multiplier": 1.2,
			"reward_bundle": {
				"materials": {"species_mat": 2, "wood": 1, "core_shard": 1},
			},
		},
	},
	}

var global_objective_sequence := [
	[
		{
			"id": "global_first_binding_lesson",
			"type": OBJECTIVE_TYPE_TUTORIAL_BIND,
			"title": "Walk through tall grass and try binding a creature.",
			"description": "Step into tall grass, then bind a creature with a magical seal.",
			"target_amount": 2,
			"is_primary": true,
		},
	],
		[
			{
				"id": "global_gather_wood",
				"type": OBJECTIVE_TYPE_GATHER,
				"title": "Gather 4 Wood",
				"description": "Gather 4 wood for your first crafts.",
				"target_id": "wood",
				"target_amount": 4,
				"is_primary": true,
			},
		],
	[
		{
			"id": "global_gather_herb",
			"type": OBJECTIVE_TYPE_GATHER,
			"title": "Gather Herbs",
			"description": "Gather 3 herbs for your first craft.",
			"target_id": "herb",
			"target_amount": 3,
			"is_primary": true,
		},
	],
	[
		{
			"id": "global_craft_small_potion",
			"type": OBJECTIVE_TYPE_CRAFT,
			"title": "Return to camp and craft a Small Potion",
			"description": "Leave the wilds, open Crafting at camp, and craft your first Small Potion.",
			"target_id": "small_potion",
			"target_amount": 1,
			"is_primary": true,
		},
	],
		[
			{
				"id": "global_win_verdant_battle",
				"type": OBJECTIVE_TYPE_BATTLE_WIN,
				"title": "Venture into Verdant Wilds again and win a battle",
				"description": "Head back into Verdant Wilds and win a battle.",
				"target_amount": 1,
				"target_map_id": "verdant_wilds",
				"is_primary": true,
			},
		],
		[
			{
				"id": "global_craft_sharp_fang",
				"type": OBJECTIVE_TYPE_CRAFT,
				"title": "Return to camp and craft Sharp Fang",
				"description": "Head back to camp, open Crafting, switch to Held Items, and craft Sharp Fang.",
				"target_id": "sharp_fang",
				"target_amount": 1,
				"is_primary": true,
			},
		],
		[
			{
				"id": "global_equip_sharp_fang",
				"type": OBJECTIVE_TYPE_EQUIP_HELD_ITEM,
				"title": "Equip Sharp Fang on one of your creatures",
				"description": "Open Creature Collection, choose Sharp Fang, and equip it to one of your creatures.",
				"target_id": "sharp_fang",
				"target_amount": 1,
				"is_primary": true,
			},
		],
		[
			{
				"id": "global_gather_tent_mats",
				"type": OBJECTIVE_TYPE_GATHER_MULTI,
				"title": "Gather materials for Party Tent",
				"description": "Gather wood, herbs, and stone to craft a Party Tent.",
				"target_materials": {"wood": 5, "herb": 2, "stone": 2},
				"is_primary": true,
			},
		],
		[
			{
				"id": "global_craft_party_tent",
				"type": OBJECTIVE_TYPE_CRAFT,
				"title": "Return to camp and craft a Party Tent",
				"description": "Head back to camp, open Crafting, switch to Camp Items, and craft a Party Tent.",
				"target_id": "party_tent",
				"target_amount": 1,
				"is_primary": true,
			},
		],
		[
			{
				"id": "global_defeat_boss",
			"type": OBJECTIVE_TYPE_BOSS_DEFEAT,
			"title": "Face the Mossking",
			"description": "A powerful creature guards the heart of Verdant Wilds. Challenge the Mossking whenever you feel ready — prepare your team, stock up on supplies, and head in on your own terms.",
			"target_amount": 1,
			"is_primary": true,
		},
	],
]

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
		"description": "A binding seal used to bind weakened wild creatures.",
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
		"icon_path": "res://assets/items/small_potion.svg",
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
		"icon_path": "res://assets/items/focus_tonic.svg",
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
		"icon_path": "res://assets/items/moss_charm.svg",
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
		"icon_path": "res://assets/items/sharp_fang.svg",
		"held_effects": [{"type": "flat_stat", "stat": "atk", "amount": 3}],
			"recipe": {"wood": 3, "core_shard": 1},
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
		"icon_path": "res://assets/items/stone_ring.svg",
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
		"icon_path": "res://assets/items/fleet_feather.svg",
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
		"icon_path": "res://assets/items/hunter_lens.svg",
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
		"icon_path": "res://assets/items/mist_cloak.svg",
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
		"icon_path": "res://assets/items/ember_idol.svg",
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
		"icon_path": "res://assets/items/mana_bead.svg",
		"held_effects": [{"type": "flat_stat", "stat": "mp_max", "amount": 6}],
		"recipe": {"crystal": 3, "species_mat": 1},
	},
	"party_tent": {
		"id": "party_tent",
		"name": "Party Tent",
		"description": "A larger expedition tent that raises the active party limit by 1.",
		"category": ITEM_CATEGORY_CAMP,
		"tags": ["expedition", "party"],
		"rarity": "uncommon",
		"sort_order": 210,
		"stackable": false,
		"max_stack": 1,
		"variant": "stone",
		"icon_path": "res://assets/items/party_tent.svg",
		"camp_effects": [{"type": "party_limit", "amount": 1}],
		"recipe": {"wood": 5, "herb": 2, "stone": 2},
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
		"sprite_path": "res://assets/creatures/mossling.svg",
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
		"sprite_path": "res://assets/creatures/cinder_pup.svg",
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
		"sprite_path": "res://assets/creatures/shellhorn.svg",
	},
	"mossking": {
		"name": "Mossking",
		"element": "grass",
		"base_hp": 42,
		"base_mp": 16,
		"base_atk": 11,
		"base_def": 9,
		"base_spd": 7,
		"passive_id": "verdant_focus",
		"abilities": ["leaf_strike"],
		"base_exp_reward": 24,
		"sprite_path": "res://assets/creatures/mossking.svg",
	},
}

var maps := {
	"verdant_wilds": {
		"display_name": "Verdant Wilds",
		"scene_path": "res://scenes/overworld/Overworld_Verdant.tscn",
		"unlock_condition": {
			"type": "always",
		},
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
				"poi_spawns": [
					{"spawn_id": "entry_cache", "poi_id": "verdant_entry_cache"},
					{"spawn_id": "waystone_shrine", "poi_id": "verdant_waystone_shrine"},
					{"spawn_id": "rich_grove", "poi_id": "verdant_rich_grove"},
					{"spawn_id": "predator_nest", "poi_id": "verdant_predator_nest"},
				],
				"resource_node_encounters": {
				"wood": {
					"chance": 0.18,
					"pool": ["mossling", "mossling", "shellhorn"],
					"message": "Something was hiding in the wood!",
					"ui_variant": "verdant",
				},
				"herb": {
					"chance": 0.14,
					"pool": ["mossling", "mossling", "shellhorn"],
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
				"species_mat": {
					"chance": 0.20,
					"pool": ["mossling", "shellhorn"],
					"message": "Disturbing the remains drew something near!",
					"ui_variant": "verdant",
				},
				},
			"active_patch_count": 1,
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
						{"material": "species_mat", "min": 1, "max": 2},
						{"material": "wood", "min": 1, "max": 2},
					],
					"victory": [
						{"material": "species_mat", "min": 1, "max": 2},
						{"material": "wood", "min": 2, "max": 3},
						{"material": "herb", "min": 1, "max": 2},
				],
				"rare": [
					{"material": "species_mat", "min": 1, "max": 1, "chance": 0.1},
					{"material": "herb", "min": 1, "max": 2, "chance": 0.18},
				],
					"boss_capture": [
						{"material": "species_mat", "min": 2, "max": 3},
						{"material": "wood", "min": 2, "max": 4},
						{"material": "herb", "min": 2, "max": 3},
					],
					"boss_victory": [
						{"material": "species_mat", "min": 2, "max": 4},
						{"material": "wood", "min": 3, "max": 5},
						{"material": "herb", "min": 2, "max": 4},
				],
				"boss_rare": [
					{"material": "species_mat", "min": 1, "max": 2, "chance": 0.4},
				],
				},
				"boss": {
					"creature_id": "mossking",
					"display_name": "Mossking",
					"sprite_path": "res://assets/creatures/mossking.svg",
					"level_bonus": 2,
					"stat_multiplier": 1.35,
					"exp_multiplier": 1.8,
				"disable_run": true,
				"ui_variant": "verdant",
				"ring_color": Color("f0d36c"),
				"body_color": Color("47633f"),
			},
		},
	},
	"ember_caves": {
		"display_name": "Ember Caves",
		"scene_path": "res://scenes/overworld/Overworld_Ember.tscn",
		"unlock_condition": {
			"type": "map_boss_defeated",
			"map_id": "verdant_wilds",
		},
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
				},
				"resource_node_encounters": {
				"wood": {
					"chance": 0.16,
					"pool": ["cinder_pup", "shellhorn"],
					"message": "Something skittered out of the charred roots!",
					"ui_variant": "ember",
				},
				"herb": {
					"chance": 0.18,
					"pool": ["cinder_pup", "cinder_pup", "shellhorn"],
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
				"species_mat": {
					"chance": 0.20,
					"pool": ["cinder_pup", "shellhorn"],
					"message": "Something was prowling near the creature remains!",
					"ui_variant": "ember",
				},
				},
				"active_patch_count": 2,
				"resource_rare_drops": {
					"crystal": [
						{"material": "crystal", "min": 1, "max": 2, "chance": 0.18},
					],
				},
				"battle_rewards": {
					"capture": [
						{"material": "species_mat", "min": 1, "max": 2},
						{"material": "stone", "min": 1, "max": 2},
					],
					"victory": [
						{"material": "species_mat", "min": 1, "max": 2},
						{"material": "stone", "min": 2, "max": 3},
						{"material": "crystal", "min": 1, "max": 2},
					],
					"rare": [
						{"material": "species_mat", "min": 1, "max": 1, "chance": 0.1},
					],
					"boss_capture": [
						{"material": "species_mat", "min": 2, "max": 3},
						{"material": "stone", "min": 2, "max": 4},
						{"material": "crystal", "min": 2, "max": 3},
					],
					"boss_victory": [
						{"material": "species_mat", "min": 2, "max": 4},
						{"material": "stone", "min": 3, "max": 5},
						{"material": "crystal", "min": 2, "max": 4},
					],
					"boss_rare": [],
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


func get_map_unlock_condition(map_id: String) -> Dictionary:
	var map_data: Dictionary = maps.get(map_id, {})
	return map_data.get("unlock_condition", {"type": "always"})


func get_poi_definition(poi_id: String) -> Dictionary:
	var poi_data: Dictionary = poi_definitions.get(poi_id, {})
	if poi_data.is_empty():
		return {}
	var resolved := poi_data.duplicate(true)
	resolved["poi_id"] = poi_id
	return resolved


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
	rewards = merge_materials(rewards, roll_material_table(reward_config.get(rare_key, [])))
	if not captured:
		rewards["core_shard"] = int(rewards.get("core_shard", 0)) + 1
	return rewards


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


func format_reward_bundle(reward_bundle: Dictionary) -> String:
	if reward_bundle.is_empty():
		return ""
	var parts: Array[String] = []
	var materials: Dictionary = reward_bundle.get("materials", {})
	for material_id in materials.keys():
		var amount := int(materials.get(material_id, 0))
		if amount <= 0:
			continue
		var material_name := str(materials_meta.get(material_id, {}).get("name", material_id.capitalize()))
		parts.append("%d %s" % [amount, material_name])
	var items_awarded: Dictionary = reward_bundle.get("items", {})
	for item_id in items_awarded.keys():
		var item_amount := int(items_awarded.get(item_id, 0))
		if item_amount <= 0:
			continue
		var item_name := str(get_item_data(str(item_id)).get("name", item_id))
		parts.append("%d %s" % [item_amount, item_name])
	return ", ".join(parts)


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


func get_global_objective_set(progression_index: int = 0, current_map_id: String = "") -> Dictionary:
	if progression_index >= 0 and progression_index < global_objective_sequence.size():
		return {
			"id": "global_sequence_%d" % progression_index,
			"source": "global_sequence",
			"progression_index": progression_index,
			"objectives": _duplicate_objectives(global_objective_sequence[progression_index]),
		}
	return {
		"id": "global_repeatable",
		"source": "global_repeatable",
		"progression_index": progression_index,
		"objectives": _duplicate_objectives(_build_repeatable_global_objectives(current_map_id)),
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
	if str(objective["type"]) == OBJECTIVE_TYPE_GATHER_MULTI:
		var target_mats: Dictionary = objective.get("target_materials", {}).duplicate(true)
		objective["target_materials"] = target_mats
		objective["target_amount"] = target_mats.size()
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


func _build_repeatable_global_objectives(current_map_id: String) -> Array:
	var map_name := str(maps.get(current_map_id, {}).get("display_name", "Current Map"))
	return [
		{
			"id": "global_repeatable_boss",
			"type": OBJECTIVE_TYPE_BOSS_DEFEAT,
			"title": "Defeat %s Boss" % map_name,
			"description": "Defeat the boss on your current venture.",
			"target_amount": 1,
			"is_primary": true,
		},
		{
			"id": "global_repeatable_battles",
			"type": OBJECTIVE_TYPE_BATTLE_WIN,
			"title": "Win 2 Battles",
			"description": "Win 2 battles during this venture.",
			"target_amount": 2,
			"is_primary": false,
			"is_bonus": true,
		},
	]


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
				parts.append("Used for binding")
	for effect in item_data.get("camp_effects", []):
		if not (effect is Dictionary):
			continue
		match str(effect.get("type", "")):
			"full_collection_restoration":
				parts.append("Restores the full collection at camp")
			"party_limit":
				parts.append("+%d active party slot" % int(effect.get("amount", 0)))
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

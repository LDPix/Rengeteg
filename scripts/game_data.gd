extends Node

# Super-small “database” for MVP.
# Later you can replace with Resources or JSON.

var creatures := {
	"mossling": {
		"name": "Mossling",
		"element": "grass",
		"base_hp": 30,
		"base_atk": 8,
		"base_def": 6,
	},
	"cinder_pup": {
		"name": "Cinder Pup",
		"element": "fire",
		"base_hp": 22,
		"base_atk": 11,
		"base_def": 4,
	},
	"shellhorn": {
		"name": "Shellhorn",
		"element": "earth",
		"base_hp": 36,
		"base_atk": 6,
		"base_def": 9,
	},
}

var maps := {
	"verdant_wilds": {
		"display_name": "Verdant Wilds",
		"scene_path": "res://scenes/overworld/Overworld_Verdant.tscn",
		"wild_pool": ["mossling", "shellhorn", "cinder_pup"],
	}
}

func pick_wild_for_map(map_id: String) -> String:
	var pool: Array = maps[map_id]["wild_pool"]
	return pool[randi() % pool.size()]

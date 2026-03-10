extends Node

# Party: array of creature instances (dicts).
var party: Array = []
var pending_wild_id: String = ""

var current_map_id: String = "verdant_wilds"
var starter_given := false
var battle_return_position: Vector2 = Vector2.ZERO
var battle_return_scene_path: String = ""
var battle_return_map_id: String = ""
var has_battle_return_position := false

const PARTY_MAX := 6
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

func ensure_starter() -> void:
	if starter_given:
		return
	if party.is_empty():
		party.append(new_creature_instance("mossling")) # pick your starter id
	starter_given = true
	
func add_creature_to_collection(mon: Dictionary) -> bool:
	# returns true if it went to party, false if it went to box
	if party.size() < PARTY_MAX:
		party.append(mon)
		return true
	box.append(mon)
	return false
	
func new_creature_instance(id: String) -> Dictionary:
	var c = GameData.creatures[id]
	return {
		"id": id,
		"name": c["name"],
		"element": c["element"],
		"level": 1,
		"hp_max": c["base_hp"],
		"atk": c["base_atk"],
		"def": c["base_def"],
		"hp": c["base_hp"],
	}
	
const SAVE_PATH := "user://savegame.json"

func to_save_dict() -> Dictionary:
	return {
		"party": party,
		"materials": materials,
	}

func from_save_dict(d: Dictionary) -> void:
	party = d.get("party", [])
	var saved_materials: Dictionary = d.get("materials", {})
	materials = materials.duplicate(true)
	for key in saved_materials.keys():
		materials[key] = saved_materials[key]

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

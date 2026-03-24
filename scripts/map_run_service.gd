class_name MapRunService
extends RefCounted

const RESOURCE_NODE_SCENE := preload("res://scenes/overworld/ResourceNode.tscn")
const BOSS_ENCOUNTER_SCENE := preload("res://scenes/overworld/BossEncounter.tscn")
const OVERWORLD_POI_SCENE := preload("res://scenes/overworld/OverworldPOI.tscn")


static func setup_current_map_run(overworld: Node2D) -> void:
	var map_id := GameState.current_map_id
	var run_data := GameState.get_current_map_run(map_id)
	if run_data.is_empty():
		run_data = _generate_map_run(overworld, map_id)
		GameState.set_current_map_run(map_id, run_data)
	_apply_run_to_scene(overworld, map_id, run_data)


static func ensure_objective_resource_node(overworld: Node2D, resource_type: String) -> void:
	var map_id := GameState.current_map_id
	var run_data := GameState.get_current_map_run(map_id)
	if run_data.is_empty():
		return
	for resource_data in run_data.get("resource_nodes", []):
		var existing_type := str(resource_data.get("resource_type", ""))
		var spawn_id := str(resource_data.get("spawn_id", ""))
		if existing_type == resource_type and not GameState.is_resource_spawn_harvested(spawn_id):
			return
	var points := _collect_resource_points(overworld)
	var used_point_ids := {}
	for resource_data in run_data.get("resource_nodes", []):
		var existing_spawn_id := str(resource_data.get("spawn_id", ""))
		var point_id := existing_spawn_id.trim_prefix("%s_" % map_id)
		if not point_id.is_empty():
			used_point_ids[point_id] = true
	var candidates: Array = []
	for point in points:
		if point == null:
			continue
		var point_id: String = point.get_spawn_id()
		if used_point_ids.has(point_id):
			continue
		if point.supports_resource(resource_type):
			candidates.append(point)
	var selected := _pick_weighted_nodes(candidates, 1)
	if selected.is_empty():
		return
	var point = selected[0]
	var resource_nodes: Array = run_data.get("resource_nodes", [])
	resource_nodes.append({
		"spawn_id": "%s_%s" % [map_id, point.get_spawn_id()],
		"position": point.global_position,
		"resource_type": resource_type,
		"visual_type": point.visual_type_override,
		"rarity": point.rarity_override,
		"min_amount": point.min_amount_override,
		"max_amount": point.max_amount_override,
		"rare_drop_table_id": point.rare_drop_table_id,
	})
	run_data["resource_nodes"] = resource_nodes
	_apply_resources(overworld, map_id, run_data)


static func _generate_map_run(overworld: Node2D, map_id: String) -> Dictionary:
	var config := GameData.get_map_run_config(map_id)
	return {
		"map_id": map_id,
		"resource_nodes": _build_resource_spawns(overworld, map_id, config),
		"poi_nodes": _build_poi_spawns(overworld, map_id, config),
		"active_patch_ids": _pick_active_patch_ids(overworld, config),
		"boss_spawn_id": _pick_boss_spawn_id(overworld),
	}


static func _build_resource_spawns(overworld: Node2D, map_id: String, config: Dictionary) -> Array:
	var points := _collect_resource_points(overworld)
	var resource_counts: Dictionary = config.get("resource_counts", {})
	var generated: Array = []
	var used_ids := {}
	if resource_counts.is_empty():
		return _build_weighted_resource_spawns(points, map_id, config, used_ids)

	for resource_type in resource_counts.keys():
		var count := int(resource_counts.get(resource_type, 0))
		if count <= 0:
			continue
		var candidates: Array = []
		for point in points:
			if point == null:
				continue
			var point_id: String = point.get_spawn_id()
			if used_ids.has(point_id):
				continue
			if point.supports_resource(str(resource_type)):
				candidates.append(point)
		var selected := _pick_weighted_nodes(candidates, count)
		for point in selected:
			var spawn_id := "%s_%s" % [map_id, point.get_spawn_id()]
			used_ids[point.get_spawn_id()] = true
			generated.append({
				"spawn_id": spawn_id,
				"position": point.global_position,
				"resource_type": str(resource_type),
				"visual_type": point.visual_type_override,
				"rarity": point.rarity_override,
				"min_amount": point.min_amount_override,
				"max_amount": point.max_amount_override,
				"rare_drop_table_id": point.rare_drop_table_id,
			})
	return generated


static func _build_weighted_resource_spawns(points: Array, map_id: String, config: Dictionary, used_ids: Dictionary) -> Array:
	var total_nodes := int(config.get("total_nodes", 0))
	var resource_weights: Dictionary = config.get("resource_weights", {})
	var resource_types := resource_weights.keys()
	var generated: Array = []
	if total_nodes <= 0 or resource_types.is_empty():
		return generated
	for _i in range(total_nodes):
		var resource_type := _pick_weighted_resource_type(resource_weights)
		if resource_type.is_empty():
			break
		var candidates: Array = []
		for point in points:
			if point == null:
				continue
			if used_ids.has(point.get_spawn_id()):
				continue
			if point.supports_resource(resource_type):
				candidates.append(point)
		var selected := _pick_weighted_nodes(candidates, 1)
		if selected.is_empty():
			continue
		var point = selected[0]
		used_ids[point.get_spawn_id()] = true
		generated.append({
			"spawn_id": "%s_%s" % [map_id, point.get_spawn_id()],
			"position": point.global_position,
			"resource_type": resource_type,
			"visual_type": point.visual_type_override,
			"rarity": point.rarity_override,
			"min_amount": point.min_amount_override,
			"max_amount": point.max_amount_override,
			"rare_drop_table_id": point.rare_drop_table_id,
		})
	return generated


static func _pick_active_patch_ids(overworld: Node2D, config: Dictionary) -> Array:
	var patch_container := overworld.get_node_or_null("EncounterZones")
	var active_ids: Array = []
	if patch_container == null:
		return active_ids
	var optional_patches: Array = []
	for child in patch_container.get_children():
		if child is EncounterPatch:
			if child.always_active:
				active_ids.append(child.get_patch_id())
			else:
				optional_patches.append(child)
	var active_count := int(config.get("active_patch_count", optional_patches.size()))
	for patch in _pick_weighted_nodes(optional_patches, active_count):
		active_ids.append(patch.get_patch_id())
	return active_ids


static func _pick_boss_spawn_id(overworld: Node2D) -> String:
	var boss_points := _collect_boss_points(overworld)
	if boss_points.is_empty():
		return ""
	var selected := _pick_weighted_nodes(boss_points, 1)
	if selected.is_empty():
		return ""
	return str(selected[0].get_spawn_id())


static func _apply_run_to_scene(overworld: Node2D, map_id: String, run_data: Dictionary) -> void:
	_apply_resources(overworld, map_id, run_data)
	_apply_pois(overworld, map_id, run_data)
	_apply_encounter_patches(overworld, run_data)
	_apply_boss(overworld, map_id, run_data)


static func _apply_resources(overworld: Node2D, map_id: String, run_data: Dictionary) -> void:
	var resource_root := _ensure_generated_child(overworld, "GeneratedContent/Resources")
	for child in resource_root.get_children():
		child.queue_free()
	for resource_data in run_data.get("resource_nodes", []):
		var spawn_id := str(resource_data.get("spawn_id", ""))
		if GameState.is_resource_spawn_harvested(spawn_id):
			continue
		var node := RESOURCE_NODE_SCENE.instantiate()
		resource_root.add_child(node)
		node.global_position = resource_data.get("position", Vector2.ZERO)
		node.resource_type = str(resource_data.get("resource_type", "wood"))
		node.biome_type = map_id
		node.spawn_id = spawn_id
		node.rare_drop_table_id = str(resource_data.get("rare_drop_table_id", ""))
		if not str(resource_data.get("visual_type", "")).is_empty():
			node.visual_type = str(resource_data.get("visual_type", ""))
		var rarity := str(resource_data.get("rarity", "auto"))
		if rarity != "auto":
			node.rarity = rarity
		var min_amount := int(resource_data.get("min_amount", 0))
		var max_amount := int(resource_data.get("max_amount", 0))
		if min_amount > 0:
			node.min_amount = min_amount
		if max_amount > 0:
			node.max_amount = max(max_amount, node.min_amount)


static func _apply_pois(overworld: Node2D, map_id: String, run_data: Dictionary) -> void:
	var poi_root := _ensure_generated_child(overworld, "GeneratedContent/POIs")
	for child in poi_root.get_children():
		child.queue_free()
	for poi_data in run_data.get("poi_nodes", []):
		var poi_id := str(poi_data.get("poi_id", ""))
		if poi_id.is_empty() or GameState.is_poi_interacted(poi_id):
			continue
		var poi := OVERWORLD_POI_SCENE.instantiate()
		poi_root.add_child(poi)
		poi.global_position = poi_data.get("position", Vector2.ZERO)
		poi.configure(poi_data, map_id)


static func _apply_encounter_patches(overworld: Node2D, run_data: Dictionary) -> void:
	var patch_container := overworld.get_node_or_null("EncounterZones")
	if patch_container == null:
		return
	var active_lookup := {}
	for patch_id in run_data.get("active_patch_ids", []):
		active_lookup[str(patch_id)] = true
	for child in patch_container.get_children():
		if child is EncounterPatch:
			child.set_active_for_run(active_lookup.has(child.get_patch_id()))
	_sync_encounter_tile_layer(overworld)


static func _apply_boss(overworld: Node2D, map_id: String, run_data: Dictionary) -> void:
	var boss_root := _ensure_generated_child(overworld, "GeneratedContent/Boss")
	for child in boss_root.get_children():
		child.queue_free()
	var boss_config := GameData.get_boss_config(map_id)
	var boss_spawn_id := str(run_data.get("boss_spawn_id", ""))
	var primary := GameState.get_primary_objective()
	var boss_objective_active := (
		str(primary.get("type", "")) == GameData.OBJECTIVE_TYPE_BOSS_DEFEAT
		and not bool(primary.get("completed", false))
	)
	if boss_config.is_empty() or boss_spawn_id.is_empty() or GameState.is_boss_cleared(boss_spawn_id) or not boss_objective_active:
		return
	var marker := _find_boss_point(overworld, boss_spawn_id)
	if marker == null:
		return
	var boss := BOSS_ENCOUNTER_SCENE.instantiate()
	boss_root.add_child(boss)
	boss.global_position = marker.global_position
	var boss_data := boss_config.duplicate(true)
	boss_data["spawn_id"] = boss_spawn_id
	boss.configure(boss_data)


static func refresh_boss_visibility(overworld: Node2D) -> void:
	var map_id := GameState.current_map_id
	var run_data := GameState.get_current_map_run(map_id)
	if run_data.is_empty():
		return
	_apply_boss(overworld, map_id, run_data)


static func _collect_resource_points(overworld: Node2D) -> Array:
	var container := overworld.get_node_or_null("ResourceSpawnPoints")
	if container == null:
		return []
	var points: Array = []
	for child in container.get_children():
		if child is ResourceSpawnPoint:
			points.append(child)
	return points


static func _build_poi_spawns(overworld: Node2D, map_id: String, config: Dictionary) -> Array:
	var points := _collect_poi_points(overworld)
	var point_lookup := {}
	for point in points:
		if point == null:
			continue
		point_lookup[point.get_spawn_id()] = point
	var generated: Array = []
	for raw_poi in config.get("poi_spawns", []):
		if not (raw_poi is Dictionary):
			continue
		var poi_data: Dictionary = raw_poi
		var point_id := str(poi_data.get("spawn_id", ""))
		var poi_id := str(poi_data.get("poi_id", ""))
		var point = point_lookup.get(point_id)
		var definition := GameData.get_poi_definition(poi_id)
		if point == null or definition.is_empty():
			continue
		definition["position"] = point.global_position
		definition["spawn_id"] = "%s_%s" % [map_id, point_id]
		generated.append(definition)
	return generated


static func _collect_poi_points(overworld: Node2D) -> Array:
	var container := overworld.get_node_or_null("POISpawnPoints")
	if container == null:
		return []
	var points: Array = []
	for child in container.get_children():
		if child is POISpawnPoint:
			points.append(child)
	return points


static func _collect_boss_points(overworld: Node2D) -> Array:
	var container := overworld.get_node_or_null("BossSpawnPoints")
	if container == null:
		return []
	var points: Array = []
	for child in container.get_children():
		if child is BossSpawnPoint:
			points.append(child)
	return points


static func _find_boss_point(overworld: Node2D, spawn_id: String) -> BossSpawnPoint:
	for point in _collect_boss_points(overworld):
		if point.get_spawn_id() == spawn_id:
			return point
	return null


static func _pick_weighted_nodes(candidates: Array, count: int) -> Array:
	var selected: Array = []
	var pool := candidates.duplicate()
	while count > 0 and not pool.is_empty():
		var chosen = _pick_weighted_node(pool)
		if chosen == null:
			break
		selected.append(chosen)
		pool.erase(chosen)
		count -= 1
	return selected


static func _pick_weighted_node(candidates: Array):
	if candidates.is_empty():
		return null
	var total_weight := 0.0
	for candidate in candidates:
		total_weight += max(_get_weight(candidate), 0.01)
	var roll := randf() * total_weight
	for candidate in candidates:
		roll -= max(_get_weight(candidate), 0.01)
		if roll <= 0.0:
			return candidate
	return candidates.back()


static func _get_weight(candidate) -> float:
	if candidate == null:
		return 1.0
	if candidate is ResourceSpawnPoint or candidate is BossSpawnPoint:
		return float(candidate.spawn_weight)
	if candidate is EncounterPatch:
		return float(candidate.activation_weight)
	return 1.0


static func _pick_weighted_resource_type(resource_weights: Dictionary) -> String:
	var total_weight := 0.0
	for resource_type in resource_weights.keys():
		total_weight += max(float(resource_weights.get(resource_type, 0.0)), 0.01)
	if total_weight <= 0.0:
		return ""
	var roll := randf() * total_weight
	for resource_type in resource_weights.keys():
		roll -= max(float(resource_weights.get(resource_type, 0.0)), 0.01)
		if roll <= 0.0:
			return str(resource_type)
	return str(resource_weights.keys().back())


static func _sync_encounter_tile_layer(overworld: Node2D) -> void:
	var encounter_layer = overworld.get_node_or_null("TileMap_Encounter")
	var ground_layer = overworld.get_node_or_null("TileMap_Ground")
	var patch_container := overworld.get_node_or_null("EncounterZones")
	if encounter_layer == null or ground_layer == null or patch_container == null:
		return
	var rows_source: PackedStringArray = ground_layer.layout_rows
	var built_rows: Array = []
	for row in rows_source:
		built_rows.append(".".repeat(row.length()))
	var tile_size := int(encounter_layer.tile_size)
	for y in range(rows_source.size()):
		var row_text: String = built_rows[y]
		for x in range(row_text.length()):
			var world_center: Vector2 = encounter_layer.to_global(Vector2((x + 0.5) * tile_size, (y + 0.5) * tile_size))
			for child in patch_container.get_children():
				if child is EncounterPatch and child.is_active_for_run() and child.contains_point(world_center):
					row_text = _set_row_char(row_text, x, child.encounter_tile_key)
			built_rows[y] = row_text
	encounter_layer.set_layout_rows(PackedStringArray(built_rows))


static func _set_row_char(row_text: String, index: int, key: String) -> String:
	if index < 0 or index >= row_text.length() or key.is_empty():
		return row_text
	return row_text.substr(0, index) + key.substr(0, 1) + row_text.substr(index + 1)


static func _ensure_generated_child(root: Node, path: String) -> Node:
	var node := root.get_node_or_null(path)
	if node != null:
		return node
	var current: Node = root
	for part in path.split("/"):
		var child := current.get_node_or_null(part)
		if child == null:
			child = Node2D.new()
			child.name = part
			current.add_child(child)
		current = child
	return current

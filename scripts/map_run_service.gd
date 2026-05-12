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
	var map_id: String = GameState.current_map_id
	var run_data: Dictionary = GameState.get_current_map_run(map_id)
	if run_data.is_empty():
		return
	for resource_data: Variant in run_data.get("resource_nodes", []):
		var rd: Dictionary = resource_data
		if str(rd.get("resource_type", "")) == resource_type \
				and not GameState.is_resource_spawn_harvested(str(rd.get("spawn_id", ""))):
			return
	var used_positions: Array[Vector2] = []
	for resource_data: Variant in run_data.get("resource_nodes", []):
		var rd: Dictionary = resource_data
		used_positions.append(rd.get("position", Vector2.ZERO))
	var new_positions: Array = _sample_walkable_positions(overworld, 1, used_positions, 64.0)
	if new_positions.is_empty():
		return
	var resource_nodes: Array = run_data.get("resource_nodes", [])
	resource_nodes.append({
		"spawn_id": "%s_r%d" % [map_id, resource_nodes.size()],
		"position": new_positions[0],
		"resource_type": resource_type,
		"visual_type": "",
		"rarity": "auto",
		"min_amount": 0,
		"max_amount": 0,
		"rare_drop_table_id": "",
	})
	run_data["resource_nodes"] = resource_nodes
	_apply_resources(overworld, map_id, run_data)


static func _generate_map_run(overworld: Node2D, map_id: String) -> Dictionary:
	var config := GameData.get_map_run_config(map_id)
	var active_patch_ids := _pick_active_patch_ids(overworld, config)
	return {
		"map_id": map_id,
		"resource_nodes": _build_resource_spawns(overworld, map_id, config),
		"poi_nodes": _build_poi_spawns(overworld, map_id, config, active_patch_ids),
		"active_patch_ids": active_patch_ids,
		"boss_spawn_id": _pick_boss_spawn_id(overworld),
	}


static func _build_resource_spawns(overworld: Node2D, map_id: String, config: Dictionary) -> Array:
	var resource_counts: Dictionary = config.get("resource_counts", {})
	if resource_counts.is_empty():
		return _build_weighted_resource_spawns(overworld, map_id, config)
	var total_needed: int = 0
	for rt: Variant in resource_counts.keys():
		total_needed += int(resource_counts.get(rt, 0))
	var positions: Array = _sample_walkable_positions(overworld, total_needed, [], 64.0)
	var generated: Array = []
	var pos_index: int = 0
	for resource_type: Variant in resource_counts.keys():
		var count: int = int(resource_counts.get(resource_type, 0))
		for _i: int in range(count):
			if pos_index >= positions.size():
				break
			var world_pos: Vector2 = positions[pos_index]
			pos_index += 1
			generated.append({
				"spawn_id": "%s_r%d" % [map_id, pos_index],
				"position": world_pos,
				"resource_type": str(resource_type),
				"visual_type": "",
				"rarity": "auto",
				"min_amount": 0,
				"max_amount": 0,
				"rare_drop_table_id": "",
			})
	return generated


static func _build_weighted_resource_spawns(overworld: Node2D, map_id: String, config: Dictionary) -> Array:
	var total_nodes: int = int(config.get("total_nodes", 0))
	var resource_weights: Dictionary = config.get("resource_weights", {})
	var generated: Array = []
	if total_nodes <= 0 or resource_weights.is_empty():
		return generated
	var positions: Array = _sample_walkable_positions(overworld, total_nodes, [], 64.0)
	for pos_index: int in range(positions.size()):
		var resource_type: String = _pick_weighted_resource_type(resource_weights)
		if resource_type.is_empty():
			break
		generated.append({
			"spawn_id": "%s_r%d" % [map_id, pos_index],
			"position": positions[pos_index],
			"resource_type": resource_type,
			"visual_type": "",
			"rarity": "auto",
			"min_amount": 0,
			"max_amount": 0,
			"rare_drop_table_id": "",
		})
	return generated


static func _sample_walkable_positions(
		overworld: Node2D,
		count: int,
		exclude_positions: Array,
		min_spacing: float) -> Array:
	var ground_layer: Node = overworld.get_node_or_null("TileMap_Ground")
	if ground_layer == null:
		return []
	var rows: PackedStringArray = ground_layer.layout_rows
	var tile_size: int = ground_layer.tile_size
	var candidates: Array = []
	for row_i: int in range(rows.size()):
		for col_i: int in range(rows[row_i].length()):
			var top_left: Vector2 = ground_layer.to_global(
				Vector2(float(col_i * tile_size), float(row_i * tile_size)))
			var center: Vector2 = top_left + Vector2(tile_size * 0.5, tile_size * 0.5)
			var tile := Vector2i(col_i, row_i)
			if _can_place_generated_node_at(overworld, tile, top_left, center, tile_size) \
					and not _is_near_exit_zone(overworld, center, float(tile_size * 5)):
				candidates.append(top_left)
	candidates.shuffle()
	var result: Array = []
	for pos: Variant in candidates:
		var world_pos: Vector2 = pos
		var too_close: bool = false
		for excl: Variant in exclude_positions:
			if world_pos.distance_to(excl) < min_spacing:
				too_close = true
				break
		if not too_close:
			for existing: Variant in result:
				if world_pos.distance_to(existing) < min_spacing:
					too_close = true
					break
		if not too_close:
			result.append(world_pos)
			if result.size() >= count:
				break
	return result


static func _can_place_generated_node_at(
		overworld: Node2D,
		tile: Vector2i,
		top_left: Vector2,
		center: Vector2,
		tile_size: int) -> bool:
	if not _has_spawn_object_clearance(overworld, tile):
		return false
	var inset: float = float(tile_size) * 0.28
	var sample_points: Array[Vector2] = [
		center,
		top_left + Vector2(inset, inset),
		top_left + Vector2(float(tile_size) - inset, inset),
		top_left + Vector2(inset, float(tile_size) - inset),
		top_left + Vector2(float(tile_size) - inset, float(tile_size) - inset),
	]
	for sample_point: Vector2 in sample_points:
		if not overworld.can_move_to_world_position(sample_point):
			return false
	return true


static func _has_spawn_object_clearance(overworld: Node2D, tile: Vector2i) -> bool:
	var object_layer = overworld.get_node_or_null("TileMap_Objects")
	if object_layer == null or not object_layer.has_method("has_tile_at"):
		return true
	for y_offset: int in range(-1, 2):
		for x_offset: int in range(-1, 2):
			if object_layer.has_tile_at(tile + Vector2i(x_offset, y_offset)):
				return false
	return true


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
	_clear_generated_group(overworld, "generated_resource_node")
	for resource_data in run_data.get("resource_nodes", []):
		var spawn_id := str(resource_data.get("spawn_id", ""))
		if GameState.is_resource_spawn_harvested(spawn_id):
			continue
		var node := RESOURCE_NODE_SCENE.instantiate()
		overworld.add_child(node)
		node.add_to_group("generated_resource_node")
		node.add_to_group("world_y_sort")
		node.set_meta("world_y_sort_origin", 18)
		node.global_position = resource_data.get("position", Vector2.ZERO) + Vector2(16, 16)
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
	_clear_generated_group(overworld, "generated_poi_node")
	for poi_data in run_data.get("poi_nodes", []):
		var poi_id := str(poi_data.get("poi_id", ""))
		if poi_id.is_empty() or GameState.is_poi_interacted(poi_id):
			continue
		var poi := OVERWORLD_POI_SCENE.instantiate()
		overworld.add_child(poi)
		poi.add_to_group("generated_poi_node")
		poi.add_to_group("world_y_sort")
		poi.set_meta("world_y_sort_origin", 20)
		poi.global_position = poi_data.get("position", Vector2.ZERO) + Vector2(16, 16)
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
	_clear_generated_group(overworld, "generated_boss_node")
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
	overworld.add_child(boss)
	boss.add_to_group("generated_boss_node")
	boss.add_to_group("world_y_sort")
	boss.set_meta("world_y_sort_origin", 20)
	boss.global_position = marker.global_position
	var boss_data := boss_config.duplicate(true)
	boss_data["spawn_id"] = boss_spawn_id
	boss.configure(boss_data)


static func _clear_generated_group(overworld: Node2D, group_name: String) -> void:
	var tree := overworld.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(group_name):
		if node is Node and overworld.is_ancestor_of(node):
			node.queue_free()


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


static func _build_poi_spawns(overworld: Node2D, map_id: String, config: Dictionary, _active_patch_ids: Array) -> Array:
	var points := _collect_poi_points(overworld)
	var generated: Array = []
	var used_point_ids := {}
	for raw_poi in config.get("poi_spawns", []):
		if not (raw_poi is Dictionary):
			continue
		var poi_data: Dictionary = raw_poi
		var poi_id := str(poi_data.get("poi_id", ""))
		var definition := GameData.get_poi_definition(poi_id)
		if definition.is_empty():
			continue
		var candidates := _filter_poi_points(points, poi_data, definition, used_point_ids)
		var selected := _pick_weighted_nodes(candidates, 1)
		if selected.is_empty():
			continue
		var point = selected[0]
		var point_id: String = point.get_spawn_id()
		used_point_ids[point_id] = true
		definition["position"] = point.global_position
		definition["spawn_id"] = "%s_%s" % [map_id, point_id]
		generated.append(definition)
	return generated


static func _filter_poi_points(points: Array, poi_data: Dictionary, definition: Dictionary, used_point_ids: Dictionary) -> Array:
	var candidate_spawn_ids: Array = poi_data.get("candidate_spawn_ids", [])
	var fixed_spawn_id := str(poi_data.get("spawn_id", ""))
	if bool(poi_data.get("fixed_spawn", false)) and not fixed_spawn_id.is_empty():
		candidate_spawn_ids = [fixed_spawn_id]
	var candidate_lookup := {}
	for spawn_id in candidate_spawn_ids:
		candidate_lookup[str(spawn_id)] = true
	var generated: Array = []
	for point in points:
		if point == null:
			continue
		var point_id: String = point.get_spawn_id()
		if used_point_ids.has(point_id):
			continue
		if not candidate_lookup.is_empty() and not candidate_lookup.has(point_id):
			continue
		if point.has_method("supports_poi") and not point.supports_poi(definition):
			continue
		generated.append(point)
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
	if candidate is POISpawnPoint:
		return float(candidate.activation_weight)
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
	var object_layer = overworld.get_node_or_null("TileMap_Objects")
	var patch_container := overworld.get_node_or_null("EncounterZones")
	if encounter_layer == null or ground_layer == null or patch_container == null:
		return
	var rows_source: PackedStringArray = ground_layer.layout_rows
	var built_rows: Array = []
	var authored_rows: PackedStringArray = encounter_layer.layout_rows
	for row_index: int in range(rows_source.size()):
		if row_index < authored_rows.size():
			var authored_row := str(authored_rows[row_index])
			var target_length := str(rows_source[row_index]).length()
			if authored_row.length() < target_length:
				authored_row += ".".repeat(target_length - authored_row.length())
			elif authored_row.length() > target_length:
				authored_row = authored_row.substr(0, target_length)
			built_rows.append(authored_row)
		else:
			built_rows.append(".".repeat(str(rows_source[row_index]).length()))
	var tile_size := int(encounter_layer.tile_size)
	var sample_offsets: Array[Vector2] = [
		Vector2(0.5,  0.5),   # center
		Vector2(0.05, 0.05),  # NW corner
		Vector2(0.95, 0.05),  # NE corner
		Vector2(0.05, 0.95),  # SW corner
		Vector2(0.95, 0.95),  # SE corner
	]
	for y in range(rows_source.size()):
		var row_text: String = built_rows[y]
		for x in range(row_text.length()):
			if object_layer != null and object_layer.has_method("has_tile_at") and object_layer.has_tile_at(Vector2i(x, y)):
				row_text = _set_row_char(row_text, x, ".")
				continue
			for child in patch_container.get_children():
				if not (child is EncounterPatch and child.is_active_for_run()):
					continue
				var hit := false
				for offset: Vector2 in sample_offsets:
					var world_pt: Vector2 = encounter_layer.to_global(Vector2((x + offset.x) * tile_size, (y + offset.y) * tile_size))
					if child.contains_point(world_pt):
						hit = true
						break
				if hit:
					row_text = _set_row_char(row_text, x, child.encounter_tile_key)
			built_rows[y] = row_text
	encounter_layer.set_layout_rows(PackedStringArray(built_rows))


static func _is_near_exit_zone(overworld: Node2D, world_position: Vector2, radius: float) -> bool:
	var exit_zone := overworld.get_node_or_null("ExitZone")
	if exit_zone == null:
		return false
	return world_position.distance_to(exit_zone.global_position) < radius


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

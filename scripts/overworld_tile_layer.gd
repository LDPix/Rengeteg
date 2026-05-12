@tool
extends TileMapLayer

@export var tile_size := 32
@export var layout_rows: PackedStringArray = []
@export var tile_paths: Dictionary = {}
@export var tile_tags: Dictionary = {}
@export var preview_colors: Dictionary = {}
@export var show_preview_in_game := false
# Wang autotiling sets. Format per key:
#   { "png": String, "json": String, "upper_chars": Array }
# upper_chars: which tile chars count as "upper" terrain when sampling corners.
# Both terrain chars sharing a tileset list the same png/json with the same upper_chars.
@export var wang_sets: Dictionary = {}
# Edge autotiling sets. Format per key:
#   { "png": String, "json": String, "upper_chars": Array }
# Uses cardinal neighbors (N/E/S/W), useful for paths where the current tile
# should stay mostly itself with only edge decoration.
@export var edge_sets: Dictionary = {}
# char → Array of texture paths; all used as random variants per cell position.
@export var tile_variant_pools: Dictionary = {}
# char → float scale multiplier; tiles draw larger/smaller than their cell.
@export var tile_scales: Dictionary = {}
# Tile chars listed here are spawned as individual Sprite2D nodes on the parent
# so they participate in the parent's y_sort_enabled ordering.
@export var y_sort_keys: Array[String] = []

var _textures: Dictionary = {}
var _variant_textures: Dictionary = {}
# Keyed by png path → { "texture": Texture2D, "tiles": Array }
# Each tile dict: { "nw", "ne", "sw", "se": String, "src": Rect2 }
var _wang_cache: Dictionary = {}
# Keyed by png path → { "texture": Texture2D, "tiles": Array }
# Each tile dict: { "n", "e", "s", "w": String, "src": Rect2 }
var _edge_cache: Dictionary = {}
var _y_sort_sprites: Array[Node] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reload_textures()
	if not Engine.is_editor_hint() and not y_sort_keys.is_empty():
		_spawn_y_sort_sprites()
	queue_redraw()


func _exit_tree() -> void:
	for s: Node in _y_sort_sprites:
		if is_instance_valid(s):
			s.queue_free()
	_y_sort_sprites.clear()


func _spawn_y_sort_sprites() -> void:
	_clear_y_sort_sprites()
	var parent: Node = get_parent()
	if parent == null:
		return
	for row_index: int in range(layout_rows.size()):
		var row: String = layout_rows[row_index]
		for col_index: int in range(row.length()):
			var key: String = row.substr(col_index, 1)
			if key == "." or key not in y_sort_keys:
				continue
			var texture: Texture2D = _pick_tile_texture(key, col_index, row_index)
			if texture == null:
				continue
			var tile_scale: float = float(tile_scales.get(key, 1.0))
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = texture
			sprite.scale = Vector2(tile_scale, tile_scale)
			var sprite_position := position + Vector2(col_index * tile_size + tile_size * 0.5, row_index * tile_size + tile_size * 0.5)
			sprite.position = sprite_position
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var sort_origin := int(tile_size * tile_scale * 0.5)
			sprite.set_meta("world_y_sort_origin", sort_origin)
			sprite.z_as_relative = false
			sprite.z_index = int(sprite_position.y) + sort_origin
			sprite.add_to_group("world_y_sort")
			_y_sort_sprites.append(sprite)
			call_deferred("_add_y_sort_sprite", sprite)


func _add_y_sort_sprite(sprite) -> void:
	if not is_instance_valid(sprite) or sprite.is_queued_for_deletion():
		return
	var parent: Node = get_parent()
	if parent == null or sprite.get_parent() != null:
		return
	parent.add_child(sprite)


func _clear_y_sort_sprites() -> void:
	for sprite: Node in _y_sort_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_y_sort_sprites.clear()


func _pick_tile_texture(key: String, col: int, row: int) -> Texture2D:
	var variants: Array = _variant_textures.get(key, [])
	if not variants.is_empty():
		var h: int = col * 374761393 + row * 668265263
		h = h ^ (h >> 13)
		h = h * 1274126177
		h = h ^ (h >> 16)
		return variants[absi(h) % variants.size()]
	return _textures.get(key)


func _draw() -> void:
	for row_index: int in range(layout_rows.size()):
		var row := layout_rows[row_index]
		for col_index: int in range(row.length()):
			var key := row.substr(col_index, 1)
			if key == ".":
				continue
			if not Engine.is_editor_hint() and key in y_sort_keys:
				continue
			var cell_rect := Rect2(col_index * tile_size, row_index * tile_size, tile_size, tile_size)

			if edge_sets.has(key):
				var cfg: Dictionary = edge_sets[key]
				var png_path: String = str(cfg.get("png", ""))
				var upper_chars: Array = cfg.get("upper_chars", [])
				if _edge_cache.has(png_path):
					var entry: Dictionary = _edge_cache[png_path]
					var src: Rect2 = _edge_src_rect(col_index, row_index, upper_chars, entry["tiles"])
					draw_texture_rect_region(entry["texture"], cell_rect, src)
					continue

			if wang_sets.has(key):
				var cfg: Dictionary = wang_sets[key]
				var png_path: String = str(cfg.get("png", ""))
				var upper_chars: Array = cfg.get("upper_chars", [])
				if _wang_cache.has(png_path):
					var entry: Dictionary = _wang_cache[png_path]
					var src: Rect2 = _wang_src_rect(col_index, row_index, upper_chars, entry["tiles"])
					draw_texture_rect_region(entry["texture"], cell_rect, src)
					continue

			var texture: Texture2D
			var variants: Array = _variant_textures.get(key, [])
			if not variants.is_empty():
				var h: int = col_index * 374761393 + row_index * 668265263
				h = h ^ (h >> 13)
				h = h * 1274126177
				h = h ^ (h >> 16)
				texture = variants[absi(h) % variants.size()]
			else:
				texture = _textures.get(key)
			if texture != null:
				var tile_scale: float = float(tile_scales.get(key, 1.0))
				if absf(tile_scale - 1.0) > 0.001:
					var center := Vector2(cell_rect.position.x + cell_rect.size.x * 0.5, cell_rect.position.y + cell_rect.size.y * 0.5)
					var scaled_size := cell_rect.size * tile_scale
					var scaled_rect := Rect2(center - scaled_size * 0.5, scaled_size)
					draw_texture_rect(texture, scaled_rect, false)
				else:
					draw_texture_rect(texture, cell_rect, false)
				continue
			if Engine.is_editor_hint() or show_preview_in_game:
				var preview_color: Variant = preview_colors.get(key)
				if preview_color != null:
					draw_rect(cell_rect, preview_color)


func _reload_textures() -> void:
	_textures.clear()
	for key: Variant in tile_paths.keys():
		var tile_path := str(tile_paths[key])
		if tile_path.is_empty():
			continue
		var texture: Texture2D = load(tile_path)
		if texture != null:
			_textures[str(key)] = texture

	_variant_textures.clear()
	for key: Variant in tile_variant_pools.keys():
		var paths: Array = tile_variant_pools[key]
		var textures: Array[Texture2D] = []
		for path: Variant in paths:
			var tex: Texture2D = load(str(path))
			if tex != null:
				textures.append(tex)
		if not textures.is_empty():
			_variant_textures[str(key)] = textures

	_edge_cache.clear()
	for key: Variant in edge_sets.keys():
		var cfg: Dictionary = edge_sets[key]
		var png_path: String = str(cfg.get("png", ""))
		if png_path.is_empty() or _edge_cache.has(png_path):
			continue
		var texture: Texture2D = load(png_path)
		if texture == null:
			continue
		var tiles: Array = []
		var json_path: String = str(cfg.get("json", ""))
		if not json_path.is_empty() and FileAccess.file_exists(json_path):
			var raw: String = FileAccess.get_file_as_string(json_path)
			var parsed: Variant = JSON.parse_string(raw)
			if parsed is Dictionary:
				var root: Dictionary = parsed
				var td: Dictionary = root["tileset_data"]
				for t: Variant in td["tiles"]:
					var tile_dict: Dictionary = t
					var edges: Dictionary = tile_dict["edges"]
					var bb: Dictionary = tile_dict["bounding_box"]
					tiles.append({
						"n": str(edges["N"]),
						"e": str(edges["E"]),
						"s": str(edges["S"]),
						"w": str(edges["W"]),
						"src": Rect2(int(bb["x"]), int(bb["y"]), int(bb["width"]), int(bb["height"]))
					})
		_edge_cache[png_path] = {"texture": texture, "tiles": tiles}

	_wang_cache.clear()
	for key: Variant in wang_sets.keys():
		var cfg: Dictionary = wang_sets[key]
		var png_path: String = str(cfg.get("png", ""))
		if png_path.is_empty() or _wang_cache.has(png_path):
			continue
		var texture: Texture2D = load(png_path)
		if texture == null:
			continue
		var tiles: Array = []
		var json_path: String = str(cfg.get("json", ""))
		if not json_path.is_empty() and FileAccess.file_exists(json_path):
			var raw: String = FileAccess.get_file_as_string(json_path)
			var parsed: Variant = JSON.parse_string(raw)
			if parsed is Dictionary:
				var root: Dictionary = parsed
				var td: Dictionary = root["tileset_data"]
				for t: Variant in td["tiles"]:
					var tile_dict: Dictionary = t
					var corners: Dictionary = tile_dict["corners"]
					var bb: Dictionary = tile_dict["bounding_box"]
					tiles.append({
						"nw": str(corners["NW"]),
						"ne": str(corners["NE"]),
						"sw": str(corners["SW"]),
						"se": str(corners["SE"]),
						"src": Rect2(int(bb["x"]), int(bb["y"]), int(bb["width"]), int(bb["height"]))
					})
		_wang_cache[png_path] = {"texture": texture, "tiles": tiles}


func _edge_src_rect(col: int, row: int, upper_chars: Array, tiles: Array) -> Rect2:
	var n: String = _edge_terrain(col, row - 1, upper_chars)
	var e: String = _edge_terrain(col + 1, row, upper_chars)
	var s: String = _edge_terrain(col, row + 1, upper_chars)
	var w: String = _edge_terrain(col - 1, row, upper_chars)
	for tile: Dictionary in tiles:
		if tile["n"] == n and tile["e"] == e and tile["s"] == s and tile["w"] == w:
			return tile["src"]
	if not tiles.is_empty():
		return (tiles[0] as Dictionary)["src"]
	return Rect2(0, 0, 16, 16)


func _edge_terrain(col: int, row: int, upper_chars: Array) -> String:
	var key: String = get_tile_key_at(Vector2i(col, row))
	return "upper" if key in upper_chars else "lower"


func _wang_src_rect(col: int, row: int, upper_chars: Array, tiles: Array) -> Rect2:
	var nw: String = _corner_terrain(col - 1, row - 1, upper_chars)
	var ne: String = _corner_terrain(col + 1, row - 1, upper_chars)
	var sw: String = _corner_terrain(col - 1, row + 1, upper_chars)
	var se: String = _corner_terrain(col + 1, row + 1, upper_chars)
	for tile: Dictionary in tiles:
		if tile["nw"] == nw and tile["ne"] == ne and tile["sw"] == sw and tile["se"] == se:
			return tile["src"]
	if not tiles.is_empty():
		return (tiles[0] as Dictionary)["src"]
	return Rect2(0, 0, 16, 16)


func _corner_terrain(col: int, row: int, upper_chars: Array) -> String:
	var key: String = get_tile_key_at(Vector2i(col, row))
	return "upper" if key in upper_chars else "lower"


func set_layout_rows(rows: PackedStringArray) -> void:
	layout_rows = rows
	if not Engine.is_editor_hint() and not y_sort_keys.is_empty():
		_spawn_y_sort_sprites()
	queue_redraw()


func has_any_tiles() -> bool:
	for row: String in layout_rows:
		if "." in row and row.replace(".", "").is_empty():
			continue
		if not row.is_empty():
			for col_index: int in range(row.length()):
				if row.substr(col_index, 1) != ".":
					return true
	return false


func has_tile_at(tile: Vector2i) -> bool:
	return get_tile_key_at(tile) != ""


func get_tile_key_at(tile: Vector2i) -> String:
	if tile.y < 0 or tile.y >= layout_rows.size():
		return ""
	var row := layout_rows[tile.y]
	if tile.x < 0 or tile.x >= row.length():
		return ""
	var key := row.substr(tile.x, 1)
	return "" if key == "." else key


func get_tile_tag_at(tile: Vector2i) -> String:
	var key := get_tile_key_at(tile)
	if key.is_empty():
		return ""
	return str(tile_tags.get(key, key))

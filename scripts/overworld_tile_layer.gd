@tool
extends TileMapLayer

@export var tile_size := 32
@export var layout_rows: PackedStringArray = []
@export var tile_paths: Dictionary = {}
@export var tile_tags: Dictionary = {}
@export var preview_colors: Dictionary = {}
@export var show_preview_in_game := false

var _textures: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reload_textures()
	queue_redraw()


func _draw() -> void:
	for row_index in range(layout_rows.size()):
		var row := layout_rows[row_index]
		for col_index in range(row.length()):
			var key := row.substr(col_index, 1)
			if key == ".":
				continue
			var texture: Texture2D = _textures.get(key)
			var cell_rect := Rect2(col_index * tile_size, row_index * tile_size, tile_size, tile_size)
			if texture != null:
				draw_texture_rect(texture, cell_rect, false)
				continue
			if Engine.is_editor_hint() or show_preview_in_game:
				var preview_color = preview_colors.get(key)
				if preview_color != null:
					draw_rect(cell_rect, preview_color)


func _reload_textures() -> void:
	_textures.clear()
	for key in tile_paths.keys():
		var tile_path := str(tile_paths[key])
		if tile_path.is_empty():
			continue
		var texture := load(tile_path)
		if texture != null:
			_textures[str(key)] = texture


func set_layout_rows(rows: PackedStringArray) -> void:
	layout_rows = rows
	queue_redraw()


func has_any_tiles() -> bool:
	for row in layout_rows:
		if "." in row and row.replace(".", "").is_empty():
			continue
		if not row.is_empty():
			for col_index in range(row.length()):
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

@tool
extends TileMapLayer

@export var tile_size := 32
@export var layout_rows: PackedStringArray = []
@export var tile_paths: Dictionary = {}

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
			if texture == null:
				continue
			draw_texture_rect(texture, Rect2(col_index * tile_size, row_index * tile_size, tile_size, tile_size), false)


func _reload_textures() -> void:
	_textures.clear()
	for key in tile_paths.keys():
		var tile_path := str(tile_paths[key])
		if tile_path.is_empty():
			continue
		var texture := load(tile_path)
		if texture != null:
			_textures[str(key)] = texture

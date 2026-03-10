extends PanelContainer

@onready var label: Label = $Padding/Label


func configure(chip_text: String, palette: String) -> void:
	label.text = chip_text
	var colors := _palette_colors(palette)
	add_theme_stylebox_override("panel", _build_stylebox(colors.background))
	label.add_theme_color_override("font_color", colors.text)


func _ready() -> void:
	if label.text.is_empty():
		label.text = "Creature"
	if not has_theme_stylebox_override("panel"):
		configure(label.text, "neutral")


func _palette_colors(palette: String) -> Dictionary:
	match palette:
		"grass":
			return {
				"background": Color("E8F5E9"),
				"text": Color("2E7D32"),
			}
		"fire":
			return {
				"background": Color("FFF3E0"),
				"text": Color("BF360C"),
			}
		_:
			return {
				"background": Color("F1F3F4"),
				"text": Color("424242"),
			}


func _build_stylebox(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	return style

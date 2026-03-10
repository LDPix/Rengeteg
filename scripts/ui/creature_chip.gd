extends Button

@export var selected := false
var palette_name := "neutral"


func configure(chip_text: String, palette: String, is_selected: bool = false) -> void:
	text = chip_text
	palette_name = palette
	selected = is_selected
	_apply_style(_palette_colors(palette))


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(custom_minimum_size.x, 52)
	if text.is_empty():
		text = "Creature"
	_apply_style(_palette_colors(palette_name))


func set_selected(value: bool) -> void:
	selected = value
	_apply_style(_palette_colors(palette_name))


func _palette_colors(palette: String) -> Dictionary:
	match palette:
		"grass":
			return {
				"background": Color("E8F5E9"),
				"border": Color("A5D6A7"),
				"text": Color("2E7D32"),
				"selected_background": Color("D7F0DB"),
				"selected_border": Color("2E7D32"),
			}
		"fire":
			return {
				"background": Color("FFF3E0"),
				"border": Color("FFCC80"),
				"text": Color("BF360C"),
				"selected_background": Color("FFE0B2"),
				"selected_border": Color("BF360C"),
			}
		"earth":
			return {
				"background": Color("EFEBE9"),
				"border": Color("BCAAA4"),
				"text": Color("5D4037"),
				"selected_background": Color("E0D4CF"),
				"selected_border": Color("6D4C41"),
			}
		_:
			return {
				"background": Color("F1F3F4"),
				"border": Color("CFD8DC"),
				"text": Color("424242"),
				"selected_background": Color("E3E8EA"),
				"selected_border": Color("424242"),
			}


func _apply_style(colors: Dictionary) -> void:
	var fill: Color = colors["background"]
	var border: Color = colors["border"]
	if selected:
		fill = colors["selected_background"]
		border = colors["selected_border"]

	var normal := _build_stylebox(fill, border, selected)
	var hover := _build_stylebox(fill.lightened(0.04), border, selected)
	var pressed := _build_stylebox(fill.darkened(0.04), border, selected)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("focus", hover)
	add_theme_color_override("font_color", colors["text"])
	add_theme_color_override("font_hover_color", colors["text"])
	add_theme_color_override("font_pressed_color", colors["text"])
	add_theme_font_size_override("font_size", 15)


func _build_stylebox(fill: Color, border: Color, emphasised: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2 if emphasised else 1
	style.border_width_top = 2 if emphasised else 1
	style.border_width_right = 2 if emphasised else 1
	style.border_width_bottom = 2 if emphasised else 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 18
	style.content_margin_top = 11
	style.content_margin_right = 18
	style.content_margin_bottom = 11
	return style

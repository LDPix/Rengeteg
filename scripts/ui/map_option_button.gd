extends Button

@export var selected := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(custom_minimum_size.x, 52)
	_apply_style()


func set_selected(value: bool) -> void:
	selected = value
	if is_inside_tree():
		_apply_style()


func _apply_style() -> void:
	var fill := Color("F7F7F7")
	var border := Color(0, 0, 0, 0.06)
	var font_color := Color("424242")
	if selected:
		fill = Color("E8F5E9")
		border = Color(0.298039, 0.686275, 0.313726, 0.18)
		font_color = Color("2E7D32")

	var normal := _style(fill, border)
	var hover := _style(fill.lightened(0.03), border)
	var pressed := _style(fill.darkened(0.03), border)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("focus", hover)
	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_hover_color", font_color)
	add_theme_color_override("font_pressed_color", font_color)
	add_theme_font_size_override("font_size", 16)


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 20
	style.content_margin_top = 14
	style.content_margin_right = 20
	style.content_margin_bottom = 14
	return style

extends Button

@export var selected := false
var palette_name := "neutral"


func configure(chip_text: String, palette: String, is_selected: bool = false) -> void:
	text = chip_text
	palette_name = palette
	selected = is_selected
	_apply_style(_palette_colors(palette))


func _ready() -> void:
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
			return {"variant": "verdant", "selected_variant": "wood"}
		"fire":
			return {"variant": "ember", "selected_variant": "stone"}
		"earth":
			return {"variant": "stone", "selected_variant": "ember"}
		_:
			return {"variant": "parchment", "selected_variant": "wood"}


func _apply_style(colors: Dictionary) -> void:
	var variant := str(colors["variant"])
	var base := WorldUI.get_variant_colors(variant)
	var accent := WorldUI.get_variant_colors(str(colors["selected_variant"]))

	var border: Color = accent["fill_alt"] if selected else base["border"]
	var border_hover: Color = accent["fill_alt"].lightened(0.08) if selected else base["border"]
	var border_pressed: Color = accent["fill"] if selected else base["border"]
	var emphasis := selected

	add_theme_stylebox_override("normal", WorldUI.build_button_style(base["fill"], border, base["shadow"], emphasis, 0))
	add_theme_stylebox_override("hover", WorldUI.build_button_style(base["fill_alt"], border_hover, base["shadow"], emphasis, -1))
	add_theme_stylebox_override("pressed", WorldUI.build_button_style(base["fill"].darkened(0.12), border_pressed, base["shadow"], emphasis, 2))
	add_theme_stylebox_override("focus", WorldUI.build_button_style(base["fill_alt"], border_hover, base["shadow"], true, -1))
	add_theme_color_override("font_color", base["text"])
	add_theme_color_override("font_hover_color", base["text"])
	add_theme_color_override("font_pressed_color", base["text"])
	add_theme_color_override("font_focus_color", base["text"])
	add_theme_color_override("font_outline_color", base["border"])
	add_theme_constant_override("outline_size", 1)
	add_theme_font_size_override("font_size", 15)

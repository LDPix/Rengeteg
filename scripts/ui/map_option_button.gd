extends Button

@export var selected := false


func _ready() -> void:
	custom_minimum_size = Vector2(custom_minimum_size.x, 52)
	_apply_style()


func set_selected(value: bool) -> void:
	selected = value
	if is_inside_tree():
		_apply_style()


func _apply_style() -> void:
	WorldUI.apply_button(self, "parchment" if selected else "stone", selected)
	add_theme_font_size_override("font_size", 16)

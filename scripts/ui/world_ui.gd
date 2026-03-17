class_name WorldUI
extends RefCounted

const TEXT_LIGHT := Color("f5edd2")
const TEXT_MUTED := Color("d4c7ac")
const TEXT_DARK := Color("2f2418")
const OUTLINE_DARK := Color("1a130d")

const MATERIAL_COLORS := {
	"wood": {
		"fill": Color("6f4d31"),
		"fill_alt": Color("8a643d"),
		"border": Color("2d1d10"),
		"shadow": Color("140d07b8"),
		"text": TEXT_LIGHT,
		"muted": Color("eadfc5"),
	},
	"parchment": {
		"fill": Color("ccb78d"),
		"fill_alt": Color("e4d2a7"),
		"border": Color("5c4830"),
		"shadow": Color("241a10a0"),
		"text": TEXT_DARK,
		"muted": Color("5f4b32"),
	},
	"stone": {
		"fill": Color("4a443f"),
		"fill_alt": Color("645d56"),
		"border": Color("181411"),
		"shadow": Color("090706c8"),
		"text": TEXT_LIGHT,
		"muted": Color("d7cdbd"),
	},
	"battle": {
		"fill": Color("332b24"),
		"fill_alt": Color("4a3b2f"),
		"border": Color("120d09"),
		"shadow": Color("080605d4"),
		"text": TEXT_LIGHT,
		"muted": Color("dbcdb1"),
	},
	"ember": {
		"fill": Color("5e3526"),
		"fill_alt": Color("7a4630"),
		"border": Color("20100a"),
		"shadow": Color("110906d0"),
		"text": Color("fff0db"),
		"muted": Color("ffd2a8"),
	},
	"verdant": {
		"fill": Color("3f5430"),
		"fill_alt": Color("58723e"),
		"border": Color("16200f"),
		"shadow": Color("091006c2"),
		"text": TEXT_LIGHT,
		"muted": Color("dbe9b9"),
	},
	"crystal": {
		"fill": Color("3f4f68"),
		"fill_alt": Color("566b8b"),
		"border": Color("141c28"),
		"shadow": Color("090b10cc"),
		"text": Color("f1fbff"),
		"muted": Color("c7f8ff"),
	},
}

const RESOURCE_META := {
	"seal": {"name": "Seals", "short": "SL", "variant": "ember", "icon_path": "res://assets/resources/magical_seal.svg"},
	"core_shard": {"name": "Core", "short": "CO", "variant": "ember", "icon_path": "res://assets/resources/core_shard_node.svg"},
	"wood": {"name": "Wood", "short": "WD", "variant": "wood", "icon_path": "res://assets/resources/wood_node.svg"},
	"herb": {"name": "Herb", "short": "HB", "variant": "verdant", "icon_path": "res://assets/resources/herb_node.svg"},
	"stone": {"name": "Stone", "short": "ST", "variant": "stone", "icon_path": "res://assets/resources/stone_node.svg"},
	"crystal": {"name": "Crystal", "short": "CR", "variant": "crystal", "icon_path": "res://assets/resources/crystal_node.svg"},
	"species_mat": {"name": "Species", "short": "SP", "variant": "parchment", "icon_path": "res://assets/resources/species_mat_node.svg"},
}


static func apply_background(rect: ColorRect, variant: String) -> void:
	var colors := _colors(variant)
	rect.color = colors["border"].lerp(colors["fill"], 0.58)


static func apply_panel(panel: PanelContainer, variant: String, emphasis: bool = false) -> void:
	var colors := _colors(variant)
	panel.add_theme_stylebox_override("panel", _panel_style(colors, emphasis))


static func apply_button(button: Button, variant: String, emphasis: bool = false, disabled_variant: String = "") -> void:
	var colors := get_variant_colors(variant)
	var disabled_colors := get_variant_colors(disabled_variant if not disabled_variant.is_empty() else variant)
	button.add_theme_stylebox_override("normal", build_button_style(colors["fill"], colors["border"], colors["shadow"], emphasis, 0))
	button.add_theme_stylebox_override("hover", build_button_style(colors["fill_alt"], colors["border"], colors["shadow"], emphasis, -1))
	button.add_theme_stylebox_override("pressed", build_button_style(colors["fill"].darkened(0.12), colors["border"], colors["shadow"], emphasis, 2))
	button.add_theme_stylebox_override("focus", build_button_style(colors["fill_alt"], colors["border"].lightened(0.12), colors["shadow"], true, -1))
	button.add_theme_stylebox_override("disabled", build_button_style(disabled_colors["fill"].darkened(0.18), disabled_colors["border"], disabled_colors["shadow"], false, 1, 0.45))
	button.add_theme_color_override("font_color", colors["text"])
	button.add_theme_color_override("font_hover_color", colors["text"])
	button.add_theme_color_override("font_pressed_color", colors["text"])
	button.add_theme_color_override("font_focus_color", colors["text"])
	button.add_theme_color_override("font_disabled_color", colors["text"].lerp(colors["border"], 0.35))
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_color_override("font_outline_color", colors["border"])
	button.focus_mode = Control.FOCUS_ALL


static func apply_label(label: Label, role: String = "body", variant: String = "wood") -> void:
	var colors := get_variant_colors(variant)
	label.add_theme_color_override("font_outline_color", colors["border"])
	label.add_theme_constant_override("outline_size", 1)
	match role:
		"title":
			label.add_theme_color_override("font_color", colors["text"])
		"subtitle":
			label.add_theme_color_override("font_color", colors["muted"])
		"accent":
			label.add_theme_color_override("font_color", colors["fill_alt"].lightened(0.34))
		"dark":
			label.add_theme_color_override("font_color", TEXT_DARK)
			label.add_theme_color_override("font_outline_color", Color("f0e2bd"))
		_:
			label.add_theme_color_override("font_color", colors["text"])


static func apply_hint(panel: PanelContainer, label: Label, variant: String) -> void:
	var colors := get_variant_colors(variant)
	var style := _panel_style(colors, true)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 20
	label.add_theme_color_override("font_color", colors["text"])
	label.add_theme_color_override("font_outline_color", colors["border"])
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_font_size_override("font_size", 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


static func populate_resource_chips(container: Control, seals: int, materials: Dictionary, context_variant: String = "wood") -> void:
	for child in container.get_children():
		child.queue_free()

	var order := ["seal", "core_shard", "wood", "herb", "stone", "crystal", "species_mat"]
	for key in order:
		var amount := seals if key == "seal" else int(materials.get(key, 0))
		container.add_child(_build_resource_chip(key, amount, context_variant))


static func format_cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost.keys():
		var meta: Dictionary = RESOURCE_META.get(key, {"name": str(key).capitalize()})
		parts.append("%d %s" % [int(cost[key]), str(meta.get("name", key))])
	return ", ".join(parts)


static func _build_resource_chip(resource_key: String, amount: int, context_variant: String) -> PanelContainer:
	var meta: Dictionary = RESOURCE_META.get(resource_key, {"name": str(resource_key).capitalize(), "short": "??", "variant": context_variant, "icon_path": ""})
	var chip := PanelContainer.new()
	apply_panel(chip, str(meta.get("variant", context_variant)))
	chip.custom_minimum_size = Vector2(150, 42)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 8)
	padding.add_theme_constant_override("margin_top", 6)
	padding.add_theme_constant_override("margin_right", 8)
	padding.add_theme_constant_override("margin_bottom", 6)
	chip.add_child(padding)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 8)
	padding.add_child(row)

	var icon_holder := PanelContainer.new()
	apply_panel(icon_holder, "parchment")
	icon_holder.custom_minimum_size = Vector2(28, 28)
	row.add_child(icon_holder)

	var icon_margin := MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_left", 4)
	icon_margin.add_theme_constant_override("margin_top", 4)
	icon_margin.add_theme_constant_override("margin_right", 4)
	icon_margin.add_theme_constant_override("margin_bottom", 4)
	icon_holder.add_child(icon_margin)

	var texture_path := str(meta.get("icon_path", ""))
	if not texture_path.is_empty():
		var icon := TextureRect.new()
		icon.texture = load(texture_path)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(20, 20)
		icon_margin.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.text = str(meta.get("short", "??"))
		apply_label(fallback, "dark", "parchment")
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_margin.add_child(fallback)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 0)
	row.add_child(text_column)

	var name_label := Label.new()
	name_label.text = str(meta.get("name", resource_key))
	apply_label(name_label, "subtitle", str(meta.get("variant", context_variant)))
	name_label.add_theme_font_size_override("font_size", 11)
	text_column.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "x%d" % amount
	apply_label(value_label, "title", str(meta.get("variant", context_variant)))
	value_label.add_theme_font_size_override("font_size", 15)
	text_column.add_child(value_label)

	return chip


static func _colors(variant: String) -> Dictionary:
	return MATERIAL_COLORS.get(variant, MATERIAL_COLORS["wood"])


static func get_variant_colors(variant: String) -> Dictionary:
	return _colors(variant)


static func build_button_style(fill: Color, border: Color, shadow: Color, emphasis: bool, vertical_shift: int, alpha_mult: float = 1.0) -> StyleBoxFlat:
	return _button_style(fill, border, shadow, emphasis, vertical_shift, alpha_mult)


static func _panel_style(colors: Dictionary, emphasis: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colors["fill"]
	style.border_color = colors["border"]
	style.shadow_color = colors["shadow"]
	style.shadow_size = 4
	style.shadow_offset = Vector2(4, 4)
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	style.border_width_left = 4 if emphasis else 3
	style.border_width_top = 4 if emphasis else 3
	style.border_width_right = 4 if emphasis else 3
	style.border_width_bottom = 4 if emphasis else 3
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style


static func _button_style(fill: Color, border: Color, shadow: Color, emphasis: bool, vertical_shift: int, alpha_mult: float = 1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill.r, fill.g, fill.b, fill.a * alpha_mult)
	style.border_color = border
	style.shadow_color = shadow
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 4 + max(vertical_shift, 0))
	style.content_margin_left = 18.0
	style.content_margin_top = 12.0 + min(vertical_shift, 0)
	style.content_margin_right = 18.0
	style.content_margin_bottom = 12.0 - min(vertical_shift, 0)
	style.border_width_left = 4 if emphasis else 3
	style.border_width_top = 4 if emphasis else 3
	style.border_width_right = 4 if emphasis else 3
	style.border_width_bottom = 5 if emphasis else 4
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style

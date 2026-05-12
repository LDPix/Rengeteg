extends HBoxContainer

const STAT_ICONS := {
	"hp_max": "res://assets/ui/stats/hp_icon.svg",
	"mp_max": "res://assets/ui/stats/mp_icon.svg",
	"atk": "res://assets/ui/stats/atk_icon.svg",
	"def": "res://assets/ui/stats/def_icon.svg",
	"spd": "res://assets/ui/stats/spd_icon.svg",
	"acc": "res://assets/ui/stats/acc_icon.svg",
	"eva": "res://assets/ui/stats/eva_icon.svg",
	"crit": "res://assets/ui/stats/crit_icon.svg",
	"exp": "res://assets/ui/stats/exp_icon.svg",
}

var creature_data := {}


func configure_tooltip(creature: Dictionary) -> void:
	creature_data = creature.duplicate(true)
	tooltip_text = "creature_stats"


func _make_custom_tooltip(_for_text: String) -> Control:
	var panel := PanelContainer.new()
	WorldUI.apply_panel(panel, "parchment", true)

	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 10)
	padding.add_theme_constant_override("margin_top", 10)
	padding.add_theme_constant_override("margin_right", 10)
	padding.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(padding)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	padding.add_child(content)

	var title := Label.new()
	title.text = "%s  Lv %d" % [str(creature_data.get("name", "Creature")), int(creature_data.get("level", 1))]
	title.add_theme_font_size_override("font_size", 20)
	WorldUI.apply_label(title, "title", "parchment")
	content.add_child(title)

	var element := Label.new()
	element.text = str(creature_data.get("element", "neutral")).capitalize()
	element.add_theme_font_size_override("font_size", 15)
	WorldUI.apply_label(element, "subtitle", "parchment")
	content.add_child(element)

	var stats := GameState.get_effective_creature_stats(creature_data)
	var stat_grid := GridContainer.new()
	stat_grid.columns = 3
	stat_grid.add_theme_constant_override("h_separation", 14)
	stat_grid.add_theme_constant_override("v_separation", 6)
	content.add_child(stat_grid)

	stat_grid.add_child(_build_stat_chip("hp_max", "%d/%d" % [int(creature_data.get("hp", 0)), int(stats.get("hp_max", 0))]))
	stat_grid.add_child(_build_stat_chip("mp_max", "%d/%d" % [int(creature_data.get("mp", 0)), int(stats.get("mp_max", 0))]))
	stat_grid.add_child(_build_stat_chip("exp", str(int(creature_data.get("exp", 0)))))
	for stat_key in ["atk", "def", "spd", "acc", "eva", "crit"]:
		stat_grid.add_child(_build_stat_chip(stat_key, str(int(stats.get(stat_key, 0)))))

	var held_item := GameState.get_creature_held_item(creature_data)
	var held_name := "None" if held_item.is_empty() else str(held_item.get("name", "Held item"))
	content.add_child(_build_detail_label("Held item: %s" % held_name))

	var passive_id := str(creature_data.get("passive_id", GameData.get_default_passive_id(str(creature_data.get("id", "")))))
	content.add_child(_build_detail_label("Passive: %s" % GameData.format_passive_summary(passive_id)))

	var ability_names: Array[String] = []
	for ability_id in GameState.get_creature_abilities(creature_data):
		var ability := GameData.get_ability_data(ability_id)
		ability_names.append(str(ability.get("name", ability_id.capitalize())))
	content.add_child(_build_detail_label("Abilities: %s" % (", ".join(ability_names) if not ability_names.is_empty() else "None")))

	return panel


func _build_stat_chip(stat_key: String, value: String) -> HBoxContainer:
	var chip := HBoxContainer.new()
	chip.custom_minimum_size = Vector2(92, 30)
	chip.add_theme_constant_override("separation", 5)

	var icon := TextureRect.new()
	icon.texture = load(str(STAT_ICONS.get(stat_key, "")))
	icon.custom_minimum_size = Vector2(24, 24)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.add_child(icon)

	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 16)
	WorldUI.apply_label(label, "dark", "parchment")
	chip.add_child(label)

	return chip


func _build_detail_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(320, 0)
	label.add_theme_font_size_override("font_size", 15)
	WorldUI.apply_label(label, "subtitle", "parchment")
	return label

@tool
extends Area2D

signal interaction_range_changed(is_active: bool)
signal harvested(resource_type: String, amount: int)
signal harvest_feedback_requested(resource_type: String, feedback_profile: String, world_position: Vector2)

const RESOURCE_DEFAULTS := {
	"wood": {
		"default_visual": "stump",
		"default_idle": "bob",
		"default_rarity": "common",
		"harvest_feedback": "bark_chips",
		"default_yield": Vector2i(3, 6),
	},
	"herb": {
		"default_visual": "leaf_cluster",
		"default_idle": "sway",
		"default_rarity": "common",
		"harvest_feedback": "leaf_rustle",
		"default_yield": Vector2i(2, 4),
	},
	"stone": {
		"default_visual": "rock_pile",
		"default_idle": "settle",
		"default_rarity": "common",
		"harvest_feedback": "pebble_burst",
		"default_yield": Vector2i(3, 5),
	},
	"crystal": {
		"default_visual": "shard_cluster",
		"default_idle": "glint",
		"default_rarity": "uncommon",
		"harvest_feedback": "shard_sparkle",
		"default_yield": Vector2i(2, 4),
	},
	"core_shard": {
		"default_visual": "floating_relic",
		"default_idle": "hover",
		"default_rarity": "rare",
		"harvest_feedback": "arcane_burst",
		"default_yield": Vector2i(1, 2),
	},
	"species_mat": {
		"default_visual": "organic_remains",
		"default_idle": "pulse",
		"default_rarity": "uncommon",
		"harvest_feedback": "creature_pickup",
		"default_yield": Vector2i(1, 3),
	},
}

const RARITY_PRESETS := {
	"common": {
		"scale": 1.0,
		"glow_alpha": 0.0,
		"shimmer_alpha": 0.0,
		"hover_strength": 0.0,
	},
	"uncommon": {
		"scale": 1.08,
		"glow_alpha": 0.12,
		"shimmer_alpha": 0.2,
		"hover_strength": 0.4,
	},
	"rare": {
		"scale": 1.18,
		"glow_alpha": 0.22,
		"shimmer_alpha": 0.35,
		"hover_strength": 0.9,
	},
}

const BIOME_PRESETS := {
	"verdant_wilds": {
		"default": {
			"ground": Color("47633f88"),
			"shadow": Color("18301970"),
			"outline": Color("11210fe0"),
			"highlight": Color("ecf7c8"),
			"accent": Color("9ed46c"),
		},
		"wood": {
			"primary": Color("7d5d38"),
			"secondary": Color("5f4227"),
			"accent": Color("7fa95a"),
			"ground": Color("55653d9e"),
			"variant": "stump",
		},
		"herb": {
			"primary": Color("59a35e"),
			"secondary": Color("3f7d45"),
			"accent": Color("d6f4a0"),
			"ground": Color("3b4a2ca2"),
			"variant": "flower_patch",
		},
		"stone": {
			"primary": Color("7e8a73"),
			"secondary": Color("55624f"),
			"accent": Color("9cb486"),
			"ground": Color("49543f9a"),
			"variant": "mossy_rocks",
		},
		"crystal": {
			"primary": Color("6bcce3"),
			"secondary": Color("3f7f97"),
			"accent": Color("c7fff5"),
			"ground": Color("355245ac"),
			"variant": "overgrown_crystal",
		},
		"core_shard": {
			"primary": Color("8ce7ff"),
			"secondary": Color("4f83b8"),
			"accent": Color("f3ffd4"),
			"ground": Color("325449b4"),
			"variant": "floating_relic",
		},
		"species_mat": {
			"primary": Color("91b26d"),
			"secondary": Color("5e7445"),
			"accent": Color("dce8b8"),
			"ground": Color("4a58359e"),
			"variant": "moss_cocoon",
		},
	},
	"ember_caves": {
		"default": {
			"ground": Color("3f2a2790"),
			"shadow": Color("110b0be0"),
			"outline": Color("050303f0"),
			"highlight": Color("ffd7a5"),
			"accent": Color("ff9d59"),
		},
		"wood": {
			"primary": Color("4f3a31"),
			"secondary": Color("241815"),
			"accent": Color("a35c3f"),
			"ground": Color("2d1e1a9e"),
			"variant": "charred_roots",
		},
		"herb": {
			"primary": Color("c48258"),
			"secondary": Color("734738"),
			"accent": Color("ffd08f"),
			"ground": Color("39251e9e"),
			"variant": "fungus",
		},
		"stone": {
			"primary": Color("585258"),
			"secondary": Color("322d33"),
			"accent": Color("8f7a6a"),
			"ground": Color("2a252b9e"),
			"variant": "basalt",
		},
		"crystal": {
			"primary": Color("ff8d52"),
			"secondary": Color("8e3641"),
			"accent": Color("ffe1b8"),
			"ground": Color("402827b2"),
			"variant": "lava_crystal",
		},
		"core_shard": {
			"primary": Color("ffbc66"),
			"secondary": Color("96443c"),
			"accent": Color("fff0c9"),
			"ground": Color("472826be"),
			"variant": "ember_relic",
		},
		"species_mat": {
			"primary": Color("c26442"),
			"secondary": Color("693328"),
			"accent": Color("ffd59a"),
			"ground": Color("381f1b9e"),
			"variant": "ember_residue",
		},
	},
}

@export_enum("wood", "herb", "stone", "crystal", "core_shard", "species_mat") var resource_type: String = "wood"
@export var visual_type: String = ""
@export_enum("auto", "verdant_wilds", "ember_caves") var biome_type: String = "auto"
@export_enum("auto", "common", "uncommon", "rare") var rarity: String = "auto"
@export_enum("auto", "bob", "sway", "settle", "glint", "hover", "pulse") var idle_animation_profile: String = "auto"
@export var min_amount: int = 1
@export var max_amount: int = 1
@export var show_ground_base := true
@export var show_contact_shadow := true
@export var show_interaction_prompt := true
@export var prompt_text := "E"
@export var show_prompt_action_text := true
@export var contrast_boost := 1.0
@export var prompt_offset := Vector2.ZERO

@onready var hint_panel: PanelContainer = $HintPanel
@onready var hint: Label = $HintPanel/HintLabel
@onready var hint_anchor: Marker2D = $HintAnchor
@onready var feedback_anchor: Marker2D = $FeedbackAnchor

var _player_near := false
var _presentation_time := 0.0
var _interaction_amount := 0.0
var _glint_accumulator := 0.0
var _pulse_accumulator := 0.0
var _cached_config: Dictionary = {}

func _ready() -> void:
	_configure_hint_label()
	_apply_default_yield_range()
	_refresh_configuration()
	_update_prompt_visibility()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(true)


func _process(delta: float) -> void:
	_presentation_time += delta
	_interaction_amount = lerpf(_interaction_amount, 1.0 if _player_near else 0.0, min(delta * 8.0, 1.0))
	_glint_accumulator = wrapf(_glint_accumulator + delta * 0.6, 0.0, TAU)
	_pulse_accumulator = wrapf(_pulse_accumulator + delta * 0.9, 0.0, TAU)
	if Engine.is_editor_hint():
		_refresh_configuration()
	_update_hint_presentation()
	queue_redraw()


func _draw() -> void:
	_draw_presentation()


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_player_near = true
	_update_prompt_visibility()
	emit_signal("interaction_range_changed", true)


func _on_body_exited(body: Node) -> void:
	if body.name != "Player":
		return
	_player_near = false
	_update_prompt_visibility()
	emit_signal("interaction_range_changed", false)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _player_near and event.is_action_pressed("interact"):
		var amount := randi_range(min_amount, max_amount)
		GameState.materials[resource_type] = GameState.materials.get(resource_type, 0) + amount
		emit_signal("harvested", resource_type, amount)
		emit_signal("harvest_feedback_requested", resource_type, _harvest_feedback_key(), feedback_anchor.global_position)
		queue_free()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not RESOURCE_DEFAULTS.has(resource_type):
		warnings.append("Unsupported resource_type '%s'." % resource_type)
	return warnings


func _apply_default_yield_range() -> void:
	if min_amount > 1 or max_amount > 1:
		return
	var defaults: Dictionary = RESOURCE_DEFAULTS.get(resource_type, {})
	var yield_range: Vector2i = defaults.get("default_yield", Vector2i(1, 2))
	min_amount = yield_range.x
	max_amount = yield_range.y


func _refresh_configuration() -> void:
	_cached_config = _resolve_visual_config()
	_update_prompt_position()
	queue_redraw()


func _resolve_visual_config() -> Dictionary:
	var biome_key := _resolved_biome()
	var biome_values: Dictionary = BIOME_PRESETS.get(biome_key, BIOME_PRESETS["verdant_wilds"])
	var default_colors: Dictionary = biome_values.get("default", {})
	var resource_defaults: Dictionary = RESOURCE_DEFAULTS.get(resource_type, RESOURCE_DEFAULTS["stone"])
	var resource_colors: Dictionary = biome_values.get(resource_type, {})
	var rarity_key := rarity if rarity != "auto" else str(resource_defaults.get("default_rarity", "common"))
	var rarity_values: Dictionary = RARITY_PRESETS.get(rarity_key, RARITY_PRESETS["common"])
	var idle_key := idle_animation_profile if idle_animation_profile != "auto" else str(resource_defaults.get("default_idle", "bob"))
	var variant := visual_type if not visual_type.is_empty() else str(resource_colors.get("variant", resource_defaults.get("default_visual", "rock_pile")))

	return {
		"biome": biome_key,
		"rarity": rarity_key,
		"idle": idle_key,
		"variant": variant,
		"primary": _boost_color(resource_colors.get("primary", default_colors.get("accent", Color.WHITE))),
		"secondary": _boost_color(resource_colors.get("secondary", default_colors.get("ground", Color.GRAY))),
		"accent": _boost_color(resource_colors.get("accent", default_colors.get("highlight", Color.WHITE))),
		"ground": resource_colors.get("ground", default_colors.get("ground", Color("55555588"))),
		"shadow": default_colors.get("shadow", Color("00000066")),
		"outline": default_colors.get("outline", Color("000000bb")),
		"highlight": default_colors.get("highlight", Color.WHITE),
		"glow_alpha": float(rarity_values.get("glow_alpha", 0.0)),
		"shimmer_alpha": float(rarity_values.get("shimmer_alpha", 0.0)),
		"scale": float(rarity_values.get("scale", 1.0)),
		"hover_strength": float(rarity_values.get("hover_strength", 0.0)),
	}


func _resolved_biome() -> String:
	if biome_type != "auto":
		return biome_type
	if Engine.is_editor_hint():
		var scene_path := str(get_tree().edited_scene_root.scene_file_path) if get_tree().edited_scene_root else ""
		if scene_path.contains("Ember"):
			return "ember_caves"
		return "verdant_wilds"
	if GameState.current_map_id == "ember_caves":
		return "ember_caves"
	return "verdant_wilds"


func _harvest_feedback_key() -> String:
	var defaults: Dictionary = RESOURCE_DEFAULTS.get(resource_type, {})
	return str(defaults.get("harvest_feedback", "pickup"))


func _configure_hint_label() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("17361edc")
	panel_style.border_color = Color("95da88")
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 11
	panel_style.corner_radius_top_right = 11
	panel_style.corner_radius_bottom_right = 11
	panel_style.corner_radius_bottom_left = 11
	panel_style.shadow_color = Color("050a06a0")
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 2)
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 4.0
	panel_style.content_margin_bottom = 4.0
	hint_panel.add_theme_stylebox_override("panel", panel_style)
	if hint.label_settings == null:
		hint.label_settings = LabelSettings.new()
	hint.label_settings.font_size = 13
	hint.label_settings.outline_size = 2
	hint.label_settings.outline_color = Color("0f0c08")
	hint.label_settings.font_color = Color("f7ffe5")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_panel.visible = false
	hint_panel.z_index = 20
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_hint_text()


func _update_prompt_visibility() -> void:
	_update_hint_text()
	hint_panel.visible = show_interaction_prompt and _player_near
	_update_prompt_position()


func _update_prompt_position() -> void:
	hint_panel.position = hint_anchor.position + prompt_offset


func _update_hint_text() -> void:
	var verb := _prompt_action_verb()
	hint.text = prompt_text if not show_prompt_action_text or verb.is_empty() else "%s  %s" % [prompt_text, verb]


func _update_hint_presentation() -> void:
	if not is_instance_valid(hint_panel):
		return
	var visibility := _interaction_amount if _player_near else 0.0
	var lift := sin(_presentation_time * 3.2) * 1.2
	hint_panel.modulate = Color(1.0, 1.0, 1.0, visibility)
	hint_panel.scale = Vector2.ONE * (0.94 + visibility * 0.06)
	hint_panel.position = hint_anchor.position + prompt_offset + Vector2(0, -4.0 - visibility * 6.0 + lift * visibility)


func _prompt_action_verb() -> String:
	match resource_type:
		"wood":
			return "CHOP"
		"herb":
			return "PICK"
		"stone":
			return "MINE"
		"crystal":
			return "MINE"
		"core_shard":
			return "COLLECT"
		"species_mat":
			return "GATHER"
		_:
			return "INTERACT"


func _boost_color(color: Color) -> Color:
	var adjusted := color
	adjusted.r = clamp(adjusted.r * contrast_boost, 0.0, 1.0)
	adjusted.g = clamp(adjusted.g * contrast_boost, 0.0, 1.0)
	adjusted.b = clamp(adjusted.b * contrast_boost, 0.0, 1.0)
	return adjusted


func _draw_presentation() -> void:
	var config: Dictionary = _cached_config if not _cached_config.is_empty() else _resolve_visual_config()
	var motion := _animation_state(config)
	var base_scale: float = float(config.get("scale", 1.0)) + motion["scale_offset"]
	var bob: float = motion["bob"]
	var sway: float = motion["sway"]
	var hover: float = motion["hover"]
	var center := Vector2(0, bob - hover)

	if show_ground_base:
		_draw_ground_patch(config, center)
	if show_contact_shadow:
		_draw_contact_shadow(config, center, 1.0 + _interaction_amount * 0.08)

	if float(config.get("glow_alpha", 0.0)) > 0.0:
		var glow_color: Color = Color(config["accent"])
		glow_color.a = float(config.get("glow_alpha", 0.0))
		draw_colored_polygon(_ellipse_points(center + Vector2(0, 2), Vector2(22, 10 + hover * 0.5), 18), glow_color)

	match resource_type:
		"wood":
			_draw_wood(config, center, base_scale, sway)
		"herb":
			_draw_herb(config, center, base_scale, sway)
		"stone":
			_draw_stone(config, center, base_scale, sway)
		"crystal":
			_draw_crystal(config, center, base_scale, sway)
		"core_shard":
			_draw_core_shard(config, center, base_scale, sway, hover)
		"species_mat":
			_draw_species_mat(config, center, base_scale, sway)
		_:
			_draw_stone(config, center, base_scale, sway)

	if _interaction_amount > 0.02:
		var ring_color := Color(config["highlight"])
		ring_color.a = 0.08 + _interaction_amount * 0.12
		draw_polyline(_ellipse_points(center + Vector2(0, 6), Vector2(20, 8), 20), ring_color, 2.0, true)


func _animation_state(config: Dictionary) -> Dictionary:
	var idle_key := str(config.get("idle", "bob"))
	var time := _presentation_time
	var bob := 0.0
	var sway := 0.0
	var hover := 0.0
	var scale_offset := _interaction_amount * 0.04
	match idle_key:
		"sway":
			sway = sin(time * 1.6) * 0.08
			bob = sin(time * 1.2) * 1.0
		"glint":
			scale_offset += max(0.0, sin(_glint_accumulator)) * 0.02
			bob = sin(time * 0.8) * 0.6
		"hover":
			hover = 2.0 + sin(time * 1.7) * 1.5 + float(config.get("hover_strength", 0.0))
			scale_offset += 0.02 + max(0.0, sin(time * 1.3)) * 0.02
		"settle":
			bob = sin(time * 0.7) * 0.4
			sway = sin(time * 0.55) * 0.02
		"pulse":
			scale_offset += max(0.0, sin(_pulse_accumulator)) * 0.03
			bob = sin(time * 0.95) * 0.6
		_:
			bob = sin(time * 1.1) * 0.7
			sway = sin(time * 0.9) * 0.03
	return {
		"bob": bob,
		"sway": sway,
		"hover": hover,
		"scale_offset": scale_offset,
	}


func _draw_ground_patch(config: Dictionary, center: Vector2) -> void:
	var ground_color := Color(config["ground"])
	var variant := str(config.get("variant", ""))
	var patch_size := Vector2(18, 7)
	match resource_type:
		"wood":
			patch_size = Vector2(20, 8)
		"herb":
			patch_size = Vector2(16, 6)
		"stone":
			patch_size = Vector2(18, 7)
		"crystal":
			patch_size = Vector2(20, 8)
		"core_shard":
			patch_size = Vector2(22, 9)
		"species_mat":
			patch_size = Vector2(18, 6)
	draw_colored_polygon(_ellipse_points(center + Vector2(0, 8), patch_size, 18), ground_color)
	if resource_type == "crystal" or resource_type == "core_shard":
		var crack_color := Color(config["accent"])
		crack_color.a = 0.18 if resource_type == "crystal" else 0.28
		draw_line(center + Vector2(-10, 6), center + Vector2(-2, 12), crack_color, 1.5)
		draw_line(center + Vector2(2, 7), center + Vector2(10, 12), crack_color, 1.5)
	elif resource_type == "wood":
		var litter_color := Color(config["accent"])
		litter_color.a = 0.18
		draw_line(center + Vector2(-12, 8), center + Vector2(-6, 11), litter_color, 1.2)
		draw_line(center + Vector2(8, 8), center + Vector2(13, 10), litter_color, 1.2)
	elif resource_type == "stone" and variant in ["basalt", "mossy_rocks", "rock_pile"]:
		var gravel_color := Color(config["secondary"])
		gravel_color.a = 0.32
		draw_circle(center + Vector2(-8, 11), 1.5, gravel_color)
		draw_circle(center + Vector2(6, 10), 1.2, gravel_color)
	elif resource_type == "herb":
		var soil_color := Color(config["secondary"])
		soil_color.a = 0.2
		draw_colored_polygon(_ellipse_points(center + Vector2(0, 9), Vector2(10, 4), 14), soil_color)


func _draw_contact_shadow(config: Dictionary, center: Vector2, shadow_scale: float) -> void:
	var shadow_color := Color(config["shadow"])
	draw_colored_polygon(
		_ellipse_points(center + Vector2(0, 9), Vector2(16, 6) * shadow_scale, 18),
		shadow_color
	)


func _draw_wood(config: Dictionary, center: Vector2, scale_value: float, sway: float) -> void:
	var variant := str(config.get("variant", "stump"))
	var primary := Color(config["primary"])
	var secondary := Color(config["secondary"])
	var accent := Color(config["accent"])
	var outline := Color(config["outline"])
	var body_center := center + Vector2(0, -6)

	if variant in ["charred_roots", "roots"]:
		var root_poly := [
			body_center + Vector2(-14, 8),
			body_center + Vector2(-3, -2),
			body_center + Vector2(8, -2),
			body_center + Vector2(16, 8),
			body_center + Vector2(7, 12),
			body_center + Vector2(-8, 12),
		]
		_draw_layered_polygon(root_poly, primary, outline, scale_value * 1.06, sway)
		draw_line(body_center + Vector2(-6, 2), body_center + Vector2(-18, 10), secondary, 3.0)
		draw_line(body_center + Vector2(4, 1), body_center + Vector2(18, 10), secondary, 3.0)
		draw_line(body_center + Vector2(0, 0), body_center + Vector2(0, -10), secondary, 4.0)
	else:
		var stump_points := _ellipse_points(body_center + Vector2(0, 4), Vector2(12, 9) * scale_value, 16)
		_draw_layered_polygon(stump_points, primary, outline, 1.08, sway)
		var top_color := accent.lerp(Color.WHITE, 0.18)
		top_color.a = 0.9
		draw_colored_polygon(_ellipse_points(body_center + Vector2(0, 1), Vector2(8, 4), 16), top_color)
		draw_arc(body_center + Vector2(0, 1), 4.0, 0.0, TAU, 16, secondary, 1.2, true)
		if variant in ["branch_pile", "log"]:
			draw_line(body_center + Vector2(-12, -1), body_center + Vector2(11, -4), secondary, 4.0)
			draw_line(body_center + Vector2(-8, 6), body_center + Vector2(9, 4), secondary, 3.0)

	if config["biome"] == "verdant_wilds":
		var leaf_color := accent
		leaf_color.a = 0.75
		draw_circle(body_center + Vector2(-8, -10), 3.2, leaf_color)
		draw_circle(body_center + Vector2(7, -9), 2.6, leaf_color)


func _draw_herb(config: Dictionary, center: Vector2, scale_value: float, sway: float) -> void:
	var variant := str(config.get("variant", "leaf_cluster"))
	var primary := Color(config["primary"])
	var secondary := Color(config["secondary"])
	var accent := Color(config["accent"])
	var outline := Color(config["outline"])
	var stem_offset := sin(_presentation_time * 1.6) * 2.0 * sway
	for x in [-8.0, -2.0, 4.0, 10.0]:
		var top := center + Vector2(x + stem_offset, -12 - abs(x) * 0.12) * scale_value
		draw_line(center + Vector2(x * 0.5, 8), top, secondary, 2.2)
		var leaf := [
			top + Vector2(0, -5),
			top + Vector2(6, 0),
			top + Vector2(0, 6),
			top + Vector2(-5, 0),
		]
		_draw_layered_polygon(leaf, primary, outline, 1.06, sway)

	if variant in ["flower_patch", "flowers"]:
		draw_circle(center + Vector2(-6, -10), 2.4 * scale_value, accent)
		draw_circle(center + Vector2(5, -14), 2.4 * scale_value, accent)
	elif variant in ["fungus", "mushroom_patch"]:
		for x in [-7.0, 4.0]:
			draw_line(center + Vector2(x, 6), center + Vector2(x, -2), secondary, 2.0)
			var cap := _ellipse_points(center + Vector2(x, -4), Vector2(6, 3) * scale_value, 12)
			_draw_layered_polygon(cap, accent, outline, 1.08, 0.0)


func _draw_stone(config: Dictionary, center: Vector2, scale_value: float, sway: float) -> void:
	var variant := str(config.get("variant", "rock_pile"))
	var primary := Color(config["primary"])
	var secondary := Color(config["secondary"])
	var accent := Color(config["accent"])
	var outline := Color(config["outline"])
	var left := [
		center + Vector2(-15, 7),
		center + Vector2(-11, -6),
		center + Vector2(-2, -10),
		center + Vector2(2, 4),
		center + Vector2(-4, 11),
	]
	var right := [
		center + Vector2(0, 7),
		center + Vector2(4, -8),
		center + Vector2(14, -5),
		center + Vector2(17, 6),
		center + Vector2(10, 11),
	]
	_draw_layered_polygon(left, primary, outline, scale_value * 1.04, sway)
	_draw_layered_polygon(right, secondary.lerp(primary, 0.45), outline, scale_value * 1.04, -sway)
	draw_line(center + Vector2(-9, -1), center + Vector2(-3, 3), accent, 1.1)
	draw_line(center + Vector2(6, -2), center + Vector2(11, 2), accent, 1.1)
	if variant in ["mossy_rocks", "rock_pile"]:
		var moss := accent
		moss.a = 0.78 if config["biome"] == "verdant_wilds" else 0.42
		draw_colored_polygon(_ellipse_points(center + Vector2(-6, -3), Vector2(5, 2), 10), moss)
	elif variant == "basalt":
		draw_line(center + Vector2(-1, -7), center + Vector2(-1, 8), outline.lerp(Color.WHITE, 0.08), 1.3)


func _draw_crystal(config: Dictionary, center: Vector2, scale_value: float, sway: float) -> void:
	var variant := str(config.get("variant", "shard_cluster"))
	var primary := Color(config["primary"])
	var secondary := Color(config["secondary"])
	var accent := Color(config["accent"])
	var outline := Color(config["outline"])
	var tall := [
		center + Vector2(-4, 10),
		center + Vector2(-1, -16),
		center + Vector2(8, 10),
	]
	var short_left := [
		center + Vector2(-16, 10),
		center + Vector2(-12, -6),
		center + Vector2(-5, 10),
	]
	var short_right := [
		center + Vector2(4, 10),
		center + Vector2(10, -8),
		center + Vector2(16, 10),
	]
	_draw_layered_polygon(short_left, secondary, outline, scale_value, sway)
	_draw_layered_polygon(short_right, primary.lerp(secondary, 0.25), outline, scale_value, -sway)
	_draw_layered_polygon(tall, primary, outline, scale_value * 1.08, sway * 0.7)
	draw_line(center + Vector2(0, -10), center + Vector2(2, 2), accent, 1.5)
	if variant in ["overgrown_crystal", "lava_crystal"]:
		var detail := accent
		detail.a = 0.5
		draw_circle(center + Vector2(-10, 5), 1.4, detail)
		draw_circle(center + Vector2(11, 4), 1.4, detail)
	if float(config.get("shimmer_alpha", 0.0)) > 0.0:
		var shimmer := accent
		shimmer.a = float(config.get("shimmer_alpha", 0.0)) * max(0.35, sin(_glint_accumulator) * 0.5 + 0.5)
		draw_line(center + Vector2(-1, -14), center + Vector2(5, -8), shimmer, 1.6)
		draw_line(center + Vector2(2, -14), center + Vector2(-4, -8), shimmer, 1.6)


func _draw_core_shard(config: Dictionary, center: Vector2, scale_value: float, sway: float, hover: float) -> void:
	var primary := Color(config["primary"])
	var secondary := Color(config["secondary"])
	var accent := Color(config["accent"])
	var outline := Color(config["outline"])
	var floating_center := center + Vector2(0, -12 - hover)
	var shard := [
		floating_center + Vector2(-5, 10),
		floating_center + Vector2(0, -12),
		floating_center + Vector2(6, 9),
		floating_center + Vector2(1, 14),
	]
	_draw_layered_polygon(shard, primary, outline, scale_value * 1.12, sway)
	var halo := accent
	halo.a = 0.16 + max(0.0, sin(_presentation_time * 1.7)) * 0.08
	draw_colored_polygon(_ellipse_points(floating_center + Vector2(0, 2), Vector2(12, 12) * scale_value, 18), halo)
	draw_line(center + Vector2(0, 2), floating_center + Vector2(0, 9), secondary, 1.2)
	draw_circle(center + Vector2(-9, -2), 1.5, accent)
	draw_circle(center + Vector2(10, -3), 1.7, accent)
	draw_circle(center + Vector2(0, 10), 1.2, accent)


func _draw_species_mat(config: Dictionary, center: Vector2, scale_value: float, sway: float) -> void:
	var variant := str(config.get("variant", "organic_remains"))
	var primary := Color(config["primary"])
	var secondary := Color(config["secondary"])
	var accent := Color(config["accent"])
	var outline := Color(config["outline"])
	if variant in ["moss_cocoon", "organic_remains"]:
		var cocoon := _ellipse_points(center + Vector2(0, -2), Vector2(11, 15) * scale_value, 16)
		_draw_layered_polygon(cocoon, primary, outline, 1.07, sway)
		draw_line(center + Vector2(-4, -14), center + Vector2(-7, 10), secondary, 1.5)
		draw_line(center + Vector2(4, -13), center + Vector2(6, 10), secondary, 1.5)
		draw_arc(center + Vector2(0, 0), 5.0, 0.3, PI - 0.3, 12, accent, 1.2, true)
	else:
		var shell := [
			center + Vector2(-14, 7),
			center + Vector2(-8, -8),
			center + Vector2(0, -11),
			center + Vector2(12, -6),
			center + Vector2(15, 7),
			center + Vector2(4, 11),
		]
		_draw_layered_polygon(shell, primary, outline, scale_value * 1.06, sway)
		draw_line(center + Vector2(-7, -1), center + Vector2(9, 3), accent, 1.4)
		draw_circle(center + Vector2(-3, -4), 1.4, secondary)
		draw_circle(center + Vector2(5, -3), 1.4, secondary)


func _draw_layered_polygon(points, fill_color: Color, outline_color: Color, scale_value: float, sway: float) -> void:
	var center := _point_average(points)
	var transformed: PackedVector2Array = []
	var outlined: PackedVector2Array = []
	for point in points:
		var point_vec: Vector2 = point
		var shifted: Vector2 = point_vec - center
		var rotated: Vector2 = shifted.rotated(sway)
		var final_point: Vector2 = center + rotated * scale_value
		transformed.append(final_point)
		outlined.append(center + rotated * (scale_value * 1.08))
	draw_colored_polygon(outlined, outline_color)
	draw_colored_polygon(transformed, fill_color)


func _ellipse_points(center: Vector2, radius: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := (float(index) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


func _point_average(points) -> Vector2:
	var total := Vector2.ZERO
	for point in points:
		var point_vec: Vector2 = point
		total += point_vec
	return total / max(points.size(), 1)

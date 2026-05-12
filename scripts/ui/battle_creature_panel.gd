extends PanelContainer

const PORTRAIT_SIZE := Vector2(108, 144)
const HP_ICON_PATH := "res://assets/ui/stats/hp_icon.svg"
const MP_ICON_PATH := "res://assets/ui/stats/mp_icon.svg"
const HP_COLOR := Color("c94040")
const HP_BG_COLOR := Color("1a0f0a")
const MP_COLOR := Color("4080c9")
const MP_BG_COLOR := Color("0a0f1a")

@export var right_aligned := false
@export_enum("wood", "stone", "battle", "ember") var panel_variant := "battle"

@onready var portrait: TextureRect = $Padding/Content/Portrait
@onready var name_label: Label = $Padding/Content/NameLabel
@onready var hp_icon: TextureRect = $Padding/Content/HPRow/HPHeader/HPIcon
@onready var hp_value_label: Label = $Padding/Content/HPRow/HPHeader/HPValueLabel
@onready var hp_bar: ProgressBar = $Padding/Content/HPRow/HPBar
@onready var mp_icon: TextureRect = $Padding/Content/MPRow/MPHeader/MPIcon
@onready var mp_value_label: Label = $Padding/Content/MPRow/MPHeader/MPValueLabel
@onready var mp_bar: ProgressBar = $Padding/Content/MPRow/MPBar


func _ready() -> void:
	hp_icon.texture = load(HP_ICON_PATH)
	mp_icon.texture = load(MP_ICON_PATH)
	_style_bar(hp_bar, HP_COLOR, HP_BG_COLOR)
	_style_bar(mp_bar, MP_COLOR, MP_BG_COLOR)
	_apply_variant()
	_apply_alignment()


func set_details(
	display_name: String,
	hp_current: int,
	hp_max: int,
	mp_current: int,
	mp_max: int,
	sprite_path: String = ""
) -> void:
	name_label.text = display_name.to_upper()
	hp_value_label.text = "%d / %d" % [hp_current, hp_max]
	hp_bar.max_value = max(hp_max, 1)
	hp_bar.value = hp_current
	mp_value_label.text = "%d / %d" % [mp_current, mp_max]
	mp_bar.max_value = max(mp_max, 1)
	mp_bar.value = mp_current
	if sprite_path.is_empty():
		portrait.texture = null
	else:
		portrait.texture = load(sprite_path)


func _apply_alignment() -> void:
	var alignment := HORIZONTAL_ALIGNMENT_RIGHT if right_aligned else HORIZONTAL_ALIGNMENT_LEFT
	portrait.custom_minimum_size = PORTRAIT_SIZE
	name_label.horizontal_alignment = alignment
	hp_value_label.horizontal_alignment = alignment
	mp_value_label.horizontal_alignment = alignment


func apply_variant(variant: String) -> void:
	panel_variant = variant
	_apply_variant()


func _apply_variant() -> void:
	WorldUI.apply_panel(self, panel_variant, true)
	WorldUI.apply_label(name_label, "title", panel_variant)
	WorldUI.apply_label(hp_value_label, "subtitle", panel_variant)
	WorldUI.apply_label(mp_value_label, "subtitle", panel_variant)


func play_attack_animation() -> void:
	var lunge_x := -40.0 if right_aligned else 40.0
	var origin := position
	var tween := create_tween()
	tween.tween_property(self, "position", origin + Vector2(lunge_x, 0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", origin, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


func play_hit_animation() -> void:
	var origin := position
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.6, 0.35, 0.35, 1.0), 0.06).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(self, "position", origin + Vector2(-8, 0), 0.06)
	tween.tween_property(self, "position", origin + Vector2(7, 0), 0.05)
	tween.tween_property(self, "position", origin + Vector2(-4, 0), 0.05)
	tween.tween_property(self, "position", origin, 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1).set_trans(Tween.TRANS_LINEAR)


func play_bind_attempt_animation() -> void:
	pivot_offset = size / 2
	var tween := create_tween()
	for _i in range(3):
		tween.tween_property(self, "modulate", Color(0.55, 0.8, 1.7, 1.0), 0.18).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(self, "scale", Vector2(1.06, 1.06), 0.18).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	await tween.finished
	pivot_offset = Vector2.ZERO


func play_bind_success_animation() -> void:
	pivot_offset = size / 2
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.2, 2.2, 1.6, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1.4, 1.15, 0.45, 1.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	pivot_offset = Vector2.ZERO


func play_bind_fail_animation() -> void:
	var origin := position
	pivot_offset = size / 2
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.7, 0.3, 0.3, 1.0), 0.07).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(self, "position", origin + Vector2(-14, 0), 0.07)
	tween.tween_property(self, "position", origin + Vector2(11, 0), 0.06)
	tween.tween_property(self, "position", origin + Vector2(-9, 0), 0.06)
	tween.tween_property(self, "position", origin + Vector2(7, 0), 0.06)
	tween.tween_property(self, "position", origin + Vector2(-4, 0), 0.05)
	tween.tween_property(self, "position", origin, 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	pivot_offset = Vector2.ZERO


func _style_bar(bar: ProgressBar, fill_color: Color, bg_color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.border_width_left = 0
	fill_style.border_width_top = 0
	fill_style.border_width_right = 0
	fill_style.border_width_bottom = 0

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.border_color = bg_color.darkened(0.4)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2

	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_stylebox_override("background", bg_style)

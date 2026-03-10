extends PanelContainer

@export var right_aligned := false

@onready var portrait: TextureRect = $Padding/Content/Portrait
@onready var name_label: Label = $Padding/Content/NameLabel
@onready var hp_label: Label = $Padding/Content/HPLabel


func _ready() -> void:
	_apply_alignment()


func set_details(display_name: String, hp_text: String, sprite_path: String = "") -> void:
	name_label.text = display_name
	hp_label.text = hp_text
	if sprite_path.is_empty():
		portrait.texture = null
	else:
		portrait.texture = load(sprite_path)


func _apply_alignment() -> void:
	var alignment := HORIZONTAL_ALIGNMENT_RIGHT if right_aligned else HORIZONTAL_ALIGNMENT_LEFT
	portrait.custom_minimum_size = Vector2(72, 72)
	name_label.horizontal_alignment = alignment
	hp_label.horizontal_alignment = alignment

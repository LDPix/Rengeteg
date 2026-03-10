extends Area2D

@export var resource_type: String = "wood" # wood/herb/stone
@export var visual_type: String = ""
@export var min_amount: int = 1
@export var max_amount: int = 1

@onready var hint: Label = $HintLabel
@onready var sprite: Sprite2D = $Sprite2D
var _player_near := false

func _ready() -> void:
	hint.visible = false
	_apply_default_yield_range()
	_apply_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_near = true
		hint.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_near = false
		hint.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_near and event.is_action_pressed("interact"):
		var amount: int = randi_range(min_amount, max_amount)
		GameState.materials[resource_type] = GameState.materials.get(resource_type, 0) + amount
		queue_free()


func _apply_visual() -> void:
	var key: String = visual_type if not visual_type.is_empty() else _default_visual_type()
	var texture_path: String = {
		"tree": "res://assets/resources/tree.png",
		"bush": "res://assets/resources/bush.png",
		"rock": "res://assets/resources/rock.png",
		"crystal": "res://assets/resources/crystal.png",
	}.get(key, "res://assets/resources/rock.png")
	sprite.texture = load(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _default_visual_type() -> String:
	match resource_type:
		"wood":
			return "tree"
		"herb":
			return "bush"
		"crystal":
			return "crystal"
		_:
			return "rock"


func _apply_default_yield_range() -> void:
	if min_amount > 1 or max_amount > 1:
		return

	match resource_type:
		"wood":
			min_amount = 3
			max_amount = 6
		"herb":
			min_amount = 2
			max_amount = 4
		"stone":
			min_amount = 3
			max_amount = 5
		"crystal":
			min_amount = 2
			max_amount = 4
		_:
			min_amount = 1
			max_amount = 2

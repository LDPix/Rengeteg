extends Node

const EFFECT_PATHS := {
	"bestiary_close": "res://assets/audio/Beatiary_close.ogg",
	"bestiary_open": "res://assets/audio/Bestiary_open.ogg",
	"battle_start": "res://assets/audio/Battle_start.wav",
	"bind_success": "res://assets/audio/Bind_success.wav",
	"button_click": "res://assets/audio/Button_click.wav",
	"craft_consumable": "res://assets/audio/Craft_consumable.wav",
	"craft_item": "res://assets/audio/Craft_item.wav",
	"herb": "res://assets/audio/Herb.wav",
	"hit": "res://assets/audio/Hit.wav",
	"inventory": "res://assets/audio/Inventory.wav",
	"miss": "res://assets/audio/Miss.wav",
	"poi": "res://assets/audio/VerdantWilds_poi.wav",
	"stone": "res://assets/audio/Stone.ogg",
	"tablet": "res://assets/audio/Tablet.wav",
	"venture": "res://assets/audio/Venture.wav",
	"wood": "res://assets/audio/Wood.wav",
}

const RESOURCE_EFFECTS := {
	"core_shard": "stone",
	"crystal": "stone",
	"herb": "herb",
	"species_mat": "herb",
	"stone": "stone",
	"wood": "wood",
}

const EFFECT_VOLUMES := {
	"battle_start": -7.0,
	"bestiary_close": -13.0,
	"bestiary_open": -12.0,
	"bind_success": -8.0,
	"button_click": -15.0,
	"craft_consumable": -10.0,
	"craft_item": -10.0,
	"herb": -14.0,
	"hit": -9.0,
	"inventory": -13.0,
	"miss": -11.0,
	"poi": -12.0,
	"stone": -13.0,
	"tablet": -12.0,
	"venture": -10.0,
	"wood": -13.0,
}

var _streams := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_streams()
	_connect_buttons(get_tree().root)
	get_tree().node_added.connect(_on_node_added)


func play(effect_id: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = _streams.get(effect_id, null)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = float(EFFECT_VOLUMES.get(effect_id, 0.0)) + volume_db
	player.pitch_scale = pitch_scale
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func play_resource(resource_type: String) -> void:
	play(str(RESOURCE_EFFECTS.get(resource_type, "")))


func _load_streams() -> void:
	for effect_id in EFFECT_PATHS.keys():
		var path := str(EFFECT_PATHS[effect_id])
		if ResourceLoader.exists(path):
			_streams[effect_id] = load(path)


func _on_node_added(node: Node) -> void:
	_connect_buttons(node)


func _connect_buttons(node: Node) -> void:
	if node is Button:
		var button := node as Button
		if not bool(button.get_meta("sfx_connected", false)):
			button.set_meta("sfx_connected", true)
			button.pressed.connect(_on_button_pressed.bind(button))
	for child in node.get_children():
		_connect_buttons(child)


func _on_button_pressed(button: Button) -> void:
	if bool(button.get_meta("sfx_click_disabled", false)):
		return
	if not bool(button.get_meta("sfx_click_enabled", false)):
		return
	play("button_click")

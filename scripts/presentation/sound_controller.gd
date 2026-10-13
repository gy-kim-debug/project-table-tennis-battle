extends Node

const CUES: Dictionary = {
	"swing": preload("res://assets/audio/swing.wav"),
	"good": preload("res://assets/audio/good.wav"),
	"perfect": preload("res://assets/audio/perfect.wav"),
	"miss": preload("res://assets/audio/miss.wav"),
	"bounce": preload("res://assets/audio/bounce.wav"),
	"damage": preload("res://assets/audio/damage.wav"),
	"smash": preload("res://assets/audio/smash.wav"),
	"victory": preload("res://assets/audio/victory.wav"),
	"defeat": preload("res://assets/audio/defeat.wav"),
}

var enabled: bool = true
var players: Array[AudioStreamPlayer] = []
var next_player: int = 0
var cue_counts: Dictionary = {}

func _ready() -> void:
	var settings: ConfigFile = ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		enabled = bool(settings.get_value("audio", "enabled", true))
	for index in range(4):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -9.0
		add_child(player)
		players.append(player)

func play_cue(name: String) -> void:
	if not enabled or not CUES.has(name):
		return
	cue_counts[name] = int(cue_counts.get(name, 0)) + 1
	# Headless tests verify dispatch without creating an audio playback thread.
	if DisplayServer.get_name() == "headless":
		return
	var player: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stop()
	player.stream = CUES[name]
	player.play()

func set_enabled(value: bool, persist: bool = true) -> void:
	enabled = value
	if not enabled:
		for player in players:
			player.stop()
	if persist:
		var settings: ConfigFile = ConfigFile.new()
		settings.set_value("audio", "enabled", enabled)
		settings.save("user://settings.cfg")

func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null

extends Node

var cues: Dictionary = {}
var enabled: bool = true
var players: Array[AudioStreamPlayer] = []
var next_player: int = 0
var cue_counts: Dictionary = {}

func _ready() -> void:
	var profile_path: String = "res://assets/audio/active.json"
	if FileAccess.file_exists(profile_path):
		var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
		for cue in profile.get("cues", {}):
			var path: String = String(profile["cues"][cue])
			if ResourceLoader.exists(path):
				cues[cue] = load(path) as AudioStream
	var settings: ConfigFile = ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		enabled = bool(settings.get_value("audio", "enabled", true))
	for index in range(4):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -9.0
		add_child(player)
		players.append(player)

func play_cue(name: String) -> void:
	if not enabled or not cues.has(name):
		return
	cue_counts[name] = int(cue_counts.get(name, 0)) + 1
	# Headless tests verify dispatch without creating an audio playback thread.
	if DisplayServer.get_name() == "headless":
		return
	var player: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stop()
	player.stream = cues[name]
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

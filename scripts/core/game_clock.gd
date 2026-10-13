extends RefCounted

var origin_us: int
var paused_at_us: int = 0
var excluded_us: int = 0
var paused: bool = false

func _init(wall_us: int = -1) -> void:
	origin_us = Time.get_ticks_usec() if wall_us < 0 else wall_us

func now_us(wall_us: int = -1) -> int:
	var wall: int = Time.get_ticks_usec() if wall_us < 0 else wall_us
	return (paused_at_us if paused else wall) - origin_us - excluded_us

func set_paused(value: bool, wall_us: int = -1) -> void:
	if value == paused:
		return
	var wall: int = Time.get_ticks_usec() if wall_us < 0 else wall_us
	if value:
		paused_at_us = wall
	else:
		excluded_us += wall - paused_at_us
	paused = value

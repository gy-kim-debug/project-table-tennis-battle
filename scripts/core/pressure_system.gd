extends RefCounted

const Judge = preload("res://scripts/core/timing_judge.gd")
signal changed(value: int)
var config: Resource
var value: int = 0

func _init(settings: Resource) -> void:
	config = settings

func reset() -> void:
	_set_value(0)

func _set_value(next: int) -> void:
	var clamped: int = clampi(next, 0, config.pressure_max)
	if value != clamped:
		value = clamped
		changed.emit(value)

func player_judgement(grade: int) -> void:
	if grade == Judge.Grade.MISS:
		reset()
	elif grade >= 0 and grade < 3:
		_set_value(value + config.player_pressure_delta[grade])

func enemy_defense(grade: int) -> void:
	if grade >= 0 and grade < 4:
		_set_value(value + config.enemy_pressure_delta[grade])

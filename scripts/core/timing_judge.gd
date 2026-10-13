extends RefCounted

const Config = preload("res://scripts/core/timing_config.gd")
enum Grade { PERFECT, GOOD, BAD, MISS }
const NAMES: Array[String] = ["PERFECT", "GOOD", "BAD", "MISS"]

var config: Resource
var target_us: int = 0
var consumed: bool = false

func _init(settings: Resource = null) -> void:
	config = settings if settings != null else Config.new()
	assert(config.is_valid(), "Timing windows must be positive and ordered")

func arm(target: int) -> void:
	target_us = target
	consumed = false

func classify(input_us: int) -> int:
	var error_us: int = absi(input_us - config.input_offset_ms * 1000 - target_us)
	if error_us <= config.perfect_ms * 1000:
		return Grade.PERFECT
	if error_us <= config.good_ms * 1000:
		return Grade.GOOD
	if error_us <= config.bad_ms * 1000:
		return Grade.BAD
	return Grade.MISS

# -1 means ignored. Even a very early swing consumes this ball.
func swing(input_us: int) -> int:
	if consumed:
		return -1
	consumed = true
	return classify(input_us)

func expire(now_us: int) -> int:
	# Include the exact late boundary; use the same compensated time as swing().
	if consumed or now_us <= target_us + (config.bad_ms + config.input_offset_ms) * 1000:
		return -1
	consumed = true
	return Grade.MISS

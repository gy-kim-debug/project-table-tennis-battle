extends RefCounted

# Presentation-only: frame selection follows the same paused game clock as the ball.
var frames: SpriteFrames
var pivot: Vector2 = Vector2(64, 116)
var racket_contact: Vector2 = Vector2(112, 52)
var contact_frame: int = 3
var animation: StringName = &"idle"
var started_us: int = 0
var last_now: float = 0.0
var hold_last: bool = false

func configure(role: String) -> bool:
	var path: String = "res://assets/characters/%s/frames.tres" % role
	if not ResourceLoader.exists(path):
		return false
	frames = load(path) as SpriteFrames
	var metadata_path: String = "res://assets/characters/%s/manifest.json" % role
	if FileAccess.file_exists(metadata_path):
		var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if metadata is Dictionary:
			var point: Array = metadata.get("contact_point", [112, 52])
			racket_contact = Vector2(point[0], point[1])
			var anchor: Array = metadata.get("pivot", [64, 116])
			pivot = Vector2(anchor[0], anchor[1])
			contact_frame = int(metadata.get("contact_frame", 3))
	return available()

func available() -> bool:
	return frames != null and frames.has_animation(&"idle") and frames.has_animation(&"swing") and frames.has_animation(&"miss")

func reset() -> void:
	animation = &"idle"
	started_us = 0
	hold_last = false

func swing_at(contact_time: float) -> void:
	if not available():
		return
	animation = &"swing"
	hold_last = false
	# The contact pose aligns to the logical contact time; it cannot change judgement.
	started_us = roundi(contact_time * 1000000.0) - roundi(float(contact_frame) * 1000000.0 / frames.get_animation_speed(&"swing"))

func miss_at(now: float) -> void:
	if not available():
		return
	animation = &"miss"
	hold_last = false
	started_us = roundi(now * 1000000.0)

func finish_at(won: bool, now: float) -> void:
	if not available():
		return
	animation = &"idle" if won else &"miss"
	hold_last = not won
	started_us = roundi(now * 1000000.0)

func index_at(now: float) -> int:
	last_now = now
	if not available():
		return 0
	var count: int = frames.get_frame_count(animation)
	var fps: float = frames.get_animation_speed(animation)
	var elapsed_us: int = maxi(0, roundi(now * 1000000.0) - started_us)
	if animation != &"idle" and elapsed_us >= roundi(float(count) * 1000000.0 / fps):
		if hold_last:
			return count - 1
		animation = &"idle"
		started_us = roundi(now * 1000000.0)
		count = frames.get_frame_count(animation)
		fps = frames.get_animation_speed(animation)
		elapsed_us = 0
	return mini(count - 1, int(float(elapsed_us) * fps / 1000000.0)) if animation != &"idle" else int(float(elapsed_us) * fps / 1000000.0) % count

func texture_at(now: float) -> Texture2D:
	if not available():
		return null
	var index: int = index_at(now)
	return frames.get_frame_texture(animation, index)

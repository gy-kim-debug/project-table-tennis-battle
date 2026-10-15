extends RefCounted

# Presentation-only: frame selection follows the same paused game clock as the ball.
var frames: SpriteFrames
var front_frames: SpriteFrames
var pivot: Vector2 = Vector2(64, 116)
var racket_contact: Vector2 = Vector2(112, 52)
var contact_frame: int = 3
var swing_variants: Dictionary = {}
var animation: StringName = &"idle"
var started_us: int = 0
var last_now: float = 0.0
var hold_last: bool = false

func configure(role: String) -> bool:
	swing_variants.clear()
	var root: String = "res://assets/characters/%s/" % role
	var whole_path: String = root + "frames.tres"
	var back_path: String = root + "body_back.tres"
	var front_path: String = root + "arm_front.tres"
	if not ResourceLoader.exists(whole_path) and not ResourceLoader.exists(back_path):
		return false
	frames = load(whole_path) as SpriteFrames if ResourceLoader.exists(whole_path) else null
	front_frames = null
	if ResourceLoader.exists(back_path) and ResourceLoader.exists(front_path):
		var fallback: SpriteFrames = frames
		frames = load(back_path) as SpriteFrames
		var candidate: SpriteFrames = load(front_path) as SpriteFrames
		if _matching_layer(candidate):
			front_frames = candidate
		else:
			frames = fallback
			push_warning("Ignored incompatible front-arm frames: " + front_path)
	elif ResourceLoader.exists(back_path):
		push_warning("Ignored body-back frames without an arm-front layer: " + back_path)
	elif ResourceLoader.exists(front_path):
		push_warning("Ignored arm-front frames without a body-back layer: " + front_path)
	var metadata_path: String = "res://assets/characters/%s/manifest.json" % role
	if FileAccess.file_exists(metadata_path):
		var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if metadata is Dictionary:
			var point: Array = metadata.get("contact_point", [112, 52])
			racket_contact = Vector2(point[0], point[1])
			var anchor: Array = metadata.get("pivot", [64, 116])
			pivot = Vector2(anchor[0], anchor[1])
			contact_frame = int(metadata.get("contact_frame", 3))
			swing_variants = metadata.get("swing_variants", {})
	return available()

func available() -> bool:
	return frames != null and frames.has_animation(&"idle") and frames.has_animation(&"swing") and frames.has_animation(&"miss")

func _matching_layer(candidate: SpriteFrames) -> bool:
	if candidate == null or not available():
		return false
	for name in frames.get_animation_names():
		if not candidate.has_animation(name) or candidate.get_frame_count(name) != frames.get_frame_count(name) or not is_equal_approx(candidate.get_animation_speed(name), frames.get_animation_speed(name)) or candidate.get_animation_loop(name) != frames.get_animation_loop(name):
			return false
		for frame in range(frames.get_frame_count(name)):
			if not is_equal_approx(candidate.get_frame_duration(name, frame), frames.get_frame_duration(name, frame)):
				return false
	return true

func has_front_layer() -> bool:
	return front_frames != null

func reset() -> void:
	animation = &"idle"
	started_us = 0
	hold_last = false

func swing_at(contact_time: float, pose: String = "default") -> void:
	if not available():
		return
	var variant: Dictionary = swing_variants.get(pose, {})
	var chosen: StringName = StringName(String(variant.get("animation", "swing")))
	animation = chosen if frames.has_animation(chosen) else &"swing"
	var chosen_contact_frame: int = int(variant.get("contact_frame", contact_frame)) if animation == chosen else contact_frame
	chosen_contact_frame = clampi(chosen_contact_frame, 0, frames.get_frame_count(animation) - 1)
	hold_last = false
	# The contact pose aligns to the logical contact time; it cannot change judgement.
	started_us = roundi(contact_time * 1000000.0) - roundi(float(chosen_contact_frame) * 1000000.0 / frames.get_animation_speed(animation))

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

func front_texture_at(now: float) -> Texture2D:
	if not has_front_layer():
		return null
	var index: int = index_at(now)
	return front_frames.get_frame_texture(animation, index)

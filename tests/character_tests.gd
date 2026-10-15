extends RefCounted

const Animator = preload("res://scripts/presentation/character_animator.gd")

func run(check: Callable) -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for entry in [["idle", 4, 4.0], ["swing", 6, 20.0], ["miss", 4, 10.0]]:
		frames.add_animation(entry[0])
		frames.set_animation_speed(entry[0], entry[2])
		for i in range(entry[1]):
			var image: Image = Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
			image.fill(Color(float(i) / 6.0, 0, 0, 1))
			frames.add_frame(entry[0], ImageTexture.create_from_image(image))
	frames.add_animation(&"drive_alt")
	frames.set_animation_speed(&"drive_alt", 10.0)
	frames.set_animation_loop(&"drive_alt", false)
	for i in range(5):
		frames.add_frame(&"drive_alt", frames.get_frame_texture(&"swing", i))
	var actor: RefCounted = Animator.new()
	actor.frames = frames
	check.call(not actor.has_front_layer(), "legacy whole-character frames work without a front-arm layer")
	actor.front_frames = frames
	check.call(actor.has_front_layer() and actor.front_texture_at(0.5) == frames.get_frame_texture(&"idle", 2), "optional front arm uses the same idle frame")
	check.call(actor.index_at(0.0) == 0 and actor.index_at(0.5) == 2, "idle animation advances with game time")
	actor.swing_at(1.0)
	check.call(actor.front_texture_at(1.0) == frames.get_frame_texture(&"swing", 3), "front arm shares logical swing contact frame")
	check.call(actor.index_at(0.85) == 0, "swing begins before contact")
	check.call(actor.index_at(1.0) == 3, "swing contact pose matches logical contact time")
	actor.swing_variants = {"alt": {"animation": "drive_alt", "contact_frame": 2}}
	actor.swing_at(1.5, "alt")
	check.call(actor.animation == &"drive_alt" and actor.index_at(1.5) == 2, "named swing pose uses its own contact frame")
	actor.swing_at(1.8, "missing")
	check.call(actor.animation == &"swing" and actor.index_at(1.8) == 3, "unknown swing pose falls back to standard swing")
	actor.swing_at(1.0)
	var frozen: int = actor.index_at(1.05)
	check.call(actor.index_at(1.05) == frozen, "paused game time freezes sprite frame")
	actor.index_at(1.16)
	check.call(actor.animation == &"idle", "swing recovers to idle")
	actor.miss_at(2.0)
	check.call(actor.index_at(2.0) == 0 and actor.index_at(2.2) == 2, "miss animates once")
	actor.index_at(2.41)
	check.call(actor.animation == &"idle", "miss recovers to idle")
	actor.reset()
	check.call(actor.animation == &"idle", "restart clears old character action")
	actor.finish_at(false, 3.0)
	check.call(actor.index_at(3.6) == 3 and actor.animation == &"miss", "defeat holds final Miss pose")
	actor.finish_at(true, 4.0)
	check.call(actor.animation == &"idle" and not actor.hold_last, "winner returns to idle celebration loop")
	actor.reset()
	check.call(not actor.hold_last, "restart clears held defeat pose")

	for role in ["player", "enemy"]:
		var actual: RefCounted = Animator.new()
		check.call(actual.configure(role), "actual character library loads " + role)
		check.call(actual.contact_frame == 3, "actual contact frame metadata")
		for entry in [["idle", 4], ["swing", 6], ["miss", 4]]:
			check.call(actual.frames.get_frame_count(entry[0]) == entry[1], "actual frame count " + role + entry[0])
			for i in range(entry[1]):
				var texture: Texture2D = actual.frames.get_frame_texture(entry[0], i)
				check.call(texture.get_width() == 128 and texture.get_height() == 128, "actual AtlasTexture 128x128")
				var image: Image = texture.get_image()
				image.convert(Image.FORMAT_RGBA8)
				var bytes: PackedByteArray = image.get_data()
				var binary: bool = true
				for offset in range(3, bytes.size(), 4):
					if bytes[offset] != 0 and bytes[offset] != 255:
						binary = false
						break
				check.call(binary, "actual frame alpha is binary")
				check.call(image.get_used_rect().end.y == 117, "actual foot baseline remains 116")
		actual.swing_at(1.0)
		check.call(actual.index_at(1.0) == 3, "actual animation contacts on time")

	for contact in [2.050051, 7.012345, 120.123456]:
		actor.swing_at(contact)
		check.call(actor.index_at(contact - 0.000001) == 2, "contact minus 1us remains preceding pose")
		check.call(actor.index_at(contact) == 3, "microsecond contact boundary selects frame 3")
		check.call(actor.index_at(contact + 0.000001) == 3, "contact plus 1us keeps contact pose")

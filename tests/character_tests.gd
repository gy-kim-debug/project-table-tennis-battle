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
	var actor: RefCounted = Animator.new()
	actor.frames = frames
	check.call(actor.index_at(0.0) == 0 and actor.index_at(0.5) == 2, "idle animation advances with game time")
	actor.swing_at(1.0)
	check.call(actor.index_at(0.85) == 0, "swing begins before contact")
	check.call(actor.index_at(1.0) == 3, "swing contact pose matches logical contact time")
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

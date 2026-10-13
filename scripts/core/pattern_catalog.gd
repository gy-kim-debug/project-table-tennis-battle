extends RefCounted

static func all() -> Array[Resource]:
	return [preload("res://resources/patterns/basic_return.tres"),
		preload("res://resources/patterns/fast_smash.tres"),
		preload("res://resources/patterns/high_lob.tres"),
		preload("res://resources/patterns/low_drive.tres"),
		preload("res://resources/patterns/tempo_change.tres")]

static func difficulties() -> Array[Resource]:
	return [preload("res://resources/difficulty/easy.tres"),
		preload("res://resources/difficulty/normal.tres"),
		preload("res://resources/difficulty/hard.tres")]

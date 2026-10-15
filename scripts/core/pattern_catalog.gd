extends RefCounted

const CATALOG = "res://resources/catalog.json"

static func _load_entries(key: String) -> Array[Resource]:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var entries: Array[Resource] = []
	for path in catalog[key]:
		var resource: Resource = load(String(path)) as Resource
		assert(resource != null, "Invalid catalog entry: " + String(path))
		entries.append(resource)
	return entries

static func all() -> Array[Resource]:
	return _load_entries("patterns")

static func difficulties() -> Array[Resource]:
	return _load_entries("difficulties")

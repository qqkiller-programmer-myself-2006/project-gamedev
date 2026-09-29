class_name SpriteSet
extends RefCounted
## Manifest-backed loader for the owner's class sprite sheets.

const ROOT := "res://assets/heroes/"
const MANIFEST := "res://assets/heroes/manifest.json"
const ART_CLASSES := {"archer": true, "mage": true, "swordsman": true, "guardian": true, "assassin": true}

static var _manifest: Dictionary = {}
static var _loaded := false
var class_id := ""
var data: Dictionary = {}

static func for_class(class_id_value: String) -> SpriteSet:
	if not ART_CLASSES.has(class_id_value.to_lower()):
		return null
	_load_manifest()
	if not _manifest.has(class_id_value.to_lower()):
		return null
	var result := SpriteSet.new()
	result.class_id = class_id_value.to_lower()
	result.data = _manifest[result.class_id]
	return result

static func portrait(class_id_value: String) -> Texture2D:
	var set := for_class(class_id_value)
	if set == null:
		return null
	return load(ROOT + set.class_id + "/portrait.png") as Texture2D

func frames(animation: String) -> Array[Texture2D]:
	var listed = data.get("animations", {}).get(animation, [])
	if listed is Dictionary:
		listed = listed.get("right", listed.get("left", []))
	elif animation == "idle" and listed is Array:
		var facing := ""
		for filename in listed:
			if str(filename).contains("_right"):
				facing = str(filename)
				break
		if facing.is_empty():
			for filename in listed:
				if str(filename).contains("_left"):
					facing = str(filename)
					break
		if facing.is_empty() and not listed.is_empty():
			facing = str(listed[0])
		listed = [facing] if not facing.is_empty() else []
	var result: Array[Texture2D] = []
	for filename in listed:
		var texture := load(ROOT + class_id + "/" + str(filename)) as Texture2D
		if texture != null:
			result.append(texture)
	return result

func mirrored(animation: String) -> bool:
	var listed = data.get("animations", {}).get(animation, [])
	if listed is Dictionary:
		return not listed.has("right") and listed.has("left")
	if animation == "idle" and listed is Array:
		var has_left := false
		for filename in listed:
			if str(filename).contains("_right"):
				return false
			has_left = has_left or str(filename).contains("_left")
		return has_left
	return false

func fps(animation: String) -> float:
	return float(data.get("fps", {}).get(animation, 4))

func baseline(animation: String) -> float:
	return float(data.get("baseline", {}).get(animation, 0))

func canvas(animation: String) -> Vector2:
	var size: Array = data.get("canvas", {}).get(animation, [1, 1])
	return Vector2(float(size[0]), float(size[1]))

static func _load_manifest() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(MANIFEST, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed

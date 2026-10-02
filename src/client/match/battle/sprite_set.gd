class_name SpriteSet
extends RefCounted
## Manifest-backed loader for the owner's class sprite sheets.

const ROOT := "res://assets/heroes/"
const MANIFEST := "res://assets/heroes/manifest.json"
const ART_CLASSES := {"archer": true, "mage": true, "swordsman": true, "guardian": true, "assassin": true, "bram": true}
const ENEMY_ROOT := "res://assets/enemies/"
const ENEMY_MANIFEST := "res://assets/enemies/manifest.json"

static var _manifest: Dictionary = {}
static var _loaded := false
static var _enemy_manifest: Dictionary = {}
static var _enemy_loaded := false
static var _texture_cache: Dictionary = {}
var class_id := ""
var enemy_id := ""
var variant := ""
var is_enemy := false
var data: Dictionary = {}

static func for_enemy(enemy_id_value: String, variant_value: String = "") -> SpriteSet:
	_load_enemy_manifest()
	var key := enemy_id_value.to_lower()
	if not _enemy_manifest.has(key):
		return null
	var entry: Dictionary = _enemy_manifest[key]
	if not variant_value.is_empty() and not entry.get("variants", []).has(variant_value):
		variant_value = ""
	var result := SpriteSet.new()
	result.enemy_id = key
	result.variant = variant_value
	result.is_enemy = true
	result.data = entry
	return result

static func enemy_manifest() -> Dictionary:
	_load_enemy_manifest()
	return _enemy_manifest.duplicate(true)

static func for_class(class_id_value: String) -> SpriteSet:
	var key := class_id_value.to_lower()
	if key == "classless":
		key = "bram"
	if not ART_CLASSES.has(key):
		return null
	_load_manifest()
	if not _manifest.has(key):
		return null
	var result := SpriteSet.new()
	result.class_id = key
	result.data = _manifest[result.class_id]
	return result

static func portrait(class_id_value: String) -> Texture2D:
	var set := for_class(class_id_value)
	if set == null:
		return null
	return _cached_texture(ROOT + set.class_id + "/portrait.png")

static func enemy_portrait(enemy_id_value: String) -> Texture2D:
	var portrait_path := ENEMY_ROOT + enemy_id_value + "/portrait.png"
	if ResourceLoader.exists(portrait_path):
		return _cached_texture(portrait_path)
	var set := for_enemy(enemy_id_value)
	if set == null:
		return null
	var idle_frames := set.frames("idle")
	return idle_frames[0] if not idle_frames.is_empty() else null

func frames(animation: String) -> Array[Texture2D]:
	animation = _key(animation)
	if not is_enemy and class_id == "bram" and (animation == "hurt" or animation == "dead" or animation == "die"):
		if not data.get("animations", {}).has(animation):
			animation = "idle"
	if is_enemy and not variant.is_empty() and animation == "idle":
		var variant_path := ENEMY_ROOT + enemy_id + "/variants/" + variant + ".png"
		var variant_texture := _cached_texture(variant_path)
		if variant_texture != null:
			return [variant_texture]
	var listed = data.get("animations", {}).get(animation, [])
	if is_enemy and (listed is int or listed is float):
		var generated: Array[String] = []
		for index in int(listed):
			generated.append("%s_%02d.png" % [animation, index])
		listed = generated
	if listed is Dictionary:
		listed = listed.get("right", listed.get("left", []))
	elif animation == "idle" and listed is Array and not is_enemy:
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
		var base := ENEMY_ROOT + enemy_id + "/" if is_enemy else ROOT + class_id + "/"
		var texture := _cached_texture(base + str(filename))
		if texture != null:
			result.append(texture)
	return result

func mirrored(animation: String) -> bool:
	if is_enemy:
		return str(data.get("faces", "right")) == "right"
	if class_id == "bram" and (animation == "hurt" or animation == "dead" or animation == "die"):
		if not data.get("animations", {}).has(animation):
			animation = "idle"
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
	animation = _key(animation)
	return float(data.get("fps", {}).get(animation, 4))

func baseline(animation: String) -> float:
	animation = _key(animation)
	if is_enemy and not variant.is_empty() and animation == "idle":
		return canvas("idle").y
	return float(data.get("baseline", {}).get(animation, 0))

func canvas(animation: String) -> Vector2:
	animation = _key(animation)
	if is_enemy and not variant.is_empty() and animation == "idle":
		var texture := _cached_texture(ENEMY_ROOT + enemy_id + "/variants/" + variant + ".png")
		if texture != null:
			return Vector2(texture.get_width(), texture.get_height())
	var size: Array = data.get("canvas", {}).get(animation, [1, 1])
	return Vector2(float(size[0]), float(size[1]))

## Enemy sheets name the death animation "die"; heroes and tokens use "dead".
func _key(animation: String) -> String:
	if animation == "dead" and is_enemy and not data.get("animations", {}).has("dead"):
		return "die"
	return animation

func size_px() -> float:
	return float(data.get("size_px", 48))

static func _cached_texture(path: String) -> Texture2D:
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path) as Texture2D
	return _texture_cache[path] as Texture2D

static func _load_enemy_manifest() -> void:
	if _enemy_loaded:
		return
	_enemy_loaded = true
	var file := FileAccess.open(ENEMY_MANIFEST, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_enemy_manifest = parsed

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

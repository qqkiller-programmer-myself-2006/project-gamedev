class_name SkillFx
extends RefCounted
## Small client-only sprite animation for resolved class skills.

const MANIFEST_PATH := "res://assets/fx/manifest.json"
static var _manifest: Dictionary = {}
static var _manifest_loaded := false


static func anchor(skill: String) -> String:
	_load_manifest()
	return str(_manifest.get(skill, {}).get("anchor", ""))


static func play(parent: Control, skill: String, at: Vector2) -> void:
	if not is_instance_valid(parent):
		return
	_load_manifest()
	var info: Dictionary = _manifest.get(skill, {})
	if info.is_empty():
		return
	if not parent.is_inside_tree():
		return
	var count := int(info.get("frames", 0))
	var size: Array = info.get("size", [])
	if count <= 0 or size.size() != 2:
		return
	var textures: Array[Texture2D] = []
	for i in count:
		var path := "res://assets/fx/%s/frame_%02d.png" % [skill, i]
		if not ResourceLoader.exists(path):
			return
		var texture := load(path) as Texture2D
		if texture == null:
			return
		textures.append(texture)
	var extent := Vector2(float(size[0]), float(size[1]))
	var sprite := TextureRect.new()
	sprite.name = "SkillFx_%s" % skill
	sprite.texture = textures[0]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.size = extent
	sprite.position = at - extent * 0.5
	sprite.z_index = 100
	parent.add_child(sprite)
	if str(info.get("tier", "normal")) == "ultimate":
		_play_flash(parent)
	var fps := maxf(1.0, float(info.get("fps", 14)))
	var tween := sprite.create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_set_frame.bind(sprite, textures, count),
		0.0, float(count - 1), float(count - 1) / fps)
	tween.tween_callback(func() -> void:
		if is_instance_valid(sprite):
			sprite.queue_free())


static func _set_frame(value: float, sprite: TextureRect, textures: Array[Texture2D], count: int) -> void:
	if is_instance_valid(sprite):
		sprite.texture = textures[clampi(roundi(value), 0, count - 1)]


static func _load_manifest() -> void:
	if _manifest_loaded:
		return
	_manifest_loaded = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if parsed is Dictionary:
		_manifest = parsed


static func _play_flash(parent: Control) -> void:
	var flash := ColorRect.new()
	flash.name = "SkillFxFlash"
	flash.color = Color(1.0, 0.78, 0.30, 0.16)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 99
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free())

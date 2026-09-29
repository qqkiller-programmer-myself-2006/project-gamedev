class_name Icons
extends RefCounted
## Loads the authored 16x16 pixel icon set (see docs/design/icons.md).

const ICON_NAMES := [
	"fight", "items", "focus", "strike", "guard", "defend", "flee", "skill", "ready", "transfer",
	"hp", "energy", "gold", "gems", "exp", "level",
	"str", "dex", "con", "int", "fth", "cha", "lck",
	"poison", "bleed", "burn", "stun", "weak", "shield", "regen", "dodge", "crit",
	"weapon", "armor", "accessory", "consumable",
	"combat", "elite", "merchant", "rest", "treasure", "story", "class_trial", "boss",
	"play", "multiplayer", "story_mode", "settings", "credits", "back", "quit", "save", "lock", "info", "warning",
]

static var _cache: Dictionary = {}
static var _placeholder: ImageTexture


static func texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	if ICON_NAMES.has(name):
		var file_name := "_con" if name == "con" else name
		var icon: Texture2D = load("res://assets/icons/%s.png" % file_name)
		if icon != null:
			_cache[name] = icon
			return icon
	push_warning("Unknown icon '%s'; showing placeholder." % name)
	return _missing_texture()


static func rect(name: String, px: int = 16) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture(name)
	icon.custom_minimum_size = Vector2(px, px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


static func with_text(name: String, text: String, px: int = 16) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(rect(name, px))
	row.add_child(UiKit.label(text, "body"))
	return row


static func _missing_texture() -> Texture2D:
	if _placeholder == null:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 16:
				var magenta := Color.MAGENTA if ((x / 4 + y / 4) % 2 == 0) else Color(0.08, 0.02, 0.08)
				image.set_pixel(x, y, magenta)
		_placeholder = ImageTexture.create_from_image(image)
	return _placeholder

class_name Home3D
extends Control
## 3D Home hub (ADR-0015, T3D-02): a third-person walkable room with six Stations
## (story, battle, party, class, shop, settings). A Station only emits
## `station_activated(id)`; the caller opens the existing screen.
##
## The scene graph is built in `_init`, so movement, bounds and station selection
## (`step`, `teleport`, `nearest_station`, `handle_key`) run headless without a
## SceneTree. Placeholder primitive meshes only; gl_compatibility safe (no shadows).

signal station_activated(id: String)

const STATION_IDS: Array[String] = ["story", "battle", "party", "class", "shop", "settings"]
## Display msgids, translated at runtime through Tr.
const STATION_LABELS := {
	"story": "Story", "battle": "Battle", "party": "Party",
	"class": "Class", "shop": "Shop", "settings": "Settings",
}
## Msgids not yet in the Thai catalog fall back to English (i18n is outside this task).
const UNAVAILABLE_TEXT := "Unavailable"
const STATION_POSITIONS := {
	"story": Vector3(0.0, 0.0, -5.5),
	"battle": Vector3(7.5, 0.0, -2.5),
	"party": Vector3(7.5, 0.0, 3.5),
	"class": Vector3(-7.5, 0.0, 3.5),
	"shop": Vector3(-7.5, 0.0, -2.5),
	"settings": Vector3(0.0, 0.0, 5.5),
}
const ARENA_HALF := Vector2(11.0, 7.5)
const WALK_SPEED := 5.0
const PLAYER_RADIUS := 0.4
const INTERACTION_RADIUS := 1.9
const CAMERA_OFFSET := Vector3(0.0, 9.0, 8.5)
const CAMERA_PITCH_DEG := -52.0
const CAMERA_SMOOTH_SPEED := 5.0
const TURN_SPEED := 14.0

const BLACK := Color("#050506")
const FLOOR := Color("#14141a")
const RED := Color("#d11f2e")
const DARK_RED := Color("#6b1119")
const WHITE := Color("#f4f4f4")
const GRAY := Color("#4a4a52")

var reduced_motion := false
var text_scale := 1.0
## When false the player cannot walk or interact (e.g. an overlay is open).
var input_enabled := true
var player: CharacterBody3D
var camera: Camera3D
var facing := Vector3(0.0, 0.0, 1.0)
var prompt: Label
var hint: Label
var enabled_stations: Array[String] = []

var _viewport: SubViewport
var _container: SubViewportContainer
var _overlay: Control
var _name_labels: Dictionary = {}
var _pads: Dictionary = {}
var _rings: Dictionary = {}
var _camera_focus := Vector3.ZERO
var _time := 0.0
var _walking := false
var _body: Node3D


func _init() -> void:
	enabled_stations.assign(STATION_IDS)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_viewport()
	_build_world()
	_build_player()
	_build_overlay()
	update_camera(0.0, true)
	set_process(true)


## Applies reduced motion and text size from the client settings.
func apply_settings(settings: ClientSettings) -> void:
	reduced_motion = settings.reduced_motion
	set_text_scale(settings.text_scale)


func set_text_scale(scale: float) -> void:
	text_scale = scale
	theme = UiKit.make_theme(scale)
	update_labels()


## Only the listed station ids can be activated (e.g. no `story` Continue without a save).
## Others stay visible but dimmed.
func set_stations_enabled(ids: Array) -> void:
	enabled_stations.clear()
	for id in ids:
		if STATION_IDS.has(str(id)):
			enabled_stations.append(str(id))
	_refresh_markers()
	update_labels()


func is_station_enabled(id: String) -> bool:
	return enabled_stations.has(id)


func station_position(id: String) -> Vector3:
	return STATION_POSITIONS.get(id, Vector3.ZERO)


## Moves the player on the XZ plane. `direction.y` is screen-down (+Z world).
func step(direction: Vector2, delta: float) -> void:
	_walking = not direction.is_zero_approx() and delta > 0.0
	if not _walking:
		return
	var dir := direction.normalized()
	var motion := dir * WALK_SPEED * delta
	var pos := player.position
	pos.x = clampf(pos.x + motion.x, -ARENA_HALF.x + PLAYER_RADIUS, ARENA_HALF.x - PLAYER_RADIUS)
	pos.z = clampf(pos.z + motion.y, -ARENA_HALF.y + PLAYER_RADIUS, ARENA_HALF.y - PLAYER_RADIUS)
	player.position = pos
	facing = Vector3(dir.x, 0.0, dir.y)


func teleport(pos: Vector3) -> void:
	player.position = Vector3(
		clampf(pos.x, -ARENA_HALF.x + PLAYER_RADIUS, ARENA_HALF.x - PLAYER_RADIUS), 0.0,
		clampf(pos.z, -ARENA_HALF.y + PLAYER_RADIUS, ARENA_HALF.y - PLAYER_RADIUS))
	update_camera(0.0, true)
	update_labels()


func nearest_station() -> String:
	var nearest := ""
	var best := INTERACTION_RADIUS
	for id in STATION_IDS:
		var pos: Vector3 = STATION_POSITIONS[id]
		var distance := Vector2(player.position.x - pos.x, player.position.z - pos.z).length()
		if distance <= best:
			nearest = id
			best = distance
	return nearest


func activate_nearest_station() -> bool:
	if not input_enabled:
		return false
	var id := nearest_station()
	if id.is_empty() or not is_station_enabled(id):
		return false
	station_activated.emit(id)
	return true


func handle_key(keycode: int) -> bool:
	if keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER]:
		return activate_nearest_station()
	return false


func read_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction


## The camera tracks the player; `snap` (and reduced motion) skips the easing.
func update_camera(delta: float, snap: bool = false) -> void:
	var target := player.position
	if snap or reduced_motion or delta <= 0.0:
		_camera_focus = target
	else:
		_camera_focus = _camera_focus.lerp(target, 1.0 - exp(-CAMERA_SMOOTH_SPEED * delta))
	camera.position = _camera_focus + CAMERA_OFFSET
	camera.rotation_degrees = Vector3(CAMERA_PITCH_DEG, 0.0, 0.0)


func camera_focus() -> Vector3:
	return _camera_focus


func prompt_rect() -> Rect2:
	return Rect2(prompt.position, prompt.size.max(prompt.get_combined_minimum_size()))


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and handle_key(key.keycode):
		if is_inside_tree():
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if input_enabled:
		step(read_input_direction(), delta)
	else:
		_walking = false
	_animate_player(delta)
	if not reduced_motion:
		_time += delta
		_pulse_rings()
	update_camera(delta)
	update_labels()


## Projects the name labels and the interaction prompt over the 3D view.
func update_labels() -> void:
	if not is_instance_valid(camera) or not camera.is_inside_tree():
		return
	var view := _view_size()
	var near := nearest_station() if input_enabled else ""
	for id in STATION_IDS:
		var label: Label = _name_labels[id]
		label.visible = true
		label.modulate = Color.WHITE if is_station_enabled(id) else Color(1, 1, 1, 0.45)
		_place_above(label, STATION_POSITIONS[id] + Vector3(0.0, 2.2, 0.0), view, 0.0)
	if near.is_empty():
		prompt.visible = false
		return
	prompt.text = "[E] " + Tr.t(str(STATION_LABELS[near]))
	if not is_station_enabled(near):
		prompt.text += " - " + Tr.t(UNAVAILABLE_TEXT)
	prompt.visible = true
	var name_label: Label = _name_labels[near]
	_place_above(prompt, STATION_POSITIONS[near] + Vector3(0.0, 2.2, 0.0), view,
			name_label.get_combined_minimum_size().y + 4.0)


func _place_above(label: Control, world: Vector3, view: Vector2, lift: float) -> void:
	if camera.is_position_behind(world):
		label.visible = false
		return
	var screen := camera.unproject_position(world)
	var label_size := label.get_combined_minimum_size()
	label.size = label_size
	label.position = Vector2(
		clampf(screen.x - label_size.x * 0.5, 8.0, maxf(8.0, view.x - label_size.x - 8.0)),
		clampf(screen.y - label_size.y - lift, 8.0, maxf(8.0, view.y - label_size.y - 54.0)))


func _view_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	if is_inside_tree():
		return get_viewport_rect().size
	return Vector2(1280.0, 720.0)


func _animate_player(delta: float) -> void:
	if _walking:
		var target_yaw := atan2(facing.x, facing.z)
		if reduced_motion:
			_body.rotation.y = target_yaw
		else:
			_body.rotation.y = lerp_angle(_body.rotation.y, target_yaw, 1.0 - exp(-TURN_SPEED * delta))
	var bob := 0.0
	if _walking and not reduced_motion:
		bob = absf(sin(_time * 12.0)) * 0.08
	_body.position.y = bob


func _pulse_rings() -> void:
	for id in _rings:
		var ring: MeshInstance3D = _rings[id]
		var s := 1.0 + 0.04 * sin(_time * 3.0 + float(STATION_IDS.find(id)))
		ring.scale = Vector3(s, 1.0, s)


# --- scene construction ------------------------------------------------------

func _build_viewport() -> void:
	_container = SubViewportContainer.new()
	_container.name = "ViewContainer"
	_container.stretch = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_container)
	_viewport = SubViewport.new()
	_viewport.name = "World3D"
	_viewport.handle_input_locally = false
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.size = Vector2i(1280, 720)
	_container.add_child(_viewport)


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d8d8e0")
	env.ambient_light_energy = 0.55
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_viewport.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.7
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-55.0, 25.0, 0.0)
	_viewport.add_child(sun)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 55.0
	camera.current = true
	_viewport.add_child(camera)

	_add_mesh(_viewport, _box(Vector3(ARENA_HALF.x * 2.0, 0.2, ARENA_HALF.y * 2.0)), _mat(FLOOR),
			Vector3(0.0, -0.1, 0.0))
	_add_floor_grid()
	_add_border()
	for id in STATION_IDS:
		_build_station(id)


func _add_floor_grid() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_LINES)
	var x := -ARENA_HALF.x
	while x <= ARENA_HALF.x + 0.01:
		surface.add_vertex(Vector3(x, 0.01, -ARENA_HALF.y))
		surface.add_vertex(Vector3(x, 0.01, ARENA_HALF.y))
		x += 2.0
	var z := -ARENA_HALF.y
	while z <= ARENA_HALF.y + 0.01:
		surface.add_vertex(Vector3(-ARENA_HALF.x, 0.01, z))
		surface.add_vertex(Vector3(ARENA_HALF.x, 0.01, z))
		z += 2.0
	var material := _mat(DARK_RED, true)
	var grid := MeshInstance3D.new()
	grid.name = "Grid"
	grid.mesh = surface.commit()
	grid.material_override = material
	_viewport.add_child(grid)


func _add_border() -> void:
	var material := _mat(RED)
	var w := ARENA_HALF.x * 2.0
	var d := ARENA_HALF.y * 2.0
	_add_mesh(_viewport, _box(Vector3(w + 0.4, 0.5, 0.2)), material, Vector3(0.0, 0.25, -ARENA_HALF.y - 0.1))
	_add_mesh(_viewport, _box(Vector3(w + 0.4, 0.5, 0.2)), material, Vector3(0.0, 0.25, ARENA_HALF.y + 0.1))
	_add_mesh(_viewport, _box(Vector3(0.2, 0.5, d)), material, Vector3(-ARENA_HALF.x - 0.1, 0.25, 0.0))
	_add_mesh(_viewport, _box(Vector3(0.2, 0.5, d)), material, Vector3(ARENA_HALF.x + 0.1, 0.25, 0.0))


func _build_station(id: String) -> void:
	var root := Node3D.new()
	root.name = "Station_%s" % id
	root.position = STATION_POSITIONS[id]
	_viewport.add_child(root)
	var pad := _add_mesh(root, _cylinder(1.25, 1.25, 0.1), _mat(RED), Vector3(0.0, 0.05, 0.0))
	pad.name = "Pad"
	_pads[id] = pad
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.25
	ring_mesh.outer_radius = 1.4
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 6
	var ring := _add_mesh(root, ring_mesh, _mat(WHITE, true), Vector3(0.0, 0.08, 0.0))
	ring.scale = Vector3(1.0, 0.15, 1.0)
	_rings[id] = ring
	var white := _mat(WHITE)
	var red := _mat(RED)
	match id:
		"story":
			_add_mesh(root, _box(Vector3(0.9, 1.4, 0.15)), white, Vector3(0.0, 0.9, 0.0))
			_add_mesh(root, _box(Vector3(0.95, 0.12, 0.2)), red, Vector3(0.0, 1.66, 0.0))
		"battle":
			var blade_a := _add_mesh(root, _box(Vector3(0.12, 1.5, 0.12)), white, Vector3(0.0, 0.95, 0.0))
			blade_a.rotation_degrees = Vector3(0.0, 0.0, 28.0)
			var blade_b := _add_mesh(root, _box(Vector3(0.12, 1.5, 0.12)), red, Vector3(0.0, 0.95, 0.0))
			blade_b.rotation_degrees = Vector3(0.0, 0.0, -28.0)
		"party":
			for i in 3:
				var angle := TAU * float(i) / 3.0
				_add_mesh(root, _cylinder(0.22, 0.22, 0.9), white if i != 0 else red,
						Vector3(cos(angle) * 0.5, 0.55, sin(angle) * 0.5))
		"class":
			_add_mesh(root, _cylinder(0.0, 0.6, 1.4), white, Vector3(0.0, 0.8, 0.0))
			_add_mesh(root, _box(Vector3(0.3, 0.3, 0.3)), red, Vector3(0.0, 1.7, 0.0))
		"shop":
			_add_mesh(root, _box(Vector3(1.4, 0.6, 0.8)), white, Vector3(0.0, 0.4, 0.0))
			_add_mesh(root, _box(Vector3(1.6, 0.12, 1.0)), red, Vector3(0.0, 1.5, 0.0))
			_add_mesh(root, _box(Vector3(0.1, 1.1, 0.1)), white, Vector3(-0.7, 0.95, 0.4))
			_add_mesh(root, _box(Vector3(0.1, 1.1, 0.1)), white, Vector3(0.7, 0.95, 0.4))
		"settings":
			_add_mesh(root, _cylinder(0.55, 0.55, 0.5), white, Vector3(0.0, 0.35, 0.0))
			for i in 4:
				var tooth := _add_mesh(root, _box(Vector3(0.22, 0.4, 0.22)), red, Vector3.ZERO)
				tooth.rotation.y = TAU * float(i) / 8.0
				tooth.position = Vector3(0.0, 0.35, 0.0)
				tooth.scale = Vector3(1.0, 1.0, 4.0)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = 1.6
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.8, 0.0)
	player.add_child(shape)
	_body = Node3D.new()
	_body.name = "Body"
	player.add_child(_body)
	_add_mesh(_body, _box(Vector3(0.7, 0.9, 0.45)), _mat(WHITE), Vector3(0.0, 0.65, 0.0))
	_add_mesh(_body, _box(Vector3(0.5, 0.5, 0.5)), _mat(RED), Vector3(0.0, 1.35, 0.0))
	_add_mesh(_body, _box(Vector3(0.5, 0.12, 0.12)), _mat(WHITE), Vector3(0.0, 1.38, 0.28))
	_viewport.add_child(player)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	for id in STATION_IDS:
		var label := UiKit.label(STATION_LABELS[id], "body", WHITE)
		label.name = "Name_%s" % id
		_outline(label)
		_overlay.add_child(label)
		_name_labels[id] = label
	prompt = UiKit.label("[E]", "heading", RED.lightened(0.35))
	prompt.name = "StationPrompt"
	_outline(prompt)
	prompt.visible = false
	_overlay.add_child(prompt)
	hint = UiKit.label("WASD / Arrows  Move   E / Enter  Interact", "small", WHITE)
	hint.name = "ControlHint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 12.0
	hint.offset_right = -12.0
	hint.offset_top = -44.0
	hint.offset_bottom = -12.0
	_outline(hint)
	_overlay.add_child(hint)
	_refresh_markers()


func _outline(label: Label) -> void:
	label.add_theme_color_override("font_outline_color", BLACK)
	label.add_theme_constant_override("outline_size", 6)


func _refresh_markers() -> void:
	for id in STATION_IDS:
		var pad: MeshInstance3D = _pads[id]
		var material := pad.material_override as StandardMaterial3D
		material.albedo_color = RED if is_station_enabled(id) else GRAY


# --- mesh helpers --------------------------------------------------------------

func _mat(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _box(extent: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = extent
	return mesh


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return mesh


func _add_mesh(parent: Node, mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance

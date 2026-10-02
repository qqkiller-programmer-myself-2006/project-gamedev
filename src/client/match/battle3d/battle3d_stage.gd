class_name Battle3DStage
extends Control
## 3D battle stage (ADR-0015, T3D-03): replaces only the "stage" (tokens + backdrop) of the
## battle screen. HUD, command menus and input stay Controls elsewhere. Party stands on the
## left, enemies on the right, a cinematic camera idles, pushes in on Strike/Skill and shakes on
## a critical hit.
##
## Input is presentation data only (no snapshot, no server types):
##   apply_state({units: [{id, side: "party"|"enemy", slot, class_key, name, hp, max_hp,
##                          energy, alive, boss?, row?}], current_actor, mode, targets: [id]})
##   play_cue({type: "strike"|"skill"|"focus"|"item"|"guard"|"hurt"|"die"|"heal",
##             actor, target, skill_id, amount, crit})
## The scene graph is built in `_init` and animation is advanced by `advance(delta)`, so state,
## anchors and cues are testable headless without a SceneTree. Placeholder primitives only;
## gl_compatibility safe (no shadows, no glow).

signal unit_clicked(id: String)

const CUE_TYPES: Array[String] = ["strike", "skill", "focus", "item", "guard", "hurt", "die", "heal"]
const MAX_ENEMIES := 5

const BLACK := Color("#050506")
const FLOOR := Color("#14141a")
const RED := Color("#d11f2e")
const DARK_RED := Color("#6b1119")
const WHITE := Color("#f4f4f4")
const GRAY := Color("#4a4a52")
const LIGHT_GRAY := Color("#9a9aa6")

const CAMERA_FOV := 45.0
const CAMERA_BASE_DISTANCE := 11.0
const CAMERA_REFERENCE_ASPECT := 16.0 / 9.0
const CAMERA_TARGET := Vector3(0.0, 0.9, 0.0)
const CAMERA_DIRECTION := Vector3(0.0, 0.42, 1.0)
const PUSH_FRACTION := 0.3
const PUSH_FOCUS_BLEND := 0.45
const SHAKE_DECAY := 1.6
const FRONT_X := 2.3
const BACK_X := 4.5
const UNIT_HEIGHT := 1.9
const PICK_RADIUS_FACTOR := 0.65
const NO_ANCHOR := Vector2(-1.0, -1.0)
const DURATIONS := {
	"strike": 0.55, "skill": 0.8, "focus": 0.7, "item": 0.55, "guard": 0.9,
	"hurt": 0.45, "die": 0.8, "heal": 0.7,
}

var reduced_motion := false
var low_quality := false
var camera: Camera3D

var _viewport: SubViewport
var _container: SubViewportContainer
var _root3d: Node3D
var _units_root: Node3D
var _effects_root: Node3D
var _decor_extra: Node3D
var _rigs: Dictionary = {}
var _effects: Array = []
var _material_cache: Dictionary = {}
var _current_actor := ""
var _targets: Array = []
var _time := 0.0
var _push_peak := 0.0
var _push_time := 0.0
var _push_len := 0.0
var _push_focus := Vector3.ZERO
var _shake := 0.0
var _camera_view := Vector2.ZERO
var last_cue: Dictionary = {}


class Rig extends RefCounted:
	var id := ""
	var side := "party"
	var class_key := ""
	var alive := true
	var boss := false
	var home := Vector3.ZERO
	var root: Node3D
	var body: Node3D
	var shield: Node3D
	var ring: MeshInstance3D
	var target_ring: MeshInstance3D
	var material: StandardMaterial3D
	var base_color := WHITE
	var anim := ""
	var anim_t := 0.0
	var anim_dur := 0.0
	var anim_dir := Vector3.ZERO
	var phase := 0.0
	var flash := 0.0
	var fallen := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_build_viewport()
	_build_world()
	resized.connect(_on_resized)
	update_camera(0.0)
	set_process(true)


# --- public API ---------------------------------------------------------------

## Presentation-state input. Unknown or malformed units are skipped; units that are no longer
## listed are removed.
func apply_state(state: Dictionary) -> void:
	var raw: Variant = state.get("units", [])
	var units: Array = raw if raw is Array else []
	_current_actor = str(state.get("current_actor", ""))
	var target_list: Variant = state.get("targets", [])
	_targets = (target_list as Array).duplicate() if target_list is Array else []
	var party: Array = []
	var enemies: Array = []
	for entry in units:
		if not (entry is Dictionary) or str(entry.get("id", "")).is_empty():
			continue
		if str(entry.get("side", "party")) == "party":
			party.append(entry)
		elif enemies.size() < MAX_ENEMIES:
			enemies.append(entry)
	var seen := {}
	for entry in party:
		var slot := clampi(int(entry.get("slot", 0)), 0, 4)
		_sync_unit(entry, _party_home(slot), seen)
	var enemy_homes := _enemy_homes(enemies)
	for i in enemies.size():
		_sync_unit(enemies[i], enemy_homes[i], seen)
	for id in _rigs.keys():
		if not seen.has(id):
			_remove_rig(id)
	_refresh_markers()


## Plays one presentation cue. Cues for unknown units animate what they can; unknown types are
## ignored.
func play_cue(cue: Dictionary) -> void:
	var type := str(cue.get("type", ""))
	if not CUE_TYPES.has(type):
		return
	last_cue = cue.duplicate()
	var actor: Rig = _rigs.get(str(cue.get("actor", "")))
	var target: Rig = _rigs.get(str(cue.get("target", "")))
	var crit := bool(cue.get("crit", false))
	match type:
		"strike":
			_start_anim(actor, "strike", _direction_to(actor, target))
			_push_to(actor, target, 1.0 if crit else 0.7)
		"skill":
			_start_anim(actor, "skill", Vector3.ZERO)
			_spawn_effect(target if target != null else actor, "burst", RED)
			_push_to(actor, target, 0.85 if crit else 0.55)
		"focus":
			_start_anim(actor, "focus", Vector3.ZERO)
			_spawn_effect(actor, "rise", WHITE)
		"item":
			_start_anim(actor, "item", Vector3.ZERO)
			_spawn_effect(target if target != null else actor, "rise", WHITE)
		"guard":
			_start_anim(actor, "guard", Vector3.ZERO)
		"hurt":
			var hit: Rig = target if target != null else actor
			_start_anim(hit, "hurt", Vector3.ZERO)
		"die":
			var down: Rig = target if target != null else actor
			_start_anim(down, "die", Vector3.ZERO)
			if down != null:
				down.alive = false
				_refresh_markers()
		"heal":
			var healed: Rig = target if target != null else actor
			_start_anim(healed, "heal", Vector3.ZERO)
			_spawn_effect(healed, "rise", WHITE)
	if crit and not reduced_motion:
		_shake = 1.0


## Screen-space anchor (pixels, inside this Control) of the unit's body centre; `NO_ANCHOR`
## when the id is unknown. HUD nameplates and damage numbers are placed from this.
func unit_screen_position(id: String) -> Vector2:
	var rig: Rig = _rigs.get(id)
	if rig == null:
		return NO_ANCHOR
	return _project(rig.home + Vector3(0.0, UNIT_HEIGHT * 0.5 * _unit_scale(rig), 0.0))


## Screen-space anchor above the unit's head, for nameplates.
func unit_head_screen_position(id: String) -> Vector2:
	var rig: Rig = _rigs.get(id)
	if rig == null:
		return NO_ANCHOR
	return _project(rig.home + Vector3(0.0, (UNIT_HEIGHT + 0.35) * _unit_scale(rig), 0.0))


func has_unit(id: String) -> bool:
	return _rigs.has(id)


func unit_ids() -> Array:
	return _rigs.keys()


func is_unit_alive(id: String) -> bool:
	var rig: Rig = _rigs.get(id)
	return rig != null and rig.alive


## Id of the nearest living unit under a screen point, or "" when none is close enough.
func pick_unit(screen_pos: Vector2) -> String:
	var best := ""
	var best_distance := INF
	for id in _rigs:
		var rig: Rig = _rigs[id]
		if not rig.alive:
			continue
		var centre := unit_screen_position(id)
		var radius := _pick_radius(rig)
		var distance := centre.distance_to(screen_pos)
		if distance <= radius and distance < best_distance:
			best = id
			best_distance = distance
	return best


## Low quality renders the 3D view at half resolution and drops decoration and camera drift.
func set_quality(low: bool) -> void:
	low_quality = low
	_container.stretch_shrink = 2 if low else 1
	_decor_extra.visible = not low


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		_shake = 0.0
		_push_peak = 0.0
	update_camera(0.0)


func animating() -> bool:
	if not _effects.is_empty() or _push_peak > 0.0 or _shake > 0.0:
		return true
	for id in _rigs:
		if (_rigs[id] as Rig).anim != "":
			return true
	return false


func camera_push_amount() -> float:
	return _push_amount()


func camera_shake_amount() -> float:
	return _shake


func camera_distance() -> float:
	return CAMERA_BASE_DISTANCE * maxf(1.0, CAMERA_REFERENCE_ASPECT / _aspect())


## Steps animation and camera. `_process` calls it with the frame delta; tests call it directly.
func advance(delta: float) -> void:
	_time += delta
	for id in _rigs:
		_animate_rig(_rigs[id], delta)
	_advance_effects(delta)
	if _push_peak > 0.0:
		_push_time += delta
		if _push_time >= _push_len:
			_push_peak = 0.0
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - SHAKE_DECAY * delta)
	update_camera(delta)


func update_camera(_delta: float) -> void:
	_camera_view = _view_size()
	var aspect := _aspect()
	var distance := CAMERA_BASE_DISTANCE * maxf(1.0, CAMERA_REFERENCE_ASPECT / aspect)
	var focus := CAMERA_TARGET
	var offset := Vector3.ZERO
	if not reduced_motion:
		if not low_quality:
			offset += Vector3(sin(_time * 0.35) * 0.4, sin(_time * 0.5) * 0.12, 0.0)
		if _shake > 0.0:
			offset += Vector3(sin(_time * 83.0), sin(_time * 61.0 + 1.7), 0.0) * (_shake * 0.22)
		var push := _push_amount()
		if push > 0.0:
			distance *= 1.0 - PUSH_FRACTION * push
			focus = focus.lerp(_push_focus, PUSH_FOCUS_BLEND * push)
	var cam_pos := focus + CAMERA_DIRECTION.normalized() * distance + offset
	var forward := (focus + offset * 0.5 - cam_pos).normalized()
	camera.transform = Transform3D(Basis.looking_at(forward, Vector3.UP), cam_pos)


# --- input ---------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	var id := pick_unit(button.position)
	if not id.is_empty():
		unit_clicked.emit(id)
		accept_event()


func _process(delta: float) -> void:
	advance(delta)


func _on_resized() -> void:
	update_camera(0.0)


# --- projection ----------------------------------------------------------------

func _view_size() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	return Vector2(1280.0, 720.0)


func _aspect() -> float:
	var view := _view_size()
	return maxf(0.4, view.x / view.y)


## Pure-math perspective projection so anchors work headless and before the first frame.
func _project(world: Vector3) -> Vector2:
	var view := _view_size()
	if view != _camera_view:
		update_camera(0.0)
	var local := camera.transform.affine_inverse() * world
	var depth := -local.z
	if depth < 0.05:
		return NO_ANCHOR
	var half_height := tan(deg_to_rad(camera.fov) * 0.5)
	var ndc_x := local.x / (depth * half_height * (view.x / view.y))
	var ndc_y := local.y / (depth * half_height)
	return Vector2((ndc_x + 1.0) * 0.5 * view.x, (1.0 - ndc_y) * 0.5 * view.y)


func _pick_radius(rig: Rig) -> float:
	var feet := _project(rig.home)
	var head := _project(rig.home + Vector3(0.0, UNIT_HEIGHT * _unit_scale(rig), 0.0))
	return maxf(18.0, feet.distance_to(head) * PICK_RADIUS_FACTOR)


func _unit_scale(rig: Rig) -> float:
	return 1.7 if rig.boss else 1.0


# --- layout --------------------------------------------------------------------

func _party_home(slot: int) -> Vector3:
	if slot < 3:
		return Vector3(-FRONT_X, 0.0, [-2.6, 0.0, 2.6][slot])
	return Vector3(-BACK_X, 0.0, [-1.3, 1.3][slot - 3])


## Rows come from `row` ("front"/"back") when given, else the first three are the front row.
## A lone boss stands in the middle.
func _enemy_homes(enemies: Array) -> Array[Vector3]:
	var fronts: Array[int] = []
	var backs: Array[int] = []
	for i in enemies.size():
		var row := str(enemies[i].get("row", ""))
		if row == "front" or (row != "back" and fronts.size() < 3):
			fronts.append(i)
		else:
			backs.append(i)
	var homes: Array[Vector3] = []
	homes.resize(enemies.size())
	for group in [[fronts, FRONT_X], [backs, BACK_X]]:
		var indices: Array = group[0]
		var zs := _row_spread(indices.size())
		for j in indices.size():
			homes[indices[j]] = Vector3(float(group[1]), 0.0, zs[j])
	return homes


func _row_spread(count: int) -> Array[float]:
	match count:
		1:
			return [0.0]
		2:
			return [-1.3, 1.3]
		3:
			return [-2.6, 0.0, 2.6]
		4:
			return [-3.0, -1.0, 1.0, 3.0]
		_:
			return [-3.6, -1.8, 0.0, 1.8, 3.6]


# --- rigs ----------------------------------------------------------------------

func _sync_unit(entry: Dictionary, home: Vector3, seen: Dictionary) -> void:
	var id := str(entry["id"])
	seen[id] = true
	var side := str(entry.get("side", "party"))
	var class_key := str(entry.get("class_key", entry.get("kind", "classless")))
	var boss := bool(entry.get("boss", false))
	var rig: Rig = _rigs.get(id)
	if rig != null and (rig.side != side or rig.class_key != class_key or rig.boss != boss):
		_remove_rig(id)
		rig = null
	if rig == null:
		rig = _make_rig(id, side, class_key, boss)
		_rigs[id] = rig
	rig.home = home
	rig.root.position = home
	var alive := bool(entry["alive"]) if entry.has("alive") else float(entry.get("hp", 1)) > 0.0
	if alive != rig.alive or (alive and rig.fallen):
		rig.alive = alive
		rig.anim = ""
		rig.fallen = not alive
		rig.flash = 0.0
		_pose(rig)


func _remove_rig(id: String) -> void:
	var rig: Rig = _rigs.get(id)
	if rig == null:
		return
	_rigs.erase(id)
	_free_node(rig.root)


func _make_rig(id: String, side: String, class_key: String, boss: bool) -> Rig:
	var rig := Rig.new()
	rig.id = id
	rig.side = side
	rig.class_key = class_key
	rig.boss = boss
	rig.phase = float(absi(id.hash()) % 628) / 100.0
	rig.root = Node3D.new()
	rig.root.name = "Unit_%s" % id
	_units_root.add_child(rig.root)
	rig.body = Node3D.new()
	rig.body.name = "Body"
	rig.root.add_child(rig.body)
	var facing := Node3D.new()
	facing.name = "Facing"
	facing.rotation.y = PI * 0.5 if side == "party" else -PI * 0.5
	rig.body.add_child(facing)
	# Floor disc (fake shadow) and the actor / target markers stay on the root, not the body.
	_add_mesh(rig.root, _cylinder(0.7, 0.7, 0.02), _mat(BLACK, true), Vector3(0.0, 0.015, 0.0))
	rig.ring = _add_ring(rig.root, 0.95, 1.1, WHITE)
	rig.target_ring = _add_ring(rig.root, 1.2, 1.38, RED)
	rig.body.scale = Vector3.ONE * _unit_scale(rig)
	_build_model(rig, facing, class_key, side)
	rig.shield = _add_mesh(facing, _box(Vector3(0.12, 1.3, 1.1)), _mat(WHITE, true), Vector3(0.7, 0.9, 0.0))
	rig.shield.visible = false
	return rig


func _add_ring(parent: Node3D, inner: float, outer: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 20
	mesh.ring_segments = 4
	var ring := _add_mesh(parent, mesh, _mat(color, true), Vector3(0.0, 0.05, 0.0))
	ring.scale = Vector3(1.0, 0.12, 1.0)
	ring.visible = false
	return ring


func _build_model(rig: Rig, facing: Node3D, class_key: String, side: String) -> void:
	var enemy := side != "party"
	var body_color := WHITE
	var accent := RED
	match class_key:
		"swordsman":
			body_color = RED
			accent = WHITE
		"guardian":
			body_color = WHITE
			accent = DARK_RED
		"mage":
			body_color = GRAY
			accent = RED
		"archer":
			body_color = LIGHT_GRAY
			accent = RED
		"assassin":
			body_color = Color("#16161c")
			accent = RED
		_:
			body_color = LIGHT_GRAY
			accent = WHITE
	if enemy:
		body_color = DARK_RED if not rig.boss else Color("#3a0a10")
		accent = WHITE
	rig.base_color = body_color
	rig.material = StandardMaterial3D.new()
	rig.material.albedo_color = body_color
	var trim := _mat(accent)
	if class_key == "mage" and not enemy:
		_add_mesh(facing, _cylinder(0.12, 0.55, 1.1), rig.material, Vector3(0.0, 0.55, 0.0))
	else:
		_add_mesh(facing, _box(Vector3(0.7, 0.95, 0.45)), rig.material, Vector3(0.0, 0.7, 0.0))
	_add_mesh(facing, _box(Vector3(0.45, 0.45, 0.45)), _mat(WHITE if not enemy else GRAY), Vector3(0.0, 1.45, 0.0))
	_add_mesh(facing, _box(Vector3(0.5, 0.1, 0.1)), trim, Vector3(0.0, 1.48, 0.24))
	if enemy:
		_add_mesh(facing, _cylinder(0.0, 0.1, 0.35), trim, Vector3(0.14, 1.8, 0.0))
		_add_mesh(facing, _cylinder(0.0, 0.1, 0.35), trim, Vector3(-0.14, 1.8, 0.0))
		_add_mesh(facing, _box(Vector3(0.14, 0.14, 0.9)), trim, Vector3(0.0, 0.9, 0.45))
		return
	match class_key:
		"swordsman":
			_add_mesh(facing, _box(Vector3(0.1, 0.1, 1.0)), trim, Vector3(0.0, 0.95, 0.65))
		"guardian":
			_add_mesh(facing, _box(Vector3(0.7, 0.9, 0.14)), trim, Vector3(0.0, 0.8, 0.35))
		"mage":
			_add_mesh(facing, _box(Vector3(0.08, 1.7, 0.08)), trim, Vector3(0.35, 0.85, 0.2))
			_add_mesh(facing, _box(Vector3(0.2, 0.2, 0.2)), _mat(RED, true), Vector3(0.35, 1.8, 0.2))
		"archer":
			_add_mesh(facing, _box(Vector3(0.08, 1.2, 0.08)), trim, Vector3(0.0, 0.9, 0.4))
		"assassin":
			_add_mesh(facing, _box(Vector3(0.1, 0.1, 0.7)), trim, Vector3(0.0, 1.1, 0.5))
			_add_mesh(facing, _box(Vector3(0.75, 0.14, 0.5)), trim, Vector3(0.0, 1.2, 0.0))
		_:
			_add_mesh(facing, _box(Vector3(0.1, 0.1, 0.6)), trim, Vector3(0.0, 0.95, 0.5))


func _refresh_markers() -> void:
	for id in _rigs:
		var rig: Rig = _rigs[id]
		rig.ring.visible = id == _current_actor and rig.alive
		rig.target_ring.visible = _targets.has(id) and rig.alive


# --- animation -------------------------------------------------------------------

func _start_anim(rig: Rig, kind: String, direction: Vector3) -> void:
	if rig == null:
		return
	rig.anim = kind
	rig.anim_t = 0.0
	rig.anim_dur = float(DURATIONS[kind])
	rig.anim_dir = direction
	if kind == "hurt":
		rig.flash = 1.0
	if kind == "guard":
		rig.shield.visible = true
	if kind == "die":
		rig.fallen = false
		rig.flash = 1.0


func _direction_to(actor: Rig, target: Rig) -> Vector3:
	if actor == null:
		return Vector3.ZERO
	if target != null:
		var delta := target.home - actor.home
		delta.y = 0.0
		if delta.length() > 0.01:
			return delta.normalized()
	return Vector3(1.0 if actor.side == "party" else -1.0, 0.0, 0.0)


func _animate_rig(rig: Rig, delta: float) -> void:
	var motion := 0.0 if reduced_motion else 1.0
	if rig.flash > 0.0:
		rig.flash = maxf(0.0, rig.flash - delta / 0.35)
		rig.material.albedo_color = rig.base_color.lerp(WHITE, rig.flash)
	if rig.anim == "":
		if rig.alive and not rig.fallen:
			var bob := 0.0 if reduced_motion or low_quality else sin(_time * 2.2 + rig.phase) * 0.04
			rig.body.position = Vector3(0.0, bob, 0.0)
		return
	rig.anim_t += delta
	var x := clampf(rig.anim_t / rig.anim_dur, 0.0, 1.0)
	var pulse := sin(PI * x)
	var knock := -1.0 if rig.side == "party" else 1.0
	var unit_scale := _unit_scale(rig)
	var body := rig.body
	match rig.anim:
		"strike":
			body.position = rig.anim_dir * 1.3 * pulse * motion
			body.scale = Vector3.ONE * unit_scale * (1.0 + 0.1 * pulse * motion)
		"skill":
			body.position = Vector3(0.0, 0.55 * pulse * motion, 0.0)
			body.rotation.y = TAU * x * 0.5 * motion
			body.scale = Vector3.ONE * unit_scale * (1.0 + 0.15 * pulse * motion)
		"focus":
			body.position = Vector3.ZERO
			body.scale = Vector3(1.0, 1.0 - 0.18 * pulse * motion, 1.0) * unit_scale
		"item":
			body.position = Vector3(0.0, 0.3 * pulse * motion, 0.0)
		"guard":
			body.position = Vector3.ZERO
			body.scale = Vector3(1.0 + 0.06 * pulse * motion, 1.0 - 0.14 * pulse * motion, 1.0) * unit_scale
		"hurt":
			body.position = Vector3(knock * 0.5 * pulse * motion, 0.0, 0.0)
		"heal":
			body.position = Vector3(0.0, 0.2 * pulse * motion, 0.0)
		"die":
			var fall := x if not reduced_motion else 1.0
			body.rotation.z = knock * -1.0 * (PI * 0.5) * fall
			body.position = Vector3(knock * 0.4 * fall, 0.25 * fall, 0.0)
	if x >= 1.0:
		rig.anim = ""
		rig.shield.visible = false
		if rig.anim == "" and not rig.alive:
			rig.fallen = true
		_pose(rig)


## Neutral pose; fallen units lie on their back.
func _pose(rig: Rig) -> void:
	rig.body.rotation = Vector3.ZERO
	rig.body.position = Vector3.ZERO
	rig.body.scale = Vector3.ONE * _unit_scale(rig)
	rig.shield.visible = false
	if rig.fallen or not rig.alive:
		var knock := -1.0 if rig.side == "party" else 1.0
		rig.body.rotation.z = knock * -1.0 * (PI * 0.5)
		rig.body.position = Vector3(knock * 0.4, 0.25, 0.0)
		rig.fallen = true
		rig.material.albedo_color = rig.base_color.darkened(0.45)
	else:
		rig.material.albedo_color = rig.base_color
	rig.ring.visible = rig.id == _current_actor and rig.alive
	rig.target_ring.visible = _targets.has(rig.id) and rig.alive


# --- effects and camera cues -------------------------------------------------------

func _spawn_effect(rig: Rig, kind: String, color: Color) -> void:
	if rig == null:
		return
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.7
	mesh.outer_radius = 0.85
	mesh.rings = 20
	mesh.ring_segments = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var node := _add_mesh(_effects_root, mesh, material, rig.home + Vector3(0.0, 0.1, 0.0))
	node.scale = Vector3(0.3, 0.1, 0.3)
	_effects.append({"node": node, "material": material, "kind": kind, "t": 0.0, "dur": 0.7, "base": rig.home})


func _advance_effects(delta: float) -> void:
	var motion := 0.0 if reduced_motion else 1.0
	for i in range(_effects.size() - 1, -1, -1):
		var effect: Dictionary = _effects[i]
		effect["t"] = float(effect["t"]) + delta
		var x := clampf(float(effect["t"]) / float(effect["dur"]), 0.0, 1.0)
		var node: MeshInstance3D = effect["node"]
		var material: StandardMaterial3D = effect["material"]
		var grow := lerpf(0.3, 2.0, x) if motion > 0.0 else 1.0
		node.scale = Vector3(grow, 0.1, grow)
		if str(effect["kind"]) == "rise":
			node.position = (effect["base"] as Vector3) + Vector3(0.0, 0.1 + 1.9 * x * motion, 0.0)
		material.albedo_color.a = 1.0 - x
		if x >= 1.0:
			_effects.remove_at(i)
			_free_node(node)


func _push_to(actor: Rig, target: Rig, peak: float) -> void:
	if reduced_motion or actor == null:
		return
	var other := target if target != null else actor
	_push_focus = (actor.home + other.home) * 0.5 + Vector3(0.0, 1.0, 0.0)
	_push_peak = peak
	_push_time = 0.0
	_push_len = 0.9


func _push_amount() -> float:
	if _push_peak <= 0.0 or _push_len <= 0.0:
		return 0.0
	var x := clampf(_push_time / _push_len, 0.0, 1.0)
	return _push_peak * sin(PI * x)


# --- scene construction ------------------------------------------------------------

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
	_root3d = Node3D.new()
	_root3d.name = "Arena"
	_viewport.add_child(_root3d)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d8d8e0")
	env.ambient_light_energy = 0.55
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_root3d.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.75
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-50.0, -25.0, 0.0)
	_root3d.add_child(sun)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = CAMERA_FOV
	camera.near = 0.3
	camera.far = 80.0
	camera.current = true
	_root3d.add_child(camera)
	_add_mesh(_root3d, _cylinder(9.0, 9.0, 0.2), _mat(FLOOR), Vector3(0.0, -0.1, 0.0))
	var edge := TorusMesh.new()
	edge.inner_radius = 8.9
	edge.outer_radius = 9.15
	edge.rings = 48
	edge.ring_segments = 4
	var edge_ring := _add_mesh(_root3d, edge, _mat(RED, true), Vector3(0.0, 0.02, 0.0))
	edge_ring.scale = Vector3(1.0, 0.2, 1.0)
	# A dark-red disc behind the arena stands in for a moon / sky glow.
	var moon := _add_mesh(_root3d, _cylinder(5.0, 5.0, 0.1), _mat(DARK_RED, true), Vector3(0.0, 5.0, -14.0))
	moon.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	# Center line between the two sides.
	_add_mesh(_root3d, _box(Vector3(0.06, 0.01, 14.0)), _mat(DARK_RED, true), Vector3(0.0, 0.015, 0.0))
	_decor_extra = Node3D.new()
	_decor_extra.name = "Decor"
	_root3d.add_child(_decor_extra)
	for i in 5:
		var angle := deg_to_rad(-70.0 + 35.0 * float(i))
		var pillar := _add_mesh(_decor_extra, _box(Vector3(0.7, 3.2 + float(i % 2), 0.7)), _mat(GRAY),
				Vector3(sin(angle) * 8.0, 1.4, -cos(angle) * 8.0))
		pillar.rotation.y = angle
		_add_mesh(_decor_extra, _box(Vector3(0.78, 0.12, 0.78)), _mat(RED, true),
				Vector3(sin(angle) * 8.0, 3.1 + float(i % 2), -cos(angle) * 8.0)).rotation.y = angle
	_decor_extra.add_child(_make_grid())
	_units_root = Node3D.new()
	_units_root.name = "Units"
	_root3d.add_child(_units_root)
	_effects_root = Node3D.new()
	_effects_root.name = "Effects"
	_root3d.add_child(_effects_root)


func _make_grid() -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_LINES)
	var v := -8.0
	while v <= 8.01:
		var reach := sqrt(maxf(0.0, 81.0 - v * v)) - 0.4
		surface.add_vertex(Vector3(v, 0.01, -reach))
		surface.add_vertex(Vector3(v, 0.01, reach))
		surface.add_vertex(Vector3(-reach, 0.01, v))
		surface.add_vertex(Vector3(reach, 0.01, v))
		v += 2.0
	var grid := MeshInstance3D.new()
	grid.name = "Grid"
	grid.mesh = surface.commit()
	grid.material_override = _mat(DARK_RED, true)
	return grid


# --- helpers -------------------------------------------------------------------------

func _free_node(node: Node) -> void:
	if node == null:
		return
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
		node.queue_free()
	else:
		var parent := node.get_parent()
		if parent != null:
			parent.remove_child(node)
		node.free()


func _mat(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), unshaded]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_cache[key] = material
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
	mesh.radial_segments = 20 if height < 0.3 else 12
	mesh.rings = 1
	return mesh


func _add_mesh(parent: Node, mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance

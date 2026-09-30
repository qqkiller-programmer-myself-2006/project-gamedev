class_name Room
extends RefCounted
## One room behind a Room code: five Player slots, a Host, and the current
## (or most recent) Match. Internal to the Match module; only MatchServer
## talks to it.

const SLOT_COUNT := 5

enum State { LOBBY, IN_MATCH, CLOSED }

var code: String
var story := false
var state: State = State.LOBBY
var host_slot := -1
## Each slot: {"session": int (0 = nobody), "name": String}
var slots: Array[Dictionary] = []
## The running Match, or the finished one whose summary is still shown.
var run: MatchRun = null
## Events waiting to be delivered to every member of the room.
var outbox: Array[Dictionary] = []

var _rng: GameRng
var _clock
var _content: ForestContent
var _profiles: ProfileStore
var _empty_since := -1.0
var _matches_started := 0


func _init(room_code: String, rng: GameRng, clock, content: ForestContent, profiles: ProfileStore = null) -> void:
	code = room_code
	_rng = rng
	_clock = clock
	_content = content
	_profiles = profiles if profiles != null else MemoryProfileStore.new()
	for i in SLOT_COUNT:
		slots.append({"session": 0, "name": "", "token": "", "profile": ProfileStore.normalize({}), "loadout": {}})


func human_count() -> int:
	var count := 0
	for slot in slots:
		if slot["session"] != 0:
			count += 1
	return count


func is_full() -> bool:
	return human_count() >= SLOT_COUNT


func slot_of(session_id: int) -> int:
	for i in SLOT_COUNT:
		if slots[i]["session"] == session_id:
			return i
	return -1


func sessions() -> Array[int]:
	var out: Array[int] = []
	for slot in slots:
		if slot["session"] != 0:
			out.append(slot["session"])
	return out


## Seats a new human in the lowest free slot. Caller checks is_full()/state.
func join(session_id: int, display_name: String) -> int:
	var index := -1
	for i in SLOT_COUNT:
		if slots[i]["session"] == 0:
			index = i
			break
	slots[index] = {"session": session_id, "name": display_name, "token": "", "profile": ProfileStore.normalize({}), "loadout": {}}
	_empty_since = -1.0
	_emit({"type": "player_joined", "slot": index, "name": display_name})
	if host_slot == -1:
		_set_host(index)
	return index


## The human in `session_id` leaves (by choice or because the connection
## dropped). Their slot becomes AI-controlled; the character keeps its state.
func leave(session_id: int, reason: String) -> void:
	var index := slot_of(session_id)
	if index == -1:
		return
	var old_name: String = slots[index]["name"]
	slots[index] = {"session": 0, "name": "", "token": "", "profile": ProfileStore.normalize({}), "loadout": {}}
	_emit({"type": "player_left", "slot": index, "name": old_name, "reason": reason})
	if run != null:
		run.set_human(index, false)
		if state == State.IN_MATCH:
			_drain_run()
	if host_slot == index:
		host_slot = -1
		for i in SLOT_COUNT:
			if slots[i]["session"] != 0:
				_set_host(i)
				break
	if human_count() == 0:
		_empty_since = _clock.now()


func start_match() -> void:
	var humans: Array[bool] = []
	for slot in slots:
		humans.append(slot["session"] != 0)
	_matches_started += 1
	state = State.IN_MATCH
	var loadouts: Array = []
	for slot in slots:
		loadouts.append(slot.get("loadout", {}).duplicate(true))
	for i in loadouts.size():
		loadouts[i] = {"loadout": loadouts[i], "profile": slots[i].get("profile", {}).duplicate(true)}
	if story:
		humans.fill(true)
		var p: Dictionary = slots[host_slot].get("profile", {})
		var ll: Dictionary = p.get("last_loadout", {})
		var c: String = loadouts[host_slot]["loadout"].get("class", "classless")
		var cmd := {"class": c, "race": ll.get("race", "Human"), "boons": ll.get("boons", [])}
		if _set_loadout(host_slot, cmd, p).get("ok", false):
			loadouts[host_slot]["loadout"] = slots[host_slot]["loadout"].duplicate()
		else:
			var fallback := {"class": c, "race": "Human", "boons": []}
			_set_loadout(host_slot, fallback, p)
			loadouts[host_slot]["loadout"] = slots[host_slot]["loadout"].duplicate()
	run = MatchRun.new(_rng.fork(), _clock, _content, humans, _matches_started, loadouts, story, host_slot)
	_drain_run()


func restore_story(data: Dictionary) -> bool:
	if not story or state != State.LOBBY or not MatchRun.valid_story_save(data, _content):
		return false
	start_match()
	run.restore_layer_start(data)
	_drain_run()
	return true


## Routes an in-Match command from the human in `slot`.
func handle_match_command(slot: int, cmd: Dictionary) -> Dictionary:
	var acting := slot
	var kind := str(cmd.get("type", ""))
	if not story and kind in ["equip", "unequip"] and cmd.has("slot") and int(cmd["slot"]) != slot:
		return {"ok": false, "error": "not_your_slot"}
	if story:
		if slot != host_slot:
			return {"ok": false, "error": "not_your_slot"}
		if kind == "action":
			var actor_id := ""
			if run.encounter is CombatEncounter:
				actor_id = str(run.encounter.actor)
			elif run.encounter is ClassEncounter and run.encounter.stage == "challenge":
				actor_id = str(run.encounter._trial.actor)
			if not actor_id.begins_with("p"):
				return {"ok": false, "error": "not_your_turn"}
			acting = int(actor_id.substr(1))
			if cmd.has("slot") and int(cmd["slot"]) != acting:
				return {"ok": false, "error": "not_your_slot"}
		elif kind in ["invest", "equip", "unequip", "transfer_item", "transfer_gold", "buy", "craft", "class_choice"]:
			acting = int(cmd.get("slot", slot))
			if acting < 0 or acting >= SLOT_COUNT:
				return {"ok": false, "error": "invalid_slot"}
	var routed := cmd.duplicate()
	if story and str(cmd.get("type", "")) == "action":
		routed["slot"] = acting
	var result := run.handle(acting, routed)
	_drain_run()
	return result

func set_profile(slot: int, profile: Dictionary, token: String) -> void:
	if slot < 0 or slot >= slots.size():
		return
	slots[slot]["profile"] = ProfileStore.normalize(profile)
	slots[slot]["token"] = token

func profile_of(slot: int) -> Dictionary:
	return slots[slot].get("profile", ProfileStore.normalize({})).duplicate(true)

func handle_setup_command(slot: int, cmd: Dictionary) -> Dictionary:
	if state != State.LOBBY:
		return {"ok": false, "error": "wrong_phase"}
	if slot < 0 or slots[slot]["session"] == 0:
		return {"ok": false, "error": "not_in_room"}
	var profile: Dictionary = slots[slot]["profile"]
	var kind := str(cmd.get("type", ""))
	match kind:
		"set_loadout":
			var target := int(cmd.get("slot", slot)) if story else slot
			if target < 0 or target >= SLOT_COUNT:
				return {"ok": false, "error": "invalid_slot"}
			var raw_boons = cmd.get("boons", [])
			if not (raw_boons is Array):
				return {"ok": false, "error": "invalid_loadout"}
			if story and target != host_slot and (str(cmd.get("race", "Human")) != "Human" or not raw_boons.is_empty()):
				return {"ok": false, "error": "invalid_loadout"}
			return _set_loadout(target, cmd, profile)
		"buy_race":
			return _buy_race(slot, str(cmd.get("race", "")), profile)
		"tree_upgrade":
			return _tree_upgrade(slot, str(cmd.get("class", "")), str(cmd.get("node", "")), profile)
		"buy_prestige":
			return _buy_prestige(slot, str(cmd.get("class", "")), profile)
		"reset_tree":
			return _reset_tree(slot, str(cmd.get("class", "")), profile)
	return {"ok": false, "error": "unknown_command"}

func _set_loadout(slot: int, cmd: Dictionary, profile: Dictionary) -> Dictionary:
	if not (cmd.get("class") is String) or not (cmd.get("race") is String) \
			or not (cmd.get("boons", []) is Array):
		return {"ok": false, "error": "invalid_loadout"}
	var class_id := str(cmd["class"])
	if class_id == "rogue":
		class_id = "assassin"
	var race := str(cmd["race"])
	var boons: Array = cmd["boons"]
	var classes := _content.get_dict("classes")
	var races := _content.get_dict("meta.races")
	var boon_defs := _content.get_dict("meta.boons")
	if class_id == "classless" or not classes.has(class_id) or not (classes[class_id] is Dictionary):
		return {"ok": false, "error": "invalid_loadout"}
	if not races.has(race) or not (races[race] is Dictionary):
		return {"ok": false, "error": "invalid_loadout"}
	if not profile.get("races_owned", []).has(race):
		return {"ok": false, "error": "race_not_owned"}
	if boons.size() > 5:
		return {"ok": false, "error": "over_capacity"}
	var used := 0
	var seen := {}
	for boon in boons:
		if not (boon is String) or seen.has(boon) or not boon_defs.has(boon) \
				or not (boon_defs[boon] is Dictionary):
			return {"ok": false, "error": "invalid_loadout"}
		seen[boon] = true
		var data: Dictionary = boon_defs[boon]
		used += int(data.get("slots", 0))
		if boon == "The Chosen One" and _prestige_total(profile) < 5:
			return {"ok": false, "error": "locked"}
	if used > 5:
		return {"ok": false, "error": "over_capacity"}
	slots[slot]["loadout"] = {"class": class_id, "race": race, "boons": boons.duplicate()}
	# In Story the player sets all five slots; only their own (host) slot is "their" loadout (review F4).
	if not story or slot == host_slot:
		profile["last_loadout"] = slots[slot]["loadout"].duplicate(true)
	_emit({"type": "loadout_changed", "slot": slot, "loadout": slots[slot]["loadout"]})
	return {"ok": true, "loadout": slots[slot]["loadout"]}

func _buy_race(slot: int, race: String, profile: Dictionary) -> Dictionary:
	var races := _content.get_dict("meta.races")
	if not races.has(race) or not (races[race] is Dictionary): return {"ok": false, "error": "invalid_race"}
	var data: Dictionary = races[race]
	if profile["races_owned"].has(race): return {"ok": false, "error": "already_owned"}
	var cost := int(data.get("cost", 0))
	if int(profile["gems"]) < cost: return {"ok": false, "error": "not_enough_gems"}
	profile["gems"] -= cost
	profile["races_owned"].append(race)
	return {"ok": true, "gems": profile["gems"], "race": race}

func _tree_upgrade(_slot: int, class_id: String, node: String, profile: Dictionary) -> Dictionary:
	var classes := _content.get_dict("classes")
	if not classes.has(class_id) or not (classes[class_id] is Dictionary) or class_id == "classless":
		return {"ok": false, "error": "invalid_class"}
	var tree: Dictionary = profile["class_trees"].get(class_id, {})
	var level := int(tree.get(node, 0))
	var nodes := _content.get_dict("meta.class_tree")
	if not nodes.has(node) or not (nodes[node] is Dictionary): return {"ok": false, "error": "invalid_node"}
	if level >= 5: return {"ok": false, "error": "max_level"}
	var cost := int(_content.get_value("meta.class_tree.%s.cost" % node, 10)) * (level + 1)
	if int(profile["gems"]) < cost: return {"ok": false, "error": "not_enough_gems"}
	profile["gems"] -= cost
	tree[node] = level + 1
	profile["class_trees"][class_id] = tree
	return {"ok": true, "gems": profile["gems"], "class": class_id, "node": node, "level": level + 1}

func _buy_prestige(_slot: int, class_id: String, profile: Dictionary) -> Dictionary:
	var classes := _content.get_dict("classes")
	if not classes.has(class_id) or not (classes[class_id] is Dictionary) or class_id == "classless":
		return {"ok": false, "error": "invalid_class"}
	var tree: Dictionary = profile["class_trees"].get(class_id, {})
	for node in _content.get_dict("meta.class_tree").keys():
		if int(tree.get(node, 0)) < 5: return {"ok": false, "error": "locked"}
	var current := int(profile["prestige"].get(class_id, 0))
	if current >= _content.get_int("meta.prestige.max", 25): return {"ok": false, "error": "max_prestige"}
	var cost := _content.get_int("meta.prestige.cost", 100)
	if int(profile["gems"]) < cost: return {"ok": false, "error": "not_enough_gems"}
	profile["gems"] -= cost
	profile["prestige"][class_id] = current + 1
	profile["class_trees"][class_id] = {}
	return {"ok": true, "gems": profile["gems"], "prestige": current + 1}

func _reset_tree(_slot: int, class_id: String, profile: Dictionary) -> Dictionary:
	var classes := _content.get_dict("classes")
	if not classes.has(class_id) or not (classes[class_id] is Dictionary) or class_id == "classless":
		return {"ok": false, "error": "invalid_class"}
	var tree: Dictionary = profile["class_trees"].get(class_id, {})
	var has_levels := false
	for value in tree.values():
		if int(value) > 0:
			has_levels = true
			break
	if not has_levels:
		return {"ok": false, "error": "nothing_to_reset"}
	var reset_cost := _content.get_int("meta.reset_cost", 50)
	if int(profile["gems"]) < reset_cost:
		return {"ok": false, "error": "not_enough_gems"}
	profile["gems"] -= reset_cost
	var refund := 0
	for node in tree:
		for level in range(1, int(tree[node]) + 1): refund += int(_content.get_value("meta.class_tree.%s.cost" % node, 10)) * level
	profile["gems"] += refund
	profile["class_trees"][class_id] = {}
	return {"ok": true, "gems": profile["gems"], "refunded": refund}


func _prestige_total(profile: Dictionary) -> int:
	var total := 0
	for value in profile.get("prestige", {}).values():
		total += int(value)
	return total


func update() -> void:
	if state == State.CLOSED:
		return
	if human_count() == 0 and _empty_since >= 0.0:
		var grace := _content.get_float("rules.empty_room_grace_seconds", 30.0)
		if _clock.now() - _empty_since >= grace:
			close()
			return
	if state == State.IN_MATCH and run != null:
		run.update()
		_drain_run()


func close() -> void:
	state = State.CLOSED
	_emit({"type": "room_closed"})


func snapshot_for(session_id: int) -> Dictionary:
	var you := slot_of(session_id)
	var slot_views: Array = []
	var members: Array = _content.get_array("party.members")
	for i in SLOT_COUNT:
		var human: bool = slots[i]["session"] != 0 or (story and human_count() > 0)
		var member: Dictionary = members[i] if i < members.size() else {}
		slot_views.append({
			"index": i,
			"character_name": str(member.get("name", "Hero %d" % (i + 1))),
			"controller": "human" if human else "ai",
			"owner_name": slots[host_slot]["name"] if story and host_slot >= 0 else slots[i]["name"],
			"is_host": i == host_slot,
			"is_you": i == you,
			"loadout": slots[i].get("loadout", {}).duplicate(true),
		})
	var view := {
		"code": code,
		"state": _state_name(),
		"host_slot": host_slot,
		"your_slot": you,
		"story": story,
		"slots": slot_views,
	}
	if you >= 0:
		view["profile"] = {"gems": slots[you]["profile"].get("gems", 0), "races_owned": slots[you]["profile"].get("races_owned", []).duplicate(), "class_trees": slots[you]["profile"].get("class_trees", {}).duplicate(true), "prestige": slots[you]["profile"].get("prestige", {}).duplicate(true), "last_loadout": slots[you]["profile"].get("last_loadout", {}).duplicate(true)}
	return view


func _set_host(index: int) -> void:
	host_slot = index
	_emit({"type": "host_changed", "slot": index, "name": slots[index]["name"]})


func _drain_run() -> void:
	if run == null:
		return
	for event in run.take_outbox():
		outbox.append(event)
	if state == State.IN_MATCH and run.is_over():
		_persist_match_rewards()
		state = State.LOBBY


func _persist_match_rewards() -> void:
	if run == null:
		return
	for i in slots.size():
		var token := str(slots[i].get("token", ""))
		var earned := int(run.gems_earned[i]) if i < run.gems_earned.size() else 0
		if token.is_empty() or earned <= 0:
			continue
		var profile: Dictionary = slots[i]["profile"]
		profile["gems"] = int(profile.get("gems", 0)) + earned
		slots[i]["profile"] = ProfileStore.normalize(profile)
		_profiles.save_profile_async(token, slots[i]["profile"])


func _emit(event: Dictionary) -> void:
	outbox.append(event)


func _state_name() -> String:
	match state:
		State.LOBBY:
			return "lobby"
		State.IN_MATCH:
			return "in_match"
		_:
			return "closed"

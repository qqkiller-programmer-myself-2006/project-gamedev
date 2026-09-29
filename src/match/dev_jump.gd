class_name DevJump
extends RefCounted
## DEV ONLY: the Playtest "jump straight to a scene" command (dev_jump).
## MatchServer only accepts it when allow_dev is set, which only the embedded
## Playtest server does. It reuses the normal rules: the Encounter comes from
## the same content pool and MatchRun code as a real route, the Party levels
## up through MatchRun.grant_exp, and everything draws from the Match's seeded
## GameRng, so the same seed and target give the same scene.

## target -> {"type": route option type, "layer": default Layer}. "boss" has no option.
const TARGETS := {
	"combat": {"type": "combat", "layer": 1},
	"merchant": {"type": "merchant", "layer": 2},
	"rest": {"type": "rest", "layer": 2},
	"class": {"type": "class", "layer": 2},
	"story": {"type": "story", "layer": 2},
	"treasure": {"type": "treasure", "layer": 2},
	"cave": {"type": "combat", "layer": 5},
	"boss": {"type": "boss", "layer": 5},
}
## Gold per Party member for each Layer already "travelled".
const GOLD_PER_LAYER := 30


## Jumps `run` to `target` on `layer` (0 = the target's usual Layer), optionally
## giving the human in `slot` `class_id`. Returns "" or an error code.
static func apply(run: MatchRun, slot: int, target: String, layer: int, class_id: String) -> String:
	if target != "journey" and not TARGETS.has(target):
		return "invalid_jump"
	if slot < 0 or slot >= run.party.size():
		return "invalid_slot"
	if not class_id.is_empty() and run.content.get_dict("classes.%s" % class_id).is_empty():
		return "invalid_class"
	if target == "journey":  # no jump: the normal Layer 1 vote, only the class is set
		if not class_id.is_empty() and run.party[slot]["class"] != class_id:
			run.change_class(slot, class_id)
		return ""
	var spec: Dictionary = TARGETS[target]
	var to_layer := layer if layer > 0 else int(spec["layer"])
	if target == "cave":
		to_layer = run.routes.size()  # the cave is the last Layer, whatever was asked
	if to_layer < 1 or to_layer > run.routes.size():
		return "invalid_jump"

	if not class_id.is_empty() and run.party[slot]["class"] != class_id:
		run.change_class(slot, class_id)
	var level := run.routes.size() + 1 if target == "boss" else to_layer
	_level_party_to(run, level)
	var passed := run.routes.size() if target == "boss" else to_layer - 1
	run.add_gold(run.party.size() * GOLD_PER_LAYER * passed)

	var option := {}
	if target != "boss":
		option = RouteGenerator.option_for(run.rng, run.content, str(spec["type"]), to_layer)
	run.dev_jump(to_layer, option)
	return ""


## The level a Party would normally have on arriving at a Layer: level = Layer.
static func _level_party_to(run: MatchRun, level: int) -> void:
	var thresholds := run.content.get_array("leveling.exp_to_next")
	for character in run.party:
		while int(character["level"]) < level and int(character["level"]) - 1 < thresholds.size():
			var need := int(thresholds[int(character["level"]) - 1]) - int(character["exp"])
			run.grant_exp(int(character["slot"]), maxi(need, 1))

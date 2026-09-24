class_name PathVote
extends RefCounted
## One round of Path Voting: every human-controlled slot has one vote, AI
## slots have none. The most votes wins; ties (and a round with no votes at
## all) are settled by the injected GameRng.

var layer: int
var options: Array
var deadline: float
## slot -> option index
var votes: Dictionary = {}


func _init(layer_number: int, route_options: Array, closes_at: float) -> void:
	layer = layer_number
	options = route_options
	deadline = closes_at


## Records a vote. Returns "" on success or an error code.
func cast(slot: int, option_index: int, is_human: bool) -> String:
	if not is_human:
		return "ai_cannot_vote"
	if votes.has(slot):
		return "already_voted"
	if option_index < 0 or option_index >= options.size():
		return "invalid_option"
	votes[slot] = option_index
	return ""


## Drops the vote of a slot that is no longer human-controlled.
func forget(slot: int) -> void:
	votes.erase(slot)


func everyone_voted(humans: Array[bool]) -> bool:
	var any_human := false
	for slot in humans.size():
		if humans[slot]:
			any_human = true
			if not votes.has(slot):
				return false
	return any_human


## Decides the route. Returns
## {"option": index, "tally": [count per option], "tie_broken": bool, "no_votes": bool}
func resolve(rng: GameRng) -> Dictionary:
	var tally: Array = []
	tally.resize(options.size())
	tally.fill(0)
	for slot in votes:
		tally[votes[slot]] += 1
	var best := 0
	for count in tally:
		best = maxi(best, count)
	var leaders: Array = []
	for i in tally.size():
		if tally[i] == best:
			leaders.append(i)
	return {
		"option": leaders[0] if leaders.size() == 1 else rng.pick(leaders),
		"tally": tally,
		"tie_broken": leaders.size() > 1 and best > 0,
		"no_votes": best == 0,
	}


func view() -> Dictionary:
	var voted: Array = votes.keys()
	voted.sort()
	return {
		"layer": layer,
		"options": _public_options(),
		"voted_slots": voted,
		"deadline": deadline,
	}


func _public_options() -> Array:
	var out: Array = []
	for i in options.size():
		var option: Dictionary = options[i]
		out.append({
			"index": i,
			"type": option["type"],
			"name": option["name"],
			"hint": option["hint"],
		})
	return out

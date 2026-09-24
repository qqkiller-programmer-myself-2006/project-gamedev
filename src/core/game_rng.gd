class_name GameRng
extends RefCounted
## The single injectable source of randomness for all game logic.
##
## Game logic must never call the engine's global random functions
## (randi(), randf(), randomize(), Array.shuffle(), Array.pick_random()...)
## directly. Everything that is random (Room codes, route generation, vote
## tie-breaks, damage variance, AI choices) goes through an instance of this
## class so a Match can be replayed exactly from its seed.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


## Integer in the inclusive range [from, to].
func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## Float in [0, 1).
func randf() -> float:
	return _rng.randf()


## Float in [from, to].
func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## True with probability `p` (0..1).
func chance(p: float) -> bool:
	if p <= 0.0:
		return false
	if p >= 1.0:
		return true
	return _rng.randf() < p


## One element of `items`, or null when it is empty.
func pick(items: Array) -> Variant:
	if items.is_empty():
		return null
	return items[_rng.randi_range(0, items.size() - 1)]


## Index chosen with probability proportional to `weights`.
## Returns -1 when every weight is zero or the array is empty.
func weighted_index(weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += maxf(0.0, float(w))
	if total <= 0.0:
		return -1
	var roll := _rng.randf() * total
	for i in weights.size():
		roll -= maxf(0.0, float(weights[i]))
		if roll < 0.0:
			return i
	return weights.size() - 1


## A shuffled copy of `items` (Fisher-Yates).
func shuffled(items: Array) -> Array:
	var out := items.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## A new independent generator whose seed is drawn from this one, so a
## sub-system (for example one room) can own its randomness while staying
## reproducible from the root seed.
func fork() -> GameRng:
	var hi := _rng.randi()
	var lo := _rng.randi()
	return GameRng.new((hi << 31) ^ lo)

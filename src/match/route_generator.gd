class_name RouteGenerator
extends RefCounted
## Builds the route options offered at every Layer of the Forest from the
## seed, under constraints that keep every Match completable:
##   - a Class Encounter option in at least one of the first
##     `class_by_layer` Layers
##   - a Merchant option in at least one Layer before the Guardian Boss

const TYPES: Array[String] = ["combat", "merchant", "rest", "treasure", "story", "class"]


## Returns one Array of options per Layer. Each option is
## {"type", "site", "name", "hint"} plus "class_id" for Class Encounters.
static func generate(rng: GameRng, content: ForestContent) -> Array:
	var layer_count := content.get_int("journey.layers", 5)
	var min_options := content.get_int("journey.options_min", 2)
	var max_options := content.get_int("journey.options_max", 3)
	var weights := content.get_dict("journey.type_weights")
	var layers: Array = []
	for layer in layer_count:
		var count := rng.randi_range(min_options, max_options)
		layers.append(_pick_types(rng, weights, count))

	var class_by := mini(content.get_int("journey.guarantees.class_by_layer", 2), layer_count)
	if class_by > 0 and not _offered(layers, "class", 0, class_by):
		_force(rng, layers, "class", rng.randi_range(0, class_by - 1))
	if content.get_value("journey.guarantees.merchant_before_boss", true) \
			and not _offered(layers, "merchant", 0, layer_count):
		var first := mini(1, layer_count - 1)
		_force(rng, layers, "merchant", rng.randi_range(first, layer_count - 1))

	var routes: Array = []
	for types in layers:
		var options: Array = []
		for type in types:
			options.append(_make_option(rng, content, type))
		routes.append(options)
	return routes


static func _pick_types(rng: GameRng, weights: Dictionary, count: int) -> Array:
	var pool: Array = []
	var pool_weights: Array = []
	for type in TYPES:
		if float(weights.get(type, 0)) > 0.0:
			pool.append(type)
			pool_weights.append(float(weights[type]))
	var picked: Array = []
	while picked.size() < count and not pool.is_empty():
		var i := rng.weighted_index(pool_weights)
		picked.append(pool[i])
		pool.remove_at(i)
		pool_weights.remove_at(i)
	return picked


static func _offered(layers: Array, type: String, from: int, to: int) -> bool:
	for i in range(from, to):
		if layers[i].has(type):
			return true
	return false


## Puts `type` into Layer `index`, replacing an option that is not itself a
## guaranteed type.
static func _force(rng: GameRng, layers: Array, type: String, index: int) -> void:
	var types: Array = layers[index]
	var replaceable: Array = []
	for i in types.size():
		if types[i] != "class" and types[i] != "merchant":
			replaceable.append(i)
	if replaceable.is_empty():
		types.append(type)
	else:
		types[rng.pick(replaceable)] = type


static func _make_option(rng: GameRng, content: ForestContent, type: String) -> Dictionary:
	var sites := content.get_array("journey.sites.%s" % type)
	var site: Dictionary = rng.pick(sites) if not sites.is_empty() else {"id": type, "name": type.capitalize()}
	var option := {
		"type": type,
		"site": str(site.get("id", type)),
		"name": str(site.get("name", type.capitalize())),
		"hint": str(site.get("hint", "")),
	}
	if type == "class":
		var offers: Dictionary = site.get("classes", {})
		var ids := offers.keys()
		var weights: Array = []
		for id in ids:
			weights.append(float(offers[id]))
		var index := rng.weighted_index(weights)
		option["class_id"] = str(ids[index]) if index >= 0 else "swordsman"
	return option

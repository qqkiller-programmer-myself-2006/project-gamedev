class_name EnemyGroups
extends RefCounted
## Picks the enemy group of a Combat Encounter from the content pool,
## filtered by Layer (and optionally by site), weighted and seeded.


static func pick(rng: GameRng, content: ForestContent, layer: int, site: String) -> Array:
	var candidates: Array = []
	var weights: Array = []
	for group in content.get_array("encounters.combat.groups"):
		var layers: Array = group.get("layers", [1, 99])
		if layer < int(layers[0]) or layer > int(layers[1]):
			continue
		var sites: Array = group.get("sites", [])
		if not sites.is_empty() and not sites.has(site):
			continue
		candidates.append(group)
		weights.append(float(group.get("weight", 1.0)))
	if candidates.is_empty():
		push_error("EnemyGroups: no combat group for layer %d site %s" % [layer, site])
		return []
	return candidates[rng.weighted_index(weights)]["enemies"]

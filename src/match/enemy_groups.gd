class_name EnemyGroups
extends RefCounted
## Picks the enemy group of a Combat Encounter from the content pool,
## filtered by Layer, weighted and seeded. Groups tied to specific sites (for
## example wolves on the Wolf Trail) take priority at those sites, so the
## route hint stays honest.


static func pick(rng: GameRng, content: ForestContent, layer: int, site: String) -> Array:
	var general: Array = []
	var local: Array = []
	for group in content.get_array("encounters.combat.groups"):
		var layers: Array = group.get("layers", [1, 99])
		if layer < int(layers[0]) or layer > int(layers[1]):
			continue
		var sites: Array = group.get("sites", [])
		if sites.is_empty():
			general.append(group)
		elif sites.has(site):
			local.append(group)
	var candidates: Array = local if not local.is_empty() else general
	var weights: Array = []
	for group in candidates:
		weights.append(float(group.get("weight", 1.0)))
	if candidates.is_empty():
		push_error("EnemyGroups: no combat group for layer %d site %s" % [layer, site])
		return []
	return candidates[rng.weighted_index(weights)]["enemies"]

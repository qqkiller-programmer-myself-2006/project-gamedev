class_name Encounter
extends RefCounted
## Base class for one Encounter on the journey (Combat, Merchant, Rest,
## Treasure, Story Event, Class Encounter, Guardian Boss). MatchRun owns the
## current Encounter and passes itself into every call, so an Encounter never
## keeps a reference back to the run.

## The route option that led here: {"type", "site", "name", "hint", ...}
var option: Dictionary
var done := false


func _init(route_option: Dictionary) -> void:
	option = route_option


func start(_run: MatchRun) -> void:
	pass


## An in-Match command from the human in `slot`. Rejections must not change
## state.
func handle(_run: MatchRun, _slot: int, _cmd: Dictionary) -> Dictionary:
	return {"ok": false, "error": "wrong_phase"}


func update(_run: MatchRun) -> void:
	pass


## A slot switched between human and AI control while this Encounter runs.
func on_control_changed(_run: MatchRun, _slot: int) -> void:
	pass


## What clients see about this Encounter.
func view(_run: MatchRun, _viewer_slot: int) -> Dictionary:
	return {}

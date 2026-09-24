class_name PlaceholderEncounter
extends Encounter
## Stand-in for Encounter types that are not implemented yet: it completes
## as soon as it starts.


func start(_run: MatchRun) -> void:
	done = true

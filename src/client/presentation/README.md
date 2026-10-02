# Battle presentation adapter

`BattlePresentation` is a static, pure adapter (`RefCounted`, with no `Node` or scene-tree access) for converting a match view and event into renderer-facing data. It does not mutate its inputs.

## State

`BattlePresentation.state(view: Dictionary) -> Dictionary` returns:

- `units`: party entries from `view.party`, followed by enemy entries from `view.encounter.enemies`. Each unit contains `id`, `side` (`party` or `enemy`), `slot`, `class_key`, `name`, `hp`, `max_hp`, `energy`, and `alive`.
- `current_actor`: the combat actor id from `view.encounter.actor`.
- `mode`: optional client UI context from `view.mode` or `view.encounter.mode`; defaults to an empty string because menu mode is not part of the server snapshot.
- `targets`: explicit `view.targets` when supplied, otherwise the targets for `mode` from the encounter choices (`attack`, `skill:<skill_id>`, or `item:<item_id>`). Defaults to an empty array.

Party `slot` comes from the party view; enemy `slot` comes from its view or its position in `enemies`. Party `class_key` uses `class`; enemy `class_key` uses `kind`. `alive` is derived from `hp > 0`, preserving fallen units in the list.

## Cues

`BattlePresentation.cues(event: Dictionary) -> Array[Dictionary]` accepts `action_resolved` events. It emits an action cue (`attack` → `strike`, `skill`/`special` → `skill`, `focus` → `focus`, `item` → `item`, `defend` → `guard`) followed by result cues (`damage` → `hurt` or `die` when `down`, `heal`/`revived` → `heal`). Every cue has `type`, `actor`, `target`, `skill_id`, `amount`, and `crit`; unused values are empty/zero/false. Unknown event/action types return an empty array.

The game’s system action names stay unchanged: `attack` is presented as `strike`, and `defend` as `guard`.

## Launch option

`LaunchOptions.use_3d(options: Dictionary) -> bool` checks the parsed `3d` flag. Without `--3d`, it returns false, keeping the existing 2D path as the default.

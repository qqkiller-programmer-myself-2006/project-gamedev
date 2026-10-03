# T3D-08 — Cutscene router + `.ogv` player

- **Task ID:** T3D-08
- **Owner:** Agy 2 (`ai/3d-agy2`, worktree `Project-GameDev-Agents/Agy2`)
- **Dependencies:** none (placeholder clips already in `assets/video/placeholder_*.ogv`). Fast-forward from `claude/game-project-lead-9a9ecc` first.
- **Read first:** `AGENTS.md`, `CONTEXT.md` (Cutscene ≠ Story Event), `docs/adr/0015-3d-presentation-offline-story-slice.md`, `docs/art/prompt-pack.md` (clip list OP-1..E3-2), `src/client/story/story_director.gd`, `assets/MANIFEST.3d.json`, `tools/video/convert_to_ogv.ps1`

## Goal
Play branching short video cutscenes in Story mode. A cutscene is a graph of short clips; it reports only flags back to `StoryDirector` and never changes match rules.

## Scope
1. **Data:** `content/cutscenes/<id>.json`:
   ```json
   {"id": "op", "start": "op_1", "nodes": {
     "op_1": {"clip": "res://assets/video/placeholder_red.ogv", "subtitles": [{"t": 0.0, "text": "..."}], "next": "op_2"},
     "op_2": {"clip": "...", "choices": [{"label": "...", "next": "op_3a", "flag": "x"}]}
   }}
   ```
   `next` or `choices` (not both); a node with neither ends the cutscene. Optional `variants` keyed by flag/route to pick a different clip. Write a loader with validation (missing clip, unknown node, cycles allowed only through choices) and a sample `content/cutscenes/sample.json` using the 3 placeholder clips.
2. **Player** `src/client/cutscene/cutscene_player.gd` (Control, built in code like the rest of the UI): `VideoStreamPlayer` with Theora, Thai subtitles drawn from the node data at the right time, choice buttons at the end of a choice node, **Skip** (skips the current clip; holding/second press skips the whole cutscene to its end node while still applying default flags), keyboard Enter/Space = next/confirm, Esc = skip, arrow keys for choices. Text scale 1.4 must not clip Thai text. Emits `finished(flags: Dictionary)`.
3. **Router** `src/client/cutscene/cutscene_router.gd`: walks the graph, applies `variants`, collects flags. Pure logic, testable headless without video.
4. **StoryDirector hook:** add one presentation entry type `cutscene` (`{"type": "cutscene", "id": "op"}`) that plays the cutscene and continues the queue on `finished`. Keep the change minimal — Claude 1 is editing story content and triggers at the same time.
5. **Missing/failed video:** if a clip fails to load or the platform cannot play it, show the subtitles on a black card for the clip duration (or 3 s) so the story never blocks.
6. **i18n:** UI strings (Skip, etc.) via `Tr.t` with Thai in `i18n/th.po`. Subtitle text in cutscene JSON is Thai directly (ADR-0016).
7. **Tests** (`tests/client/cutscene/`): loader validation errors, router linear path, choice path + flags, variants by flag, skip-all applies defaults, StoryDirector plays a `cutscene` entry and continues, missing clip falls back to the subtitle card.

## Allowed paths
`src/client/cutscene/**`, `content/cutscenes/**`, `tests/client/cutscene/**`, `src/client/story/story_director.gd` (the `cutscene` entry type only), `i18n/**`, `tools/dev/ui_preview.gd` (add a cutscene preview mode)

## Forbidden paths
`src/match/**`, `src/net/**`, `src/server/**`, `content/forest.json`, `content/story_mode.json`, `src/client/match/**`, `assets/**` (use existing placeholders)

## Acceptance criteria
1. Tests in scope 7 pass; `GODOT=D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` green, count not reduced.
2. Sample cutscene plays in a real window (`ui_preview` mode) with subtitles, a choice and Skip — attach 2 screenshots at 1280×720 (one with subtitles, one with choices) at text scale 1.4.
3. test_thai_catalog passes.

## Handoff
`.ai/handoff/T3D-08.md`: branch + sha, files, test result, screenshot paths, notes on Web playback if checked, open questions. Commit on `ai/3d-agy2`, never push.

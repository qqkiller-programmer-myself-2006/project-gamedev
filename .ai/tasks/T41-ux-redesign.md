# T41 — Redesign the in-match UI/UX (path vote screen + battle screen) — production in ~4 h

The owner says the UI/UX is bad. Two reference screenshots are attached (-i): (1) the "Layer 4 of 5: choose the next path" screen,
(2) the battle screen (Forest 4/5, Wolf Trail). Read `AGENTS.md`, `docs/design/ui-style.md` (Navy + Gold tokens), `docs/accessibility.md`,
`src/client/ui/ui_kit.gd`, `src/client/match/match_screen.gd`, `src/client/match/battle/battle_view.gd`, `combat_panel.gd`,
`battle_token.gd`. Keep the AAC reference look (`docs/references/aac_rogue/`) — fix the problems, do not restyle from scratch.

## Problems seen in the screenshots (fix all)
1. Right edge is clipped on both screens: header row overflows ("D…" cut at the right, "Forest (4/5)" runs off), the path card
   and the "Vote for this path" button run past the panel. Nothing may ever overflow or clip at 1280x720, 1600x900 or
   1920x1080, with text scale 1.0, 1.2 and 1.4. Use containers/anchors/wrapping, never fixed widths.
2. Header is a crowded single row (progress chips, layer text, gold, Clues, Settings, Leave). Group it: left = region + layer
   progress, centre = status, right = Gold + Clues + menu buttons; collapse low-priority items before they overflow.
3. Mixed fonts/sizes: pixel font for a few labels (Forest, Carved Stone, Leave) beside a sans font elsewhere; headings far too
   large ("Turn 1", "Layer 4 of 5…"). Define one clear type scale (title / heading / body / caption) in `UiKit` and use pixel font
   only for short titles; body and digits stay in the readable font.
4. Battle: the turn-order list on the left overlaps/clips its own rows (names collide with HP numbers, text sits on the bars),
   the "attacks: Bram takes 6…" log is cut off at the bottom-left, the bottom action bar is cut off at the bottom of the screen,
   and nameplates under tokens are too small/low contrast against the backdrop. Rebuild the layout so: turn order = compact rows
   (portrait/name/HP bar, current actor highlighted in gold); combat log = readable multi-line panel with scroll, always fully on
   screen; action bar = always fully visible with big, clearly labelled buttons (Fight / Skills / Items / Defend / Flee) and
   keyboard hints; enemies and allies clearly separated, current actor and targetable enemies obviously highlighted.
5. Vote screen: make the recommended path obvious, show the vote count and the countdown clearly, make the primary action one
   obvious button, and keep long descriptions inside the card (wrap).
6. Keep every existing function, keyboard shortcut, accessibility setting (text scale, reduced motion) and the new SkillFx.

## Process
- Reproduce first with `tools/dev/ui_preview.gd` (`"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ui --seed=11 --speed=10 --class=mage`,
  and `--scale=1.4`; see `docs/design/ui-style.md` / README for options) at 1920x1080 and 1280x720; save before/after PNGs under
  `build/ux/` (not committed) and LOOK at them yourself. Iterate until nothing clips or overlaps in any combination.
- Change only `src/client/**` (UiKit tokens/variations preferred over per-screen overrides) and tests/docs. No server/content edits.
- Update `docs/design/ui-style.md` with the type scale and the new battle/header layout rules.
- Add/extend tests under `tests/client/` for the new layout invariants (e.g. no child exceeds its parent rect at 1280x720 and
  1920x1080, scale 1.4).
- Commit in small steps `feat(ui): ...`, explicit `git add <paths>`, each ending with
  `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Do not push.
- ONE Godot process at a time. Run the full suite at the end only if `tasklist | grep -i godot` shows no other Godot.
  `GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe`.
- Report in English: what changed per problem 1-6, before/after screenshot paths, test summary line, commit hashes, open issues.

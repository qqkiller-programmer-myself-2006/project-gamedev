# T9b — Use the owner's class sprites in battle (and portraits in UI)

The owner supplied pixel-art sheets for Archer, Mage (female) and Swordsman. They are sliced into transparent frames under
`assets/characters/<class>/` with `assets/characters/manifest.json` (per class: frame lists per animation, canvas size,
baseline, fps). Read the manifest and look at each `_contact.png` first.

## Files you may change

`src/client/battle/battle_token.gd`, new files under `src/client/battle/` (e.g. a small `SpriteSet` loader),
`project.godot` only for texture filter import defaults if needed, `tools/ui_preview.gd` (screenshots).
Do NOT touch `src/match/**`, `content/**`, `tests/**` (except a UI-only test), or the layout constants in `battle_view.gd`
(fixed slots from `.ai/tasks/T1-r3-combat-layout.md` must keep working).

## What to build

1. For a party unit whose Class has a sprite set (`archer`, `mage`, `swordsman`), `BattleToken` draws the sprite instead of the
   code-drawn blocky figure. Party faces right (`*_right` frames); if a set had only left frames, mirror them.
   Classes without art (Classless, Rogue, Guardian) and all enemies keep the current code-drawn figures.
2. Animations, driven only by snapshot/events the view already receives (ADR-0001 — the client decides nothing):
   idle loop (idle frame + a gentle 2 px bob at ~1 Hz, disabled by Reduced motion), attack (play `attack_right_*` once when
   this unit's `action_resolved` arrives, then back to idle), hurt (play `hurt_*` once when it takes damage), dead
   (play `dead_*` once when it goes down and hold the last frame; revive → idle).
3. Scale with nearest-neighbour filtering so pixels stay crisp; the sprite's feet sit on the slot baseline and its height
   matches the ~110 px figure height of the fixed layout (keep nameplates exactly where they are).
4. Each party member still needs to be distinguishable when two share a class: keep the existing per-member palette as a thin
   coloured ground ring / name colour, not by recolouring the art.
5. Portrait: expose `portrait.png` per class for other screens (e.g. a helper `SpriteSet.portrait(class_id)`), used later by the
   Class setup screen (#53).

## Verify

- `bash scripts/run_tests.sh` → 0 failed.
- Screenshots with `tools/ui_preview.gd` for `--class=archer`, `--class=mage`, `--class=swordsman` (seed 11 and 3, scale 1.0 and
  1.4): idle, an attack frame, hurt, and a downed unit if the run reaches one. Look at them: crisp pixels, feet on the baseline,
  nothing covering nameplates, no black halo around sprites.

Report in English: files changed, items 1–5 done/partial, test summary line, screenshot paths.

## Also fix these combat leftovers from #48 QA (same files)

6. Skill/Fight cards cut their text ("Cost: 0 | Cooldo…"): widen the grid or use a smaller font for the cost line so the full
   "Cost: x | Cooldown: y" fits at scale 1.0 and 1.4.
7. The big green "Victory!" text overlaps a nameplate: place it in the top-centre area, clear of every nameplate.
8. Reward text bottom-left ("+18 Gold", "30 EXP", clue) overlaps the combat log: move the log up or the rewards above it so
   they never overlap.
9. Long enemy names are truncated in the nameplate ("Elder Thornwarde…"): allow the boss plate to be wider or shrink the font.
10. Focus must be enabled when `choices.focus` is true (the server supports it now) and enemies must show their blue Energy bar
    (`enemies[].energy` exists now). Check both in screenshots.

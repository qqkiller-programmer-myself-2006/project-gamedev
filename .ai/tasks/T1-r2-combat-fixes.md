# T1 round 2 — combat screen QA fixes

Continue the combat screen work already on this branch (`src/client/battle/battle_view.gd`, `battle_token.gd`).
Same rules and file limits as `.ai/tasks/T1-combat-ui.md` (read it again). QA compared your screenshots
(`build/ui_t1_final2/04_combat_turn.png`, `04_combat_skills.png`) with the references and found these defects.
Fix every one, then re-capture and compare again.

1. **Characters look identical and tiny.** Every party member is the same colour and shape (all purple as Rogue, all beige
   as Classless). Give each of Arin, Bram, Cora, Dain, Wren a distinct outfit palette (shirt/pants/hair colours) that does
   not depend on class; class only changes the held weapon/prop. Make figures about 1.6× bigger (reference figures are
   roughly 1/6 of screen height) with a head, hair block, torso, two arms, two legs, and simple light/dark shading per face.
2. **Enemies are all humanoids.** Draw by enemy id: `grey_wolf` = grey four-legged wolf (body box, head box with snout,
   ears, four legs, tail); `thornback_boar` = brown quadruped with tusks and spiky back; `forest_wisp` = floating glowing
   cyan orb with a soft halo; `bramble_archer` = green humanoid with a bow; bee/spider/rat if present in content; bandits and
   outlaws = dark humanoids with masks; the Guardian Boss about 2× size. Check `content/forest.json` `enemies` for every id
   and give each a recognisable silhouette.
3. **Initiative list text overlaps.** In each entry the "hp/max" and "e/max" texts are drawn on top of each other and
   over the name. Layout per entry, top to bottom: name line; red HP bar (~8 px) with its text centred inside; blue Energy
   bar (~8 px) with its text centred inside. Use a small font (≈9–10 px at scale 1) so text fits inside the bars. No overlap.
4. **"Your turn!" covers the battlefield and nameplates.** The big grey stripe is only for action names (Skill/Item/boss
   move) and must sit in the lower third *below every nameplate* and above the HUD, tilted about −1° (ref 06).
   "Your turn!" becomes a small short-lived label just above the HUD (or top centre), never covering units.
   Also: the Fight grid must be visible in `04_combat_skills.png` — the turn notice must not hide it.
5. **Energy bar** in the HUD must be one continuous blue bar with "e/max" centred (ref 04), not 6 segments.
   Remove the extra thin coloured bar above the HP bar (the timer is the seconds text).
6. **Gold icon** is a diamond; make it a yellow coin/pouch icon like the reference.
7. **Toasts** ("Bob joined the room.") appear over the HUD buttons — move toasts to the top centre on the combat screen.
8. **Unit placement**: spread units over the field like ref 04 (party in a loose cluster on the left 45%, enemies on the
   right 45%, some front/back depth); keep every nameplate fully visible and not overlapping another nameplate or the HUD,
   the Fight grid, or the initiative list.
9. Capture a screenshot where the **Fight grid is open**, one with the **action banner** showing, and one **after a win
   with the reward text** (extend `tools/ui_preview.gd` if needed — you may edit that file) and compare with refs 05, 06, 11.

Verify: `bash scripts/run_tests.sh` → 0 failed; screenshots at scale 1.0 and `--scale=1.4` (seed 11 and seed 3).
Report in English: each item 1–9 done/partial, test result line, screenshot paths.

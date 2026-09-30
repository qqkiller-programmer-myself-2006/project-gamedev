# T13 — Final UI polish pass (collected QA leftovers)

Fix every item; all are small. Same rules as earlier UI tasks (client only; text in `ui_text.gd`; ONE Godot process at a time).
Compare against `docs/references/aac_rogue/` and capture screenshots at 1280×720, 1920×1080 and `--scale=1.4`.

## Home page (#57) — `src/client/screens/title_screen.gd`, `src/client/home/`
1. At 1.0× the Swordsman sprite is hidden behind the menu panel: place all three class sprites standing on the ground around
   the campfire (bottom-centre/right), feet on the ground line, none behind the menu.
2. Campfire: replace the flat triangle with a small pixel-art campfire (logs + layered flickering flames + sparks) and a warm
   orange additive glow (not a dark disk). Moon glow also must not be a dark disk.
3. Remove the horizontal stripe/banding lines across the sky (use a smooth gradient).
4. Menu panel uses the navy style (#1c2233, light grey 2 px border, corner diamonds), not green.
5. Build/version text bottom-right is clipped: fit it inside the screen.
6. The Seed field belongs in a small Playtest options popup (gear button next to Playtest), not in the main menu; the Playtest
   button gets a distinct orange border + small "DEV" tag.
7. **Bug**: the embedded Playtest server does not fall back when port 8911 is busy (log: "cannot listen on port 8911 (error 22)").
   Try 8911..8920 and use the first free one; show an error in the panel if none — never quit the app.
   Also stop and free the embedded server whenever the player returns to the home page (owner hit this: second Playtest
   after returning home failed with "cannot listen on port 8911" and the game exited with code 1).

## Character setup (#53) — `src/client/setup/`
8. Boons: the left detail panel stays empty for the selected/hovered Boon — show name, slot cost, effect text, lock reason.
9. Button and list text is much smaller than the reference's large pixel font (Races list "Elf", "Kobold"…, Boon names): enlarge.
10. "Class", "Races", "Description", "Skill Tree" title boxes float above/below their panels as separate boxes like refs 01–02.

## Battle (#56) — `src/client/battle/`
11. Sprite attack frames render smaller than idle frames: compute the sprite scale from the idle frame height once per class and
    use it for every animation (attack canvases are wider because of effects — keep the same scale, don't fit-to-box).
12. The action banner covers the HUD header row; when the banner shows, the HUD must be collapsed below it (or the banner moves up).
13. At 1.4× the enemy nameplate numbers overlap ("109/120" into "0/4"): shrink the numbers or widen the plate.

Verify: `bash scripts/run_tests.sh` → 0 failed; screenshots of home (3 sizes), setup tabs, and a battle with an attack frame.
Report in English: items 1–13 done/partial, test line, screenshot paths.

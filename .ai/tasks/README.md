These are historical executor task specs retained for reference.
`T-number` identifies ticket order; lettered tasks are subtasks within that sequence.
`-rN` marks a retry or fix round for the corresponding task.

## Combat/Battle UI
- [T1-combat-ui.md](T1-combat-ui.md) — Match the combat screen to the AAC reference.
- [T1-r2-combat-fixes.md](T1-r2-combat-fixes.md) — Fix combat screen issues found in QA.
- [T1-r3-combat-layout.md](T1-r3-combat-layout.md) — Set fixed combat layout positions and prevent overlaps.
- [T31-battle-input-and-turn-feedback.md](T31-battle-input-and-turn-feedback.md) — Improve battle input and turn feedback.
- [T32-redesign-combat-merchant.md](T32-redesign-combat-merchant.md) — Redesign Combat and Merchant screens to match new mockups.
- [T35-turn-list-and-tip-placement.md](T35-turn-list-and-tip-placement.md) — Keep the current actor visible and prevent tips covering content.
- [T36a-battle-followup.md](T36a-battle-followup.md) — Apply follow-up fixes to the T30 battle polish.
- [T41-smooth-battle.md](T41-smooth-battle.md) — Smooth battle rendering and resolve the listed battle issues.
- [T41-ux-redesign.md](T41-ux-redesign.md) — Redesign the in-match Path Vote and battle experience.
- [T-ui-battle-camp-gamefeel.md](T-ui-battle-camp-gamefeel.md) — Improve Battle and Camp HUD feel and proportions.

## Camp/Merchant UI
- [T3-camp-ui.md](T3-camp-ui.md) — Match Merchant and Rest camp screens to the AAC reference.
- [T3-r2-camp-fixes.md](T3-r2-camp-fixes.md) — Fix Camp screen issues found in QA.
- [T3-r3-camp-fixes.md](T3-r3-camp-fixes.md) — Complete the next round of Camp QA fixes.
- [T23-camp-interaction.md](T23-camp-interaction.md) — Fix Camp interaction bugs and the Assassin badge.
- [T34-camp-update-in-place.md](T34-camp-update-in-place.md) — Update Camp in place and preserve search focus.

## Story mode
- [T11a-story-content-and-ui.md](T11a-story-content-and-ui.md) — Add Story script, dialogue UI, offline launcher, and save file.
- [T11b-story-wiring.md](T11b-story-wiring.md) — Wire Story rooms, save/restore, and home page flow.
- [T24-story-pacing.md](T24-story-pacing.md) — Improve Story pacing and control.
- [T33-story-mode-single-player-ui.md](T33-story-mode-single-player-ui.md) — Present Story mode as single-player and show the prologue first.

## Setup/Lobby/Title
- [T6-setup-screens-ui.md](T6-setup-screens-ui.md) — Bring character setup screens in line with the AAC reference.
- [T10a-home-page-playtest.md](T10a-home-page-playtest.md) — Create a new home page and one-click Playtest bypass.
- [T27-playtest-jump.md](T27-playtest-jump.md) — Let development Playtest jump directly to a scene.
- [T33-title-menu.md](T33-title-menu.md) — Remove the DEV button and center the title menu.
- [T36b-title-scale.md](T36b-title-scale.md) — Make the title menu work at 1.4 text scale.

## Server/Rules/Balance
- [T2-attributes-focus-server.md](T2-attributes-focus-server.md) — Add server attributes, derived stats, and the Focus command.
- [T4-enemy-energy-gold-server.md](T4-enemy-energy-gold-server.md) — Add enemy Energy, personal Gold, transfers, and consumable slot rules.
- [T5-loadout-server.md](T5-loadout-server.md) — Implement server loadouts, skill tree, Prestige, and Gems.
- [T5-r2-finish-loadout.md](T5-r2-finish-loadout.md) — Finish server loadout and meta progression work.
- [T8-profile-worker.md](T8-profile-worker.md) — Build a Cloudflare Worker and D1 storage for player profiles.
- [T12-balance-loadout.md](T12-balance-loadout.md) — Tune content balance for loadout mode win rates.
- [T14-p0-stash-and-story-trust.md](T14-p0-stash-and-story-trust.md) — Fix consumable transfers and secure the Story save boundary.
- [T15-p0-d1-profile-sender.md](T15-p0-d1-profile-sender.md) — Make profile storage persist through the D1 sender.
- [T20b-forest-renames-cave-layer.md](T20b-forest-renames-cave-layer.md) — Rename Forest enemies and turn Layer 5 into a cave.
- [T21-effects-apply.md](T21-effects-apply.md) — Apply Attribute, Boon, and Race effects in gameplay.
- [T26-server-tidy-save-trust.md](T26-server-tidy-save-trust.md) — Tidy server rules, backfill tests, and finish Story save trust fixes.
- [T28-reliability-41-43.md](T28-reliability-41-43.md) — Handle unknown encounters, clean up statuses, and fix Ready check.
- [T30-match-rule-fixes.md](T30-match-rule-fixes.md) — Fix match rules identified by the full QA report.
- [T4-r2-fix-failing-tests.md](T4-r2-fix-failing-tests.md) — Make the test suite pass without masking failures.
- [T76-p2-followups.md](T76-p2-followups.md) — Address P2 follow-ups for profiles, Story profiles, and export filters.

## Art/Sprites/Icons/FX
- [T16-icons-phase1.md](T16-icons-phase1.md) — Create the first phase of the pixel icon set.
- [T16-r2-icons-fix.md](T16-r2-icons-fix.md) — Improve quality of the pixel icon set.
- [T18-enemy-art-slice.md](T18-enemy-art-slice.md) — Slice enemy sheets and backgrounds.
- [T19-heroes-v2-assassin.md](T19-heroes-v2-assassin.md) — Create updated hero art and rename Rogue to Assassin.
- [T20a-enemy-sprites-backdrops.md](T20a-enemy-sprites-backdrops.md) — Add enemy sprites and painted battle backgrounds.
- [T25-icons-phase2.md](T25-icons-phase2.md) — Add icons across all screens in phase two.
- [T32-remaining-art.md](T32-remaining-art.md) — Integrate four owner-supplied sprite sheets.
- [T40-skill-fx.md](T40-skill-fx.md) — Create skill effect art and wire it into battle.
- [T40-r2-fx-fixes.md](T40-r2-fx-fixes.md) — Fix skill effect art while retaining the current implementation.
- [T9a-slice-character-sheets.md](T9a-slice-character-sheets.md) — Slice class character sheets into transparent sprite frames.
- [T9a-r2-slice-fix.md](T9a-r2-slice-fix.md) — Correctly slice character sheets using Python and Pillow.
- [T9a-r3-attack-frames.md](T9a-r3-attack-frames.md) — Separate merged character attack frames.
- [T9a-r4-attack-right.md](T9a-r4-attack-right.md) — Ensure each class has four Attack Right frames.
- [T9b-sprites-in-battle.md](T9b-sprites-in-battle.md) — Use class sprites in battle and portraits in the UI.

## Audio
- [audio-sourcing.md](audio-sourcing.md) — Research production-quality music and sound effects for the game.
- [audio-integrate.md](audio-integrate.md) — Download approved audio and connect it to SoundBank.
- [audio-critical-sfx.md](audio-critical-sfx.md) — Source and wire a critical-hit sound effect.
- [audio-magic-sfx.md](audio-magic-sfx.md) — Source and wire magic sound effects into SoundBank.
- [audio-fix-defeat.md](audio-fix-defeat.md) — Stop defeat music from replaying after its one-shot ends.

## Polish/UX/Responsive/A11y
- [T13-ui-polish.md](T13-ui-polish.md) — Fix the collected final UI polish issues.
- [T29-qa-polish.md](T29-qa-polish.md) — Address polish issues from the large-screen and large-text QA pass.
- [T30-ui-polish.md](T30-ui-polish.md) — Complete the UI polish items for issue #87.
- [T31-p2-followups.md](T31-p2-followups.md) — Address the P2 follow-up items for issue #76.
- [T32-readable-digits-and-ligatures.md](T32-readable-digits-and-ligatures.md) — Improve digit readability and prevent broken ligatures.
- [T34-path-vote-redesign.md](T34-path-vote-redesign.md) — Redesign the Path Voting screen.
- [T41-r2-ux-fixes.md](T41-r2-ux-fixes.md) — Apply UI fixes found in reviewer QA.
- [T42-vote-summary-fit.md](T42-vote-summary-fit.md) — Fix Path Vote overflow and Summary banner overlap at large text scale.
- [T42b-vote-horizontal.md](T42b-vote-horizontal.md) — Fix Path Vote overflowing to the right at text scale 1.4.
- [T44-battle-scale14.md](T44-battle-scale14.md) — Fix three Battle layout bugs at text scale 1.4.
- [T44-r2-finish.md](T44-r2-finish.md) — Finish the T44 scale-1.4 fixes after an interrupted run.
- [T44-a11y-baseline.md](T44-a11y-baseline.md) — Complete the keyboard and accessibility baseline.
- [T45-responsive.md](T45-responsive.md) — Verify responsive layouts for Battle, Merchant, and Rest.
- [T87-visual-polish.md](T87-visual-polish.md) — Complete remaining visual polish found on main.

## Reliability/Tests/Restructure
- [T17-restructure.md](T17-restructure.md) — Restructure project folders and files.
- [T22-connection-and-hints.md](T22-connection-and-hints.md) — Fix connection lifecycle and tutorial hints.
- [T41-r3-tests.md](T41-r3-tests.md) — Finish T41 by making the suite pass.

## Other


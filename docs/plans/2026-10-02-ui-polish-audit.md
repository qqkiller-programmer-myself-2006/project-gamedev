# UI polish restore audit (2026-10-02)

This audit records the state of the current branch before this restore. The earlier `f4b20cd` implementation was used as a reference; changes below were reimplemented against the current files.

| Item | Done on current branch? | Evidence before this restore | Action |
|---|---|---|---|
| U22 personal Gold wording and shares | Partial | `src/client/match/match_screen.gd:753` showed aggregate Gold in the header and `:473,541,600`, `src/client/match/battle/battle_view.gd:1082`, and `src/client/match/battle/combat_panel.gd:246` used raw party rewards; `src/client/match/camp/merchant_panel.gd:20` said "Party Gold". `src/client/ui/ui_text.gd:33` and `tests/client/test_qa_polish.gd:68,146` already used personal insufficient-Gold wording and personal-Gold tips. | Show the viewer's purse and share in HUD/reward copy; add regression coverage. |
| U24 DoT tip | No | `src/client/ui/ui_text.gd:108` said the badge displayed a turns counter `(t)`. | Describe stack count and hover tooltip. |
| U26 one Summary title; Esc/F2 work during banner | Partial | `tests/client/test_story_ui.gd:99` already covers the Summary title; `src/client/client_app.gd:627` swallowed all keys while a banner showed. | Keep Summary behavior and allow Esc/F2 through banners. |
| U27 consistent Esc on list screens | No | `src/client/match/match_screen.gd:228` called `confirm_leave()` directly; setup created no list-screen menu. | Add a first-Esc menu and second-Esc close behavior. |
| U32 live text-scale/reduced-motion settings | No | `src/client/client_app.gd:593` refreshed the current screen but had no settings callback; `src/client/story/story_director.gd:23` only received settings at creation. | Propagate changes through MatchScreen and the active Story presentation. |
| U33 content-sized Story dialogue, aspect-safe portrait, narrator style | No | `src/client/story/dialogue_panel.gd:34-35` used a fixed 196px box, `:76` stretched portraits, and `:80` drew a generic initial for Narrator. | Size to text, fit portraits without distortion, and draw a book mark for Narrator. |
| U34 graphical pager dots | No | `src/client/lobby/character_setup.gd:201-203` built its pager from `O`/`o` text labels. | Draw active/inactive dots. |
| U31 large-text vote page | Yes | `src/client/match/vote_panel.gd:29-35` gives route choices their own scroll area; `tests/client/test_story_ui.gd:70` covers 1.4 scale status/timer placement. | No change. |
| U25 Lobby toast vs Copy code | Yes | `src/client/client_app.gd:408-415` places Lobby notices in the top-right safe area; other screens use bottom-right. | Keep placement and add a regression test. |

The new UI restore cases live in `tests/client/test_ui_polish_restore.gd`; `tests/run_tests.gd` discovers `test_*.gd` recursively, so no explicit registration is needed.

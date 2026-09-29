# T15 — P0: profile storage never saves (#64)

Read first: `AGENTS.md`, `CONTEXT.md`, `docs/adr/0013-pre-match-loadout-class-race-boons-prestige-gems.md`,
`docs/review/2026-09-29-server-review.md` (findings S3, S11, S18), `gh issue view 64` and `gh issue view 55`
(repo qqkiller-programmer-myself-2006/project-gamedev), `src/core/profile_store.gd`, `src/core/d1_profile_store.gd`,
`src/core/file_profile_store.gd`, `src/match/match_server.gd` (`_set_session_profile`, `save_profile_async` call),
`src/server/game_server.gd` (`configure`), `deploy/profile-worker/src/index.js` and its test.

## Problem
`GameServer.configure` builds `D1ProfileStore.new(url, secret)` with no HTTP sender and none exists in `src/`, so with
`PROFILE_URL` set every load returns an empty profile and every save is dropped (S3). D1 errors are turned into an empty
profile that could then be saved over the real one (S11). The Worker accepts only lowercase hex tokens, the server also
uppercase (S18).

## Build
1. `src/core/http_profile_sender.gd` (`class_name HttpProfileSender`): implements the `request(method, url, headers, body)`
   contract `D1ProfileStore` already calls and returns `{"status": int, "body": Variant}` (parsed JSON or null). Use Godot
   `HTTPClient` (TLS for https). Loads may block the server loop: they happen only on join; cap them with a 3 s timeout.
2. Saves must not block: a worker `Thread` + queue inside the sender or the store (`save_profile_async` already exists on the
   ProfileStore seam — use it). Retry each save up to 3 times with backoff (0.5 s, 1 s, 2 s); keep only the newest pending
   save per token. Stop the thread cleanly when the server exits (no hang on quit).
3. `D1ProfileStore.load_profile`: 200 -> normalized profile; 404 -> new empty profile (first visit); anything else
   (401/5xx/timeout/network) -> the profile is **unavailable**: return a normalized empty profile marked
   `"_unavailable": true`, and `save_profile`/`save_profile_async` must refuse to write a profile carrying that mark (never
   overwrite the stored one). Tell the player: `MatchServer` emits an event (e.g. `profile_unavailable`) on join; add the
   player text to `src/client/ui/ui_text.gd` and show it as a toast/notice where other join notices appear.
4. Optimistic concurrency: include a `version` integer in the profile; the Worker's PUT only updates when the stored
   version is lower (`... WHERE excluded.version > version` or an equivalent check) and returns 409 otherwise; the server
   bumps `version` on every save. Update `deploy/profile-worker` code, its README/schema notes and its tests
   (`npm test` in `deploy/profile-worker` if node_modules exists; otherwise say so — do not install packages globally).
5. Tokens: normalise to lowercase in `match_server.gd` before use; the Worker keeps the lowercase-only regex.
6. `GameServer.configure` passes `HttpProfileSender.new()` to `D1ProfileStore`.
7. Tests (`tests/core/` or `tests/match/`): a fake sender covering 200, 404, 500/timeout (unavailable -> no save),
   retry-then-success, newest-save-wins, uppercase token accepted as lowercase. No real network in tests.

## Rules
- Do not touch `src/client/**` except `ui_text.gd` and the one place that shows the notice. Do not touch `src/match/match_run.gd`
  or `src/match/encounters/**` (another executor is editing them).
- Commit in small steps, messages like `fix: D1 profile store gets a real HTTP sender (#64)`, each ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash scripts/run_tests.sh` -> paste the exact
  summary line (0 failed). After adding a `class_name`, run `"$GODOT" --headless --path . --import` once. ONE Godot process
  at a time (low RAM). Never ask for or print real secrets.
- Report in English: design (threading, retry), files changed, test line, Worker test result, commit hashes, and the exact
  deploy steps the owner must run for the Worker change (#55).

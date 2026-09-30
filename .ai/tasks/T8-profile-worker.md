# T8 — Cloudflare Worker + D1 for player profiles (ADR-0013 §5)

Build a tiny Cloudflare Worker that stores player profiles in D1 for the game server. Read
`docs/adr/0013-pre-match-loadout-class-race-boons-prestige-gems.md` §5 first.

## Files you may create/change

`deploy/profile-worker/**` (new) and `docs/running.md` (add a short "Profile storage" section). Nothing else.

## Requirements

- `deploy/profile-worker/wrangler.toml` (name `btwe-profiles`, a `DB` D1 binding placeholder with a clear comment where the
  owner pastes the `database_id`), `schema.sql` (`profiles(token TEXT PRIMARY KEY, data TEXT NOT NULL, updated_at INTEGER)`),
  `src/index.js` (ES module Worker), `package.json` with `wrangler` as a dev dependency and `test` script,
  and a small test using the Vitest + `@cloudflare/vitest-pool-workers` setup OR plain unit tests of the request handler.
- API: `GET /profiles/:token` → 200 JSON profile or 404; `PUT /profiles/:token` with JSON body → 204.
  `:token` must be 32 lowercase hex chars (else 400). Every request needs `Authorization: Bearer <SERVER_SECRET>`
  (Worker secret `SERVER_SECRET`, compared in constant time) else 401. Body limit 64 KB (413). Only JSON objects accepted.
- No CORS (only the game server calls it). No logging of tokens or bodies.
- `docs/running.md`: exact commands the owner runs once: `npx wrangler login`, `npx wrangler d1 create btwe-profiles`,
  paste id, `npx wrangler d1 execute btwe-profiles --remote --file=schema.sql`, `npx wrangler secret put SERVER_SECRET`,
  `npx wrangler deploy`, then start the game server with `--profile-url=https://... --profile-secret=...`.
  Do NOT run any of these yourself (they need the owner's Cloudflare login).

## Verify

`npm install` and `npm test` inside `deploy/profile-worker/` pass (tests must not need network or a Cloudflare account).

## Report (in English)

Files created; test result; the exact owner commands.

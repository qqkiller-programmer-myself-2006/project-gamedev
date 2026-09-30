# Player profile Worker

The Worker authenticates requests with `SERVER_SECRET` and stores a JSON profile for each lowercase 32-character hexadecimal token. Profiles include a non-negative integer `version`. A PUT is accepted only when its version is greater than the stored version; stale or equal writes return HTTP 409.

## Deploy

For an existing D1 database, apply the one-time migration before deploying the Worker:

```sh
wrangler d1 execute <DATABASE_NAME> --remote --command "ALTER TABLE profiles ADD COLUMN version INTEGER NOT NULL DEFAULT 0;"
```

For a new database, apply `schema.sql` instead. Then deploy from this directory:

```sh
wrangler deploy
```

Set the Worker secret once with `wrangler secret put SERVER_SECRET`, and configure the game server with the Worker URL and the same `PROFILE_SECRET`. The owner must run `wrangler login` before these deployment commands.

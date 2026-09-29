CREATE TABLE IF NOT EXISTS profiles (
  token TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  updated_at INTEGER
);

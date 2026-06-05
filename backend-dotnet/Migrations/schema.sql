-- Users
CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    name        VARCHAR(100) NOT NULL,
    password_hash TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Learning plan per user
CREATE TABLE IF NOT EXISTS learning_plans (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    language        VARCHAR(50) NOT NULL,
    current_level   VARCHAR(5)  NOT NULL DEFAULT 'A1',  -- A1,A2,B1,B2,C1,C2
    target_level    VARCHAR(5)  NOT NULL DEFAULT 'C2',
    sessions_per_week INTEGER NOT NULL DEFAULT 3,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, language)
);

-- Individual conversation sessions
CREATE TABLE IF NOT EXISTS sessions (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id     INTEGER NOT NULL REFERENCES learning_plans(id) ON DELETE CASCADE,
    topic       TEXT NOT NULL,
    language    VARCHAR(50) NOT NULL,
    level       VARCHAR(5)  NOT NULL,
    started_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at    TIMESTAMPTZ,
    duration_seconds INTEGER,
    message_count    INTEGER NOT NULL DEFAULT 0
);

-- Individual messages within a session
CREATE TABLE IF NOT EXISTS messages (
    id          SERIAL PRIMARY KEY,
    session_id  INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    role        VARCHAR(10) NOT NULL CHECK (role IN ('user','assistant')),
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Corrections made during sessions
CREATE TABLE IF NOT EXISTS corrections (
    id              SERIAL PRIMARY KEY,
    session_id      INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    original_text   TEXT NOT NULL,
    corrected_text  TEXT NOT NULL,
    explanation     TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- XP and level progression
CREATE TABLE IF NOT EXISTS progress (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id         INTEGER NOT NULL REFERENCES learning_plans(id) ON DELETE CASCADE,
    total_sessions  INTEGER NOT NULL DEFAULT 0,
    total_xp        INTEGER NOT NULL DEFAULT 0,
    streak_days     INTEGER NOT NULL DEFAULT 0,
    last_session_date DATE,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, plan_id)
);

-- Topics pool per language (seeded below)
CREATE TABLE IF NOT EXISTS topics (
    id          SERIAL PRIMARY KEY,
    language    VARCHAR(50) NOT NULL,
    level       VARCHAR(5)  NOT NULL,
    title       TEXT NOT NULL
);

-- Seed topics
INSERT INTO topics (language, level, title) VALUES
  ('English','A1','Introducing yourself'),
  ('English','A1','Your family'),
  ('English','A1','Numbers and colours'),
  ('English','A2','Daily routines'),
  ('English','A2','Shopping at a market'),
  ('English','A2','Describing your home'),
  ('English','B1','Working from home'),
  ('English','B1','Planning a weekend trip'),
  ('English','B1','Cooking a favourite meal'),
  ('English','B1','Job interviews and career goals'),
  ('English','B1','Technology in everyday life'),
  ('English','B2','Discussing current news'),
  ('English','B2','Climate change and environment'),
  ('English','B2','Work-life balance'),
  ('English','B2','Debating remote work vs office'),
  ('English','C1','Analysing a political debate'),
  ('English','C1','Idiomatic expressions in business'),
  ('English','C1','Nuances of formal writing'),
  ('English','C2','Literary analysis'),
  ('English','C2','Philosophical discussion'),
  ('Polish','A1','Przedstawianie się'),
  ('Polish','A1','Rodzina i przyjaciele'),
  ('Polish','A2','Codzienne rutyny'),
  ('Polish','A2','Zakupy i jedzenie'),
  ('Polish','B1','Praca zdalna'),
  ('Polish','B1','Planowanie weekendu'),
  ('Polish','B1','Technologia w codziennym życiu'),
  ('Polish','B2','Dyskusja o aktualnych wydarzeniach'),
  ('Polish','C1','Analiza polityczna'),
  ('Polish','C1','Wyrażenia idiomatyczne')
ON CONFLICT DO NOTHING;

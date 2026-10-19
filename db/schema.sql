-- Dailies · online schema (Neon Postgres)
--
-- The offline app never needs any of this. These tables back the optional
-- cloud save, the guild hall leaderboard and the weekly world boss.

create table if not exists players (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  name_key       text not null unique,
  sync_code_hash text unique,
  created_at     timestamptz not null default now(),
  last_seen_at   timestamptz,
  constraint players_name_length check (char_length(name) between 2 and 24)
);

-- One row per device that has claimed the account. Tokens are stored as
-- SHA-256 hashes so a database leak never exposes a usable token.
create table if not exists player_tokens (
  token_hash   text primary key,
  player_id    uuid not null references players(id) on delete cascade,
  created_at   timestamptz not null default now(),
  last_used_at timestamptz
);

create index if not exists player_tokens_player_idx
  on player_tokens (player_id);

-- Habit ids are generated on the device (base36 counters, demo ids with
-- dashes), so the primary key is scoped per player instead of global.
create table if not exists habits (
  player_id   uuid not null references players(id) on delete cascade,
  id          text not null,
  name        text not null,
  icon_index  smallint not null default 0,
  color_index smallint not null default 0,
  position    smallint not null default 0,
  primary key (player_id, id),
  constraint habits_name_length check (char_length(name) between 1 and 60)
);

create table if not exists completions (
  player_id  uuid not null,
  habit_id   text not null,
  day        date not null,
  created_at timestamptz not null default now(),
  primary key (player_id, habit_id, day),
  foreign key (player_id, habit_id)
    references habits (player_id, id) on delete cascade
);

create index if not exists completions_day_idx
  on completions (day);

create index if not exists completions_player_day_idx
  on completions (player_id, day);

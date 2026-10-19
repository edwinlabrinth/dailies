import { neon } from '@neondatabase/serverless';

/**
 * Dailies API — a single Netlify Function (v2, Web Fetch API) serving /api/*.
 *
 * Design notes
 * ------------
 * - Identity is passwordless. Registering creates a device token plus a
 *   human-readable sync code that can be claimed on another device.
 * - Habits are last-write-wins: the device owns the data and pushes a full
 *   snapshot. That is what keeps the Flutter app offline-first.
 * - The world boss needs no extra writes. Its damage is simply the sum of the
 *   week's completions, computed on read.
 */

const XP_PER_COMPLETION = 10;
const BOSS_HP_PER_PLAYER = 700; // ~70 completions per active player per week
const BOSS_NAMES = [
  'The Procrastination Hydra',
  'The Snooze Golem',
  'The Doomscroll Kraken',
  'The Inbox Wyrm',
  'The Deadline Djinn',
  'The Chaos Mimic',
  'The Excuse Wraith',
];

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'authorization, content-type',
  'access-control-max-age': '86400',
};

const json = (status, body, extraHeaders = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      ...CORS,
      ...extraHeaders,
    },
  });

class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

// ---------------------------------------------------------------------------
// Database

let cachedSql;

function db() {
  if (!process.env.DATABASE_URL) {
    throw new ApiError(
      503,
      'not_configured',
      'This deployment has no DATABASE_URL configured.',
    );
  }
  cachedSql ??= neon(process.env.DATABASE_URL);
  return cachedSql;
}

// ---------------------------------------------------------------------------
// Small utilities

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

function randomString(length) {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  let out = '';
  for (let i = 0; i < length; i += 1) out += ALPHABET[bytes[i] % ALPHABET.length];
  return out;
}

function makeToken() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/** XXXX-XXXX-XXXX — spoken, typed and screenshotted easily. */
function makeSyncCode() {
  return [4, 4, 4].map(() => randomString(4)).join('-');
}

const normalizeCode = (value) =>
  String(value ?? '')
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '');

async function sha256(value) {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, '0'),
  ).join('');
}

// ---------------------------------------------------------------------------
// Dates. Everything is UTC: completions are calendar days, not timestamps.

const dayKey = (date) => date.toISOString().slice(0, 10);

function startOfWeekUTC(now = new Date()) {
  const date = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
  const offset = (date.getUTCDay() + 6) % 7; // Monday = 0
  date.setUTCDate(date.getUTCDate() - offset);
  return date;
}

/** Monday is 7 days from the end, Sunday is 1. */
const daysUntilMonday = (now = new Date()) => 7 - ((now.getUTCDay() + 6) % 7);

function isoWeek(date) {
  const d = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7) + 3);
  const firstThursday = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
  return 1 + Math.round((d - firstThursday) / (7 * 86_400_000));
}

/** Consecutive days (UTC) with activity, with the same midnight grace as habits. */
function currentStreak(days) {
  const set = new Set(days);
  const cursor = new Date(`${dayKey(new Date())}T00:00:00Z`);
  if (!set.has(dayKey(cursor))) cursor.setUTCDate(cursor.getUTCDate() - 1);
  let streak = 0;
  while (set.has(dayKey(cursor))) {
    streak += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }
  return streak;
}

// ---------------------------------------------------------------------------
// Validation

async function readJson(request) {
  const text = await request.text();
  if (text.length > 250_000) {
    throw new ApiError(413, 'payload_too_large', 'That payload is too big.');
  }
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    throw new ApiError(400, 'invalid_json', 'The request body must be JSON.');
  }
}

function cleanName(raw) {
  if (typeof raw !== 'string') return null;
  const name = raw.replace(/\s+/g, ' ').trim();
  if (name.length < 2 || name.length > 24) return null;
  if (!/^[\p{L}\p{N} '._-]+$/u.test(name)) return null;
  return name;
}

const isDay = (value) =>
  typeof value === 'string' &&
  /^\d{4}-\d{2}-\d{2}$/.test(value) &&
  !Number.isNaN(Date.parse(`${value}T00:00:00Z`));

function normalizeHabits(input) {
  if (!Array.isArray(input) || input.length > 50) return null;
  const tomorrow = dayKey(new Date(Date.now() + 86_400_000));
  const seen = new Set();
  const habits = [];

  for (const raw of input) {
    if (!raw || typeof raw !== 'object') return null;
    const id = typeof raw.id === 'string' ? raw.id.trim() : '';
    const name = typeof raw.name === 'string' ? raw.name.trim() : '';
    if (!/^[A-Za-z0-9_-]{1,64}$/.test(id)) return null;
    if (name.length < 1 || name.length > 60) return null;
    if (seen.has(id)) return null;
    seen.add(id);

    const clamp = (value) => {
      const number = Number.parseInt(value, 10);
      return Number.isFinite(number) ? Math.min(Math.max(number, 0), 64) : 0;
    };
    const done = Array.isArray(raw.done)
      ? raw.done.filter(isDay).filter((day) => day <= tomorrow)
      : [];

    habits.push({
      id,
      name,
      icon: clamp(raw.icon),
      color: clamp(raw.color),
      position: habits.length,
      done: [...new Set(done)].sort(),
    });
  }
  return habits;
}

// ---------------------------------------------------------------------------
// Queries

const publicPlayer = (row) => ({
  id: row.id,
  name: row.name,
  createdAt: row.created_at,
});

async function requirePlayer(request) {
  const header = request.headers.get('authorization') ?? '';
  const match = /^Bearer\s+([A-Za-z0-9_-]{20,})$/.exec(header);
  if (!match) {
    throw new ApiError(401, 'unauthorized', 'Missing or malformed token.');
  }
  const tokenHash = await sha256(match[1]);
  const rows = await db().query(
    `update player_tokens t
        set last_used_at = now()
       from players p
      where t.token_hash = $1
        and p.id = t.player_id
      returning p.id, p.name, p.created_at`,
    [tokenHash],
  );
  if (!rows.length) {
    throw new ApiError(401, 'unauthorized', 'That token is not valid.');
  }
  return rows[0];
}

async function loadHabits(playerId) {
  const sql = db();
  const habitRows = await sql.query(
    `select id, name, icon_index, color_index
       from habits
      where player_id = $1
      order by position asc, name asc`,
    [playerId],
  );
  const doneRows = await sql.query(
    `select habit_id, day::text as day
       from completions
      where player_id = $1
      order by day asc`,
    [playerId],
  );

  const doneByHabit = new Map();
  for (const row of doneRows) {
    const list = doneByHabit.get(row.habit_id) ?? [];
    list.push(row.day);
    doneByHabit.set(row.habit_id, list);
  }

  return habitRows.map((habit) => ({
    id: habit.id,
    name: habit.name,
    icon: habit.icon_index,
    color: habit.color_index,
    done: doneByHabit.get(habit.id) ?? [],
  }));
}

async function playerStats(playerId, habits) {
  const weekStart = dayKey(startOfWeekUTC());
  const [row] = await db().query(
    `select count(*)::int as total,
            count(*) filter (where day >= $1)::int as week
       from completions
      where player_id = $2`,
    [weekStart, playerId],
  );
  const streak = habits.reduce(
    (best, habit) => Math.max(best, currentStreak(habit.done)),
    0,
  );
  return {
    totalXp: row.total * XP_PER_COMPLETION,
    weeklyXp: row.week * XP_PER_COMPLETION,
    streak,
  };
}

async function loadWorld() {
  const sql = db();
  const weekStart = dayKey(startOfWeekUTC());
  const today = dayKey(new Date());

  const [week] = await sql.query(
    `select count(*)::int as completions,
            count(distinct player_id)::int as players
       from completions
      where day >= $1`,
    [weekStart],
  );
  const [todayRow] = await sql.query(
    `select count(*)::int as completions
       from completions
      where day = $1`,
    [today],
  );
  const activeDays = await sql.query(
    `select distinct day::text as day
       from completions
      order by day desc
      limit 400`,
  );
  const [total] = await sql.query(
    'select count(*)::int as completions from completions',
  );

  const activePlayers = Math.max(1, week.players);
  const hpMax = BOSS_HP_PER_PLAYER * activePlayers;
  const damage = week.completions * XP_PER_COMPLETION;
  const bossName = BOSS_NAMES[isoWeek(new Date()) % BOSS_NAMES.length];

  return {
    weekStart,
    boss: {
      name: bossName,
      hpMax,
      damage,
      remaining: Math.max(0, hpMax - damage),
      percent: Math.min(100, Math.round((damage / hpMax) * 100)),
      defeated: damage >= hpMax,
      endsInDays: daysUntilMonday(),
    },
    guild: {
      players: week.players,
      weeklyCompletions: week.completions,
      weeklyXp: damage,
      todayCompletions: todayRow.completions,
      todayXp: todayRow.completions * XP_PER_COMPLETION,
      streakDays: currentStreak(activeDays.map((row) => row.day)),
      totalCompletions: total.completions,
    },
  };
}

// ---------------------------------------------------------------------------
// Handlers

async function health() {
  const [row] = await db().query(
    `select now() as now,
            (select count(*)::int from players) as players,
            (select count(*)::int from completions) as completions`,
  );
  return json(200, {
    ok: true,
    now: row.now,
    players: row.players,
    completions: row.completions,
  });
}

async function register(request) {
  const body = await readJson(request);
  const name = cleanName(body?.name);
  if (!name) {
    throw new ApiError(
      400,
      'invalid_name',
      'Pick a name between 2 and 24 characters.',
    );
  }

  const nameKey = name.normalize('NFKC').toLowerCase();
  const sql = db();
  const existing = await sql.query(
    'select 1 from players where name_key = $1',
    [nameKey],
  );
  if (existing.length) {
    throw new ApiError(
      409,
      'name_taken',
      'Someone already claimed that name in the guild hall.',
    );
  }

  const syncCode = makeSyncCode();
  const [player] = await sql.query(
    `insert into players (name, name_key, sync_code_hash, last_seen_at)
     values ($1, $2, $3, now())
     returning id, name, created_at`,
    [name, nameKey, await sha256(normalizeCode(syncCode))],
  );

  const token = makeToken();
  await sql.query(
    'insert into player_tokens (token_hash, player_id) values ($1, $2)',
    [await sha256(token), player.id],
  );

  return json(201, {
    player: publicPlayer(player),
    token,
    syncCode,
    world: await loadWorld(),
  });
}

async function claim(request) {
  const body = await readJson(request);
  const code = normalizeCode(body?.syncCode);
  if (code.length < 8) {
    throw new ApiError(400, 'invalid_code', 'Enter the 12-character sync code.');
  }

  const sql = db();
  const [player] = await sql.query(
    'select id, name, created_at from players where sync_code_hash = $1',
    [await sha256(code)],
  );
  if (!player) {
    throw new ApiError(
      404,
      'code_not_found',
      'That sync code does not match anyone in the guild.',
    );
  }

  const token = makeToken();
  await sql.query(
    'insert into player_tokens (token_hash, player_id) values ($1, $2)',
    [await sha256(token), player.id],
  );
  await sql.query('update players set last_seen_at = now() where id = $1', [
    player.id,
  ]);

  return json(200, {
    player: publicPlayer(player),
    token,
    habits: await loadHabits(player.id),
    world: await loadWorld(),
  });
}

async function rotateSyncCode(request) {
  const player = await requirePlayer(request);
  const syncCode = makeSyncCode();
  await db().query('update players set sync_code_hash = $1 where id = $2', [
    await sha256(normalizeCode(syncCode)),
    player.id,
  ]);
  return json(200, { syncCode });
}

async function pullHabits(request) {
  const player = await requirePlayer(request);
  const habits = await loadHabits(player.id);
  return json(200, {
    player: publicPlayer(player),
    habits,
    stats: await playerStats(player.id, habits),
    world: await loadWorld(),
  });
}

async function pushHabits(request) {
  const player = await requirePlayer(request);
  const body = await readJson(request);
  const habits = normalizeHabits(body?.habits);
  if (!habits) {
    throw new ApiError(
      400,
      'invalid_habits',
      'Habits must be an array of at most 50 valid habits.',
    );
  }

  const sql = db();
  // Full replace keeps the sync model honest: the device owns its data, the
  // server is a mirror. Everything happens in one atomic HTTP transaction.
  const queries = [sql.query('delete from habits where player_id = $1', [player.id])];
  for (const habit of habits) {
    queries.push(
      sql.query(
        `insert into habits (player_id, id, name, icon_index, color_index, position)
         values ($1, $2, $3, $4, $5, $6)`,
        [player.id, habit.id, habit.name, habit.icon, habit.color, habit.position],
      ),
    );
    if (habit.done.length) {
      queries.push(
        sql.query(
          `insert into completions (player_id, habit_id, day)
           select $1, $2, day::date from unnest($3::text[]) as day`,
          [player.id, habit.id, habit.done],
        ),
      );
    }
  }
  queries.push(
    sql.query('update players set last_seen_at = now() where id = $1', [
      player.id,
    ]),
  );
  await sql.transaction(queries);

  return json(200, {
    player: publicPlayer(player),
    stats: await playerStats(player.id, habits),
    world: await loadWorld(),
  });
}

async function leaderboard() {
  const weekStart = dayKey(startOfWeekUTC());
  const leaders = await db().query(
    `select p.id,
            p.name,
            count(c.habit_id) filter (where c.day >= $1)::int * $2 as weekly_xp,
            count(c.habit_id)::int * $2 as total_xp,
            p.last_seen_at
       from players p
       left join completions c on c.player_id = p.id
      group by p.id, p.name, p.last_seen_at
      order by weekly_xp desc, total_xp desc, p.name asc
      limit 25`,
    [weekStart, XP_PER_COMPLETION],
  );
  const world = await loadWorld();

  return json(
    200,
    {
      world,
      leaders: leaders.map((row) => ({
        id: row.id,
        name: row.name,
        weeklyXp: row.weekly_xp,
        totalXp: row.total_xp,
        lastSeenAt: row.last_seen_at,
      })),
    },
    { 'cache-control': 'public, max-age=10, s-maxage=20' },
  );
}

async function world() {
  return json(200, { world: await loadWorld() }, {
    'cache-control': 'public, max-age=10, s-maxage=20',
  });
}

// ---------------------------------------------------------------------------
// Router

export default async function handler(request) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS });
  }

  const { pathname } = new URL(request.url);
  const route = pathname.replace(/^\/api\/?/, '').replace(/\/+$/, '') || 'health';

  try {
    if (request.method === 'GET' && route === 'health') return await health();
    if (request.method === 'GET' && route === 'world') return await world();
    if (request.method === 'GET' && route === 'leaderboard') {
      return await leaderboard();
    }
    if (request.method === 'POST' && route === 'register') {
      return await register(request);
    }
    if (request.method === 'POST' && route === 'claim') {
      return await claim(request);
    }
    if (request.method === 'POST' && route === 'sync-code') {
      return await rotateSyncCode(request);
    }
    if (request.method === 'GET' && route === 'sync') {
      return await pullHabits(request);
    }
    if (request.method === 'POST' && route === 'sync') {
      return await pushHabits(request);
    }
    throw new ApiError(
      404,
      'not_found',
      `No route for ${request.method} /api/${route}.`,
    );
  } catch (error) {
    if (error instanceof ApiError) {
      return json(error.status, { error: error.code, message: error.message });
    }
    console.error('dailies api error', error);
    return json(500, {
      error: 'server_error',
      message: 'Something broke on the server. Try again in a moment.',
    });
  }
}

export const config = { path: '/api/*' };

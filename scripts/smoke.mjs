import assert from 'node:assert/strict';

import { neon } from '@neondatabase/serverless';

import handler from '../netlify/functions/api.mjs';

/**
 * End-to-end smoke test for the API, straight against the real database.
 * Creates one throwaway player and deletes it again in a finally block.
 *
 *   npm run smoke
 */
const sql = neon(process.env.DATABASE_URL);

async function call(method, route, { body, token } = {}) {
  const response = await handler(
    new Request(`http://localhost/api/${route}`, {
      method,
      headers: {
        'content-type': 'application/json',
        ...(token ? { authorization: `Bearer ${token}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    }),
  );
  const data = await response.json();
  return { status: response.status, data };
}

const today = new Date();
const yesterday = new Date(Date.now() - 86_400_000);
const day = (date) => date.toISOString().slice(0, 10);

let playerId;
let failures = 0;

async function check(label, fn) {
  try {
    await fn();
    console.log(`  ✓ ${label}`);
  } catch (error) {
    failures += 1;
    console.log(`  ✗ ${label}`);
    console.log(`    ${error.message}`);
  }
}

try {
  console.log('Dailies API smoke test\n');

  await check('health reports the database is reachable', async () => {
    const { status, data } = await call('GET', 'health');
    assert.equal(status, 200);
    assert.equal(data.ok, true);
    assert.ok(Number.isInteger(data.players));
  });

  const name = `Smoke${Date.now().toString(36)}`;
  let token;
  let syncCode;

  await check('register creates a player, token and sync code', async () => {
    const { status, data } = await call('POST', 'register', { body: { name } });
    assert.equal(status, 201, JSON.stringify(data));
    assert.equal(data.player.name, name);
    assert.match(data.token, /^[A-Za-z0-9_-]{40,}$/);
    assert.match(data.syncCode, /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/);
    assert.equal(data.world.boss.percent >= 0, true);
    playerId = data.player.id;
    token = data.token;
    syncCode = data.syncCode;
  });

  await check('duplicate names are rejected', async () => {
    const { status, data } = await call('POST', 'register', { body: { name } });
    assert.equal(status, 409);
    assert.equal(data.error, 'name_taken');
  });

  await check('sync pushes habits and completions', async () => {
    const { status, data } = await call('POST', 'sync', {
      token,
      body: {
        habits: [
          {
            id: 'smoke-1',
            name: 'Smoke habit',
            icon: 2,
            color: 1,
            done: [day(yesterday), day(today)],
          },
          { id: 'smoke-2', name: 'Empty habit', icon: 4, color: 3, done: [] },
        ],
      },
    });
    assert.equal(status, 200, JSON.stringify(data));
    assert.equal(data.stats.totalXp, 20);
    assert.equal(data.stats.weeklyXp >= 10, true);
    assert.equal(data.stats.streak, 2);
  });

  await check('leaderboard lists the player with weekly XP', async () => {
    const { status, data } = await call('GET', 'leaderboard');
    assert.equal(status, 200);
    const me = data.leaders.find((entry) => entry.name === name);
    assert.ok(me, 'player missing from leaderboard');
    assert.equal(me.weeklyXp, 10); // Monday: only today counts this week
    assert.equal(data.world.guild.weeklyCompletions >= 1, true);
  });

  let claimToken;

  await check('the sync code claims the account on another device', async () => {
    const { status, data } = await call('POST', 'claim', {
      body: { syncCode },
    });
    assert.equal(status, 200, JSON.stringify(data));
    assert.equal(data.player.name, name);
    assert.equal(data.habits.length, 2);
    const smoke = data.habits.find((habit) => habit.id === 'smoke-1');
    assert.deepEqual(smoke.done, [day(yesterday), day(today)]);
    claimToken = data.token;
  });

  await check('pulling with the claimed token returns the snapshot', async () => {
    const { status, data } = await call('GET', 'sync', { token: claimToken });
    assert.equal(status, 200);
    assert.equal(data.habits.length, 2);
    assert.equal(data.stats.totalXp, 20);
  });

  await check('rotating the sync code invalidates the old one', async () => {
    const rotated = await call('POST', 'sync-code', { token });
    assert.equal(rotated.status, 200);
    assert.notEqual(rotated.data.syncCode, syncCode);
    const stale = await call('POST', 'claim', { body: { syncCode } });
    assert.equal(stale.status, 404);
    const fresh = await call('POST', 'claim', {
      body: { syncCode: rotated.data.syncCode },
    });
    assert.equal(fresh.status, 200);
  });

  await check('unauthorized pulls are refused', async () => {
    const { status } = await call('GET', 'sync');
    assert.equal(status, 401);
  });

  await check('the world boss scales with active players', async () => {
    const { status, data } = await call('GET', 'world');
    assert.equal(status, 200);
    const { boss, guild } = data.world;
    assert.ok(boss.hpMax >= 700);
    assert.ok(boss.percent >= 0 && boss.percent <= 100);
    assert.ok(boss.name.length > 0);
    assert.ok(guild.streakDays >= 1);
  });
} finally {
  if (playerId) {
    await sql.query('delete from players where id = $1', [playerId]);
    console.log('\ncleaned up the smoke-test player');
  }
}

console.log(failures === 0 ? '\nall smoke checks passed' : `\n${failures} check(s) failed`);
process.exit(failures === 0 ? 0 : 1);

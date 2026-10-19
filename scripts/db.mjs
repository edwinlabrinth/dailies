import { readFile } from 'node:fs/promises';

import { neon } from '@neondatabase/serverless';

/**
 * Applies db/schema.sql to the database in DATABASE_URL. Safe to re-run:
 * every statement uses `if not exists`.
 */
const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error('DATABASE_URL is missing. Run `npm run db` (it loads .env).');
  process.exit(1);
}

const sql = neon(connectionString);
const source = await readFile(new URL('../db/schema.sql', import.meta.url), 'utf8');

// Strip `--` line comments before splitting: a comment is allowed to contain
// a semicolon, and a naive split would cut a statement in half.
const withoutComments = source
  .split('\n')
  .filter((line) => !line.trim().startsWith('--'))
  .join('\n');

const statements = withoutComments
  .split(';')
  .map((chunk) => chunk.trim())
  .filter((chunk) => chunk.length > 0);

console.log(`Applying ${statements.length} statements…`);
for (const statement of statements) {
  await sql.query(statement);
  const firstLine = statement
    .split('\n')
    .map((line) => line.trim())
    .find((line) => line);
  console.log(`  · ${firstLine.slice(0, 78)}`);
}

const [tables] = await sql.query(
  `select count(*)::int as count
     from information_schema.tables
    where table_schema = 'public'
      and table_name in ('players', 'player_tokens', 'habits', 'completions')`,
);
const [stats] = await sql.query(
  `select (select count(*)::int from players) as players,
          (select count(*)::int from habits) as habits,
          (select count(*)::int from completions) as completions`,
);

console.log(
  `schema ready: ${tables.count}/4 tables · players=${stats.players} habits=${stats.habits} completions=${stats.completions}`,
);

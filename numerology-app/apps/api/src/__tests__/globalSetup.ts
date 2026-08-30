import { execSync } from 'node:child_process';
import path from 'node:path';
import fs from 'node:fs';
import dotenv from 'dotenv';

/**
 * Prepares the test database before the suite runs.
 *
 * Migrations are applied with `prisma migrate deploy` (never a destructive
 * reset), the standard seed content is loaded, and only the rows the tests
 * themselves create are cleared. The suite therefore runs against the real
 * schema and the real seeded rules rather than mocks.
 */
export default async function setup() {
  const root = path.resolve(__dirname, '../..');
  const envPath = path.join(root, '.env.test');
  if (!fs.existsSync(envPath)) {
    throw new Error('.env.test is missing - copy .env.example and point DATABASE_URL at a test database.');
  }

  const parsed = dotenv.parse(fs.readFileSync(envPath));
  Object.assign(process.env, parsed);
  const env = { ...process.env, ...parsed };

  if (!/numerology_test/.test(parsed.DATABASE_URL ?? '')) {
    throw new Error('Refusing to run tests against a database that is not the test database.');
  }

  execSync('npx prisma migrate deploy', { cwd: root, env, stdio: 'pipe' });
  execSync('npx tsx prisma/seed.ts', { cwd: root, env, stdio: 'pipe' });
  execSync('npx tsx src/__tests__/resetTestData.ts', { cwd: root, env, stdio: 'pipe' });
}

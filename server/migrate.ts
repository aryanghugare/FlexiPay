import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { Pool } from 'pg';

const here = dirname(fileURLToPath(import.meta.url));
const schemaPath = resolve(here, '../db/init.sql');
const connectionString = process.env.DATABASE_URL ?? 'postgres://emi_user:emi_password@localhost:5432/emi_catalog';
const pool = new Pool({ connectionString });

try {
  await pool.query(await readFile(schemaPath, 'utf8'));
  console.log('Database schema and seed data are ready.');
} finally {
  await pool.end();
}

/**
 * NORTE BOUND — Migration & Seed Runner
 * ---------------------------------------------------------------------------
 * Usage:  node database/seeds/run_migrator_and_seeds.mjs
 *
 * Behaviour:
 *   1. Loads DB config from backend/.env (falls back to backend/.env.example).
 *   2. Connects to MySQL without requiring the target database to exist.
 *   3. Creates `norte_bound_db` if missing.
 *   4. Runs every database/migrations/*.sql file in strict numeric order.
 *   5. Seeds LGUs, taxonomy, destinations and dependent tables from JSON.
 *
 * All writes are idempotent (schema_migrations ledger + upsert statements),
 * so the script is safe to re-run.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '../..');

const MIGRATIONS_DIR = path.join(ROOT, 'database/migrations');
const SEEDS_DIR = path.join(ROOT, 'database/seeds');
const ENV_PATH = path.join(ROOT, 'backend/.env');
const ENV_EXAMPLE_PATH = path.join(ROOT, 'backend/.env.example');

const DEFAULTS = {
  PORT: '5000',
  DB_HOST: 'localhost',
  DB_USER: 'root',
  DB_PASSWORD: '',
  DB_NAME: 'norte_bound_db',
  DB_PORT: '3306',
  JWT_SECRET: 'super_secret_jwt_key_change_in_production',
  GEMINI_API_KEY: 'your_gemini_api_key_here'
};

function log(icon, message) {
  console.log(`${icon}  ${message}`);
}

function parseEnvFile(filePath) {
  const values = {};
  if (!fs.existsSync(filePath)) return values;
  const raw = fs.readFileSync(filePath, 'utf8');
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  }
  return values;
}

function loadConfig() {
  const fromExample = parseEnvFile(ENV_EXAMPLE_PATH);
  const fromEnv = parseEnvFile(ENV_PATH);
  const merged = { ...DEFAULTS, ...fromExample, ...fromEnv };
  const envSource = fs.existsSync(ENV_PATH) ? 'backend/.env' : 'backend/.env.example';
  return { config: merged, envSource };
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

async function loadMysql() {
  const candidates = [
    pathToFileURL(path.join(ROOT, 'backend/node_modules/mysql2/promise.js')).href,
    'mysql2/promise'
  ];
  for (const candidate of candidates) {
    try {
      const mod = await import(candidate);
      const mysql = mod?.default?.createConnection ? mod.default : mod;
      if (mysql?.createConnection) return mysql;
    } catch {
      /* try next candidate */
    }
  }
  throw new Error(
    'mysql2 is not installed. Run `npm install mysql2` inside backend/ before running this script.'
  );
}

function listMigrationFiles() {
  return fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((file) => file.toLowerCase().endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b, 'en', { numeric: true }));
}

async function ensureMigrationsTable(conn) {
  await conn.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename   VARCHAR(255) NOT NULL,
      applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (filename)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  `);
}

async function runMigrations(conn) {
  await ensureMigrationsTable(conn);

  const [appliedRows] = await conn.query('SELECT filename FROM schema_migrations');
  const applied = new Set(appliedRows.map((row) => row.filename));
  const files = listMigrationFiles();

  if (files.length === 0) {
    log('⚠️', 'No migration files found in database/migrations/.');
    return;
  }

  log('📦', `Found ${files.length} migration file(s).`);

  for (const file of files) {
    if (applied.has(file)) {
      log('↩️', `Migration already applied, skipping: ${file}`);
      continue;
    }

    const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
    log('▶️', `Applying migration: ${file}`);

    try {
      await conn.query(sql);
      await conn.query('INSERT INTO schema_migrations (filename) VALUES (?)', [file]);
      log('✅', `Migration applied: ${file}`);
    } catch (err) {
      if (err && err.code === 'ER_TABLE_EXISTS_ERROR') {
        log('↩️', `Tables already exist for ${file}; marking as applied.`);
        await conn.query('INSERT IGNORE INTO schema_migrations (filename) VALUES (?)', [file]);
        continue;
      }
      throw new Error(`Migration failed (${file}): ${err.message}`);
    }
  }
}

async function seedLgus(conn, lgus) {
  const sql = `
    INSERT INTO lgus (
      lgu_code, name, lgu_type, tourism_cluster,
      center_latitude, center_longitude, terrain_type,
      road_tortuosity_multiplier, is_major_hub, baseline_dispersal_bonus
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      name = VALUES(name),
      lgu_type = VALUES(lgu_type),
      tourism_cluster = VALUES(tourism_cluster),
      center_latitude = VALUES(center_latitude),
      center_longitude = VALUES(center_longitude),
      terrain_type = VALUES(terrain_type),
      road_tortuosity_multiplier = VALUES(road_tortuosity_multiplier),
      is_major_hub = VALUES(is_major_hub),
      baseline_dispersal_bonus = VALUES(baseline_dispersal_bonus)
  `;

  for (const lgu of lgus) {
    await conn.query(sql, [
      lgu.lgu_code,
      lgu.name,
      lgu.lgu_type,
      lgu.tourism_cluster,
      lgu.center_latitude,
      lgu.center_longitude,
      lgu.terrain_type,
      lgu.road_tortuosity_multiplier,
      lgu.is_major_hub ? 1 : 0,
      lgu.baseline_dispersal_bonus
    ]);
  }
  return lgus.length;
}

async function seedTaxonomy(conn, taxonomy) {
  const categorySql = `
    INSERT INTO categories (category_code, name, description)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE
      name = VALUES(name),
      description = VALUES(description)
  `;

  for (const category of taxonomy.categories) {
    await conn.query(categorySql, [
      category.category_code,
      category.label,
      category.description
    ]);
  }

  const tagSql = `
    INSERT INTO interest_tags (tag_slug, display_name, category_code, ai_synonyms)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      display_name = VALUES(display_name),
      category_code = VALUES(category_code),
      ai_synonyms = VALUES(ai_synonyms)
  `;

  for (const tag of taxonomy.interest_tags) {
    const primaryCategory =
      Array.isArray(tag.related_categories) && tag.related_categories.length > 0
        ? tag.related_categories[0]
        : null;
    if (!primaryCategory) {
      throw new Error(`Interest tag "${tag.tag_code}" has no related_categories.`);
    }
    await conn.query(tagSql, [
      tag.tag_code,
      tag.label,
      primaryCategory,
      JSON.stringify(Array.isArray(tag.synonyms) ? tag.synonyms : [])
    ]);
  }

  return { categories: taxonomy.categories.length, tags: taxonomy.interest_tags.length };
}

async function seedDestinations(conn, destinations) {
  const destSql = `
    INSERT INTO destinations (
      slug, name, lgu_code, category_code, description, historical_background,
      address, latitude, longitude, entity_type, popularity_tier,
      highway_accessible, road_condition, verification_status,
      source_name, source_type, last_verified_date
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      name = VALUES(name),
      lgu_code = VALUES(lgu_code),
      category_code = VALUES(category_code),
      description = VALUES(description),
      historical_background = VALUES(historical_background),
      address = VALUES(address),
      latitude = VALUES(latitude),
      longitude = VALUES(longitude),
      entity_type = VALUES(entity_type),
      popularity_tier = VALUES(popularity_tier),
      highway_accessible = VALUES(highway_accessible),
      road_condition = VALUES(road_condition),
      verification_status = VALUES(verification_status),
      source_name = VALUES(source_name),
      source_type = VALUES(source_type),
      last_verified_date = VALUES(last_verified_date)
  `;

  const tagSql = `
    INSERT INTO destination_tags (destination_id, tag_slug)
    VALUES (?, ?)
    ON DUPLICATE KEY UPDATE tag_slug = VALUES(tag_slug)
  `;

  const hoursSql = `
    INSERT INTO operating_hours (
      destination_id, day_of_week, opening_time, closing_time,
      is_24_hours, temporarily_closed
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      opening_time = VALUES(opening_time),
      closing_time = VALUES(closing_time),
      is_24_hours = VALUES(is_24_hours),
      temporarily_closed = VALUES(temporarily_closed)
  `;

  const pricingSql = `
    INSERT INTO pricing_tiers (
      destination_id, entrance_fee_adult, entrance_fee_concession,
      mandatory_activity_fee, estimated_meal_min, estimated_meal_max,
      parking_fee, is_free, currency
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      entrance_fee_adult = VALUES(entrance_fee_adult),
      entrance_fee_concession = VALUES(entrance_fee_concession),
      mandatory_activity_fee = VALUES(mandatory_activity_fee),
      estimated_meal_min = VALUES(estimated_meal_min),
      estimated_meal_max = VALUES(estimated_meal_max),
      parking_fee = VALUES(parking_fee),
      is_free = VALUES(is_free),
      currency = VALUES(currency)
  `;

  const counts = { destinations: 0, tags: 0, hours: 0, pricing: 0 };

  for (const dest of destinations) {
    const vm = dest.verification_metadata || {};
    const coords = dest.coordinates || {};
    const dispersal = dest.dispersal_and_accessibility || {};
    const financials = dest.financials || {};

    await conn.query(destSql, [
      dest.destination_code,
      dest.name,
      dest.lgu_code,
      dest.category_code,
      dest.short_description,
      dest.historical_background ?? null,
      dest.address ?? null,
      coords.latitude,
      coords.longitude,
      dest.entity_type,
      dispersal.popularity_tier,
      dispersal.highway_accessible ? 1 : 0,
      dispersal.road_condition,
      vm.verification_status,
      vm.source_name,
      vm.source_type,
      vm.last_verified_date
    ]);
    counts.destinations += 1;

    const [idRows] = await conn.query('SELECT id FROM destinations WHERE slug = ?', [
      dest.destination_code
    ]);
    if (idRows.length === 0) {
      throw new Error(`Could not resolve destination id for slug "${dest.destination_code}".`);
    }
    const destinationId = idRows[0].id;

    for (const tag of dest.interest_tags || []) {
      await conn.query(tagSql, [destinationId, tag]);
      counts.tags += 1;
    }

    for (const slot of dest.operating_schedule || []) {
      await conn.query(hoursSql, [
        destinationId,
        slot.day_of_week,
        slot.open_time ?? null,
        slot.close_time ?? null,
        slot.is_24_hours ? 1 : 0,
        slot.temporarily_closed ? 1 : 0
      ]);
      counts.hours += 1;
    }

    await conn.query(pricingSql, [
      destinationId,
      financials.entrance_fee_adult ?? 0,
      financials.entrance_fee_student_senior ?? 0,
      financials.mandatory_activity_fee ?? 0,
      financials.estimated_meal_cost_min ?? 0,
      financials.estimated_meal_cost_max ?? 0,
      financials.parking_fee ?? 0,
      financials.is_free ? 1 : 0,
      'PHP'
    ]);
    counts.pricing += 1;
  }

  return counts;
}

async function main() {
  const { config, envSource } = loadConfig();
  const mysql = await loadMysql();

  const dbName = config.DB_NAME;
  if (!/^[A-Za-z0-9_]+$/.test(dbName)) {
    throw new Error(`Invalid DB_NAME "${dbName}". Only letters, numbers, and underscores are allowed.`);
  }

  const connectionConfig = {
    host: config.DB_HOST,
    port: Number(config.DB_PORT) || 3306,
    user: config.DB_USER,
    password: config.DB_PASSWORD,
    multipleStatements: true
  };

  console.log('');
  console.log('==================================================================');
  console.log('  NORTE BOUND — DATABASE MIGRATOR & SEEDER');
  console.log('==================================================================');
  log('⚙️', `Env source: ${envSource}`);
  log('🔌', `Target: ${config.DB_USER}@${config.DB_HOST}:${connectionConfig.port}/${dbName}`);
  console.log('');

  let conn;
  try {
    conn = await mysql.createConnection(connectionConfig);
    log('✅', 'Connected to MySQL server.');

    await conn.query(
      `CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`
    );
    await conn.query(`USE \`${dbName}\``);
    log('✅', `Database ready: ${dbName}`);

    console.log('');
    console.log('--- MIGRATIONS ---------------------------------------------------');
    await runMigrations(conn);

    console.log('');
    console.log('--- SEEDS --------------------------------------------------------');

    const lgus = readJson(path.join(SEEDS_DIR, '01_lgus_registry.json'));
    const taxonomy = readJson(path.join(SEEDS_DIR, '02_taxonomy_categories_tags.json'));
    const destinations = readJson(path.join(SEEDS_DIR, '03_destinations_dataset.json'));

    await conn.beginTransaction();
    try {
      const lguCount = await seedLgus(conn, lgus);
      log('✅', `Seeded LGUs: ${lguCount}`);

      const taxCounts = await seedTaxonomy(conn, taxonomy);
      log('✅', `Seeded categories: ${taxCounts.categories}`);
      log('✅', `Seeded interest tags: ${taxCounts.tags}`);

      const destCounts = await seedDestinations(conn, destinations);
      log('✅', `Seeded destinations: ${destCounts.destinations}`);
      log('✅', `Seeded destination tags: ${destCounts.tags}`);
      log('✅', `Seeded operating hours: ${destCounts.hours}`);
      log('✅', `Seeded pricing tiers: ${destCounts.pricing}`);

      await conn.commit();
      log('✅', 'Seed transaction committed.');
    } catch (seedError) {
      await conn.rollback();
      log('↩️', 'Seed transaction rolled back.');
      throw seedError;
    }

    console.log('');
    log('🎉', 'All migrations and seeds completed successfully.');
    console.log('==================================================================');
    console.log('');
  } catch (error) {
    console.error('');
    log('❌', `FATAL: ${error.message}`);
    console.log('==================================================================');
    console.log('');
    process.exitCode = 1;
  } finally {
    if (conn) {
      await conn.end();
      log('🔒', 'MySQL connection closed.');
    }
  }
}

main();

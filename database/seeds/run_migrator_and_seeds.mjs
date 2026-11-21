/**
 * NORTE BOUND — Supabase PostgreSQL Seed Runner
 * ---------------------------------------------------------------------------
 * Usage:  node database/seeds/run_migrator_and_seeds.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '../..');

const SEEDS_DIR = path.join(ROOT, 'database/seeds');
const ENV_PATH = path.join(ROOT, 'backend/.env');
const ENV_EXAMPLE_PATH = path.join(ROOT, 'backend/.env.example');

const SEEDED_USERS = [
  {
    email: 'admin@nortebound.ph',
    password: 'AdminPass123!',
    fullName: 'Norte Bound Curator',
    role: 'admin',
  },
  {
    email: 'tourist@nortebound.ph',
    password: 'TouristPass123!',
    fullName: 'Norte Bound Traveler',
    role: 'tourist',
  },
];

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
  return {
    config: { ...fromExample, ...fromEnv },
    envSource: fs.existsSync(ENV_PATH) ? 'backend/.env' : 'backend/.env.example',
  };
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

async function loadPg() {
  const candidates = [
    pathToFileURL(path.join(ROOT, 'backend/node_modules/pg/lib/index.js')).href,
    'pg',
  ];
  for (const candidate of candidates) {
    try {
      const mod = await import(candidate);
      return mod.default ?? mod;
    } catch {
      /* try next */
    }
  }
  throw new Error('pg is not installed. Run `npm install pg` inside backend/.');
}

async function loadBcrypt() {
  const candidates = [
    pathToFileURL(path.join(ROOT, 'backend/node_modules/bcrypt/bcrypt.js')).href,
    'bcrypt',
  ];
  for (const candidate of candidates) {
    try {
      const mod = await import(candidate);
      return mod.default ?? mod;
    } catch {
      /* try next */
    }
  }
  throw new Error('bcrypt is not installed. Run `npm install bcrypt` inside backend/.');
}

function isCommunityBasedDestination(dest) {
  const tags = Array.isArray(dest.interest_tags) ? dest.interest_tags : [];
  if (tags.includes('community-based') || tags.includes('local-craft') || tags.includes('indigenous-heritage')) {
    return true;
  }
  if (dest.category_code === 'artisan_craft_experience' || dest.category_code === 'agro_eco_tourism') {
    return true;
  }
  const text = `${dest.short_description ?? ''} ${dest.historical_background ?? ''}`.toLowerCase();
  return /cooperative|community|association|artisan|weav|pottery|barangay|farmers/.test(text);
}

async function seedLgus(client, lgus) {
  for (const lgu of lgus) {
    await client.query(
      `
        INSERT INTO public.lgus (
          lgu_code, name, lgu_type, tourism_cluster,
          center_latitude, center_longitude, terrain_type,
          road_tortuosity_multiplier, is_major_hub, baseline_dispersal_bonus
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        ON CONFLICT (lgu_code) DO UPDATE SET
          name = EXCLUDED.name,
          lgu_type = EXCLUDED.lgu_type,
          tourism_cluster = EXCLUDED.tourism_cluster,
          center_latitude = EXCLUDED.center_latitude,
          center_longitude = EXCLUDED.center_longitude,
          terrain_type = EXCLUDED.terrain_type,
          road_tortuosity_multiplier = EXCLUDED.road_tortuosity_multiplier,
          is_major_hub = EXCLUDED.is_major_hub,
          baseline_dispersal_bonus = EXCLUDED.baseline_dispersal_bonus
      `,
      [
        lgu.lgu_code,
        lgu.name,
        lgu.lgu_type,
        lgu.tourism_cluster,
        lgu.center_latitude,
        lgu.center_longitude,
        lgu.terrain_type,
        lgu.road_tortuosity_multiplier,
        Boolean(lgu.is_major_hub),
        lgu.baseline_dispersal_bonus,
      ],
    );
  }
  return lgus.length;
}

async function seedTaxonomy(client, taxonomy) {
  for (const category of taxonomy.categories) {
    await client.query(
      `
        INSERT INTO public.categories (category_code, name, description)
        VALUES ($1, $2, $3)
        ON CONFLICT (category_code) DO UPDATE SET
          name = EXCLUDED.name,
          description = EXCLUDED.description
      `,
      [category.category_code, category.label, category.description],
    );
  }

  for (const tag of taxonomy.interest_tags) {
    const primaryCategory = tag.related_categories?.[0] ?? null;
    if (!primaryCategory) {
      throw new Error(`Interest tag "${tag.tag_code}" has no related_categories.`);
    }
    await client.query(
      `
        INSERT INTO public.interest_tags (tag_slug, display_name, category_code, ai_synonyms)
        VALUES ($1, $2, $3, $4::jsonb)
        ON CONFLICT (tag_slug) DO UPDATE SET
          display_name = EXCLUDED.display_name,
          category_code = EXCLUDED.category_code,
          ai_synonyms = EXCLUDED.ai_synonyms
      `,
      [
        tag.tag_code,
        tag.label,
        primaryCategory,
        JSON.stringify(Array.isArray(tag.synonyms) ? tag.synonyms : []),
      ],
    );
  }

  return { categories: taxonomy.categories.length, tags: taxonomy.interest_tags.length };
}

async function seedDestinations(client, destinations) {
  const counts = { destinations: 0, tags: 0, hours: 0, pricing: 0 };

  for (const dest of destinations) {
    const vm = dest.verification_metadata || {};
    const coords = dest.coordinates || {};
    const dispersal = dest.dispersal_and_accessibility || {};
    const financials = dest.financials || {};
    const pacing = dest.duration_and_pacing || {};

    const res = await client.query(
      `
        INSERT INTO public.destinations (
          slug, name, lgu_code, category_code, description, historical_background,
          address, latitude, longitude, entity_type, popularity_tier,
          highway_accessible, road_condition, recommended_duration_minutes,
          best_time_of_day, is_community_based, verification_status,
          source_name, source_type, last_verified_date
        ) VALUES (
          $1, $2, $3, $4, $5, $6,
          $7, $8, $9, $10, $11,
          $12, $13, $14,
          $15, $16, $17,
          $18, $19, $20
        )
        ON CONFLICT (slug) DO UPDATE SET
          name = EXCLUDED.name,
          lgu_code = EXCLUDED.lgu_code,
          category_code = EXCLUDED.category_code,
          description = EXCLUDED.description,
          historical_background = EXCLUDED.historical_background,
          address = EXCLUDED.address,
          latitude = EXCLUDED.latitude,
          longitude = EXCLUDED.longitude,
          entity_type = EXCLUDED.entity_type,
          popularity_tier = EXCLUDED.popularity_tier,
          highway_accessible = EXCLUDED.highway_accessible,
          road_condition = EXCLUDED.road_condition,
          recommended_duration_minutes = EXCLUDED.recommended_duration_minutes,
          best_time_of_day = EXCLUDED.best_time_of_day,
          is_community_based = EXCLUDED.is_community_based,
          verification_status = EXCLUDED.verification_status,
          source_name = EXCLUDED.source_name,
          source_type = EXCLUDED.source_type,
          last_verified_date = EXCLUDED.last_verified_date
        RETURNING id
      `,
      [
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
        Boolean(dispersal.highway_accessible),
        dispersal.road_condition,
        Number(pacing.recommended_duration_minutes) || 60,
        pacing.best_time_of_day ?? null,
        isCommunityBasedDestination(dest),
        vm.verification_status,
        vm.source_name ?? null,
        vm.source_type ?? null,
        vm.last_verified_date ?? null,
      ],
    );
    const destinationId = res.rows[0].id;
    counts.destinations += 1;

    const tags = dest.interest_tags || [];
    if (tags.length > 0) {
      const tagValues = [];
      const tagPlaceholders = tags.map((t, idx) => {
        tagValues.push(destinationId, t);
        return `($${idx * 2 + 1}, $${idx * 2 + 2})`;
      });
      await client.query(
        `INSERT INTO public.destination_tags (destination_id, tag_slug) VALUES ${tagPlaceholders.join(', ')} ON CONFLICT DO NOTHING`,
        tagValues,
      );
      counts.tags += tags.length;
    }

    const schedule = dest.operating_schedule || [];
    if (schedule.length > 0) {
      const hourValues = [];
      const hourPlaceholders = schedule.map((slot, idx) => {
        hourValues.push(
          destinationId,
          slot.day_of_week,
          slot.open_time ?? null,
          slot.close_time ?? null,
          Boolean(slot.is_24_hours),
          Boolean(slot.temporarily_closed),
        );
        const b = idx * 6;
        return `($${b + 1}, $${b + 2}, $${b + 3}, $${b + 4}, $${b + 5}, $${b + 6})`;
      });
      await client.query(
        `
          INSERT INTO public.operating_hours (
            destination_id, day_of_week, opening_time, closing_time,
            is_24_hours, temporarily_closed
          ) VALUES ${hourPlaceholders.join(', ')}
          ON CONFLICT (destination_id, day_of_week) DO UPDATE SET
            opening_time = EXCLUDED.opening_time,
            closing_time = EXCLUDED.closing_time,
            is_24_hours = EXCLUDED.is_24_hours,
            temporarily_closed = EXCLUDED.temporarily_closed
        `,
        hourValues,
      );
      counts.hours += schedule.length;
    }

    await client.query(
      `
        INSERT INTO public.pricing_tiers (
          destination_id, entrance_fee_adult, entrance_fee_concession,
          mandatory_activity_fee, estimated_meal_min, estimated_meal_max,
          parking_fee, is_free, currency
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (destination_id) DO UPDATE SET
          entrance_fee_adult = EXCLUDED.entrance_fee_adult,
          entrance_fee_concession = EXCLUDED.entrance_fee_concession,
          mandatory_activity_fee = EXCLUDED.mandatory_activity_fee,
          estimated_meal_min = EXCLUDED.estimated_meal_min,
          estimated_meal_max = EXCLUDED.estimated_meal_max,
          parking_fee = EXCLUDED.parking_fee,
          is_free = EXCLUDED.is_free,
          currency = EXCLUDED.currency
      `,
      [
        destinationId,
        financials.entrance_fee_adult ?? 0,
        financials.entrance_fee_student_senior ?? 0,
        financials.mandatory_activity_fee ?? 0,
        financials.estimated_meal_cost_min ?? 0,
        financials.estimated_meal_cost_max ?? 0,
        financials.parking_fee ?? 0,
        Boolean(financials.is_free),
        'PHP',
      ],
    );
    counts.pricing += 1;
  }

  return counts;
}

async function seedUsers(client, bcrypt) {
  for (const user of SEEDED_USERS) {
    const passwordHash = await bcrypt.hash(user.password, 10);
    await client.query(
      `
        INSERT INTO public.users (email, password_hash, full_name, role)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (email) DO UPDATE SET
          password_hash = EXCLUDED.password_hash,
          full_name = EXCLUDED.full_name,
          role = EXCLUDED.role
      `,
      [user.email, passwordHash, user.fullName, user.role],
    );
  }
  return SEEDED_USERS.length;
}

async function main() {
  const { config, envSource } = loadConfig();
  const pg = await loadPg();
  const bcrypt = await loadBcrypt();

  const clientConfig = config.DATABASE_URL
    ? { connectionString: config.DATABASE_URL, ssl: { rejectUnauthorized: false } }
    : {
        host: config.DB_HOST,
        port: Number(config.DB_PORT) || 5432,
        user: config.DB_USER,
        password: config.DB_PASSWORD,
        database: config.DB_NAME || 'postgres',
        ssl: { rejectUnauthorized: false },
      };

  console.log('');
  console.log('==================================================================');
  console.log('  NORTE BOUND — SUPABASE POSTGRESQL SEEDER');
  console.log('==================================================================');
  log('⚙️', `Env source: ${envSource}`);
  log('🔌', `Target: ${config.SUPABASE_URL ?? config.DB_HOST}`);
  console.log('');

  const client = new pg.Client(clientConfig);
  try {
    await client.connect();
    log('✅', 'Connected to Supabase PostgreSQL.');

    const lgus = readJson(path.join(SEEDS_DIR, '01_lgus_registry.json'));
    const taxonomy = readJson(path.join(SEEDS_DIR, '02_taxonomy_categories_tags.json'));
    const destinations = readJson(path.join(SEEDS_DIR, '03_destinations_dataset.json'));

    await client.query('BEGIN');
    try {
      const lguCount = await seedLgus(client, lgus);
      log('✅', `Seeded LGUs: ${lguCount}`);

      const taxCounts = await seedTaxonomy(client, taxonomy);
      log('✅', `Seeded categories: ${taxCounts.categories}`);
      log('✅', `Seeded interest tags: ${taxCounts.tags}`);

      const destCounts = await seedDestinations(client, destinations);
      log('✅', `Seeded destinations: ${destCounts.destinations}`);
      log('✅', `Seeded destination tags: ${destCounts.tags}`);
      log('✅', `Seeded operating hours: ${destCounts.hours}`);
      log('✅', `Seeded pricing tiers: ${destCounts.pricing}`);

      const userCount = await seedUsers(client, bcrypt);
      log('✅', `Seeded default accounts: ${userCount}`);

      await client.query('COMMIT');
      log('✅', 'Seed transaction committed.');
    } catch (seedError) {
      await client.query('ROLLBACK');
      log('↩️', 'Seed transaction rolled back.');
      throw seedError;
    }

    console.log('');
    log('🎉', 'Supabase seeding completed successfully.');
    console.log('==================================================================');
  } catch (error) {
    console.error('');
    log('❌', `FATAL: ${error.message}`);
    process.exitCode = 1;
  } finally {
    await client.end();
    log('🔒', 'Supabase connection closed.');
  }
}

main();

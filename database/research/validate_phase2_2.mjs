import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '../..');

const LGU_PATH = path.join(ROOT, 'database/seeds/01_lgus_registry.json');
const TAX_PATH = path.join(ROOT, 'database/seeds/02_taxonomy_categories_tags.json');
const DEST_PATH = path.join(ROOT, 'database/seeds/03_destinations_dataset.json');

const ENTITY_TYPES = new Set(['attraction', 'food_establishment', 'cultural_experience', 'activity_hub']);
const BEST_TIMES = new Set(['morning', 'midday', 'afternoon', 'sunset', 'any']);
const MEAL_WINDOWS = new Set(['breakfast', 'lunch', 'merienda', 'dinner']);
const POPULARITY = new Set(['iconic_hub', 'moderate', 'hidden_gem']);
const ROADS = new Set(['paved_all_weather', 'rough_patch', '4x4_or_trek_required']);
const VERIF = new Set(['verified', 'needs_field_verification']);
const SOURCES = new Set(['provincial_tourism', 'lgu_official', 'dot_accredited', 'verified_establishment']);
const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

const LAT_MIN = 17.80, LAT_MAX = 18.68, LNG_MIN = 120.40, LNG_MAX = 121.05;

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function isNonNegNum(v) {
  return typeof v === 'number' && Number.isFinite(v) && v >= 0;
}

const lgus = readJson(LGU_PATH);
const taxonomy = readJson(TAX_PATH);
const destinations = readJson(DEST_PATH);

const lguByCode = new Map(lgus.map((l) => [l.lgu_code, l]));
const categorySet = new Set(taxonomy.categories.map((c) => c.category_code));
const tagSet = new Set(taxonomy.interest_tags.map((t) => t.tag_code));

const errors = [];

if (!Array.isArray(destinations)) {
  console.error('FATAL: 03_destinations_dataset.json must be a JSON array.');
  process.exit(1);
}

if (destinations.length < 55 || destinations.length > 69) {
  errors.push(`Dataset must contain 55-69 records; found ${destinations.length}.`);
}

const seenCodes = new Map();
const seenNames = new Map();
const seenCoords = new Map();
const perLgu = new Map();

for (const d of destinations) {
  const label = d?.destination_code || d?.name || 'unknown-record';

  const required = [
    'destination_code', 'name', 'entity_type', 'lgu_code', 'category_code',
    'interest_tags', 'short_description', 'coordinates', 'operating_schedule',
    'financials', 'duration_and_pacing', 'dispersal_and_accessibility', 'verification_metadata'
  ];
  for (const key of required) {
    if (d[key] === undefined || d[key] === null) {
      errors.push(`[${label}] missing required field "${key}".`);
    }
  }
  if (errors.length > 200) break;

  if (typeof d.destination_code !== 'string' || !/^[a-z0-9-]+$/.test(d.destination_code)) {
    errors.push(`[${label}] destination_code must be a lowercase slug.`);
  }
  if (seenCodes.has(d.destination_code)) errors.push(`Duplicate destination_code: ${d.destination_code}`);
  seenCodes.set(d.destination_code, true);

  if (typeof d.name !== 'string' || d.name.trim() === '') {
    errors.push(`[${label}] name must be a non-empty string.`);
  }
  const nameKey = String(d.name || '').trim().toLowerCase();
  if (seenNames.has(nameKey)) errors.push(`Duplicate name: ${d.name}`);
  seenNames.set(nameKey, true);

  if (!ENTITY_TYPES.has(d.entity_type)) errors.push(`[${label}] invalid entity_type "${d.entity_type}".`);

  const lgu = lguByCode.get(d.lgu_code);
  if (!lgu) {
    errors.push(`[${label}] unknown lgu_code "${d.lgu_code}".`);
  } else {
    const c = d.coordinates || {};
    if (typeof c.latitude !== 'number' || c.latitude < LAT_MIN || c.latitude > LAT_MAX) {
      errors.push(`[${label}] latitude ${c.latitude} outside Ilocos Norte bounds [${LAT_MIN}, ${LAT_MAX}].`);
    }
    if (typeof c.longitude !== 'number' || c.longitude < LNG_MIN || c.longitude > LNG_MAX) {
      errors.push(`[${label}] longitude ${c.longitude} outside Ilocos Norte bounds [${LNG_MIN}, ${LNG_MAX}].`);
    }
    const coordKey = `${c.latitude},${c.longitude}`;
    if (seenCoords.has(coordKey)) {
      errors.push(`Duplicate coordinates ${coordKey} shared by "${label}" and "${seenCoords.get(coordKey)}".`);
    }
    seenCoords.set(coordKey, label);

    if (!perLgu.has(d.lgu_code)) perLgu.set(d.lgu_code, []);
    perLgu.get(d.lgu_code).push(d);
  }

  if (!categorySet.has(d.category_code)) errors.push(`[${label}] category_code "${d.category_code}" not in taxonomy.`);

  if (!Array.isArray(d.interest_tags) || d.interest_tags.length === 0) {
    errors.push(`[${label}] interest_tags must be a non-empty array.`);
  } else {
    const localTags = new Set();
    for (const tag of d.interest_tags) {
      if (!tagSet.has(tag)) errors.push(`[${label}] interest tag "${tag}" not in taxonomy.`);
      if (localTags.has(tag)) errors.push(`[${label}] duplicate interest tag "${tag}".`);
      localTags.add(tag);
    }
  }

  if (!Array.isArray(d.operating_schedule) || d.operating_schedule.length !== 7) {
    errors.push(`[${label}] operating_schedule must have exactly 7 day entries.`);
  } else {
    const days = new Set();
    for (const slot of d.operating_schedule) {
      const sLabel = `[${label}] day ${slot?.day_of_week}`;
      if (!Number.isInteger(slot.day_of_week) || slot.day_of_week < 0 || slot.day_of_week > 6) {
        errors.push(`${sLabel}: invalid day_of_week.`);
      }
      if (days.has(slot.day_of_week)) errors.push(`[${label}] duplicate day_of_week ${slot.day_of_week}.`);
      days.add(slot.day_of_week);
      if (typeof slot.open_time !== 'string' || !TIME_RE.test(slot.open_time)) {
        errors.push(`${sLabel}: invalid open_time "${slot.open_time}".`);
      }
      if (typeof slot.close_time !== 'string' || !TIME_RE.test(slot.close_time)) {
        errors.push(`${sLabel}: invalid close_time "${slot.close_time}".`);
      }
      if (typeof slot.is_24_hours !== 'boolean') errors.push(`${sLabel}: is_24_hours must be boolean.`);
      if (typeof slot.temporarily_closed !== 'boolean') errors.push(`${sLabel}: temporarily_closed must be boolean.`);
    }
  }

  const f = d.financials || {};
  for (const key of ['entrance_fee_adult', 'entrance_fee_student_senior', 'mandatory_activity_fee', 'estimated_meal_cost_min', 'estimated_meal_cost_max', 'parking_fee']) {
    if (!isNonNegNum(f[key])) errors.push(`[${label}] financials.${key} must be a non-negative number.`);
  }
  if (typeof f.is_free !== 'boolean') errors.push(`[${label}] financials.is_free must be boolean.`);
  if (
    typeof f.is_free === 'boolean' &&
    f.is_free === true &&
    (f.entrance_fee_adult > 0 || f.entrance_fee_student_senior > 0 || f.mandatory_activity_fee > 0)
  ) {
    errors.push(`[${label}] is_free=true but a mandatory fee is greater than zero.`);
  }

  const dp = d.duration_and_pacing || {};
  if (!Number.isInteger(dp.recommended_duration_minutes) || dp.recommended_duration_minutes <= 0) {
    errors.push(`[${label}] recommended_duration_minutes must be a positive integer.`);
  }
  if (!BEST_TIMES.has(dp.best_time_of_day)) errors.push(`[${label}] invalid best_time_of_day "${dp.best_time_of_day}".`);
  if (!Array.isArray(dp.meal_window_compatibility)) {
    errors.push(`[${label}] meal_window_compatibility must be an array.`);
  } else {
    for (const w of dp.meal_window_compatibility) {
      if (!MEAL_WINDOWS.has(w)) errors.push(`[${label}] invalid meal window "${w}".`);
    }
  }

  const da = d.dispersal_and_accessibility || {};
  if (!POPULARITY.has(da.popularity_tier)) errors.push(`[${label}] invalid popularity_tier "${da.popularity_tier}".`);
  if (typeof da.highway_accessible !== 'boolean') errors.push(`[${label}] highway_accessible must be boolean.`);
  if (!ROADS.has(da.road_condition)) errors.push(`[${label}] invalid road_condition "${da.road_condition}".`);

  const vm = d.verification_metadata || {};
  if (!VERIF.has(vm.verification_status)) errors.push(`[${label}] invalid verification_status "${vm.verification_status}".`);
  if (typeof vm.source_name !== 'string' || vm.source_name.trim() === '') errors.push(`[${label}] source_name required.`);
  if (!SOURCES.has(vm.source_type)) errors.push(`[${label}] invalid source_type "${vm.source_type}".`);
  if (typeof vm.last_verified_date !== 'string' || !DATE_RE.test(vm.last_verified_date)) {
    errors.push(`[${label}] last_verified_date must be YYYY-MM-DD.`);
  }
}

for (const lgu of lgus) {
  const list = perLgu.get(lgu.lgu_code) || [];
  if (list.length < 2) {
    errors.push(`LGU coverage failure: ${lgu.lgu_code} (${lgu.name}) has ${list.length} record(s), minimum is 2.`);
  }
}

const LGU_MIN = 2;
const lguCount = perLgu.size;

const pad = (v, n) => String(v).padEnd(n, ' ');
const padL = (v, n) => String(v).padStart(n, ' ');

console.log('');
console.log('==========================================================================================');
console.log('  NORTE BOUND — PHASE 2.2 TOURISM DATASET AUDIT');
console.log('==========================================================================================');
console.log(`  Dataset records      : ${destinations.length}`);
console.log(`  LGU coverage         : ${lguCount}/${lgus.length} (minimum ${LGU_MIN} per LGU)`);
console.log(`  Categories (taxonomy): ${categorySet.size}`);
console.log(`  Interest tags        : ${tagSet.size}`);
console.log('');

const header = `${pad('LGU CODE', 16)} ${pad('LGU NAME', 22)} ${pad('CLUSTER', 24)} ${padL('RECS', 5)}  ${pad('CATEGORIES', 44)} TAGS`;
console.log(header);
console.log('-'.repeat(126));

let totalTags = 0;
const circuitTotals = new Map();

for (const lgu of lgus) {
  const list = perLgu.get(lgu.lgu_code) || [];
  const cats = [...new Set(list.map((r) => r.category_code))].join(', ');
  const tagCount = list.reduce((acc, r) => acc + r.interest_tags.length, 0);
  totalTags += tagCount;
  circuitTotals.set(lgu.tourism_cluster, (circuitTotals.get(lgu.tourism_cluster) || 0) + list.length);
  console.log(
    `${pad(lgu.lgu_code, 16)} ${pad(lgu.name, 22)} ${pad(lgu.tourism_cluster, 24)} ${padL(list.length, 5)}  ${pad(cats || '(none)', 44)} ${tagCount}`
  );
}

console.log('-'.repeat(126));
console.log('');
console.log('Circuit Distribution:');
for (const [cluster, count] of circuitTotals) {
  console.log(`  - ${pad(cluster, 26)} ${padL(count, 3)} records`);
}
console.log('');

const verified = destinations.filter((d) => d.verification_metadata.verification_status === 'verified').length;
const needs = destinations.length - verified;
console.log(`Verification status  : ${verified} verified / ${needs} needs_field_verification`);
console.log(`Total interest tags  : ${totalTags}`);
console.log('');

if (errors.length > 0) {
  console.error(`RESULT: FAILED — ${errors.length} error(s) detected.`);
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log('RESULT: PASSED — 0 errors. Dataset conforms to Phase 2.1 schema, taxonomy, and 23-LGU coverage rules.');
console.log('==========================================================================================');

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '../..');

const LGU_REGISTRY_PATH = path.join(ROOT_DIR, 'database/seeds/01_lgus_registry.json');
const TAXONOMY_PATH = path.join(ROOT_DIR, 'database/seeds/02_taxonomy_categories_tags.json');
const TEMPLATE_PATH = path.join(ROOT_DIR, 'database/research/destination_schema_template.json');

const EXPECTED_LGUS = [
  'adams',
  'bacarra',
  'badoc',
  'bangui',
  'banna',
  'batac-city',
  'burgos',
  'carasi',
  'currimao',
  'dingras',
  'dumalneg',
  'laoag-city',
  'marcos',
  'nueva-era',
  'pagudpud',
  'paoay',
  'pasuquin',
  'piddig',
  'pinili',
  'san-nicolas',
  'sarrat',
  'solsona',
  'vintar'
];

const VALID_CLUSTERS = new Set([
  'northern_coast',
  'central_urban_heritage',
  'southern_heritage_coast',
  'eastern_agri_highland'
]);

const VALID_TERRAINS = new Set([
  'flat_coastal',
  'rolling_inland',
  'mountainous_winding'
]);

const VALID_LGU_TYPES = new Set(['municipality', 'component_city']);

const EXPECTED_MAJOR_HUBS = new Set([
  'laoag-city',
  'pagudpud',
  'paoay',
  'batac-city',
  'burgos'
]);

const EXPECTED_CATEGORIES = new Set([
  'natural_attraction',
  'heritage_cultural',
  'food_culinary',
  'agro_eco_tourism',
  'artisan_craft_experience',
  'recreation_adventure'
]);

const EXPECTED_TRANSPORT_MODES = new Set([
  'motorcycle',
  'private_car',
  'public_commute'
]);

const LAT_MIN = 17.80;
const LAT_MAX = 18.68;
const LNG_MIN = 120.40;
const LNG_MAX = 121.05;

const errors = [];

function readJson(filePath) {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    errors.push(`Failed to read/parse JSON at ${filePath}: ${err.message}`);
    return null;
  }
}

function validateLguRegistry(lgus) {
  if (!Array.isArray(lgus)) {
    errors.push('01_lgus_registry.json must be a JSON array.');
    return;
  }

  if (lgus.length !== 23) {
    errors.push(`Expected exactly 23 LGUs in 01_lgus_registry.json, found ${lgus.length}.`);
  }

  const seenCodes = new Set();
  let cityCount = 0;
  let municipalityCount = 0;

  for (const lgu of lgus) {
    const label = lgu?.lgu_code || lgu?.name || 'unknown';

    if (!lgu.lgu_code || typeof lgu.lgu_code !== 'string') {
      errors.push(`LGU missing valid string lgu_code: ${JSON.stringify(lgu)}`);
      continue;
    }

    if (seenCodes.has(lgu.lgu_code)) {
      errors.push(`Duplicate lgu_code found: ${lgu.lgu_code}`);
    }
    seenCodes.add(lgu.lgu_code);

    if (!lgu.name || typeof lgu.name !== 'string') {
      errors.push(`[${label}] Missing valid name.`);
    }

    if (!VALID_LGU_TYPES.has(lgu.lgu_type)) {
      errors.push(`[${label}] Invalid lgu_type: ${lgu.lgu_type}`);
    } else if (lgu.lgu_type === 'component_city') {
      cityCount += 1;
    } else {
      municipalityCount += 1;
    }

    if (lgu.psgc_province !== 'Ilocos Norte') {
      errors.push(`[${label}] psgc_province must be "Ilocos Norte", got "${lgu.psgc_province}".`);
    }

    if (!VALID_CLUSTERS.has(lgu.tourism_cluster)) {
      errors.push(`[${label}] Invalid tourism_cluster: ${lgu.tourism_cluster}`);
    }

    if (
      typeof lgu.center_latitude !== 'number' ||
      lgu.center_latitude < LAT_MIN ||
      lgu.center_latitude > LAT_MAX
    ) {
      errors.push(
        `[${label}] center_latitude (${lgu.center_latitude}) out of bounds [${LAT_MIN}, ${LAT_MAX}].`
      );
    }

    if (
      typeof lgu.center_longitude !== 'number' ||
      lgu.center_longitude < LNG_MIN ||
      lgu.center_longitude > LNG_MAX
    ) {
      errors.push(
        `[${label}] center_longitude (${lgu.center_longitude}) out of bounds [${LNG_MIN}, ${LNG_MAX}].`
      );
    }

    if (!VALID_TERRAINS.has(lgu.terrain_type)) {
      errors.push(`[${label}] Invalid terrain_type: ${lgu.terrain_type}`);
    }

    if (
      typeof lgu.road_tortuosity_multiplier !== 'number' ||
      lgu.road_tortuosity_multiplier < 1.20 ||
      lgu.road_tortuosity_multiplier > 1.60
    ) {
      errors.push(
        `[${label}] road_tortuosity_multiplier (${lgu.road_tortuosity_multiplier}) must be within [1.20, 1.60].`
      );
    }

    if (typeof lgu.is_major_hub !== 'boolean') {
      errors.push(`[${label}] is_major_hub must be a boolean.`);
    } else {
      const shouldBeHub = EXPECTED_MAJOR_HUBS.has(lgu.lgu_code);
      if (lgu.is_major_hub !== shouldBeHub) {
        errors.push(
          `[${label}] is_major_hub is ${lgu.is_major_hub}, expected ${shouldBeHub}.`
        );
      }
    }

    if (
      typeof lgu.baseline_dispersal_bonus !== 'number' ||
      lgu.baseline_dispersal_bonus < 0.0 ||
      lgu.baseline_dispersal_bonus > 1.0
    ) {
      errors.push(
        `[${label}] baseline_dispersal_bonus (${lgu.baseline_dispersal_bonus}) must be within [0.0, 1.0].`
      );
    }
  }

  for (const expectedCode of EXPECTED_LGUS) {
    if (!seenCodes.has(expectedCode)) {
      errors.push(`Missing required LGU code: ${expectedCode}`);
    }
  }

  if (cityCount !== 2 || municipalityCount !== 21) {
    errors.push(
      `Expected 2 component cities and 21 municipalities, found ${cityCount} cities and ${municipalityCount} municipalities.`
    );
  }
}

function validateTaxonomy(taxonomy) {
  if (!taxonomy || typeof taxonomy !== 'object') {
    errors.push('02_taxonomy_categories_tags.json must be a JSON object.');
    return;
  }

  // Categories
  if (!Array.isArray(taxonomy.categories)) {
    errors.push('taxonomy.categories must be an array.');
  } else {
    const catCodes = new Set();
    for (const cat of taxonomy.categories) {
      if (!cat.category_code || typeof cat.category_code !== 'string') {
        errors.push(`Category missing valid category_code: ${JSON.stringify(cat)}`);
        continue;
      }
      if (catCodes.has(cat.category_code)) {
        errors.push(`Duplicate category_code: ${cat.category_code}`);
      }
      catCodes.add(cat.category_code);
      if (!cat.label || !cat.description) {
        errors.push(`Category [${cat.category_code}] missing label or description.`);
      }
    }
    for (const expectedCat of EXPECTED_CATEGORIES) {
      if (!catCodes.has(expectedCat)) {
        errors.push(`Missing required category_code: ${expectedCat}`);
      }
    }
  }

  // Interest Tags
  if (!Array.isArray(taxonomy.interest_tags)) {
    errors.push('taxonomy.interest_tags must be an array.');
  } else {
    if (taxonomy.interest_tags.length < 25) {
      errors.push(
        `Expected at least 25 interest_tags, found ${taxonomy.interest_tags.length}.`
      );
    }
    const tagCodes = new Set();
    for (const tag of taxonomy.interest_tags) {
      if (!tag.tag_code || typeof tag.tag_code !== 'string') {
        errors.push(`Interest tag missing valid tag_code: ${JSON.stringify(tag)}`);
        continue;
      }
      if (tagCodes.has(tag.tag_code)) {
        errors.push(`Duplicate tag_code: ${tag.tag_code}`);
      }
      tagCodes.add(tag.tag_code);
      if (!tag.label || !Array.isArray(tag.related_categories) || tag.related_categories.length === 0) {
        errors.push(`Tag [${tag.tag_code}] missing label or related_categories.`);
      } else {
        for (const relCat of tag.related_categories) {
          if (!EXPECTED_CATEGORIES.has(relCat)) {
            errors.push(`Tag [${tag.tag_code}] references unknown category "${relCat}".`);
          }
        }
      }
    }
  }

  // Transport Modes
  if (!Array.isArray(taxonomy.transport_modes)) {
    errors.push('taxonomy.transport_modes must be an array.');
  } else {
    const modeCodes = new Set();
    for (const mode of taxonomy.transport_modes) {
      if (!mode.mode_code || typeof mode.mode_code !== 'string') {
        errors.push(`Transport mode missing valid mode_code: ${JSON.stringify(mode)}`);
        continue;
      }
      if (modeCodes.has(mode.mode_code)) {
        errors.push(`Duplicate mode_code: ${mode.mode_code}`);
      }
      modeCodes.add(mode.mode_code);
      if (typeof mode.avg_speed_kmh !== 'number' || mode.avg_speed_kmh <= 0) {
        errors.push(`Transport mode [${mode.mode_code}] has invalid avg_speed_kmh.`);
      }
      if (
        typeof mode.estimated_cost_per_km_php !== 'number' ||
        mode.estimated_cost_per_km_php < 0
      ) {
        errors.push(
          `Transport mode [${mode.mode_code}] has invalid estimated_cost_per_km_php.`
        );
      }
      if (typeof mode.requires_highway_accessible !== 'boolean') {
        errors.push(
          `Transport mode [${mode.mode_code}] missing boolean requires_highway_accessible.`
        );
      }
    }
    for (const expectedMode of EXPECTED_TRANSPORT_MODES) {
      if (!modeCodes.has(expectedMode)) {
        errors.push(`Missing required transport mode: ${expectedMode}`);
      }
    }
  }
}

function validateTemplate(template) {
  if (!template || typeof template !== 'object' || !template.record_template) {
    errors.push('destination_schema_template.json must contain record_template.');
    return;
  }

  const rec = template.record_template;
  if (!Array.isArray(rec.operating_schedule) || rec.operating_schedule.length !== 7) {
    errors.push('destination_schema_template.json operating_schedule must cover all 7 days (0-6).');
  }
  if (!EXPECTED_LGUS.includes(rec.lgu_code)) {
    errors.push(`Template sample lgu_code "${rec.lgu_code}" is not in the 23-LGU registry.`);
  }
  if (!EXPECTED_CATEGORIES.has(rec.category_code)) {
    errors.push(`Template sample category_code "${rec.category_code}" is invalid.`);
  }
}

const lgus = readJson(LGU_REGISTRY_PATH);
const taxonomy = readJson(TAXONOMY_PATH);
const template = readJson(TEMPLATE_PATH);

if (lgus) validateLguRegistry(lgus);
if (taxonomy) validateTaxonomy(taxonomy);
if (template) validateTemplate(template);

if (errors.length > 0) {
  console.error('❌ Phase 2.1 Validation FAILED with errors:');
  for (const err of errors) {
    console.error(`  - ${err}`);
  }
  process.exit(1);
}

console.log('✅ Phase 2.1 Validation PASSED (0 errors)');
console.log(`   - LGUs verified: ${lgus.length} (2 component cities, 21 municipalities)`);
console.log(`   - Categories verified: ${taxonomy.categories.length}`);
console.log(`   - Interest tags verified: ${taxonomy.interest_tags.length}`);
console.log(`   - Transport modes verified: ${taxonomy.transport_modes.length}`);
console.log('   - Destination schema template verified: valid');

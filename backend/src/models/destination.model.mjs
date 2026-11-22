import { query } from '../config/db.mjs';

const DESTINATION_ORDER = `
  CASE d.popularity_tier
    WHEN 'iconic_hub' THEN 1
    WHEN 'moderate' THEN 2
    WHEN 'hidden_gem' THEN 3
    ELSE 4
  END,
  d.name ASC
`;

const DESTINATION_COLUMNS = `
  d.id,
  d.slug,
  d.name,
  d.lgu_code,
  l.name AS lgu_name,
  l.tourism_cluster,
  d.category_code,
  c.name AS category_name,
  d.description,
  d.address,
  d.latitude,
  d.longitude,
  d.image_url,
  d.entity_type,
  d.popularity_tier,
  d.highway_accessible,
  d.road_condition,
  d.recommended_duration_minutes,
  d.best_time_of_day,
  d.is_community_based,
  d.verification_status,
  d.source_name,
  d.source_type,
  d.last_verified_date,
  p.entrance_fee_adult,
  p.entrance_fee_concession,
  p.mandatory_activity_fee,
  p.estimated_meal_min,
  p.estimated_meal_max,
  p.parking_fee,
  p.is_free,
  p.currency
`;

const LIST_SELECT = `
  ${DESTINATION_COLUMNS},
  tag_agg.tags
`;

const DETAIL_SELECT = `
  ${DESTINATION_COLUMNS},
  tag_agg.tags,
  d.historical_background,
  d.created_at,
  d.updated_at,
  l.lgu_type,
  l.center_latitude AS lgu_center_latitude,
  l.center_longitude AS lgu_center_longitude,
  l.terrain_type,
  l.road_tortuosity_multiplier,
  l.is_major_hub,
  l.baseline_dispersal_bonus,
  c.description AS category_description
`;

const TAG_AGGREGATE_JOIN = `
  LEFT JOIN (
    SELECT
      dt.destination_id,
      JSON_AGG(
        JSON_BUILD_OBJECT('slug', it.tag_slug, 'name', it.display_name)
        ORDER BY it.display_name
      ) AS tags
    FROM destination_tags dt
    INNER JOIN interest_tags it ON it.tag_slug = dt.tag_slug
    GROUP BY dt.destination_id
  ) tag_agg ON tag_agg.destination_id = d.id
`;

const BASE_JOINS = `
  FROM destinations d
  INNER JOIN lgus l ON l.lgu_code = d.lgu_code
  INNER JOIN categories c ON c.category_code = d.category_code
  LEFT JOIN pricing_tiers p ON p.destination_id = d.id
`;

function escapeLike(value) {
  return value.replace(/[!%_]/g, '!$&');
}

function buildFilters(filters = {}) {
  const conditions = [];
  const params = [];

  if (filters.lgu_code) {
    conditions.push('d.lgu_code = ?');
    params.push(filters.lgu_code);
  }

  if (filters.cluster) {
    conditions.push('l.tourism_cluster = ?');
    params.push(filters.cluster);
  }

  if (filters.category_code) {
    conditions.push('d.category_code = ?');
    params.push(filters.category_code);
  }

  if (filters.popularity_tier) {
    conditions.push('d.popularity_tier = ?');
    params.push(filters.popularity_tier);
  }

  if (filters.is_free !== undefined && filters.is_free !== null) {
    conditions.push('p.is_free = ?');
    params.push(Boolean(filters.is_free));
  }

  if (filters.q) {
    const term = `%${escapeLike(filters.q)}%`;
    conditions.push("(d.name ILIKE ? ESCAPE '!' OR d.description ILIKE ? ESCAPE '!')");
    params.push(term, term);
  }

  return {
    where: conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '',
    params,
  };
}

export async function getAllDestinations(filters = {}) {
  const page = Number.isInteger(filters.page) && filters.page > 0 ? filters.page : 1;
  const limit = Number.isInteger(filters.limit) && filters.limit > 0
    ? Math.min(filters.limit, 100)
    : 20;
  const offset = (page - 1) * limit;

  const { where, params } = buildFilters(filters);

  const countSql = `
    SELECT COUNT(*) AS total
    ${BASE_JOINS}
    ${where}
  `;

  const listSql = `
    SELECT
      ${LIST_SELECT}
    ${BASE_JOINS}
    ${TAG_AGGREGATE_JOIN}
    ${where}
    ORDER BY ${DESTINATION_ORDER}
    LIMIT ? OFFSET ?
  `;

  const [countRows, rows] = await Promise.all([
    query(countSql, params),
    query(listSql, [...params, limit, offset]),
  ]);

  return {
    rows,
    total: Number(countRows[0]?.total ?? 0),
    page,
    limit,
  };
}

export async function getDestinationBySlug(slug) {
  const detailSql = `
    SELECT
      ${DETAIL_SELECT}
    ${BASE_JOINS}
    ${TAG_AGGREGATE_JOIN}
    WHERE d.slug = ?
    LIMIT 1
  `;

  const rows = await query(detailSql, [slug]);

  if (rows.length === 0) {
    return null;
  }

  const destination = rows[0];

  const hoursSql = `
    SELECT
      day_of_week,
      opening_time,
      closing_time,
      is_24_hours,
      temporarily_closed
    FROM operating_hours
    WHERE destination_id = ?
    ORDER BY day_of_week ASC
  `;

  const tagsSql = `
    SELECT
      it.tag_slug,
      it.display_name,
      it.category_code
    FROM destination_tags dt
    INNER JOIN interest_tags it ON it.tag_slug = dt.tag_slug
    WHERE dt.destination_id = ?
    ORDER BY it.display_name ASC
  `;

  const [operatingHours, tags] = await Promise.all([
    query(hoursSql, [destination.id]),
    query(tagsSql, [destination.id]),
  ]);

  return {
    destination,
    operatingHours,
    tags,
  };
}

export async function getAllLgus() {
  return query(`
    SELECT
      lgu_code,
      name,
      lgu_type,
      tourism_cluster,
      center_latitude,
      center_longitude,
      terrain_type,
      road_tortuosity_multiplier,
      is_major_hub,
      baseline_dispersal_bonus
    FROM lgus
    ORDER BY tourism_cluster ASC, name ASC
  `);
}

export async function getAllCategoriesAndTags() {
  const categoriesSql = `
    SELECT category_code, name, description
    FROM categories
    ORDER BY name ASC
  `;

  const tagsSql = `
    SELECT tag_slug, display_name, category_code, ai_synonyms
    FROM interest_tags
    ORDER BY display_name ASC
  `;

  const [categories, tags] = await Promise.all([
    query(categoriesSql),
    query(tagsSql),
  ]);

  return { categories, tags };
}

const DAY_NAMES = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

export function toNumber(value) {
  return value === null || value === undefined ? null : Number(value);
}

export function toBoolean(value) {
  return value === true || value === 1 || value === '1';
}

export function formatDate(value) {
  if (!value) {
    return null;
  }

  if (value instanceof Date) {
    const year = value.getFullYear();
    const month = String(value.getMonth() + 1).padStart(2, '0');
    const day = String(value.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  return String(value).slice(0, 10);
}

export function formatTimestamp(value) {
  if (!value) {
    return null;
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? String(value) : date.toISOString();
}

export function formatTime(value) {
  if (!value) {
    return null;
  }

  return String(value).slice(0, 5);
}

export function parseJsonArray(value) {
  if (!value) {
    return [];
  }

  let parsed = value;

  if (Buffer.isBuffer(parsed)) {
    parsed = parsed.toString('utf8');
  }

  if (typeof parsed === 'string') {
    try {
      parsed = JSON.parse(parsed);
    } catch {
      return [];
    }
  }

  return Array.isArray(parsed) ? parsed : [];
}

export function humanize(value) {
  return String(value)
    .split('_')
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function mapPricing(row) {
  return {
    entranceFeeAdult: toNumber(row.entrance_fee_adult),
    entranceFeeConcession: toNumber(row.entrance_fee_concession),
    mandatoryActivityFee: toNumber(row.mandatory_activity_fee),
    estimatedMealMin: toNumber(row.estimated_meal_min),
    estimatedMealMax: toNumber(row.estimated_meal_max),
    parkingFee: toNumber(row.parking_fee),
    isFree: toBoolean(row.is_free),
    currency: row.currency || 'PHP',
  };
}

function mapVerification(row) {
  return {
    status: row.verification_status,
    sourceName: row.source_name,
    sourceType: row.source_type,
    lastVerifiedDate: formatDate(row.last_verified_date),
  };
}

function mapAggregatedTags(value) {
  let tags = value;

  if (Buffer.isBuffer(tags)) {
    tags = tags.toString('utf8');
  }

  if (typeof tags === 'string') {
    try {
      tags = JSON.parse(tags);
    } catch {
      return [];
    }
  }

  if (!Array.isArray(tags)) {
    return [];
  }

  return tags.map((tag) => ({
    slug: tag.slug ?? tag.tag_slug ?? null,
    name: tag.name ?? tag.display_name ?? null,
  }));
}

export function toDestinationSummary(row) {
  return {
    id: row.id,
    slug: row.slug,
    name: row.name,
    lgu: {
      code: row.lgu_code,
      name: row.lgu_name,
      cluster: row.tourism_cluster,
    },
    category: {
      code: row.category_code,
      name: row.category_name,
    },
    description: row.description,
    address: row.address,
    coordinates: {
      latitude: toNumber(row.latitude),
      longitude: toNumber(row.longitude),
    },
    imageUrl: row.image_url ?? null,
    entityType: row.entity_type,
    popularityTier: row.popularity_tier,
    highwayAccessible: toBoolean(row.highway_accessible),
    roadCondition: row.road_condition,
    recommendedDurationMinutes: toNumber(row.recommended_duration_minutes) ?? 60,
    bestTimeOfDay: row.best_time_of_day ?? null,
    isCommunityBased: toBoolean(row.is_community_based),
    verification: mapVerification(row),
    pricing: mapPricing(row),
    tags: mapAggregatedTags(row.tags),
  };
}

export function toDestinationDetail(destination, operatingHours, tags) {
  const summary = toDestinationSummary(destination);

  return {
    ...summary,
    historicalBackground: destination.historical_background,
    lgu: {
      ...summary.lgu,
      type: destination.lgu_type,
      center: {
        latitude: toNumber(destination.lgu_center_latitude),
        longitude: toNumber(destination.lgu_center_longitude),
      },
      terrainType: destination.terrain_type,
      roadTortuosityMultiplier: toNumber(destination.road_tortuosity_multiplier),
      isMajorHub: toBoolean(destination.is_major_hub),
      baselineDispersalBonus: toNumber(destination.baseline_dispersal_bonus),
    },
    category: {
      ...summary.category,
      description: destination.category_description,
    },
    operatingHours: operatingHours.map((slot) => ({
      dayOfWeek: slot.day_of_week,
      dayName: DAY_NAMES[slot.day_of_week] ?? null,
      openingTime: formatTime(slot.opening_time),
      closingTime: formatTime(slot.closing_time),
      is24Hours: toBoolean(slot.is_24_hours),
      temporarilyClosed: toBoolean(slot.temporarily_closed),
    })),
    tags: tags.map((tag) => ({
      slug: tag.tag_slug,
      name: tag.display_name,
      categoryCode: tag.category_code,
    })),
    createdAt: formatTimestamp(destination.created_at),
    updatedAt: formatTimestamp(destination.updated_at),
  };
}

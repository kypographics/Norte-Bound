import { query } from '../config/db.mjs';
import { formatTime, toBoolean, toNumber } from '../utils/destination.mapper.mjs';
import { estimateTravelLeg, haversineKm, toMinutes } from '../utils/geo.matrix.mjs';

const PHILIPPINE_ORIGINS = {
  manila: { name: 'Metro Manila', latitude: 14.5995, longitude: 120.9842, entryGatewayLgu: 'badoc' },
  'quezon-city': { name: 'Quezon City', latitude: 14.676, longitude: 121.0437, entryGatewayLgu: 'badoc' },
  'baguio-city': { name: 'Baguio City', latitude: 16.4023, longitude: 120.596, entryGatewayLgu: 'badoc' },
  'vigan-city': { name: 'Vigan City', latitude: 17.5747, longitude: 120.3869, entryGatewayLgu: 'badoc' },
  'la-union': { name: 'San Fernando, La Union', latitude: 16.6159, longitude: 120.3209, entryGatewayLgu: 'badoc' },
  pangasinan: { name: 'Dagupan, Pangasinan', latitude: 16.0433, longitude: 120.3333, entryGatewayLgu: 'badoc' },
  'clark-pampanga': { name: 'Clark / Angeles, Pampanga', latitude: 15.1859, longitude: 120.56, entryGatewayLgu: 'badoc' },
  'tuguegarao-city': { name: 'Tuguegarao City', latitude: 17.6132, longitude: 121.727, entryGatewayLgu: 'pagudpud' },
  'claveria-cagayan': { name: 'Claveria / Sanchez Mira', latitude: 18.6067, longitude: 121.0831, entryGatewayLgu: 'pagudpud' },
  'cebu-city': { name: 'Cebu City', latitude: 10.3157, longitude: 123.8854, entryGatewayLgu: 'laoag-city' },
  'davao-city': { name: 'Davao City', latitude: 7.1907, longitude: 125.4553, entryGatewayLgu: 'laoag-city' },
};

const SCENERY_LABELS = {
  coastal: 'Coastal scenery',
  highland: 'Highland scenery',
  heritage_urban: 'Heritage setting',
  rural_agro: 'Rural & agro setting',
};

const SCENERY_PATTERNS = {
  coastal: /\b(beach|cove|lagoon|coast|coastal|island|sea|ocean|bay|viaduct|rock formation|kapurpurawan|salt-making|salinas|coral|sand dunes|windmill|cliff)\b/i,
  highland: /\b(highland|mountain|peak|mount|falls|waterfall|ridge|hill|cordillera|viewdeck|dam|forest|spring|creek|eco-trail|riverbank|picnic grounds|upland|plantation)\b/i,
  heritage_urban: /\b(church|cathedral|chapel|bell tower|museum|museo|shrine|ancestral|heritage|monument|plaza|convent|ruins|colonial|malacañang)\b/i,
  rural_agro: /\b(farm|agri|agro|plantation|organic|weaving|inabel|binakol|pottery|damili|loom|loomweaving|cooperative|village|rice|garlic|dragonfruit|bugnay|wine|coffee|salt-making|salinas)\b/i,
};

export function classifyDestinationScenery(dest) {
  const text = `${dest.name ?? ''} ${dest.slug ?? ''} ${dest.description ?? ''}`;
  const tagSlugs = new Set((dest.tags ?? []).map((t) => t.slug));
  const scenery = [];

  if (
    ['beach', 'surfing', 'lighthouse', 'sand-dunes', 'wind-farm'].some((s) => tagSlugs.has(s)) ||
    SCENERY_PATTERNS.coastal.test(text) ||
    (dest.terrainType === 'flat_coastal' && tagSlugs.has('sunset-spot'))
  ) {
    scenery.push('coastal');
  }

  if (
    dest.terrainType === 'mountainous_winding' ||
    ['waterfall', 'hiking', 'motorcycle-scenic-ride'].some((s) => tagSlugs.has(s)) ||
    SCENERY_PATTERNS.highland.test(text)
  ) {
    scenery.push('highland');
  }

  if (
    dest.categoryCode === 'heritage_cultural' ||
    ['historical', 'unesco-heritage', 'museum', 'lighthouse'].some((s) => tagSlugs.has(s)) ||
    SCENERY_PATTERNS.heritage_urban.test(text)
  ) {
    scenery.push('heritage_urban');
  }

  if (
    dest.categoryCode === 'agro_eco_tourism' ||
    dest.categoryCode === 'artisan_craft_experience' ||
    ['agro-farm', 'weaving-craft', 'pottery', 'cultural-immersion'].some((s) => tagSlugs.has(s)) ||
    SCENERY_PATTERNS.rural_agro.test(text)
  ) {
    scenery.push('rural_agro');
  }

  if (scenery.length === 0) {
    if (dest.terrainType === 'flat_coastal') scenery.push('coastal');
    else if (dest.terrainType === 'rolling_inland') scenery.push('rural_agro');
    else scenery.push('highland');
  }

  return scenery;
}

const WEIGHTS = {
  interest: 0.48,
  budget: 0.16,
  proximity: 0.16,
  duration: 0.06,
  dispersal: 0.14,
};

export async function loadVerifiedCatalog(dayOfWeek) {
  const targetDay = Number.isInteger(dayOfWeek) ? dayOfWeek : new Date().getDay();

  const [destRows, lguRows, hourRows, tagRows] = await Promise.all([
    query(`
      SELECT
        d.id,
        d.slug,
        d.name,
        d.lgu_code,
        l.name AS lgu_name,
        l.tourism_cluster,
        l.center_latitude AS lgu_center_latitude,
        l.center_longitude AS lgu_center_longitude,
        l.terrain_type,
        l.road_tortuosity_multiplier,
        l.is_major_hub,
        l.baseline_dispersal_bonus,
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
        p.entrance_fee_adult,
        p.entrance_fee_concession,
        p.mandatory_activity_fee,
        p.estimated_meal_min,
        p.estimated_meal_max,
        p.parking_fee,
        p.is_free,
        p.currency
      FROM destinations d
      INNER JOIN lgus l ON l.lgu_code = d.lgu_code
      INNER JOIN categories c ON c.category_code = d.category_code
      LEFT JOIN pricing_tiers p ON p.destination_id = d.id
    `),
    query('SELECT lgu_code, name, tourism_cluster, center_latitude, center_longitude, road_tortuosity_multiplier FROM lgus'),
    query('SELECT destination_id, day_of_week, opening_time, closing_time, is_24_hours, temporarily_closed FROM operating_hours'),
    query(`
      SELECT dt.destination_id, it.tag_slug, it.display_name, it.category_code
      FROM destination_tags dt
      INNER JOIN interest_tags it ON it.tag_slug = dt.tag_slug
    `),
  ]);

  const hoursMap = new Map();
  for (const h of hourRows) {
    if (!hoursMap.has(h.destination_id)) hoursMap.set(h.destination_id, []);
    hoursMap.get(h.destination_id).push({
      dayOfWeek: h.day_of_week,
      openingTime: formatTime(h.opening_time),
      closingTime: formatTime(h.closing_time),
      is24Hours: toBoolean(h.is_24_hours),
      temporarilyClosed: toBoolean(h.temporarily_closed),
    });
  }

  const tagsMap = new Map();
  for (const t of tagRows) {
    if (!tagsMap.has(t.destination_id)) tagsMap.set(t.destination_id, []);
    tagsMap.get(t.destination_id).push({
      slug: t.tag_slug,
      name: t.display_name,
      categoryCode: t.category_code,
    });
  }

  const lguByCode = new Map(lguRows.map((l) => [l.lgu_code, l]));

  const destinations = destRows.map((row) => {
    const hours = hoursMap.get(row.id) ?? [];
    const todaySchedule = hours.find((h) => h.dayOfWeek === targetDay) ?? null;
    const tags = tagsMap.get(row.id) ?? [];
    const entryFee = toNumber(row.entrance_fee_adult) ?? 0;
    const mandatoryFee = toNumber(row.mandatory_activity_fee) ?? 0;
    const parkingFee = toNumber(row.parking_fee) ?? 0;

    const dest = {
      id: row.id,
      slug: row.slug,
      name: row.name,
      lguCode: row.lgu_code,
      lguName: row.lgu_name,
      tourismCluster: row.tourism_cluster,
      terrainType: row.terrain_type,
      tortuosityMultiplier: toNumber(row.road_tortuosity_multiplier) ?? 1.3,
      isMajorHub: toBoolean(row.is_major_hub),
      baselineDispersalBonus: toNumber(row.baseline_dispersal_bonus) ?? 0.5,
      categoryCode: row.category_code,
      categoryName: row.category_name,
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
      isLesserKnown: row.popularity_tier === 'hidden_gem' || toBoolean(row.is_community_based),
      verificationStatus: row.verification_status,
      pricing: {
        entranceFeeAdult: entryFee,
        entranceFeeConcession: toNumber(row.entrance_fee_concession) ?? 0,
        mandatoryActivityFee: mandatoryFee,
        estimatedMealMin: toNumber(row.estimated_meal_min) ?? 0,
        estimatedMealMax: toNumber(row.estimated_meal_max) ?? 0,
        parkingFee,
        isFree: toBoolean(row.is_free),
        currency: row.currency || 'PHP',
        singleVisitPerPersonCost: entryFee + mandatoryFee,
      },
      operatingHours: hours,
      todaySchedule,
      tags,
    };
    dest.sceneryTypes = classifyDestinationScenery(dest);
    return dest;
  });

  return { destinations, lguByCode, targetDay };
}

export function resolveOrigin(preferences, lguByCode) {
  const code = preferences.originLguCode || 'laoag-city';
  const internalLgu = lguByCode.get(code);
  const externalHub = PHILIPPINE_ORIGINS[code];

  let resolved;
  if (
    preferences.originCoordinates &&
    Number.isFinite(preferences.originCoordinates.latitude) &&
    Number.isFinite(preferences.originCoordinates.longitude)
  ) {
    resolved = {
      lguCode: code,
      name:
        preferences.originName ||
        internalLgu?.name ||
        externalHub?.name ||
        'Current GPS Location',
      coordinates: preferences.originCoordinates,
    };
  } else if (externalHub) {
    resolved = {
      lguCode: code,
      name: preferences.originName || externalHub.name,
      coordinates: {
        latitude: externalHub.latitude,
        longitude: externalHub.longitude,
      },
    };
  } else {
    const originLgu = internalLgu ?? lguByCode.get('laoag-city');
    resolved = {
      lguCode: originLgu?.lgu_code ?? code,
      name: preferences.originName || originLgu?.name || 'Laoag City',
      coordinates: {
        latitude: toNumber(originLgu?.center_latitude) ?? 18.1978,
        longitude: toNumber(originLgu?.center_longitude) ?? 120.5936,
      },
    };
  }

  const { latitude, longitude } = resolved.coordinates;
  const outsideProvince =
    latitude < 17.85 || latitude > 18.68 || longitude < 120.4 || longitude > 121.05;

  if (!outsideProvince) {
    return resolved;
  }

  let gatewayLgu = externalHub?.entryGatewayLgu
    ? lguByCode.get(externalHub.entryGatewayLgu)
    : null;
  if (!gatewayLgu && latitude < 12.5) {
    gatewayLgu = lguByCode.get('laoag-city');
  }
  if (!gatewayLgu) {
    let bestDist = Infinity;
    for (const candidate of lguByCode.values()) {
      const cLat = toNumber(candidate.center_latitude);
      const cLon = toNumber(candidate.center_longitude);
      if (cLat === null || cLon === null) continue;
      const d = haversineKm(resolved.coordinates, { latitude: cLat, longitude: cLon });
      if (d < bestDist) {
        bestDist = d;
        gatewayLgu = candidate;
      }
    }
  }

  const gwLat = toNumber(gatewayLgu?.center_latitude) ?? 18.1978;
  const gwLon = toNumber(gatewayLgu?.center_longitude) ?? 120.5936;
  return {
    ...resolved,
    isExternalOrigin: true,
    entryGatewayName: gatewayLgu?.name ?? 'Laoag City',
    gatewayCoordinates: { latitude: gwLat, longitude: gwLon },
  };
}

export function perPersonBudget(preferences) {
  if (preferences.budgetAmount === null || preferences.budgetAmount === undefined) {
    return Infinity;
  }
  const amount = Number(preferences.budgetAmount);
  if (preferences.budgetScope === 'totalGroup') {
    return amount / Math.max(1, preferences.groupSize || 1);
  }
  return amount;
}

function isOpenDuringWindow(schedule, startTime, endTime) {
  if (!schedule) return true;
  if (schedule.temporarilyClosed) return false;
  if (schedule.is24Hours) return true;
  const openMin = toMinutes(schedule.openingTime);
  const closeMin = toMinutes(schedule.closingTime);
  const userStart = toMinutes(startTime) ?? 480;
  const userEnd = toMinutes(endTime) ?? 1080;
  if (openMin === null || closeMin === null) return false;
  // Must have at least 45 minutes of overlapping open window
  const overlapStart = Math.max(openMin, userStart);
  const overlapEnd = Math.min(closeMin, userEnd);
  return overlapEnd - overlapStart >= 45;
}

export function scoreAndFilterDestinations(catalog, preferences) {
  const { destinations, lguByCode } = catalog;
  const origin = resolveOrigin(preferences, lguByCode);
  const budgetCap = perPersonBudget(preferences);
  const excludedSet = new Set(preferences.excludedDestinationIds ?? []);
  const areaLgus = new Set(preferences.preferredLgus ?? []);
  const areaClusters = new Set(preferences.preferredClusters ?? []);
  const wantCategories = new Set(preferences.categories ?? []);
  const wantTags = new Set(preferences.interestTags ?? []);
  const wantScenery = new Set(preferences.preferredScenery ?? []);

  const filteredOut = { unverified: 0, closed: 0, budget: 0, area: 0, preference: 0 };
  const primaryMatches = [];
  const relatedMatches = [];

  for (const dest of destinations) {
    if (excludedSet.has(dest.id)) continue;

    if (dest.verificationStatus !== 'verified') {
      filteredOut.unverified += 1;
      continue;
    }

    if (!isOpenDuringWindow(dest.todaySchedule, preferences.startTime, preferences.endTime)) {
      filteredOut.closed += 1;
      continue;
    }

    if (dest.pricing.singleVisitPerPersonCost > budgetCap) {
      filteredOut.budget += 1;
      continue;
    }

    if (areaLgus.size > 0 && !areaLgus.has(dest.lguCode)) {
      filteredOut.area += 1;
      continue;
    }

    if (areaClusters.size > 0 && !areaClusters.has(dest.tourismCluster)) {
      filteredOut.area += 1;
      continue;
    }

    // Strict preference alignment: exclude destinations that miss selected filters
    const sceneryTypes = dest.sceneryTypes ?? classifyDestinationScenery(dest);
    const matchedScenery = [...wantScenery].filter((s) => sceneryTypes.includes(s));
    const hasSceneryMatch = wantScenery.size === 0 || matchedScenery.length > 0;

    const directCatMatch = wantCategories.size === 0 || wantCategories.has(dest.categoryCode);
    const matchedCatTags = dest.tags.filter((t) => wantCategories.has(t.categoryCode));
    const relatedCatMatch = directCatMatch || matchedCatTags.length > 0;

    const matchedTags = dest.tags.filter((t) => wantTags.has(t.slug));
    const hasTagMatch = wantTags.size === 0 || matchedTags.length > 0;

    if (!hasSceneryMatch || !relatedCatMatch || !hasTagMatch) {
      filteredOut.preference += 1;
      continue;
    }

    // Score components in [0, 1]
    const catMatch = wantCategories.size === 0 ? 0.65 : directCatMatch ? 1.0 : 0.45;
    const tagMatch =
      wantTags.size === 0
        ? wantCategories.size > 0
          ? matchedCatTags.length > 0
            ? 1.0
            : 0.55
          : 0.6
        : Math.min(1, matchedTags.length / Math.min(3, wantTags.size));
    const sceneryMatch = wantScenery.size === 0 ? 0.6 : 1.0;
    const sInterest = Number((catMatch * 0.5 + tagMatch * 0.25 + sceneryMatch * 0.25).toFixed(4));

    const sBudget = Number.isFinite(budgetCap) && budgetCap > 0
      ? Math.max(0, Math.min(1, 1 - dest.pricing.singleVisitPerPersonCost / Math.max(budgetCap, 1)))
      : 1.0;

    const scoringOrigin = origin.gatewayCoordinates ?? origin.coordinates;
    const leg = estimateTravelLeg(
      scoringOrigin,
      dest.coordinates,
      dest.tortuosityMultiplier,
      preferences.transportMode,
      preferences.groupSize,
    );
    const sProximity = Number(Math.max(0.05, 1 - Math.min(leg.distanceKm, 90) / 95).toFixed(4));

    const targetVisitMax = preferences.pacing === 'relaxed' ? 120 : preferences.pacing === 'packed' ? 75 : 95;
    const sDuration = dest.recommendedDurationMinutes <= targetVisitMax ? 1.0 : 0.65;

    const sDispersal = Number(
      Math.min(
        1,
        dest.baselineDispersalBonus * 0.6 +
          (dest.popularityTier === 'hidden_gem' ? 0.3 : 0.08) +
          (dest.isCommunityBased ? 0.15 : 0),
      ).toFixed(4),
    );

    const sTotal = Number(
      (
        WEIGHTS.interest * sInterest +
        WEIGHTS.budget * sBudget +
        WEIGHTS.proximity * sProximity +
        WEIGHTS.duration * sDuration +
        WEIGHTS.dispersal * sDispersal
      ).toFixed(4),
    );

    const reasons = [];
    if (wantCategories.has(dest.categoryCode)) {
      reasons.push(`Matches ${dest.categoryName}`);
    } else if (matchedCatTags.length > 0) {
      reasons.push(`Includes ${matchedCatTags[0].name}`);
    } else if (matchedTags.length > 0) {
      reasons.push(`Matches ${matchedTags[0].name}`);
    }
    if (matchedScenery.length > 0 && SCENERY_LABELS[matchedScenery[0]]) {
      reasons.push(SCENERY_LABELS[matchedScenery[0]]);
    }
    if (dest.todaySchedule?.is24Hours) {
      reasons.push('Open 24 hours');
    } else if (dest.todaySchedule?.openingTime) {
      reasons.push(`Open ${dest.todaySchedule.openingTime}–${dest.todaySchedule.closingTime}`);
    }
    if (dest.isLesserKnown && reasons.length < 3) {
      reasons.push(dest.isCommunityBased ? `Community spot in ${dest.lguName}` : `Hidden gem in ${dest.lguName}`);
    }
    if (reasons.length < 2) {
      reasons.push(dest.pricing.isFree ? 'Free entry' : `₱${Math.round(dest.pricing.singleVisitPerPersonCost)} entry fits budget`);
    }

    const scored = {
      ...dest,
      matchPercentage: Math.min(99, Math.max(55, Math.round(sTotal * 100))),
      scoreBreakdown: {
        total: sTotal,
        interest: sInterest,
        budget: Number(sBudget.toFixed(4)),
        proximity: sProximity,
        duration: sDuration,
        dispersal: sDispersal,
      },
      distanceKm: leg.distanceKm,
      estimatedTravelMinutes: leg.travelMinutes,
      explanationReasons: reasons.slice(0, 2),
    };

    if (directCatMatch) {
      primaryMatches.push(scored);
    } else {
      relatedMatches.push(scored);
    }
  }

  // Only include tag-related cross-category matches when direct matches are sparse (< 4).
  const viable =
    primaryMatches.length >= 4
      ? primaryMatches
      : [...primaryMatches, ...relatedMatches];

  viable.sort((a, b) => b.scoreBreakdown.total - a.scoreBreakdown.total);

  return { origin, budgetCap, filteredOut, viable };
}

export function enforceThirtyPercentQuota(ranked, limit) {
  if (ranked.length <= 1) return ranked;
  const targetCount = Math.min(limit, ranked.length);
  const requiredLesserKnown = Math.ceil(targetCount * 0.3);

  const selected = ranked.slice(0, targetCount);
  const currentLesserKnown = selected.filter((d) => d.isLesserKnown).length;
  if (currentLesserKnown >= requiredLesserKnown) {
    return selected;
  }

  const remainingLesserKnown = ranked.slice(targetCount).filter((d) => d.isLesserKnown);
  const result = [...selected];
  let needed = requiredLesserKnown - currentLesserKnown;

  for (let i = result.length - 1; i >= 0 && needed > 0 && remainingLesserKnown.length > 0; i -= 1) {
    if (!result[i].isLesserKnown) {
      result[i] = remainingLesserKnown.shift();
      needed -= 1;
    }
  }

  result.sort((a, b) => b.scoreBreakdown.total - a.scoreBreakdown.total);
  return result;
}

export async function getRecommendations(preferences) {
  const catalog = await loadVerifiedCatalog(preferences.dayOfWeek);
  const { origin, budgetCap, filteredOut, viable } = scoreAndFilterDestinations(catalog, preferences);
  const items = enforceThirtyPercentQuota(viable, preferences.limit ?? 12);

  const lesserKnownCount = items.filter((d) => d.isLesserKnown).length;
  const lesserKnownRatio = items.length > 0 ? Number((lesserKnownCount / items.length).toFixed(2)) : 0;

  const relaxationSuggestions = [];
  if (items.length === 0) {
    if (filteredOut.budget > 0 && Number.isFinite(budgetCap)) {
      relaxationSuggestions.push({
        type: 'budget',
        label: `Raise budget by ₱${Math.max(200, Math.round(budgetCap * 0.25))}`,
        patch: { budgetAmount: Math.round((preferences.budgetAmount ?? 500) + 300) },
      });
    }
    if (filteredOut.area > 0) {
      relaxationSuggestions.push({
        type: 'area',
        label: 'Include nearby towns in Ilocos Norte',
        patch: { preferredLgus: [], preferredClusters: [] },
      });
    }
    if (filteredOut.closed > 0) {
      relaxationSuggestions.push({
        type: 'time',
        label: 'Expand daily hours (08:00–18:00)',
        patch: { startTime: '08:00', endTime: '18:00', availableHoursPerDay: 10 },
      });
    }
    if (filteredOut.preference > 0) {
      relaxationSuggestions.push({
        type: 'preference',
        label: 'Broaden scenery or category filters',
        patch: { preferredScenery: [] },
      });
    }
  }

  return {
    origin,
    totalMatches: viable.length,
    dispersalSummary: {
      lesserKnownCount,
      totalCount: items.length,
      lesserKnownRatio,
      meetsThirtyPercentTarget: items.length === 0 ? false : lesserKnownRatio >= 0.3,
    },
    filteredSummary: filteredOut,
    relaxationSuggestions,
    items,
  };
}

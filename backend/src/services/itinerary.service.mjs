import {
  enforceThirtyPercentQuota,
  loadVerifiedCatalog,
  scoreAndFilterDestinations,
} from './recommendation.service.mjs';
import { estimateTravelLeg, formatMinutes, toMinutes } from '../utils/geo.matrix.mjs';
import { formatTime, toBoolean, toNumber } from '../utils/destination.mapper.mjs';

function isStopOpenAt(dest, dayOfWeek, arrivalMin, departureMin) {
  const schedule = dest.operatingHours?.find((h) => h.dayOfWeek === dayOfWeek);
  if (!schedule) return { ok: true, windowLabel: 'Standard hours' };
  if (schedule.temporarilyClosed) {
    return { ok: false, reason: `${dest.name} is temporarily closed` };
  }
  if (schedule.is24Hours) {
    return { ok: true, windowLabel: 'Open 24 hours' };
  }
  const openMin = toMinutes(schedule.openingTime);
  const closeMin = toMinutes(schedule.closingTime);
  if (openMin === null || closeMin === null) {
    return { ok: false, reason: `${dest.name} has no operating hours on that day` };
  }
  if (arrivalMin < openMin || departureMin > closeMin) {
    return {
      ok: false,
      reason: `${dest.name} is open ${schedule.openingTime}–${schedule.closingTime}, outside ${formatMinutes(arrivalMin)}–${formatMinutes(departureMin)}`,
    };
  }
  return { ok: true, windowLabel: `Open ${schedule.openingTime}–${schedule.closingTime}` };
}

function stopTotalCost(dest, groupSize, transportMode) {
  const pax = Math.max(1, groupSize || 1);
  const entry = (dest.pricing.entranceFeeAdult + dest.pricing.mandatoryActivityFee) * pax;
  const parking = transportMode === 'publicCommute' ? 0 : dest.pricing.parkingFee;
  return entry + parking;
}

function mealCostForStop(dest, groupSize) {
  const pax = Math.max(1, groupSize || 1);
  const avgMeal =
    dest && dest.pricing.estimatedMealMax > 0
      ? Math.round((dest.pricing.estimatedMealMin + dest.pricing.estimatedMealMax) / 2)
      : 180;
  return avgMeal * pax;
}

export async function generateFeasibleItinerary(preferences) {
  const startedAt = performance.now();
  const catalog = await loadVerifiedCatalog(preferences.dayOfWeek);
  const { origin, viable } = scoreAndFilterDestinations(catalog, preferences);

  const lockedIds = new Set(preferences.lockedDestinationIds ?? []);
  const lockedStops = catalog.destinations.filter(
    (d) => lockedIds.has(d.id) && d.verificationStatus === 'verified',
  );

  // Merge locked stops (if any) with top scored candidates preserving >= 30% lesser-known quota
  const poolLimit = Math.max(preferences.availableDays * 5, 12);
  const rankedPool = enforceThirtyPercentQuota(viable, poolLimit);
  const candidatePool = [
    ...lockedStops.map((d) => ({
      ...d,
      matchPercentage: 98,
      explanationReasons: ['Selected by traveler'],
      isLocked: true,
    })),
    ...rankedPool.filter((d) => !lockedIds.has(d.id)),
  ];

  // Fallback pool of lesser-known verified stops in the requested area (if quota needs an extra stop)
  const areaLgus = new Set(preferences.preferredLgus ?? []);
  const areaClusters = new Set(preferences.preferredClusters ?? []);
  const extraAreaLesserKnown = catalog.destinations.filter(
    (d) =>
      d.verificationStatus === 'verified' &&
      d.isLesserKnown &&
      !candidatePool.some((c) => c.id === d.id) &&
      (areaLgus.size === 0 || areaLgus.has(d.lguCode)) &&
      (areaClusters.size === 0 || areaClusters.has(d.tourismCluster)),
  );
  for (const extra of extraAreaLesserKnown) {
    candidatePool.push({
      ...extra,
      scoreBreakdown: { total: 0.62 },
    });
  }

  const foodPool = catalog.destinations.filter(
    (d) =>
      d.verificationStatus === 'verified' &&
      (d.categoryCode === 'food_culinary' || d.entityType === 'food_establishment'),
  );

  const totalBudget =
    preferences.budgetAmount === null || preferences.budgetAmount === undefined
      ? Infinity
      : preferences.budgetScope === 'totalGroup'
        ? Number(preferences.budgetAmount)
        : Number(preferences.budgetAmount) * Math.max(1, preferences.groupSize);

  const dayStartMin = toMinutes(preferences.startTime) ?? 480;
  const configuredEndMin = toMinutes(preferences.endTime) ?? 1080;
  const maxAvailableMin = Math.round((preferences.availableHoursPerDay ?? 9) * 60);
  const dayEndMin = Math.min(configuredEndMin, dayStartMin + maxAvailableMin);

  const maxStopsPerDay =
    preferences.pacing === 'relaxed' ? 3 : preferences.pacing === 'packed' ? 5 : 4;

  const usedIds = new Set();
  const days = [];
  const violatedConstraints = [];

  let entranceAndActivityCost = 0;
  let parkingCost = 0;
  let mealsCost = 0;
  let transportCost = 0;
  let totalTravelMinutes = 0;
  let totalVisitMinutes = 0;
  let totalDistanceKm = 0;
  let allOperatingHoursOk = true;
  let allTimeWindowsOk = true;
  let allRoutesCalculable = true;
  let scheduledCount = 0;
  let scheduledLesserKnownCount = 0;
  let multiDayCursor = origin.coordinates;

  for (let dayNum = 1; dayNum <= preferences.availableDays; dayNum += 1) {
    const dayOfWeek = ((preferences.dayOfWeek ?? new Date().getDay()) + (dayNum - 1)) % 7;
    let cursorTime = dayStartMin;
    let cursorCoords = multiDayCursor;
    let lunchInjected = false;
    let dinnerInjected = false;
    let activityStopsToday = 0;
    const dayItems = [];

    const tryPickBestNext = (candidates, enforceBudget, maxDistanceKm = Infinity) => {
      let best = null;
      let bestCostScore = -Infinity;
      const needsDispersalQuota =
        scheduledCount === 0 || scheduledLesserKnownCount / Math.max(1, scheduledCount) < 0.3;

      for (const cand of candidates) {
        if (usedIds.has(cand.id)) continue;
        const leg = estimateTravelLeg(
          cursorCoords,
          cand.coordinates,
          cand.tortuosityMultiplier,
          preferences.transportMode,
          preferences.groupSize,
        );
        if (leg.distanceKm > maxDistanceKm) continue;
        const arrival = cursorTime + leg.travelMinutes;
        const duration = cand.recommendedDurationMinutes || 60;
        const departure = arrival + duration;
        if (departure > dayEndMin) continue;

        const openCheck = isStopOpenAt(cand, dayOfWeek, arrival, departure);
        if (!openCheck.ok) continue;

        const stopSpend = stopTotalCost(cand, preferences.groupSize, preferences.transportMode) + leg.transportCostPhp;
        const runningSpend = entranceAndActivityCost + parkingCost + mealsCost + transportCost + stopSpend;
        if (enforceBudget && runningSpend > totalBudget) continue;

        // Balance candidate relevance score with proximity and 30% dispersal target
        const baseScore = cand.isLocked ? 2.0 : (cand.scoreBreakdown?.total ?? 0.65);
        const quotaBoost = needsDispersalQuota && cand.isLesserKnown ? 0.9 : 0;
        const proximityPenalty = Math.min(0.45, leg.distanceKm / 120);
        const combo = baseScore + quotaBoost - proximityPenalty;
        if (combo > bestCostScore) {
          bestCostScore = combo;
          best = { cand, leg, arrival, departure, duration, openCheck };
        }
      }
      return best;
    };

    // Keep scheduling while stops fit inside the day window
    while (activityStopsToday < maxStopsPerDay) {
      // Inject lunch window when cursor reaches 11:30–13:30 (nearby <= 20 km or attach to previous stop)
      if (!lunchInjected && cursorTime >= 690 && cursorTime <= 810 && cursorTime + 60 <= dayEndMin) {
        lunchInjected = true;
        const lunchChoice = tryPickBestNext(foodPool, true, 20);
        if (lunchChoice) {
          const { cand, leg, arrival, departure, duration, openCheck } = lunchChoice;
          usedIds.add(cand.id);
          const pax = Math.max(1, preferences.groupSize);
          const mealEst = mealCostForStop(cand, pax);
          const entry = (cand.pricing.entranceFeeAdult + cand.pricing.mandatoryActivityFee) * pax;
          const park = preferences.transportMode === 'publicCommute' ? 0 : cand.pricing.parkingFee;
          entranceAndActivityCost += entry;
          parkingCost += park;
          mealsCost += mealEst;
          transportCost += leg.transportCostPhp;
          totalTravelMinutes += leg.travelMinutes;
          totalVisitMinutes += duration;
          totalDistanceKm += leg.distanceKm;

          dayItems.push({
            sequenceOrder: dayItems.length + 1,
            destinationId: cand.id,
            slug: cand.slug,
            name: cand.name,
            lguCode: cand.lguCode,
            lguName: cand.lguName,
            categoryCode: cand.categoryCode,
            categoryName: cand.categoryName,
            coordinates: cand.coordinates,
            popularityTier: cand.popularityTier,
            isCommunityBased: cand.isCommunityBased,
            isLesserKnown: cand.isLesserKnown,
            mealWindow: 'lunch',
            startTime: formatMinutes(arrival),
            endTime: formatMinutes(departure),
            estimatedDurationMinutes: duration,
            travelTimeFromPrevMinutes: leg.travelMinutes,
            distanceFromPrevKm: leg.distanceKm,
            legTransportCostPhp: leg.transportCostPhp,
            entryCostPhp: entry + park,
            estimatedMealCostPhp: mealEst,
            operatingWindowLabel: openCheck.windowLabel,
            isOpenCompliant: true,
          });
          cursorTime = departure;
          cursorCoords = cand.coordinates;
          multiDayCursor = cand.coordinates;
          scheduledCount += 1;
          if (cand.isLesserKnown) scheduledLesserKnownCount += 1;
          continue;
        } else if (dayItems.length > 0) {
          const lastStop = dayItems[dayItems.length - 1];
          const localMealEst = mealCostForStop(null, preferences.groupSize);
          if (entranceAndActivityCost + parkingCost + mealsCost + transportCost + localMealEst <= totalBudget) {
            mealsCost += localMealEst;
            lastStop.mealWindow = 'lunch';
            lastStop.estimatedMealCostPhp += localMealEst;
            cursorTime = Math.min(dayEndMin, cursorTime + 45);
          }
        }
      }

      // First try respecting strict financial budget, fallback for locked stops only
      let picked = tryPickBestNext(candidatePool, true);
      if (!picked && lockedStops.some((l) => !usedIds.has(l.id))) {
        picked = tryPickBestNext(lockedStops, false);
      }
      if (!picked) break;

      const { cand, leg, arrival, departure, duration, openCheck } = picked;
      usedIds.add(cand.id);
      activityStopsToday += 1;

      const pax = Math.max(1, preferences.groupSize);
      const entry = (cand.pricing.entranceFeeAdult + cand.pricing.mandatoryActivityFee) * pax;
      const park = preferences.transportMode === 'publicCommute' ? 0 : cand.pricing.parkingFee;
      const mealEst = cand.categoryCode === 'food_culinary' ? mealCostForStop(cand, pax) : 0;

      entranceAndActivityCost += entry;
      parkingCost += park;
      mealsCost += mealEst;
      transportCost += leg.transportCostPhp;
      totalTravelMinutes += leg.travelMinutes;
      totalVisitMinutes += duration;
      totalDistanceKm += leg.distanceKm;

      if (!Number.isFinite(leg.distanceKm)) allRoutesCalculable = false;

      dayItems.push({
        sequenceOrder: dayItems.length + 1,
        destinationId: cand.id,
        slug: cand.slug,
        name: cand.name,
        lguCode: cand.lguCode,
        lguName: cand.lguName,
        categoryCode: cand.categoryCode,
        categoryName: cand.categoryName,
        coordinates: cand.coordinates,
        popularityTier: cand.popularityTier,
        isCommunityBased: cand.isCommunityBased,
        isLesserKnown: cand.isLesserKnown,
        mealWindow: cand.categoryCode === 'food_culinary' ? (cursorTime >= 990 ? 'dinner' : 'lunch') : null,
        startTime: formatMinutes(arrival),
        endTime: formatMinutes(departure),
        estimatedDurationMinutes: duration,
        travelTimeFromPrevMinutes: leg.travelMinutes,
        distanceFromPrevKm: leg.distanceKm,
        legTransportCostPhp: leg.transportCostPhp,
        entryCostPhp: entry + park,
        estimatedMealCostPhp: mealEst,
        operatingWindowLabel: openCheck.windowLabel,
        isOpenCompliant: openCheck.ok,
      });

      cursorTime = departure;
      cursorCoords = cand.coordinates;
      multiDayCursor = cand.coordinates;
      scheduledCount += 1;
      if (cand.isLesserKnown) scheduledLesserKnownCount += 1;
    }

    // Add dinner slot if day extends past 17:30 and still fits inside window (within 20 km)
    if (!dinnerInjected && dayEndMin >= 1080 && cursorTime <= 1050 && cursorTime + 60 <= dayEndMin) {
      const dinnerChoice = tryPickBestNext(foodPool, true, 20);
      if (dinnerChoice) {
        const { cand, leg, arrival, departure, duration, openCheck } = dinnerChoice;
        usedIds.add(cand.id);
        const pax = Math.max(1, preferences.groupSize);
        const mealEst = mealCostForStop(cand, pax);
        const entry = (cand.pricing.entranceFeeAdult + cand.pricing.mandatoryActivityFee) * pax;
        const park = preferences.transportMode === 'publicCommute' ? 0 : cand.pricing.parkingFee;
        entranceAndActivityCost += entry;
        parkingCost += park;
        mealsCost += mealEst;
        transportCost += leg.transportCostPhp;
        totalTravelMinutes += leg.travelMinutes;
        totalVisitMinutes += duration;
        totalDistanceKm += leg.distanceKm;

        dayItems.push({
          sequenceOrder: dayItems.length + 1,
          destinationId: cand.id,
          slug: cand.slug,
          name: cand.name,
          lguCode: cand.lguCode,
          lguName: cand.lguName,
          categoryCode: cand.categoryCode,
          categoryName: cand.categoryName,
          coordinates: cand.coordinates,
          popularityTier: cand.popularityTier,
          isCommunityBased: cand.isCommunityBased,
          isLesserKnown: cand.isLesserKnown,
          mealWindow: 'dinner',
          startTime: formatMinutes(arrival),
          endTime: formatMinutes(departure),
          estimatedDurationMinutes: duration,
          travelTimeFromPrevMinutes: leg.travelMinutes,
          distanceFromPrevKm: leg.distanceKm,
          legTransportCostPhp: leg.transportCostPhp,
          entryCostPhp: entry + park,
          estimatedMealCostPhp: mealEst,
          operatingWindowLabel: openCheck.windowLabel,
          isOpenCompliant: openCheck.ok,
        });
        multiDayCursor = cand.coordinates;
        scheduledCount += 1;
        if (cand.isLesserKnown) scheduledLesserKnownCount += 1;
      }
    }

    const totalDayMinutes = dayItems.reduce(
      (sum, item) => sum + item.estimatedDurationMinutes + item.travelTimeFromPrevMinutes,
      0,
    );
    if (totalDayMinutes > maxAvailableMin) {
      allTimeWindowsOk = false;
      violatedConstraints.push(`Day ${dayNum} exceeds available hours (${totalDayMinutes} mins > ${maxAvailableMin} mins).`);
    }

    days.push({
      dayNumber: dayNum,
      dayOfWeek,
      startTime: formatMinutes(dayStartMin),
      endTime: dayItems.length > 0 ? dayItems[dayItems.length - 1].endTime : formatMinutes(dayStartMin),
      stops: dayItems,
    });
  }

  const allStops = days.flatMap((d) => d.stops);
  const totalEstimatedCost = Math.round(
    entranceAndActivityCost + parkingCost + mealsCost + transportCost,
  );
  const financialBudgetCompliant = totalEstimatedCost <= totalBudget;
  if (!financialBudgetCompliant) {
    violatedConstraints.push(
      `Total estimated cost (₱${totalEstimatedCost}) exceeds budget (₱${Math.round(totalBudget)}).`,
    );
  }

  if (allStops.length === 0) {
    allTimeWindowsOk = false;
    violatedConstraints.push('No verified destinations fit the selected time window, area, and budget.');
  }

  const lesserKnownCount = allStops.filter((s) => s.isLesserKnown).length;
  const lesserKnownRatio =
    allStops.length > 0 ? Number((lesserKnownCount / allStops.length).toFixed(2)) : 0;

  const totalScheduledMinutes = totalTravelMinutes + totalVisitMinutes;
  const totalAllowedMinutes = preferences.availableDays * maxAvailableMin;
  const timeBudgetCompliant = allStops.length > 0 && totalScheduledMinutes <= totalAllowedMinutes;

  const isFeasible =
    allStops.length > 0 &&
    timeBudgetCompliant &&
    allOperatingHoursOk &&
    financialBudgetCompliant &&
    allTimeWindowsOk &&
    allRoutesCalculable;

  const recalculationTimeMs = Math.max(1, Math.round(performance.now() - startedAt));

  return {
    origin,
    totalDays: preferences.availableDays,
    totalStops: allStops.length,
    totalDistanceKm: Number(totalDistanceKm.toFixed(2)),
    totalTravelMinutes,
    totalVisitMinutes,
    recalculationTimeMs,
    lesserKnownCount,
    lesserKnownRatio,
    expenseBreakdown: {
      entranceAndActivityCost: Math.round(entranceAndActivityCost),
      parkingCost: Math.round(parkingCost),
      mealsCost: Math.round(mealsCost),
      transportCost: Math.round(transportCost),
      totalEstimatedCost,
      budgetAmount: Number.isFinite(totalBudget) ? Math.round(totalBudget) : null,
      remainingBudget: Number.isFinite(totalBudget)
        ? Math.round(totalBudget - totalEstimatedCost)
        : null,
      currency: 'PHP',
    },
    feasibilityReport: {
      isFeasible,
      checks: {
        timeBudgetCompliant,
        operatingHoursCompliant: allOperatingHoursOk,
        financialBudgetCompliant,
        timeWindowCompliant: allTimeWindowsOk,
        routesCalculable: allRoutesCalculable,
      },
      violatedConstraints,
    },
    days,
  };
}

export function detectSavedItineraryChanges(savedData) {
  const { itinerary, items } = savedData;
  const detectedChanges = [];

  for (const row of items) {
    if (row.verification_status !== 'verified') {
      detectedChanges.push({
        type: 'verification_revoked',
        detectionMode: 'automatic',
        destinationId: row.destination_id,
        destinationName: row.name,
        message: `${row.name} is pending field verification and excluded from active schedules.`,
      });
    } else if (toBoolean(row.temporarily_closed)) {
      detectedChanges.push({
        type: 'destination_closed',
        detectionMode: 'automatic',
        destinationId: row.destination_id,
        destinationName: row.name,
        message: `${row.name} was marked temporarily closed.`,
      });
    } else if (row.scheduled_time && !toBoolean(row.is_24_hours)) {
      const openMin = toMinutes(formatTime(row.opening_time));
      const closeMin = toMinutes(formatTime(row.closing_time));
      const [startStr, endStr] = String(row.scheduled_time).split('-');
      const startMin = toMinutes(startStr?.trim());
      const endMin = toMinutes(endStr?.trim());
      if (
        openMin !== null &&
        closeMin !== null &&
        startMin !== null &&
        endMin !== null &&
        (startMin < openMin || endMin > closeMin)
      ) {
        detectedChanges.push({
          type: 'schedule_shift',
          detectionMode: 'automatic',
          destinationId: row.destination_id,
          destinationName: row.name,
          message: `${row.name} hours (${formatTime(row.opening_time)}–${formatTime(row.closing_time)}) conflict with ${row.scheduled_time}.`,
        });
      }
    }
  }

  return {
    itinerary: {
      id: itinerary.id,
      title: itinerary.title,
      totalDays: itinerary.total_days,
      totalEstimatedCost: toNumber(itinerary.total_estimated_cost) ?? 0,
      preferencesSnapshot: itinerary.preferences_snapshot ?? {},
      createdAt: itinerary.created_at,
      updatedAt: itinerary.updated_at,
    },
    items: items.map((row) => ({
      itemId: row.item_id,
      destinationId: row.destination_id,
      slug: row.slug,
      name: row.name,
      lguCode: row.lgu_code,
      lguName: row.lgu_name,
      categoryCode: row.category_code,
      coordinates: {
        latitude: toNumber(row.latitude),
        longitude: toNumber(row.longitude),
      },
      dayNumber: row.day_number,
      sequenceOrder: row.sequence_order,
      scheduledTime: row.scheduled_time,
      mealWindow: row.meal_window,
      estimatedDurationMinutes: row.estimated_duration_minutes,
      travelTimeFromPrevMinutes: row.travel_time_from_prev_minutes,
      verificationStatus: row.verification_status,
      temporarilyClosed: toBoolean(row.temporarily_closed),
      entryCostPhp:
        (toNumber(row.entrance_fee_adult) ?? 0) +
        (toNumber(row.mandatory_activity_fee) ?? 0),
    })),
    detectedChanges,
  };
}

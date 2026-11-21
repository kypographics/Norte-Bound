const EARTH_RADIUS_KM = 6371;

const MODE_SPEED_KMH = {
  motorcycle: 44,
  privateCar: 48,
  publicCommute: 28,
};

const MODE_BOARDING_OVERHEAD_MIN = {
  motorcycle: 4,
  privateCar: 5,
  publicCommute: 14,
};

export function toMinutes(timeStr) {
  if (!timeStr || typeof timeStr !== 'string') return null;
  const parts = timeStr.split(':');
  if (parts.length < 2) return null;
  const h = Number(parts[0]);
  const m = Number(parts[1]);
  if (!Number.isFinite(h) || !Number.isFinite(m)) return null;
  return h * 60 + m;
}

export function formatMinutes(totalMinutes) {
  const clamped = Math.max(0, Math.round(totalMinutes));
  const h = Math.floor(clamped / 60) % 24;
  const m = clamped % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

export function haversineKm(a, b) {
  if (!a || !b) return 0;
  const lat1 = Number(a.latitude);
  const lon1 = Number(a.longitude);
  const lat2 = Number(b.latitude);
  const lon2 = Number(b.longitude);
  if (![lat1, lon1, lat2, lon2].every(Number.isFinite)) return 0;

  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const sinLat = Math.sin(dLat / 2);
  const sinLon = Math.sin(dLon / 2);

  const h =
    sinLat * sinLat +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * sinLon * sinLon;

  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(h)));
}

export function estimateTravelLeg(
  fromCoords,
  toCoords,
  tortuosityMultiplier = 1.3,
  transportMode = 'motorcycle',
  groupSize = 1,
) {
  const straightKm = haversineKm(fromCoords, toCoords);
  const factor = Number(tortuosityMultiplier) || 1.3;
  const distanceKm = Number((straightKm * factor).toFixed(2));

  if (distanceKm < 0.05) {
    return { distanceKm: 0, travelMinutes: 0, transportCostPhp: 0 };
  }

  const speed = MODE_SPEED_KMH[transportMode] ?? MODE_SPEED_KMH.motorcycle;
  const overhead =
    MODE_BOARDING_OVERHEAD_MIN[transportMode] ??
    MODE_BOARDING_OVERHEAD_MIN.motorcycle;
  const travelMinutes = Math.max(5, Math.round((distanceKm / speed) * 60 + overhead));

  let transportCostPhp = 0;
  if (transportMode === 'motorcycle') {
    transportCostPhp = Math.round(distanceKm * 3.5);
  } else if (transportMode === 'privateCar') {
    transportCostPhp = Math.round(distanceKm * 9.0);
  } else {
    // Public commute fare: base fare + per-km jeepney/bus rate per traveler
    transportCostPhp = Math.round((20 + distanceKm * 3.2) * Math.max(1, groupSize));
  }

  return {
    distanceKm,
    travelMinutes,
    transportCostPhp,
  };
}

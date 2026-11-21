import { getDbPool, query } from '../config/db.mjs';

export async function createSavedItinerary(userId, payload) {
  const connection = await getDbPool().getConnection();

  try {
    await connection.beginTransaction();

    const [rows] = await connection.execute(
      `
        INSERT INTO itineraries (user_id, title, total_days, total_estimated_cost, preferences_snapshot)
        VALUES (?, ?, ?, ?, ?::jsonb)
        RETURNING id, user_id, title, total_days, total_estimated_cost, preferences_snapshot, created_at, updated_at
      `,
      [
        userId,
        payload.title,
        payload.totalDays,
        payload.totalEstimatedCost,
        JSON.stringify(payload.preferencesSnapshot ?? {}),
      ],
    );

    const itinerary = rows[0];

    const placeholders = payload.items
      .map(() => '(?, ?, ?, ?, ?, ?, ?, ?)')
      .join(', ');
    const params = payload.items.flatMap((item) => [
      itinerary.id,
      item.destinationId,
      item.dayNumber,
      item.sequenceOrder,
      item.scheduledTime ?? null,
      item.mealWindow ?? null,
      item.estimatedDurationMinutes ?? 60,
      item.travelTimeFromPrevMinutes ?? 0,
    ]);

    await connection.execute(
      `
        INSERT INTO itinerary_items (
          itinerary_id, destination_id, day_number, sequence_order,
          scheduled_time, meal_window, estimated_duration_minutes, travel_time_from_prev_minutes
        ) VALUES ${placeholders}
      `,
      params,
    );

    await connection.commit();
    return itinerary.id;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

export async function listItinerariesByUser(userId) {
  return query(
    `
      SELECT
        i.id,
        i.title,
        i.total_days,
        i.total_estimated_cost,
        i.created_at,
        i.updated_at,
        COUNT(ii.id)::int AS stop_count
      FROM itineraries i
      LEFT JOIN itinerary_items ii ON ii.itinerary_id = i.id
      WHERE i.user_id = ?
      GROUP BY i.id
      ORDER BY i.updated_at DESC
    `,
    [userId],
  );
}

export async function getSavedItineraryWithLiveStatus(itineraryId, userId, targetDayOfWeek) {
  const headerRows = await query(
    `
      SELECT id, user_id, title, total_days, total_estimated_cost, preferences_snapshot, created_at, updated_at
      FROM itineraries
      WHERE id = ? AND user_id = ?
      LIMIT 1
    `,
    [itineraryId, userId],
  );

  if (headerRows.length === 0) return null;

  const day = Number.isInteger(targetDayOfWeek) ? targetDayOfWeek : new Date().getDay();
  const itemRows = await query(
    `
      SELECT
        ii.id AS item_id,
        ii.destination_id,
        ii.day_number,
        ii.sequence_order,
        ii.scheduled_time,
        ii.meal_window,
        ii.estimated_duration_minutes,
        ii.travel_time_from_prev_minutes,
        d.slug,
        d.name,
        d.lgu_code,
        l.name AS lgu_name,
        d.category_code,
        d.latitude,
        d.longitude,
        d.verification_status,
        d.popularity_tier,
        d.is_community_based,
        oh.opening_time,
        oh.closing_time,
        oh.is_24_hours,
        oh.temporarily_closed,
        p.entrance_fee_adult,
        p.mandatory_activity_fee
      FROM itinerary_items ii
      INNER JOIN destinations d ON d.id = ii.destination_id
      INNER JOIN lgus l ON l.lgu_code = d.lgu_code
      LEFT JOIN operating_hours oh ON oh.destination_id = d.id AND oh.day_of_week = ?
      LEFT JOIN pricing_tiers p ON p.destination_id = d.id
      WHERE ii.itinerary_id = ?
      ORDER BY ii.day_number ASC, ii.sequence_order ASC
    `,
    [day, itineraryId],
  );

  return { itinerary: headerRows[0], items: itemRows };
}

export async function deleteSavedItinerary(itineraryId, userId) {
  const result = await query(
    'DELETE FROM itineraries WHERE id = ? AND user_id = ?',
    [itineraryId, userId],
  );
  return result.affectedRows > 0;
}

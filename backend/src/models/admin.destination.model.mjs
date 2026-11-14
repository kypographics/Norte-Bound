import { getDbPool, query } from '../config/db.mjs';

const UPDATABLE_COLUMNS = [
  'name',
  'slug',
  'lgu_code',
  'category_code',
  'description',
  'historical_background',
  'address',
  'latitude',
  'longitude',
  'entity_type',
  'popularity_tier',
  'highway_accessible',
  'road_condition',
  'verification_status',
  'source_name',
  'source_type',
];

function today() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function verificationDate(status) {
  return status === 'verified' ? today() : null;
}

function normalizeColumnValue(column, value) {
  if (column === 'highway_accessible') {
    return value ? 1 : 0;
  }

  return value;
}

async function replaceTags(connection, destinationId, tags) {
  await connection.execute(
    'DELETE FROM destination_tags WHERE destination_id = ?',
    [destinationId],
  );

  const uniqueTags = [...new Set(tags ?? [])];

  if (uniqueTags.length === 0) {
    return;
  }

  const placeholders = uniqueTags.map(() => '(?, ?)').join(', ');
  const params = uniqueTags.flatMap((tag) => [destinationId, tag]);

  await connection.execute(
    `INSERT INTO destination_tags (destination_id, tag_slug) VALUES ${placeholders}`,
    params,
  );
}

async function replaceOperatingHours(connection, destinationId, operatingHours) {
  await connection.execute(
    'DELETE FROM operating_hours WHERE destination_id = ?',
    [destinationId],
  );

  if (!Array.isArray(operatingHours) || operatingHours.length === 0) {
    return;
  }

  const placeholders = operatingHours.map(() => '(?, ?, ?, ?, ?, ?)').join(', ');
  const params = operatingHours.flatMap((slot) => [
    destinationId,
    slot.day_of_week,
    slot.opening_time ?? null,
    slot.closing_time ?? null,
    slot.is_24_hours ? 1 : 0,
    slot.temporarily_closed ? 1 : 0,
  ]);

  await connection.execute(
    `
      INSERT INTO operating_hours (
        destination_id,
        day_of_week,
        opening_time,
        closing_time,
        is_24_hours,
        temporarily_closed
      ) VALUES ${placeholders}
    `,
    params,
  );
}

async function upsertPricing(connection, destinationId, pricing) {
  if (!pricing) {
    return;
  }

  await connection.execute(
    `
      INSERT INTO pricing_tiers (
        destination_id,
        entrance_fee_adult,
        entrance_fee_concession,
        mandatory_activity_fee,
        estimated_meal_min,
        estimated_meal_max,
        parking_fee,
        is_free,
        currency
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
    `,
    [
      destinationId,
      pricing.entrance_fee_adult ?? 0,
      pricing.entrance_fee_concession ?? 0,
      pricing.mandatory_activity_fee ?? 0,
      pricing.estimated_meal_min ?? 0,
      pricing.estimated_meal_max ?? 0,
      pricing.parking_fee ?? 0,
      pricing.is_free ? 1 : 0,
      pricing.currency ?? 'PHP',
    ],
  );
}

export async function createDestination(data) {
  const connection = await getDbPool().getConnection();

  try {
    await connection.beginTransaction();

    const [result] = await connection.execute(
      `
        INSERT INTO destinations (
          slug,
          name,
          lgu_code,
          category_code,
          description,
          historical_background,
          address,
          latitude,
          longitude,
          entity_type,
          popularity_tier,
          highway_accessible,
          road_condition,
          verification_status,
          source_name,
          source_type,
          last_verified_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        data.slug,
        data.name,
        data.lgu_code,
        data.category_code,
        data.description,
        data.historical_background ?? null,
        data.address,
        data.latitude,
        data.longitude,
        data.entity_type,
        data.popularity_tier,
        data.highway_accessible ? 1 : 0,
        data.road_condition ?? 'paved_all_weather',
        data.verification_status,
        data.source_name ?? null,
        data.source_type ?? null,
        verificationDate(data.verification_status),
      ],
    );

    const destinationId = result.insertId;

    await replaceTags(connection, destinationId, data.tags);
    await replaceOperatingHours(connection, destinationId, data.operatingHours);
    await upsertPricing(connection, destinationId, data.pricing);

    await connection.commit();

    return destinationId;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

export async function updateDestination(id, data) {
  const connection = await getDbPool().getConnection();

  try {
    await connection.beginTransaction();

    const [existingRows] = await connection.execute(
      'SELECT id, slug FROM destinations WHERE id = ? FOR UPDATE',
      [id],
    );

    if (existingRows.length === 0) {
      await connection.rollback();
      return null;
    }

    const assignments = [];
    const params = [];

    for (const column of UPDATABLE_COLUMNS) {
      if (data[column] === undefined) {
        continue;
      }

      assignments.push(`${column} = ?`);
      params.push(normalizeColumnValue(column, data[column]));
    }

    if (data.verification_status !== undefined) {
      assignments.push('last_verified_date = ?');
      params.push(verificationDate(data.verification_status));
    }

    if (assignments.length > 0) {
      await connection.execute(
        `UPDATE destinations SET ${assignments.join(', ')} WHERE id = ?`,
        [...params, id],
      );
    }

    if (data.tags !== undefined) {
      await replaceTags(connection, id, data.tags);
    }

    if (data.operatingHours !== undefined) {
      await replaceOperatingHours(connection, id, data.operatingHours);
    }

    if (data.pricing !== undefined) {
      await upsertPricing(connection, id, data.pricing);
    }

    const [updatedRows] = await connection.execute(
      'SELECT slug FROM destinations WHERE id = ?',
      [id],
    );

    await connection.commit();

    return updatedRows[0]?.slug ?? existingRows[0].slug;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

export async function updateVerificationStatus(id, {
  verificationStatus,
  sourceName,
  sourceTypeName,
}) {
  const existingRows = await query(
    'SELECT id, slug FROM destinations WHERE id = ? LIMIT 1',
    [id],
  );

  if (existingRows.length === 0) {
    return null;
  }

  const assignments = [
    'verification_status = ?',
    'last_verified_date = ?',
  ];
  const params = [
    verificationStatus,
    verificationDate(verificationStatus),
  ];

  if (sourceName !== undefined) {
    assignments.push('source_name = ?');
    params.push(sourceName);
  }

  if (sourceTypeName !== undefined) {
    assignments.push('source_type = ?');
    params.push(sourceTypeName);
  }

  await query(
    `UPDATE destinations SET ${assignments.join(', ')} WHERE id = ?`,
    [...params, id],
  );

  return {
    id: existingRows[0].id,
    slug: existingRows[0].slug,
  };
}

export async function deleteDestination(id) {
  const connection = await getDbPool().getConnection();

  try {
    await connection.beginTransaction();

    const [result] = await connection.execute(
      'DELETE FROM destinations WHERE id = ?',
      [id],
    );

    if (result.affectedRows === 0) {
      await connection.rollback();
      return false;
    }

    await connection.commit();

    return true;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

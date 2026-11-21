import { query } from '../config/db.mjs';

const USER_COLUMNS =
  'id, email, password_hash, full_name, role, travel_preferences, created_at, updated_at';

export async function createUser({ email, passwordHash, fullName, role = 'tourist' }) {
  const result = await query(
    'INSERT INTO users (email, password_hash, full_name, role) VALUES (?, ?, ?, ?) RETURNING id',
    [email, passwordHash, fullName, role],
  );

  return findUserById(result.insertId ?? result[0]?.id);
}

export async function findUserByEmail(email) {
  const rows = await query(
    `SELECT ${USER_COLUMNS} FROM users WHERE email = ? LIMIT 1`,
    [email],
  );

  return rows[0] ?? null;
}

export async function findUserById(id) {
  const rows = await query(
    `SELECT ${USER_COLUMNS} FROM users WHERE id = ? LIMIT 1`,
    [id],
  );

  return rows[0] ?? null;
}

export async function updateUserProfile(id, { fullName, travelPreferences }) {
  const assignments = [];
  const params = [];

  if (fullName !== undefined) {
    assignments.push('full_name = ?');
    params.push(fullName);
  }

  if (travelPreferences !== undefined) {
    assignments.push('travel_preferences = ?');
    params.push(
      travelPreferences === null ? null : JSON.stringify(travelPreferences),
    );
  }

  if (assignments.length === 0) {
    return findUserById(id);
  }

  params.push(id);

  await query(
    `UPDATE users SET ${assignments.join(', ')} WHERE id = ?`,
    params,
  );

  return findUserById(id);
}

export async function updateUserPassword(id, passwordHash) {
  const result = await query(
    'UPDATE users SET password_hash = ? WHERE id = ?',
    [passwordHash, id],
  );

  return result.affectedRows > 0;
}

import { query } from '../config/db.mjs';

const USER_COLUMNS = 'id, email, password_hash, full_name, role, created_at, updated_at';

export async function createUser({ email, passwordHash, fullName, role = 'tourist' }) {
  const result = await query(
    'INSERT INTO users (email, password_hash, full_name, role) VALUES (?, ?, ?, ?)',
    [email, passwordHash, fullName, role],
  );

  return findUserById(result.insertId);
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

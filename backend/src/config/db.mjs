import pg from 'pg';
import { env } from './env.mjs';

const { Pool } = pg;

let pool = null;

export function toPgSql(sql) {
  let index = 0;
  let inSingleQuote = false;
  let out = '';

  for (let i = 0; i < sql.length; i += 1) {
    const ch = sql[i];
    if (ch === "'") {
      inSingleQuote = !inSingleQuote;
      out += ch;
    } else if (ch === '?' && !inSingleQuote) {
      index += 1;
      out += `$${index}`;
    } else {
      out += ch;
    }
  }
  return out;
}

function createPoolConfig() {
  const ssl = env.DB_SSL ? { rejectUnauthorized: false } : false;

  if (env.DATABASE_URL) {
    return {
      connectionString: env.DATABASE_URL,
      ssl,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    };
  }

  return {
    host: env.DB_HOST,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    database: env.DB_NAME,
    port: env.DB_PORT,
    ssl,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  };
}

function getPool() {
  if (!pool) {
    pool = new Pool(createPoolConfig());
  }
  return pool;
}

export function getDbPool() {
  const pgPool = getPool();

  return {
    async getConnection() {
      const client = await pgPool.connect();
      return {
        async beginTransaction() {
          await client.query('BEGIN');
        },
        async commit() {
          await client.query('COMMIT');
        },
        async rollback() {
          await client.query('ROLLBACK');
        },
        async execute(sql, params = []) {
          const res = await client.query(toPgSql(sql), params);
          const rows = res.rows ?? [];
          rows.affectedRows = res.rowCount ?? 0;
          rows.insertId = rows[0]?.id ?? null;
          return [rows, res];
        },
        release() {
          client.release();
        },
      };
    },
  };
}

export async function query(sql, params = []) {
  const res = await getPool().query(toPgSql(sql), params);
  const rows = res.rows ?? [];
  rows.affectedRows = res.rowCount ?? 0;
  rows.insertId = rows[0]?.id ?? null;
  return rows;
}

export async function pingDatabase() {
  await getPool().query('SELECT 1');
  return true;
}

export async function closePool() {
  if (!pool) {
    return;
  }
  const currentPool = pool;
  pool = null;
  await currentPool.end();
}

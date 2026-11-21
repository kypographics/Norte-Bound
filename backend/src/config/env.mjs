import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';
import { z } from 'zod';

const currentDir = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(currentDir, '../../.env') });

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(5000),

  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_PUBLISHABLE_KEY: z.string().optional(),
  DATABASE_URL: z.string().trim().optional(),

  DB_HOST: z.string().trim().default('aws-1-ap-southeast-1.pooler.supabase.com'),
  DB_USER: z.string().trim().default('postgres'),
  DB_PASSWORD: z.string().default(''),
  DB_NAME: z.string().trim().default('postgres'),
  DB_PORT: z.coerce.number().int().positive().default(5432),
  DB_SSL: z
    .string()
    .optional()
    .transform((v) => v === undefined || v === 'true' || v === '1'),

  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  ADMIN_INVITE_CODE: z
    .string()
    .trim()
    .min(1, 'ADMIN_INVITE_CODE is required')
    .default('NORTE-CURATOR-2026'),
  GEMINI_API_KEY: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const details = parsed.error.issues
    .map((issue) => `  - ${issue.path.join('.') || 'environment'}: ${issue.message}`)
    .join('\n');

  console.error(`[config] Invalid environment configuration:\n${details}`);
  console.error('[config] Copy backend/.env.example to backend/.env and provide valid values.');
  process.exit(1);
}

export const env = Object.freeze(parsed.data);

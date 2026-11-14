import { z } from 'zod';

const emailSchema = z
  .string()
  .trim()
  .toLowerCase()
  .email('A valid email address is required.');

export const registerSchema = z.object({
  email: emailSchema,
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters.')
    .max(72, 'Password must be at most 72 characters.'),
  full_name: z
    .string()
    .trim()
    .min(2, 'Full name must be at least 2 characters.')
    .max(150, 'Full name must be at most 150 characters.'),
  role: z.enum(['tourist', 'admin']).default('tourist'),
});

export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required.'),
});

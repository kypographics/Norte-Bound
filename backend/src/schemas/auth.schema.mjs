import { z } from 'zod';

const emailSchema = z
  .string()
  .trim()
  .toLowerCase()
  .email('A valid email address is required.');

const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters.')
  .max(72, 'Password must be at most 72 characters.');

const travelPreferencesSchema = z.object({
  defaultTransportMode: z.enum(['motorcycle', 'privateCar', 'publicCommute']),
  defaultBudgetScope: z.enum(['perPerson', 'totalGroup']),
  defaultGroupSize: z
    .number()
    .int('Group size must be a whole number.')
    .min(1, 'Group size must be at least 1.')
    .max(50, 'Group size must be at most 50.'),
  defaultPacing: z.enum(['relaxed', 'moderate', 'packed']),
  favoriteTags: z
    .array(z.string().trim().min(1, 'Favorite tags cannot be empty.'))
    .max(50, 'At most 50 favorite tags are allowed.')
    .default([]),
});

export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  full_name: z
    .string()
    .trim()
    .min(2, 'Full name must be at least 2 characters.')
    .max(150, 'Full name must be at most 150 characters.'),
  role: z.enum(['tourist', 'admin']).default('tourist'),
  adminInviteCode: z
    .string()
    .trim()
    .min(1, 'A curator invite code is required.')
    .max(100, 'The curator invite code is too long.')
    .optional(),
});

export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required.'),
});

export const updateProfileSchema = z
  .object({
    fullName: z
      .string()
      .trim()
      .min(2, 'Full name must be at least 2 characters.')
      .max(100, 'Full name must be at most 100 characters.')
      .optional(),
    travelPreferences: travelPreferencesSchema.optional(),
  })
  .refine(
    (data) =>
      data.fullName !== undefined || data.travelPreferences !== undefined,
    {
      message: 'Provide a full name or travel preferences to update.',
    },
  );

export const changePasswordSchema = z.object({
  currentPassword: z
    .string()
    .min(1, 'Your current password is required.')
    .max(72, 'Your current password is too long.'),
  newPassword: passwordSchema,
});

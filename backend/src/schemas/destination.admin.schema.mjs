import { z } from 'zod';

const ENTITY_TYPES = ['attraction', 'food_establishment', 'cultural_experience', 'activity_hub'];
const POPULARITY_TIERS = ['iconic_hub', 'moderate', 'hidden_gem'];
const VERIFICATION_STATUSES = ['verified', 'needs_field_verification'];
const ROAD_CONDITIONS = ['paved_all_weather', 'rough_patch', '4x4_or_trek_required'];
const SOURCE_TYPES = [
  'provincial_tourism',
  'lgu_official',
  'dot_accredited',
  'verified_establishment',
];

const TIME_PATTERN = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

const emptyToUndefined = (value) => (
  typeof value === 'string' && value.trim() === '' ? undefined : value
);

const requiredString = (maxLength, minLength = 1) => z
  .string()
  .trim()
  .min(minLength, `Must be at least ${minLength} characters.`)
  .max(maxLength, `Must be at most ${maxLength} characters.`);

const optionalNullableString = (maxLength) => z.preprocess(
  emptyToUndefined,
  z.string().trim().max(maxLength).nullable().optional(),
);

const tagSchema = z.string().trim().min(1).max(64);

const tagsSchema = z.array(tagSchema).max(100);

const timeSchema = z
  .string()
  .regex(TIME_PATTERN, 'Time must use HH:MM or HH:MM:SS format.')
  .nullable()
  .optional();

const operatingHourSchema = z.object({
  day_of_week: z.coerce.number().int().min(0).max(6),
  opening_time: timeSchema,
  closing_time: timeSchema,
  is_24_hours: z.boolean().default(false),
  temporarily_closed: z.boolean().default(false),
});

const operatingHoursSchema = z
  .array(operatingHourSchema)
  .length(7, 'Exactly 7 operating-hour entries are required.')
  .superRefine((slots, ctx) => {
    const days = new Set(slots.map((slot) => slot.day_of_week));

    if (days.size !== 7) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Each day of the week (0-6) must appear exactly once.',
      });
    }

    for (let day = 0; day <= 6; day += 1) {
      if (!days.has(day)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `Missing operating hours for day_of_week ${day}.`,
        });
      }
    }
  });

const moneySchema = z.coerce.number().min(0).max(99999999.99);

const pricingSchema = z
  .object({
    entrance_fee_adult: moneySchema.default(0),
    entrance_fee_concession: moneySchema.default(0),
    mandatory_activity_fee: moneySchema.default(0),
    estimated_meal_min: moneySchema.default(0),
    estimated_meal_max: moneySchema.default(0),
    parking_fee: moneySchema.default(0),
    is_free: z.boolean().optional(),
    currency: z.string().trim().length(3).transform((value) => value.toUpperCase()).default('PHP'),
  })
  .refine((pricing) => pricing.estimated_meal_max >= pricing.estimated_meal_min, {
    message: 'estimated_meal_max must be greater than or equal to estimated_meal_min.',
    path: ['estimated_meal_max'],
  })
  .transform((pricing) => ({
    ...pricing,
    is_free: pricing.is_free ?? (
      pricing.entrance_fee_adult === 0
      && pricing.entrance_fee_concession === 0
      && pricing.mandatory_activity_fee === 0
    ),
  }));

const destinationFields = {
  name: requiredString(200, 2),
  slug: z
    .string()
    .trim()
    .min(1)
    .max(191)
    .regex(
      /^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      'Slug must contain lowercase letters, numbers, and single hyphens only.',
    ),
  lgu_code: requiredString(64),
  category_code: requiredString(64),
  description: requiredString(10000),
  address: requiredString(255),
  latitude: z.coerce
    .number()
    .min(17.8, 'Latitude must be within Ilocos Norte.')
    .max(18.68, 'Latitude must be within Ilocos Norte.'),
  longitude: z.coerce
    .number()
    .min(120.4, 'Longitude must be within Ilocos Norte.')
    .max(121.05, 'Longitude must be within Ilocos Norte.'),
  entity_type: z.enum(ENTITY_TYPES),
  popularity_tier: z.enum(POPULARITY_TIERS),
  verification_status: z.enum(VERIFICATION_STATUSES),
  historical_background: optionalNullableString(10000),
  highway_accessible: z.boolean(),
  road_condition: z.enum(ROAD_CONDITIONS),
  source_name: optionalNullableString(255),
  source_type: z.enum(SOURCE_TYPES).nullable().optional(),
  tags: tagsSchema,
  operatingHours: operatingHoursSchema,
  pricing: pricingSchema,
};

export const createDestinationSchema = z.object({
  ...destinationFields,
  highway_accessible: destinationFields.highway_accessible.default(false),
  road_condition: destinationFields.road_condition.default('paved_all_weather'),
  tags: destinationFields.tags.default([]),
  operatingHours: operatingHoursSchema.optional(),
  pricing: pricingSchema.optional(),
});

export const updateDestinationSchema = z
  .object(destinationFields)
  .partial()
  .refine((data) => Object.values(data).some((value) => value !== undefined), {
    message: 'At least one destination field must be provided.',
  });

export const updateDestinationStatusSchema = z.object({
  verification_status: z.enum(VERIFICATION_STATUSES),
  source_name: optionalNullableString(255),
  source_type: z.enum(SOURCE_TYPES).nullable().optional(),
});

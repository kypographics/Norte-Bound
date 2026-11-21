import { z } from 'zod';

const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/;

export const sceneryValues = [
  'coastal',
  'highland',
  'heritage_urban',
  'rural_agro',
];

export const parseIntentSchema = z.object({
  prompt: z.string().trim().min(3, 'Describe your trip in at least 3 characters.').max(800),
  originLguCode: z.string().trim().min(1).optional(),
  currentLocation: z
    .object({
      latitude: z.number().min(17.5).max(19.0),
      longitude: z.number().min(120.0).max(121.5),
    })
    .optional(),
});

export const tripPreferencesBodySchema = z.object({
  categories: z.array(z.string().trim().min(1)).default([]),
  interestTags: z.array(z.string().trim().min(1)).default([]),
  preferredScenery: z.array(z.enum(sceneryValues)).default([]),
  preferredLgus: z.array(z.string().trim().min(1)).default([]),
  preferredClusters: z.array(z.string().trim().min(1)).default([]),
  budgetAmount: z.coerce.number().min(0).max(200000).nullable().default(2500),
  budgetLevel: z.enum(['budget', 'moderate', 'flexible']).default('moderate'),
  budgetScope: z.enum(['perPerson', 'totalGroup']).default('perPerson'),
  availableDays: z.coerce.number().int().min(1).max(7).default(1),
  availableHoursPerDay: z.coerce.number().min(2).max(14).default(9),
  startTime: z.string().regex(timeRegex, 'startTime must be HH:mm').default('08:00'),
  endTime: z.string().regex(timeRegex, 'endTime must be HH:mm').default('18:00'),
  originLguCode: z.string().trim().min(1).default('laoag-city'),
  originCoordinates: z
    .object({
      latitude: z.number(),
      longitude: z.number(),
    })
    .optional(),
  groupSize: z.coerce.number().int().min(1).max(50).default(1),
  transportMode: z
    .enum(['motorcycle', 'privateCar', 'publicCommute'])
    .default('motorcycle'),
  pacing: z.enum(['relaxed', 'moderate', 'packed']).default('moderate'),
  dayOfWeek: z.coerce.number().int().min(0).max(6).optional(),
  limit: z.coerce.number().int().min(1).max(40).default(12),
  lockedDestinationIds: z.array(z.coerce.number().int().positive()).default([]),
  excludedDestinationIds: z.array(z.coerce.number().int().positive()).default([]),
});

export const saveItinerarySchema = z.object({
  title: z.string().trim().min(2).max(200),
  totalDays: z.coerce.number().int().min(1).max(7),
  totalEstimatedCost: z.coerce.number().min(0),
  preferencesSnapshot: z.record(z.string(), z.unknown()).optional(),
  items: z
    .array(
      z.object({
        destinationId: z.coerce.number().int().positive(),
        dayNumber: z.coerce.number().int().min(1).max(7),
        sequenceOrder: z.coerce.number().int().min(1),
        scheduledTime: z.string().trim().max(16).nullable().optional(),
        mealWindow: z
          .enum(['breakfast', 'lunch', 'merienda', 'dinner'])
          .nullable()
          .optional(),
        estimatedDurationMinutes: z.coerce.number().int().min(0).default(60),
        travelTimeFromPrevMinutes: z.coerce.number().int().min(0).default(0),
      }),
    )
    .min(1, 'At least one itinerary stop is required.'),
});

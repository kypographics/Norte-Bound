import { z } from 'zod';

const emptyToUndefined = (value) => (
  typeof value === 'string' && value.trim() === '' ? undefined : value
);

const optionalFilter = (maxLength) => z.preprocess(
  emptyToUndefined,
  z.string().trim().min(1).max(maxLength).optional(),
);

export const destinationQuerySchema = z.object({
  lgu_code: optionalFilter(64),
  cluster: optionalFilter(64),
  category_code: optionalFilter(64),
  popularity_tier: z.preprocess(
    emptyToUndefined,
    z.enum(['iconic_hub', 'moderate', 'hidden_gem']).optional(),
  ),
  is_free: z.preprocess(
    emptyToUndefined,
    z.enum(['true', 'false', '1', '0'])
      .transform((value) => value === 'true' || value === '1')
      .optional(),
  ),
  q: optionalFilter(100),
  page: z.preprocess(
    emptyToUndefined,
    z.coerce.number().int().min(1).default(1),
  ),
  limit: z.preprocess(
    emptyToUndefined,
    z.coerce.number().int().min(1).max(100).default(20),
  ),
});

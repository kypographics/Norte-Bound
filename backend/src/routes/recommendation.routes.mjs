import { Router } from 'express';
import {
  parseIntent,
  recommendDestinations,
} from '../controllers/recommendation.controller.mjs';
import { verifyToken } from '../middlewares/auth.mjs';
import { validate } from '../middlewares/validate.mjs';
import {
  parseIntentSchema,
  tripPreferencesBodySchema,
} from '../schemas/recommendation.schema.mjs';

const router = Router();

router.use(verifyToken);

router.post('/parse-intent', validate(parseIntentSchema), parseIntent);
router.post('/', validate(tripPreferencesBodySchema), recommendDestinations);

export default router;

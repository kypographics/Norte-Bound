import { Router } from 'express';
import {
  generateItinerary,
  getItineraryDetail,
  listItineraries,
  removeItinerary,
  saveItinerary,
} from '../controllers/itinerary.controller.mjs';
import { verifyToken } from '../middlewares/auth.mjs';
import { validate } from '../middlewares/validate.mjs';
import {
  saveItinerarySchema,
  tripPreferencesBodySchema,
} from '../schemas/recommendation.schema.mjs';

const router = Router();

router.use(verifyToken);

router.post('/generate', validate(tripPreferencesBodySchema), generateItinerary);
router.post('/', validate(saveItinerarySchema), saveItinerary);
router.get('/', listItineraries);
router.get('/:id', getItineraryDetail);
router.delete('/:id', removeItinerary);

export default router;

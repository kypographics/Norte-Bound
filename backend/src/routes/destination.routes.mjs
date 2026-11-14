import { Router } from 'express';
import {
  getDestinationDetail,
  getDestinations,
  getLgus,
  getTaxonomy,
} from '../controllers/destination.controller.mjs';
import { validateQuery } from '../middlewares/validate.mjs';
import { destinationQuerySchema } from '../schemas/destination.schema.mjs';

const router = Router();

router.get('/lgus', getLgus);
router.get('/taxonomy', getTaxonomy);
router.get('/', validateQuery(destinationQuerySchema), getDestinations);
router.get('/:slug', getDestinationDetail);

export default router;

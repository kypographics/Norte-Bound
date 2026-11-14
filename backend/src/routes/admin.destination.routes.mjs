import { Router } from 'express';
import {
  createDestination,
  removeDestination,
  updateDestination,
  updateStatus,
} from '../controllers/admin.destination.controller.mjs';
import { requireRole, verifyToken } from '../middlewares/auth.mjs';
import { validate } from '../middlewares/validate.mjs';
import {
  createDestinationSchema,
  updateDestinationSchema,
  updateDestinationStatusSchema,
} from '../schemas/destination.admin.schema.mjs';

const router = Router();

router.use(verifyToken, requireRole('admin'));

router.post('/', validate(createDestinationSchema), createDestination);
router.put('/:id', validate(updateDestinationSchema), updateDestination);
router.patch('/:id/status', validate(updateDestinationStatusSchema), updateStatus);
router.delete('/:id', removeDestination);

export default router;

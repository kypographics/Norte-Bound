import { Router } from 'express';
import {
  changePassword,
  getMe,
  login,
  register,
  updateProfile,
} from '../controllers/auth.controller.mjs';
import { verifyToken } from '../middlewares/auth.mjs';
import { validate } from '../middlewares/validate.mjs';
import {
  changePasswordSchema,
  loginSchema,
  registerSchema,
  updateProfileSchema,
} from '../schemas/auth.schema.mjs';

const router = Router();

router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);
router.get('/me', verifyToken, getMe);
router.put('/profile', verifyToken, validate(updateProfileSchema), updateProfile);
router.put(
  '/password',
  verifyToken,
  validate(changePasswordSchema),
  changePassword,
);

export default router;

import { Router } from 'express';
import { getMe, login, register } from '../controllers/auth.controller.mjs';
import { verifyToken } from '../middlewares/auth.mjs';
import { validate } from '../middlewares/validate.mjs';
import { loginSchema, registerSchema } from '../schemas/auth.schema.mjs';

const router = Router();

router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);
router.get('/me', verifyToken, getMe);

export default router;

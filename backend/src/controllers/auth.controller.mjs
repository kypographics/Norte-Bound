import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.mjs';
import {
  createUser,
  findUserByEmail,
  findUserById,
  updateUserPassword,
  updateUserProfile,
} from '../models/user.model.mjs';

const BCRYPT_ROUNDS = 10;
const TOKEN_EXPIRES_IN = '7d';

function parseTravelPreferences(value) {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch {
      return null;
    }
  }

  return value;
}

function toSafeUser(user) {
  return {
    id: user.id,
    email: user.email,
    fullName: user.full_name,
    role: user.role,
    travelPreferences: parseTravelPreferences(user.travel_preferences),
    createdAt: user.created_at,
    updatedAt: user.updated_at,
  };
}

function generateToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    env.JWT_SECRET,
    { expiresIn: TOKEN_EXPIRES_IN },
  );
}

function invalidCredentials(res) {
  return res.status(401).json({
    success: false,
    error: {
      code: 'INVALID_CREDENTIALS',
      message: 'Invalid email or password.',
    },
  });
}

export async function register(req, res, next) {
  try {
    const { email, password, full_name: fullName, adminInviteCode } = req.body;
    const role = req.body.role ?? 'tourist';

    if (role === 'admin' && adminInviteCode !== env.ADMIN_INVITE_CODE) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'INVALID_ADMIN_INVITE_CODE',
          message: 'Invalid curator invite code',
        },
      });
    }

    const existingUser = await findUserByEmail(email);

    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: {
          code: 'EMAIL_ALREADY_REGISTERED',
          message: 'An account with this email address already exists.',
        },
      });
    }

    const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const user = await createUser({ email, passwordHash, fullName, role });
    const token = generateToken(user);

    return res.status(201).json({
      success: true,
      user: toSafeUser(user),
      token,
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        success: false,
        error: {
          code: 'EMAIL_ALREADY_REGISTERED',
          message: 'An account with this email address already exists.',
        },
      });
    }

    return next(error);
  }
}

export async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    const user = await findUserByEmail(email);

    if (!user) {
      return invalidCredentials(res);
    }

    const passwordMatches = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatches) {
      return invalidCredentials(res);
    }

    const token = generateToken(user);

    return res.status(200).json({
      success: true,
      user: toSafeUser(user),
      token,
    });
  } catch (error) {
    return next(error);
  }
}

export async function getMe(req, res, next) {
  try {
    const user = await findUserById(req.user.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'The authenticated user no longer exists.',
        },
      });
    }

    return res.status(200).json({
      success: true,
      user: toSafeUser(user),
    });
  } catch (error) {
    return next(error);
  }
}

export async function updateProfile(req, res, next) {
  try {
    const { fullName, travelPreferences } = req.body;
    const user = await updateUserProfile(req.user.id, {
      fullName,
      travelPreferences,
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'The authenticated user no longer exists.',
        },
      });
    }

    return res.status(200).json({
      success: true,
      user: toSafeUser(user),
    });
  } catch (error) {
    return next(error);
  }
}

export async function changePassword(req, res, next) {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await findUserById(req.user.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'The authenticated user no longer exists.',
        },
      });
    }

    const passwordMatches = await bcrypt.compare(
      currentPassword,
      user.password_hash,
    );

    if (!passwordMatches) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_CURRENT_PASSWORD',
          message: 'Current password is incorrect.',
        },
      });
    }

    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    const updated = await updateUserPassword(user.id, passwordHash);

    if (!updated) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'The authenticated user no longer exists.',
        },
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Password updated successfully.',
    });
  } catch (error) {
    return next(error);
  }
}

import jwt from 'jsonwebtoken';
import { env } from '../config/env.mjs';

export function verifyToken(req, res, next) {
  const authorization = req.headers.authorization;
  const match = typeof authorization === 'string'
    ? authorization.match(/^Bearer\s+(.+)$/i)
    : null;

  if (!match || !match[1].trim()) {
    return res.status(401).json({
      success: false,
      error: {
        code: 'AUTH_TOKEN_MISSING',
        message: 'A Bearer token is required to access this resource.',
      },
    });
  }

  try {
    const payload = jwt.verify(match[1].trim(), env.JWT_SECRET, {
      algorithms: ['HS256'],
    });

    if (typeof payload !== 'object' || payload === null || payload.id === undefined) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'AUTH_TOKEN_INVALID',
          message: 'The provided authentication token is invalid.',
        },
      });
    }

    req.user = {
      id: payload.id,
      email: payload.email,
      role: payload.role,
    };

    return next();
  } catch (error) {
    const expired = error instanceof jwt.TokenExpiredError;

    return res.status(401).json({
      success: false,
      error: {
        code: expired ? 'AUTH_TOKEN_EXPIRED' : 'AUTH_TOKEN_INVALID',
        message: expired
          ? 'The authentication token has expired.'
          : 'The provided authentication token is invalid.',
      },
    });
  }
}

export function requireRole(role) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'AUTHENTICATION_REQUIRED',
          message: 'Authentication is required to access this resource.',
        },
      });
    }

    if (req.user.role === role || req.user.role === 'admin') {
      return next();
    }

    return res.status(403).json({
      success: false,
      error: {
        code: 'FORBIDDEN',
        message: `This resource requires the '${role}' role.`,
      },
    });
  };
}

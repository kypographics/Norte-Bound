import { env } from '../config/env.mjs';

const isProduction = env.NODE_ENV === 'production';

export function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.originalUrl} was not found.`,
    },
  });
}

export function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  const statusCode = Number(err.statusCode ?? err.status) || 500;
  const isServerError = statusCode >= 500;
  const message = isProduction && isServerError
    ? 'Internal server error.'
    : err.message || 'Internal server error.';

  if (isServerError) {
    console.error(`[error] ${req.method} ${req.originalUrl}`, err);
  }

  const body = {
    success: false,
    error: {
      code: err.code || (isServerError ? 'INTERNAL_SERVER_ERROR' : 'REQUEST_ERROR'),
      message,
    },
  };

  if (!isProduction && err.stack) {
    body.error.stack = err.stack;
  }

  res.status(statusCode).json(body);
}

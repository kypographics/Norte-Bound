function sendValidationError(res, issues) {
  return res.status(400).json({
    success: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'Request validation failed.',
      details: issues.map((issue) => ({
        field: issue.path.join('.') || null,
        message: issue.message,
      })),
    },
  });
}

export function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body ?? {});

    if (!result.success) {
      return sendValidationError(res, result.error.issues);
    }

    req.body = result.data;
    return next();
  };
}

export function validateQuery(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.query ?? {});

    if (!result.success) {
      return sendValidationError(res, result.error.issues);
    }

    req.validatedQuery = result.data;
    return next();
  };
}

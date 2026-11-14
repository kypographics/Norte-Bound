import {
  createDestination as createDestinationRecord,
  deleteDestination as deleteDestinationRecord,
  updateDestination as updateDestinationRecord,
  updateVerificationStatus as updateVerificationStatusRecord,
} from '../models/admin.destination.model.mjs';
import { getDestinationBySlug } from '../models/destination.model.mjs';
import { toDestinationDetail } from '../utils/destination.mapper.mjs';

function parseDestinationId(rawValue) {
  const raw = String(rawValue ?? '');

  if (!/^\d+$/.test(raw)) {
    return null;
  }

  const id = Number(raw);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

function sendInvalidId(res) {
  return res.status(400).json({
    success: false,
    error: {
      code: 'INVALID_DESTINATION_ID',
      message: 'Destination id must be a positive integer.',
    },
  });
}

function sendNotFound(res) {
  return res.status(404).json({
    success: false,
    error: {
      code: 'DESTINATION_NOT_FOUND',
      message: 'The requested destination was not found.',
    },
  });
}

function handleCurationError(error, res, next) {
  if (error.code === 'ER_DUP_ENTRY' || error.errno === 1062) {
    return res.status(409).json({
      success: false,
      error: {
        code: 'DESTINATION_SLUG_CONFLICT',
        message: 'A destination with this slug already exists.',
      },
    });
  }

  if (
    error.code === 'ER_NO_REFERENCED_ROW_2'
    || error.code === 'ER_NO_REFERENCED_ROW'
    || error.errno === 1452
  ) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'INVALID_REFERENCE',
        message: 'One or more referenced LGUs, categories, or tags do not exist.',
      },
    });
  }

  if (error.code === 'ER_ROW_IS_REFERENCED_2' || error.errno === 1451) {
    return res.status(409).json({
      success: false,
      error: {
        code: 'DESTINATION_IN_USE',
        message: 'This destination is referenced by existing itineraries and cannot be deleted.',
      },
    });
  }

  return next(error);
}

async function fetchDestinationDetail(slug) {
  const result = await getDestinationBySlug(slug);

  if (!result) {
    return null;
  }

  return toDestinationDetail(
    result.destination,
    result.operatingHours,
    result.tags,
  );
}

export async function createDestination(req, res, next) {
  try {
    const destinationId = await createDestinationRecord(req.body);
    const created = await fetchDestinationDetail(req.body.slug);

    return res.status(201).json({
      success: true,
      message: 'Destination created successfully.',
      data: created ?? { id: destinationId, slug: req.body.slug },
    });
  } catch (error) {
    return handleCurationError(error, res, next);
  }
}

export async function updateDestination(req, res, next) {
  const id = parseDestinationId(req.params.id);

  if (!id) {
    return sendInvalidId(res);
  }

  try {
    const slug = await updateDestinationRecord(id, req.body);

    if (!slug) {
      return sendNotFound(res);
    }

    const updated = await fetchDestinationDetail(slug);

    return res.status(200).json({
      success: true,
      message: 'Destination updated successfully.',
      data: updated,
    });
  } catch (error) {
    return handleCurationError(error, res, next);
  }
}

export async function updateStatus(req, res, next) {
  const id = parseDestinationId(req.params.id);

  if (!id) {
    return sendInvalidId(res);
  }

  try {
    const updated = await updateVerificationStatusRecord(id, {
      verificationStatus: req.body.verification_status,
      sourceName: req.body.source_name,
      sourceTypeName: req.body.source_type,
    });

    if (!updated) {
      return sendNotFound(res);
    }

    const destination = await fetchDestinationDetail(updated.slug);

    return res.status(200).json({
      success: true,
      message: 'Verification status updated successfully.',
      data: destination,
    });
  } catch (error) {
    return handleCurationError(error, res, next);
  }
}

export async function removeDestination(req, res, next) {
  const id = parseDestinationId(req.params.id);

  if (!id) {
    return sendInvalidId(res);
  }

  try {
    const deleted = await deleteDestinationRecord(id);

    if (!deleted) {
      return sendNotFound(res);
    }

    return res.status(200).json({
      success: true,
      message: 'Destination deleted successfully.',
    });
  } catch (error) {
    return handleCurationError(error, res, next);
  }
}

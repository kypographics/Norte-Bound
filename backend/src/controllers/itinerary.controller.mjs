import {
  createSavedItinerary,
  deleteSavedItinerary,
  getSavedItineraryWithLiveStatus,
  listItinerariesByUser,
} from '../models/itinerary.model.mjs';
import {
  detectSavedItineraryChanges,
  generateFeasibleItinerary,
} from '../services/itinerary.service.mjs';

export async function generateItinerary(req, res, next) {
  try {
    const plan = await generateFeasibleItinerary(req.body);
    return res.status(200).json({
      success: true,
      data: plan,
    });
  } catch (error) {
    return next(error);
  }
}

export async function saveItinerary(req, res, next) {
  try {
    const itineraryId = await createSavedItinerary(req.user.id, req.body);
    const saved = await getSavedItineraryWithLiveStatus(itineraryId, req.user.id);
    return res.status(201).json({
      success: true,
      data: detectSavedItineraryChanges(saved),
    });
  } catch (error) {
    return next(error);
  }
}

export async function listItineraries(req, res, next) {
  try {
    const rows = await listItinerariesByUser(req.user.id);
    return res.status(200).json({
      success: true,
      data: rows.map((row) => ({
        id: row.id,
        title: row.title,
        totalDays: row.total_days,
        totalEstimatedCost: Number(row.total_estimated_cost ?? 0),
        stopCount: Number(row.stop_count ?? 0),
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      })),
    });
  } catch (error) {
    return next(error);
  }
}

export async function getItineraryDetail(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_ITINERARY_ID', message: 'Invalid itinerary id.' },
      });
    }

    const saved = await getSavedItineraryWithLiveStatus(id, req.user.id);
    if (!saved) {
      return res.status(404).json({
        success: false,
        error: { code: 'ITINERARY_NOT_FOUND', message: 'Itinerary not found.' },
      });
    }

    return res.status(200).json({
      success: true,
      data: detectSavedItineraryChanges(saved),
    });
  } catch (error) {
    return next(error);
  }
}

export async function removeItinerary(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_ITINERARY_ID', message: 'Invalid itinerary id.' },
      });
    }

    const deleted = await deleteSavedItinerary(id, req.user.id);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        error: { code: 'ITINERARY_NOT_FOUND', message: 'Itinerary not found.' },
      });
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    return next(error);
  }
}

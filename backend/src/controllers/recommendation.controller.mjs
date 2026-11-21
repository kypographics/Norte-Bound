import { parseNaturalLanguageIntent } from '../services/ai.intent.service.mjs';
import { getRecommendations } from '../services/recommendation.service.mjs';

export async function parseIntent(req, res, next) {
  try {
    const result = await parseNaturalLanguageIntent(req.body);
    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    return next(error);
  }
}

export async function recommendDestinations(req, res, next) {
  try {
    const result = await getRecommendations(req.body);
    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    return next(error);
  }
}

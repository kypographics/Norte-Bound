import {
  getAllCategoriesAndTags,
  getAllDestinations,
  getAllLgus,
  getDestinationBySlug,
} from '../models/destination.model.mjs';
import {
  humanize,
  parseJsonArray,
  toBoolean,
  toDestinationDetail,
  toDestinationSummary,
  toNumber,
} from '../utils/destination.mapper.mjs';

export async function getLgus(req, res, next) {
  try {
    const rows = await getAllLgus();
    const grouped = new Map();

    for (const row of rows) {
      const cluster = row.tourism_cluster;

      if (!grouped.has(cluster)) {
        grouped.set(cluster, {
          cluster,
          label: humanize(cluster),
          lgus: [],
        });
      }

      grouped.get(cluster).lgus.push({
        code: row.lgu_code,
        name: row.name,
        type: row.lgu_type,
        coordinates: {
          latitude: toNumber(row.center_latitude),
          longitude: toNumber(row.center_longitude),
        },
        terrainType: row.terrain_type,
        roadTortuosityMultiplier: toNumber(row.road_tortuosity_multiplier),
        isMajorHub: toBoolean(row.is_major_hub),
        baselineDispersalBonus: toNumber(row.baseline_dispersal_bonus),
      });
    }

    const clusters = [...grouped.values()].map((group) => ({
      ...group,
      total: group.lgus.length,
    }));

    return res.status(200).json({
      success: true,
      total: rows.length,
      data: clusters,
    });
  } catch (error) {
    return next(error);
  }
}

export async function getTaxonomy(req, res, next) {
  try {
    const { categories, tags } = await getAllCategoriesAndTags();

    return res.status(200).json({
      success: true,
      data: {
        categories: categories.map((category) => ({
          code: category.category_code,
          name: category.name,
          description: category.description,
        })),
        interestTags: tags.map((tag) => ({
          slug: tag.tag_slug,
          name: tag.display_name,
          categoryCode: tag.category_code,
          synonyms: parseJsonArray(tag.ai_synonyms),
        })),
      },
    });
  } catch (error) {
    return next(error);
  }
}

export async function getDestinations(req, res, next) {
  try {
    const filters = req.validatedQuery ?? req.query ?? {};
    const { rows, total, page, limit } = await getAllDestinations(filters);
    const totalPages = total === 0 ? 0 : Math.ceil(total / limit);

    return res.status(200).json({
      success: true,
      data: rows.map(toDestinationSummary),
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    });
  } catch (error) {
    return next(error);
  }
}

export async function getDestinationDetail(req, res, next) {
  try {
    const slug = String(req.params.slug ?? '').trim();
    const result = await getDestinationBySlug(slug);

    if (!result) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'DESTINATION_NOT_FOUND',
          message: 'The requested destination was not found.',
        },
      });
    }

    return res.status(200).json({
      success: true,
      data: toDestinationDetail(
        result.destination,
        result.operatingHours,
        result.tags,
      ),
    });
  } catch (error) {
    return next(error);
  }
}

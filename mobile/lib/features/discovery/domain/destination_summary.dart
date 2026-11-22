import '../../../core/utils/json_parse.dart';
import 'lgu.dart';

class DestinationPricing {
  const DestinationPricing({
    required this.isFree,
    this.entranceFeeAdult,
    this.estimatedMealMin,
    this.estimatedMealMax,
  });

  final bool isFree;
  final double? entranceFeeAdult;
  final double? estimatedMealMin;
  final double? estimatedMealMax;

  String get priceLabel {
    if (isFree) {
      return '₱0 Free';
    }

    if (entranceFeeAdult != null && entranceFeeAdult! > 0) {
      return '₱${_money(entranceFeeAdult!)}/pax';
    }

    if (estimatedMealMin != null && estimatedMealMax != null) {
      return '₱${_money(estimatedMealMin!)}–${_money(estimatedMealMax!)}/pax';
    }

    if (estimatedMealMin != null) {
      return '₱${_money(estimatedMealMin!)}+/pax';
    }

    return 'Verified rates';
  }

  factory DestinationPricing.fromJson(Map<String, dynamic> json) {
    return DestinationPricing(
      isFree: jsonBool(json['isFree'] ?? json['is_free']),
      entranceFeeAdult: jsonDouble(
        json['entranceFeeAdult'] ?? json['entrance_fee_adult'],
      ),
      estimatedMealMin: jsonDouble(
        json['estimatedMealMin'] ?? json['estimated_meal_min'],
      ),
      estimatedMealMax: jsonDouble(
        json['estimatedMealMax'] ?? json['estimated_meal_max'],
      ),
    );
  }
}

class DestinationTagRef {
  const DestinationTagRef({required this.slug, required this.name});

  final String slug;
  final String name;

  factory DestinationTagRef.fromJson(Map<String, dynamic> json) {
    return DestinationTagRef(
      slug: jsonString(json['slug'] ?? json['tagSlug']),
      name: jsonString(json['name'] ?? json['displayName']),
    );
  }
}

class DestinationSummary {
  const DestinationSummary({
    required this.id,
    required this.slug,
    required this.name,
    required this.lguCode,
    required this.lguName,
    required this.tourismCluster,
    required this.categoryCode,
    required this.categoryName,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.entityType,
    required this.popularityTier,
    required this.highwayAccessible,
    required this.verificationStatus,
    required this.pricing,
    required this.tags,
  });

  final int id;
  final String slug;
  final String name;
  final String lguCode;
  final String lguName;
  final String tourismCluster;
  final String categoryCode;
  final String categoryName;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String entityType;
  final String popularityTier;
  final bool highwayAccessible;
  final String verificationStatus;
  final DestinationPricing pricing;
  final List<DestinationTagRef> tags;

  bool get isHiddenGem => popularityTier == 'hidden_gem';

  bool get isIconic => popularityTier == 'iconic_hub';

  String get clusterLabel => TourismClusterInfo.labelFor(tourismCluster);

  String get priceLabel => pricing.priceLabel;

  factory DestinationSummary.fromJson(Map<String, dynamic> json) {
    final lgu = json['lgu'];
    final category = json['category'];
    final coordinates = json['coordinates'];
    final verification = json['verification'];
    final pricing = json['pricing'];
    final rawTags = json['tags'];

    return DestinationSummary(
      id: jsonInt(json['id']),
      slug: jsonString(json['slug']),
      name: jsonString(json['name']),
      lguCode: jsonString(
        json['lguCode'] ?? (lgu is Map<String, dynamic> ? lgu['code'] : null),
      ),
      lguName: jsonString(
        json['lguName'] ?? (lgu is Map<String, dynamic> ? lgu['name'] : null),
      ),
      tourismCluster: jsonString(
        json['tourismCluster'] ??
            (lgu is Map<String, dynamic> ? lgu['cluster'] : null),
      ),
      categoryCode: jsonString(
        json['categoryCode'] ??
            (category is Map<String, dynamic> ? category['code'] : null),
      ),
      categoryName: jsonString(
        json['categoryName'] ??
            (category is Map<String, dynamic> ? category['name'] : null),
      ),
      description: jsonString(json['description']),
      address: jsonString(json['address']),
      latitude: jsonDouble(
        json['latitude'] ??
            (coordinates is Map<String, dynamic>
                ? coordinates['latitude']
                : null),
      ),
      longitude: jsonDouble(
        json['longitude'] ??
            (coordinates is Map<String, dynamic>
                ? coordinates['longitude']
                : null),
      ),
      imageUrl: jsonStringNullable(json['imageUrl'] ?? json['image_url']),
      entityType: jsonString(json['entityType']),
      popularityTier: jsonString(json['popularityTier'], fallback: 'moderate'),
      highwayAccessible: jsonBool(
        json['highwayAccessible'] ?? json['highway_accessible'],
      ),
      verificationStatus: jsonString(
        json['verificationStatus'] ??
            (verification is Map<String, dynamic>
                ? verification['status']
                : null),
        fallback: 'verified',
      ),
      pricing: pricing is Map<String, dynamic>
          ? DestinationPricing.fromJson(pricing)
          : DestinationPricing(
              isFree: jsonBool(json['isFree'] ?? json['is_free']),
              entranceFeeAdult: jsonDouble(
                json['entranceFeeAdult'] ?? json['entrance_fee_adult'],
              ),
              estimatedMealMin: jsonDouble(
                json['estimatedMealMin'] ?? json['estimated_meal_min'],
              ),
              estimatedMealMax: jsonDouble(
                json['estimatedMealMax'] ?? json['estimated_meal_max'],
              ),
            ),
      tags: rawTags is List
          ? rawTags
                .whereType<Map<String, dynamic>>()
                .map(DestinationTagRef.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class DestinationPage {
  const DestinationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<DestinationSummary> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasNextPage => page < totalPages;

  bool get isEmpty => items.isEmpty;

  DestinationPage copyWith({
    List<DestinationSummary>? items,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
  }) {
    return DestinationPage(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  factory DestinationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'];
    final rawPagination = json['pagination'];
    final pagination = rawPagination is Map<String, dynamic>
        ? rawPagination
        : const <String, dynamic>{};

    if (rawItems is! List) {
      throw const FormatException('Destination response is missing data.');
    }

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(DestinationSummary.fromJson)
        .toList(growable: false);

    return DestinationPage(
      items: items,
      total: jsonInt(pagination['total'], fallback: items.length),
      page: jsonInt(pagination['page'], fallback: 1),
      limit: jsonInt(
        pagination['limit'],
        fallback: items.isEmpty ? 20 : items.length,
      ),
      totalPages: jsonInt(
        pagination['totalPages'],
        fallback: items.isEmpty ? 0 : 1,
      ),
    );
  }
}

String _money(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

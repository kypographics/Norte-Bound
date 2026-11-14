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
      isFree: _bool(json['isFree'] ?? json['is_free']),
      entranceFeeAdult: _double(
        json['entranceFeeAdult'] ?? json['entrance_fee_adult'],
      ),
      estimatedMealMin: _double(
        json['estimatedMealMin'] ?? json['estimated_meal_min'],
      ),
      estimatedMealMax: _double(
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
      slug: _string(json['slug'] ?? json['tagSlug']),
      name: _string(json['name'] ?? json['displayName']),
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
      id: _int(json['id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      lguCode: _string(
        json['lguCode'] ?? (lgu is Map<String, dynamic> ? lgu['code'] : null),
      ),
      lguName: _string(
        json['lguName'] ?? (lgu is Map<String, dynamic> ? lgu['name'] : null),
      ),
      tourismCluster: _string(
        json['tourismCluster'] ??
            (lgu is Map<String, dynamic> ? lgu['cluster'] : null),
      ),
      categoryCode: _string(
        json['categoryCode'] ??
            (category is Map<String, dynamic> ? category['code'] : null),
      ),
      categoryName: _string(
        json['categoryName'] ??
            (category is Map<String, dynamic> ? category['name'] : null),
      ),
      description: _string(json['description']),
      address: _string(json['address']),
      latitude: _double(
        json['latitude'] ??
            (coordinates is Map<String, dynamic>
                ? coordinates['latitude']
                : null),
      ),
      longitude: _double(
        json['longitude'] ??
            (coordinates is Map<String, dynamic>
                ? coordinates['longitude']
                : null),
      ),
      entityType: _string(json['entityType']),
      popularityTier: _string(json['popularityTier'], fallback: 'moderate'),
      highwayAccessible: _bool(
        json['highwayAccessible'] ?? json['highway_accessible'],
      ),
      verificationStatus: _string(
        json['verificationStatus'] ??
            (verification is Map<String, dynamic>
                ? verification['status']
                : null),
        fallback: 'verified',
      ),
      pricing: pricing is Map<String, dynamic>
          ? DestinationPricing.fromJson(pricing)
          : DestinationPricing(
              isFree: _bool(json['isFree'] ?? json['is_free']),
              entranceFeeAdult: _double(
                json['entranceFeeAdult'] ?? json['entrance_fee_adult'],
              ),
              estimatedMealMin: _double(
                json['estimatedMealMin'] ?? json['estimated_meal_min'],
              ),
              estimatedMealMax: _double(
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
      total: _int(pagination['total'], fallback: items.length),
      page: _int(pagination['page'], fallback: 1),
      limit: _int(
        pagination['limit'],
        fallback: items.isEmpty ? 20 : items.length,
      ),
      totalPages: _int(
        pagination['totalPages'],
        fallback: items.isEmpty ? 0 : 1,
      ),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  if (value is num || value is bool) {
    return value.toString();
  }

  return fallback;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

double? _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

bool _bool(Object? value) {
  return value == true || value == 1 || value == '1';
}

String _money(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

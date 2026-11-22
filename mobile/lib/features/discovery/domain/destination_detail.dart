import '../../../core/utils/json_parse.dart';
import 'destination_summary.dart';

class DestinationVerificationInfo {
  const DestinationVerificationInfo({
    required this.status,
    this.sourceName,
    this.sourceType,
    this.lastVerifiedDate,
  });

  final String status;
  final String? sourceName;
  final String? sourceType;
  final String? lastVerifiedDate;

  bool get isVerified => status.toLowerCase() == 'verified';

  String get statusLabel => _humanizeToken(status, fallback: 'Verified');

  String get sourceTypeLabel =>
      _humanizeToken(sourceType, fallback: 'Official Registry');

  factory DestinationVerificationInfo.fromJson(Map<String, dynamic> json) {
    return DestinationVerificationInfo(
      status: jsonString(json['status'] ?? json['verificationStatus'], fallback: 'verified'),
      sourceName: jsonStringNullable(json['sourceName'] ?? json['source_name']),
      sourceType: jsonStringNullable(json['sourceType'] ?? json['source_type']),
      lastVerifiedDate: jsonStringNullable(json['lastVerifiedDate'] ?? json['last_verified_date']),
    );
  }
}

class DestinationDetailPricing {
  const DestinationDetailPricing({
    required this.isFree,
    this.entranceFeeAdult,
    this.entranceFeeConcession,
    this.mandatoryActivityFee,
    this.estimatedMealMin,
    this.estimatedMealMax,
    this.parkingFee,
    this.currency = 'PHP',
  });

  final bool isFree;
  final double? entranceFeeAdult;
  final double? entranceFeeConcession;
  final double? mandatoryActivityFee;
  final double? estimatedMealMin;
  final double? estimatedMealMax;
  final double? parkingFee;
  final String currency;

  factory DestinationDetailPricing.fromJson(Map<String, dynamic> json) {
    return DestinationDetailPricing(
      isFree: jsonBool(json['isFree'] ?? json['is_free']),
      entranceFeeAdult: jsonDouble(json['entranceFeeAdult'] ?? json['entrance_fee_adult']),
      entranceFeeConcession: jsonDouble(json['entranceFeeConcession'] ?? json['entrance_fee_concession']),
      mandatoryActivityFee: jsonDouble(json['mandatoryActivityFee'] ?? json['mandatory_activity_fee']),
      estimatedMealMin: jsonDouble(json['estimatedMealMin'] ?? json['estimated_meal_min']),
      estimatedMealMax: jsonDouble(json['estimatedMealMax'] ?? json['estimated_meal_max']),
      parkingFee: jsonDouble(json['parkingFee'] ?? json['parking_fee']),
      currency: jsonString(json['currency'], fallback: 'PHP'),
    );
  }

  String formatAmount(double? amount, {String zeroLabel = '₱0'}) {
    if (amount == null || amount <= 0) {
      return zeroLabel;
    }

    final rounded = amount.roundToDouble();
    if ((amount - rounded).abs() < 0.01) {
      return '₱${rounded.toInt()}';
    }
    return '₱${amount.toStringAsFixed(2)}';
  }

  String get adultEntryLabel =>
      isFree ? '₱0 Free' : formatAmount(entranceFeeAdult, zeroLabel: '₱0 Free');

  String get concessionEntryLabel =>
      isFree ? '₱0 Free' : formatAmount(entranceFeeConcession, zeroLabel: '₱0');

  String get mandatoryActivityLabel =>
      formatAmount(mandatoryActivityFee, zeroLabel: '₱0');

  String get parkingLabel => formatAmount(parkingFee, zeroLabel: '₱0');

  String get mealRangeLabel {
    if (estimatedMealMin == null && estimatedMealMax == null) {
      return 'N/A';
    }
    final min = estimatedMealMin ?? estimatedMealMax!;
    final max = estimatedMealMax ?? estimatedMealMin!;
    if (min <= 0 && max <= 0) {
      return 'N/A';
    }
    if ((min - max).abs() < 0.01) {
      return formatAmount(min);
    }
    return '${formatAmount(min)}–${formatAmount(max).replaceFirst('₱', '')}';
  }
}

class DestinationOperationalStatus {
  const DestinationOperationalStatus({
    required this.isOpen,
    required this.isTemporarilyClosed,
    required this.hasSchedule,
    required this.label,
    required this.detailText,
  });

  final bool isOpen;
  final bool isTemporarilyClosed;
  final bool hasSchedule;
  final String label;
  final String detailText;
}

class DestinationOperatingHour {
  const DestinationOperatingHour({
    required this.dayOfWeek,
    this.dayName,
    this.openingTime,
    this.closingTime,
    required this.is24Hours,
    required this.temporarilyClosed,
  });

  final int dayOfWeek;
  final String? dayName;
  final String? openingTime;
  final String? closingTime;
  final bool is24Hours;
  final bool temporarilyClosed;

  factory DestinationOperatingHour.fromJson(Map<String, dynamic> json) {
    return DestinationOperatingHour(
      dayOfWeek: jsonInt(json['dayOfWeek'] ?? json['day_of_week']),
      dayName: jsonStringNullable(json['dayName'] ?? json['day_name']),
      openingTime: jsonStringNullable(json['openingTime'] ?? json['opening_time']),
      closingTime: jsonStringNullable(json['closingTime'] ?? json['closing_time']),
      is24Hours: jsonBool(json['is24Hours'] ?? json['is_24_hours']),
      temporarilyClosed: jsonBool(json['temporarilyClosed'] ?? json['temporarily_closed']),
    );
  }
}

class DestinationDetail {
  const DestinationDetail({
    required this.id,
    required this.slug,
    required this.name,
    required this.lguCode,
    required this.lguName,
    this.lguType,
    required this.tourismCluster,
    required this.categoryCode,
    required this.categoryName,
    this.categoryDescription,
    required this.description,
    this.historicalBackground,
    required this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.entityType,
    required this.popularityTier,
    required this.highwayAccessible,
    this.roadCondition,
    required this.verification,
    required this.pricing,
    required this.operatingHours,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String slug;
  final String name;
  final String lguCode;
  final String lguName;
  final String? lguType;
  final String tourismCluster;
  final String categoryCode;
  final String categoryName;
  final String? categoryDescription;
  final String description;
  final String? historicalBackground;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String entityType;
  final String popularityTier;
  final bool highwayAccessible;
  final String? roadCondition;
  final DestinationVerificationInfo verification;
  final DestinationDetailPricing pricing;
  final List<DestinationOperatingHour> operatingHours;
  final List<DestinationTagRef> tags;
  final String? createdAt;
  final String? updatedAt;

  bool get isHiddenGem => popularityTier == 'hidden_gem';
  bool get isIconic => popularityTier == 'iconic_hub';

  String get verificationStatus => verification.status;
  String get popularityLabel => isHiddenGem
      ? 'Hidden Gem'
      : isIconic
          ? 'Iconic Hub'
          : _humanizeToken(popularityTier, fallback: 'Verified Stop');
  String get roadConditionLabel =>
      _humanizeToken(roadCondition, fallback: highwayAccessible ? 'Paved Highway' : 'Local Road');
  String get priceLabel => pricing.isFree ? '₱0 Free' : (pricing.entranceFeeAdult != null && pricing.entranceFeeAdult! > 0 ? '₱${pricing.entranceFeeAdult!.toStringAsFixed(0)}/pax' : 'Verified rates');

  DestinationOperationalStatus operationalStatusAt([DateTime? now]) {
    if (operatingHours.isEmpty) {
      return const DestinationOperationalStatus(
        isOpen: false,
        isTemporarilyClosed: false,
        hasSchedule: false,
        label: 'Hours Unlisted',
        detailText: 'Standard hours apply',
      );
    }

    final current = now ?? DateTime.now();
    // Backend day_of_week uses 0 = Sunday .. 6 = Saturday.
    final todayIndex = current.weekday % 7;
    DestinationOperatingHour? todaySlot;
    for (final slot in operatingHours) {
      if (slot.dayOfWeek == todayIndex) {
        todaySlot = slot;
        break;
      }
    }

    if (todaySlot == null) {
      return const DestinationOperationalStatus(
        isOpen: false,
        isTemporarilyClosed: false,
        hasSchedule: false,
        label: 'Closed',
        detailText: 'No schedule for today',
      );
    }

    if (todaySlot.temporarilyClosed) {
      return const DestinationOperationalStatus(
        isOpen: false,
        isTemporarilyClosed: true,
        hasSchedule: true,
        label: 'Closed',
        detailText: 'Temporarily closed today',
      );
    }

    if (todaySlot.is24Hours) {
      return const DestinationOperationalStatus(
        isOpen: true,
        isTemporarilyClosed: false,
        hasSchedule: true,
        label: 'Open Now',
        detailText: 'Open 24 hours',
      );
    }

    final openMinutes = _parseMinutes(todaySlot.openingTime);
    final closeMinutes = _parseMinutes(todaySlot.closingTime);
    if (openMinutes == null || closeMinutes == null) {
      return const DestinationOperationalStatus(
        isOpen: false,
        isTemporarilyClosed: false,
        hasSchedule: true,
        label: 'Closed',
        detailText: 'Closed today',
      );
    }

    final nowMinutes = current.hour * 60 + current.minute;
    final bool isOpenNow = closeMinutes >= openMinutes
        ? nowMinutes >= openMinutes && nowMinutes < closeMinutes
        : nowMinutes >= openMinutes || nowMinutes < closeMinutes;

    if (isOpenNow) {
      return DestinationOperationalStatus(
        isOpen: true,
        isTemporarilyClosed: false,
        hasSchedule: true,
        label: 'Open Now',
        detailText: 'Closes at ${todaySlot.closingTime}',
      );
    }

    return DestinationOperationalStatus(
      isOpen: false,
      isTemporarilyClosed: false,
      hasSchedule: true,
      label: 'Closed',
      detailText: nowMinutes < openMinutes
          ? 'Opens at ${todaySlot.openingTime}'
          : 'Closed for today',
    );
  }

  factory DestinationDetail.fromJson(Map<String, dynamic> json) {
    final summary = DestinationSummary.fromJson(json);
    final lgu = json['lgu'];
    final category = json['category'];
    final verification = json['verification'];
    final pricing = json['pricing'];
    final rawHours = json['operatingHours'] ?? json['operating_hours'];

    return DestinationDetail(
      id: summary.id,
      slug: summary.slug,
      name: summary.name,
      lguCode: summary.lguCode,
      lguName: summary.lguName,
      lguType: lgu is Map<String, dynamic> ? jsonStringNullable(lgu['type']) : null,
      tourismCluster: summary.tourismCluster,
      categoryCode: summary.categoryCode,
      categoryName: summary.categoryName,
      categoryDescription: category is Map<String, dynamic> ? jsonStringNullable(category['description']) : null,
      description: summary.description,
      historicalBackground: jsonStringNullable(json['historicalBackground'] ?? json['historical_background']),
      address: summary.address,
      latitude: summary.latitude,
      longitude: summary.longitude,
      imageUrl: summary.imageUrl ??
          jsonStringNullable(json['imageUrl'] ?? json['image_url']),
      entityType: summary.entityType,
      popularityTier: summary.popularityTier,
      highwayAccessible: summary.highwayAccessible,
      roadCondition: jsonStringNullable(json['roadCondition'] ?? json['road_condition']),
      verification: verification is Map<String, dynamic>
          ? DestinationVerificationInfo.fromJson(verification)
          : DestinationVerificationInfo(status: summary.verificationStatus),
      pricing: pricing is Map<String, dynamic>
          ? DestinationDetailPricing.fromJson(pricing)
          : DestinationDetailPricing(
              isFree: summary.pricing.isFree,
              entranceFeeAdult: summary.pricing.entranceFeeAdult,
              estimatedMealMin: summary.pricing.estimatedMealMin,
              estimatedMealMax: summary.pricing.estimatedMealMax,
            ),
      operatingHours: rawHours is List
          ? rawHours.whereType<Map<String, dynamic>>().map(DestinationOperatingHour.fromJson).toList(growable: false)
          : const [],
      tags: summary.tags,
      createdAt: jsonStringNullable(json['createdAt'] ?? json['created_at']),
      updatedAt: jsonStringNullable(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

int? _parseMinutes(String? time) {
  if (time == null || time.isEmpty) return null;
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

String _humanizeToken(String? value, {String fallback = ''}) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value
      .trim()
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

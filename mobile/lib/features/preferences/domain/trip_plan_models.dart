class TripPreferenceInput {
  const TripPreferenceInput({
    this.categories = const [],
    this.interestTags = const [],
    this.preferredScenery = const [],
    this.preferredLgus = const [],
    this.preferredClusters = const [],
    this.budgetAmount = 2500,
    this.budgetLevel = 'moderate',
    this.budgetScope = 'perPerson',
    this.availableDays = 1,
    this.availableHoursPerDay = 9,
    this.startTime = '08:00',
    this.endTime = '18:00',
    this.originLguCode = 'laoag-city',
    this.originLatitude,
    this.originLongitude,
    this.groupSize = 1,
    this.transportMode = 'motorcycle',
    this.pacing = 'moderate',
    this.lockedDestinationIds = const [],
    this.excludedDestinationIds = const [],
  });

  final List<String> categories;
  final List<String> interestTags;
  final List<String> preferredScenery;
  final List<String> preferredLgus;
  final List<String> preferredClusters;
  final double? budgetAmount;
  final String budgetLevel;
  final String budgetScope;
  final int availableDays;
  final double availableHoursPerDay;
  final String startTime;
  final String endTime;
  final String originLguCode;
  final double? originLatitude;
  final double? originLongitude;
  final int groupSize;
  final String transportMode;
  final String pacing;
  final List<int> lockedDestinationIds;
  final List<int> excludedDestinationIds;

  factory TripPreferenceInput.fromJson(
    Map<String, dynamic> json, {
    String? originLguCode,
  }) {
    return TripPreferenceInput(
      categories: _stringList(json['categories']),
      interestTags: _stringList(json['interestTags']),
      preferredScenery: _stringList(json['preferredScenery']),
      preferredLgus: _stringList(json['preferredLgus']),
      preferredClusters: _stringList(json['preferredClusters']),
      budgetAmount: _doubleNullable(json['budgetAmount']) ?? 2500,
      budgetLevel: _string(json['budgetLevel'], fallback: 'moderate'),
      budgetScope: _string(json['budgetScope'], fallback: 'perPerson'),
      availableDays: _int(json['availableDays'], fallback: 1).clamp(1, 7),
      availableHoursPerDay:
          (_doubleNullable(json['availableHoursPerDay']) ?? 9).clamp(2, 14),
      startTime: _string(json['startTime'], fallback: '08:00'),
      endTime: _string(json['endTime'], fallback: '18:00'),
      originLguCode:
          originLguCode ?? _string(json['originLguCode'], fallback: 'laoag-city'),
      groupSize: _int(json['groupSize'], fallback: 1).clamp(1, 50),
      transportMode: _string(json['transportMode'], fallback: 'motorcycle'),
      pacing: _string(json['pacing'], fallback: 'moderate'),
    );
  }

  Map<String, dynamic> toJson({int limit = 12}) {
    return {
      'categories': categories,
      'interestTags': interestTags,
      'preferredScenery': preferredScenery,
      'preferredLgus': preferredLgus,
      'preferredClusters': preferredClusters,
      'budgetAmount': budgetAmount,
      'budgetLevel': budgetLevel,
      'budgetScope': budgetScope,
      'availableDays': availableDays,
      'availableHoursPerDay': availableHoursPerDay,
      'startTime': startTime,
      'endTime': endTime,
      'originLguCode': originLguCode,
      if (originLatitude != null && originLongitude != null)
        'originCoordinates': {
          'latitude': originLatitude,
          'longitude': originLongitude,
        },
      'groupSize': groupSize,
      'transportMode': transportMode,
      'pacing': pacing,
      'limit': limit,
      'lockedDestinationIds': lockedDestinationIds,
      'excludedDestinationIds': excludedDestinationIds,
    };
  }

  TripPreferenceInput copyWith({
    List<String>? categories,
    List<String>? interestTags,
    List<String>? preferredScenery,
    List<String>? preferredLgus,
    List<String>? preferredClusters,
    double? budgetAmount,
    bool clearBudget = false,
    String? budgetLevel,
    String? budgetScope,
    int? availableDays,
    double? availableHoursPerDay,
    String? startTime,
    String? endTime,
    String? originLguCode,
    double? originLatitude,
    double? originLongitude,
    bool clearOriginCoords = false,
    int? groupSize,
    String? transportMode,
    String? pacing,
    List<int>? lockedDestinationIds,
    List<int>? excludedDestinationIds,
  }) {
    return TripPreferenceInput(
      categories: categories ?? this.categories,
      interestTags: interestTags ?? this.interestTags,
      preferredScenery: preferredScenery ?? this.preferredScenery,
      preferredLgus: preferredLgus ?? this.preferredLgus,
      preferredClusters: preferredClusters ?? this.preferredClusters,
      budgetAmount: clearBudget ? null : (budgetAmount ?? this.budgetAmount),
      budgetLevel: budgetLevel ?? this.budgetLevel,
      budgetScope: budgetScope ?? this.budgetScope,
      availableDays: availableDays ?? this.availableDays,
      availableHoursPerDay: availableHoursPerDay ?? this.availableHoursPerDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      originLguCode: originLguCode ?? this.originLguCode,
      originLatitude:
          clearOriginCoords ? null : (originLatitude ?? this.originLatitude),
      originLongitude:
          clearOriginCoords ? null : (originLongitude ?? this.originLongitude),
      groupSize: groupSize ?? this.groupSize,
      transportMode: transportMode ?? this.transportMode,
      pacing: pacing ?? this.pacing,
      lockedDestinationIds: lockedDestinationIds ?? this.lockedDestinationIds,
      excludedDestinationIds:
          excludedDestinationIds ?? this.excludedDestinationIds,
    );
  }
}

class ParsedIntentResult {
  const ParsedIntentResult({
    required this.source,
    required this.originLguCode,
    required this.extractedPreferences,
    required this.requiresUserConfirmation,
  });

  final String source;
  final String originLguCode;
  final TripPreferenceInput extractedPreferences;
  final bool requiresUserConfirmation;

  factory ParsedIntentResult.fromJson(Map<String, dynamic> json) {
    final origin = _string(json['originLguCode'], fallback: 'laoag-city');
    final extracted = json['extractedPreferences'];
    return ParsedIntentResult(
      source: _string(json['source'], fallback: 'deterministic-rule-parser'),
      originLguCode: origin,
      extractedPreferences: TripPreferenceInput.fromJson(
        extracted is Map<String, dynamic> ? extracted : const {},
        originLguCode: origin,
      ),
      requiresUserConfirmation: json['requiresUserConfirmation'] != false,
    );
  }
}

class DispersalSummary {
  const DispersalSummary({
    required this.lesserKnownCount,
    required this.totalCount,
    required this.lesserKnownRatio,
    required this.meetsThirtyPercentTarget,
  });

  final int lesserKnownCount;
  final int totalCount;
  final double lesserKnownRatio;
  final bool meetsThirtyPercentTarget;

  factory DispersalSummary.fromJson(Map<String, dynamic> json) {
    return DispersalSummary(
      lesserKnownCount: _int(json['lesserKnownCount']),
      totalCount: _int(json['totalCount']),
      lesserKnownRatio: _doubleNullable(json['lesserKnownRatio']) ?? 0,
      meetsThirtyPercentTarget: json['meetsThirtyPercentTarget'] == true,
    );
  }
}

class RelaxationSuggestion {
  const RelaxationSuggestion({
    required this.type,
    required this.label,
    required this.patch,
  });

  final String type;
  final String label;
  final Map<String, dynamic> patch;

  factory RelaxationSuggestion.fromJson(Map<String, dynamic> json) {
    final rawPatch = json['patch'];
    return RelaxationSuggestion(
      type: _string(json['type']),
      label: _string(json['label']),
      patch: rawPatch is Map<String, dynamic> ? rawPatch : const {},
    );
  }
}

class RecommendedStop {
  const RecommendedStop({
    required this.id,
    required this.slug,
    required this.name,
    required this.lguCode,
    required this.lguName,
    required this.tourismCluster,
    required this.categoryCode,
    required this.categoryName,
    required this.popularityTier,
    required this.isCommunityBased,
    required this.isLesserKnown,
    required this.recommendedDurationMinutes,
    required this.matchPercentage,
    required this.distanceKm,
    required this.estimatedTravelMinutes,
    required this.entryFeePhp,
    required this.isFree,
    required this.explanationReasons,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String slug;
  final String name;
  final String lguCode;
  final String lguName;
  final String tourismCluster;
  final String categoryCode;
  final String categoryName;
  final String popularityTier;
  final bool isCommunityBased;
  final bool isLesserKnown;
  final int recommendedDurationMinutes;
  final int matchPercentage;
  final double distanceKm;
  final int estimatedTravelMinutes;
  final double entryFeePhp;
  final bool isFree;
  final List<String> explanationReasons;
  final double? latitude;
  final double? longitude;

  String get entryLabel => isFree || entryFeePhp <= 0
      ? 'Free entry'
      : '₱${entryFeePhp.round()} entry';

  factory RecommendedStop.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'];
    final coords = json['coordinates'];
    final entryFee = pricing is Map<String, dynamic>
        ? (_doubleNullable(pricing['singleVisitPerPersonCost']) ??
            _doubleNullable(pricing['entranceFeeAdult']) ??
            0)
        : 0.0;
    final isFree = pricing is Map<String, dynamic> && pricing['isFree'] == true;

    return RecommendedStop(
      id: _int(json['id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      lguCode: _string(json['lguCode']),
      lguName: _string(json['lguName']),
      tourismCluster: _string(json['tourismCluster']),
      categoryCode: _string(json['categoryCode']),
      categoryName: _string(json['categoryName']),
      popularityTier: _string(json['popularityTier'], fallback: 'moderate'),
      isCommunityBased: json['isCommunityBased'] == true,
      isLesserKnown: json['isLesserKnown'] == true,
      recommendedDurationMinutes:
          _int(json['recommendedDurationMinutes'], fallback: 60),
      matchPercentage: _int(json['matchPercentage'], fallback: 80),
      distanceKm: _doubleNullable(json['distanceKm']) ?? 0,
      estimatedTravelMinutes: _int(json['estimatedTravelMinutes']),
      entryFeePhp: entryFee,
      isFree: isFree,
      explanationReasons: _stringList(json['explanationReasons']),
      latitude: coords is Map<String, dynamic>
          ? _doubleNullable(coords['latitude'])
          : null,
      longitude: coords is Map<String, dynamic>
          ? _doubleNullable(coords['longitude'])
          : null,
    );
  }
}

class RecommendationResponse {
  const RecommendationResponse({
    required this.originName,
    required this.totalMatches,
    required this.dispersalSummary,
    required this.relaxationSuggestions,
    required this.items,
  });

  final String originName;
  final int totalMatches;
  final DispersalSummary dispersalSummary;
  final List<RelaxationSuggestion> relaxationSuggestions;
  final List<RecommendedStop> items;

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'];
    final dispersal = json['dispersalSummary'];
    final relax = json['relaxationSuggestions'];
    final rawItems = json['items'];

    return RecommendationResponse(
      originName: origin is Map<String, dynamic>
          ? _string(origin['name'], fallback: 'Laoag City')
          : 'Laoag City',
      totalMatches: _int(json['totalMatches']),
      dispersalSummary: DispersalSummary.fromJson(
        dispersal is Map<String, dynamic> ? dispersal : const {},
      ),
      relaxationSuggestions: relax is List
          ? relax
              .whereType<Map<String, dynamic>>()
              .map(RelaxationSuggestion.fromJson)
              .toList(growable: false)
          : const [],
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(RecommendedStop.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class ItineraryStopItem {
  const ItineraryStopItem({
    required this.sequenceOrder,
    required this.destinationId,
    required this.slug,
    required this.name,
    required this.lguCode,
    required this.lguName,
    required this.categoryCode,
    required this.categoryName,
    required this.popularityTier,
    required this.isCommunityBased,
    required this.isLesserKnown,
    this.mealWindow,
    required this.startTime,
    required this.endTime,
    required this.estimatedDurationMinutes,
    required this.travelTimeFromPrevMinutes,
    required this.distanceFromPrevKm,
    required this.legTransportCostPhp,
    required this.entryCostPhp,
    required this.estimatedMealCostPhp,
    required this.operatingWindowLabel,
    required this.isOpenCompliant,
    this.latitude,
    this.longitude,
  });

  final int sequenceOrder;
  final int destinationId;
  final String slug;
  final String name;
  final String lguCode;
  final String lguName;
  final String categoryCode;
  final String categoryName;
  final String popularityTier;
  final bool isCommunityBased;
  final bool isLesserKnown;
  final String? mealWindow;
  final String startTime;
  final String endTime;
  final int estimatedDurationMinutes;
  final int travelTimeFromPrevMinutes;
  final double distanceFromPrevKm;
  final double legTransportCostPhp;
  final double entryCostPhp;
  final double estimatedMealCostPhp;
  final String operatingWindowLabel;
  final bool isOpenCompliant;
  final double? latitude;
  final double? longitude;

  factory ItineraryStopItem.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'];
    return ItineraryStopItem(
      sequenceOrder: _int(json['sequenceOrder'], fallback: 1),
      destinationId: _int(json['destinationId']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      lguCode: _string(json['lguCode']),
      lguName: _string(json['lguName']),
      categoryCode: _string(json['categoryCode']),
      categoryName: _string(json['categoryName']),
      popularityTier: _string(json['popularityTier'], fallback: 'moderate'),
      isCommunityBased: json['isCommunityBased'] == true,
      isLesserKnown: json['isLesserKnown'] == true,
      mealWindow: json['mealWindow'] is String ? json['mealWindow'] as String : null,
      startTime: _string(json['startTime'], fallback: '08:00'),
      endTime: _string(json['endTime'], fallback: '09:00'),
      estimatedDurationMinutes: _int(json['estimatedDurationMinutes'], fallback: 60),
      travelTimeFromPrevMinutes: _int(json['travelTimeFromPrevMinutes']),
      distanceFromPrevKm: _doubleNullable(json['distanceFromPrevKm']) ?? 0,
      legTransportCostPhp: _doubleNullable(json['legTransportCostPhp']) ?? 0,
      entryCostPhp: _doubleNullable(json['entryCostPhp']) ?? 0,
      estimatedMealCostPhp: _doubleNullable(json['estimatedMealCostPhp']) ?? 0,
      operatingWindowLabel: _string(json['operatingWindowLabel'], fallback: 'Open'),
      isOpenCompliant: json['isOpenCompliant'] != false,
      latitude: coords is Map<String, dynamic>
          ? _doubleNullable(coords['latitude'])
          : null,
      longitude: coords is Map<String, dynamic>
          ? _doubleNullable(coords['longitude'])
          : null,
    );
  }
}

class ItineraryDayPlan {
  const ItineraryDayPlan({
    required this.dayNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.stops,
  });

  final int dayNumber;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final List<ItineraryStopItem> stops;

  factory ItineraryDayPlan.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    return ItineraryDayPlan(
      dayNumber: _int(json['dayNumber'], fallback: 1),
      dayOfWeek: _int(json['dayOfWeek']),
      startTime: _string(json['startTime'], fallback: '08:00'),
      endTime: _string(json['endTime'], fallback: '18:00'),
      stops: rawStops is List
          ? rawStops
              .whereType<Map<String, dynamic>>()
              .map(ItineraryStopItem.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class ItineraryExpenseBreakdown {
  const ItineraryExpenseBreakdown({
    required this.entranceAndActivityCost,
    required this.parkingCost,
    required this.mealsCost,
    required this.transportCost,
    required this.totalEstimatedCost,
    this.budgetAmount,
    this.remainingBudget,
  });

  final double entranceAndActivityCost;
  final double parkingCost;
  final double mealsCost;
  final double transportCost;
  final double totalEstimatedCost;
  final double? budgetAmount;
  final double? remainingBudget;

  factory ItineraryExpenseBreakdown.fromJson(Map<String, dynamic> json) {
    return ItineraryExpenseBreakdown(
      entranceAndActivityCost:
          _doubleNullable(json['entranceAndActivityCost']) ?? 0,
      parkingCost: _doubleNullable(json['parkingCost']) ?? 0,
      mealsCost: _doubleNullable(json['mealsCost']) ?? 0,
      transportCost: _doubleNullable(json['transportCost']) ?? 0,
      totalEstimatedCost: _doubleNullable(json['totalEstimatedCost']) ?? 0,
      budgetAmount: _doubleNullable(json['budgetAmount']),
      remainingBudget: _doubleNullable(json['remainingBudget']),
    );
  }
}

class FeasibilityReport {
  const FeasibilityReport({
    required this.isFeasible,
    required this.timeBudgetCompliant,
    required this.operatingHoursCompliant,
    required this.financialBudgetCompliant,
    required this.timeWindowCompliant,
    required this.routesCalculable,
    required this.violatedConstraints,
  });

  final bool isFeasible;
  final bool timeBudgetCompliant;
  final bool operatingHoursCompliant;
  final bool financialBudgetCompliant;
  final bool timeWindowCompliant;
  final bool routesCalculable;
  final List<String> violatedConstraints;

  int get passedCount => [
    timeBudgetCompliant,
    operatingHoursCompliant,
    financialBudgetCompliant,
    timeWindowCompliant,
    routesCalculable,
  ].where((check) => check).length;

  factory FeasibilityReport.fromJson(Map<String, dynamic> json) {
    final checks = json['checks'];
    final map = checks is Map<String, dynamic> ? checks : const <String, dynamic>{};
    return FeasibilityReport(
      isFeasible: json['isFeasible'] == true,
      timeBudgetCompliant: map['timeBudgetCompliant'] == true,
      operatingHoursCompliant: map['operatingHoursCompliant'] == true,
      financialBudgetCompliant: map['financialBudgetCompliant'] == true,
      timeWindowCompliant: map['timeWindowCompliant'] == true,
      routesCalculable: map['routesCalculable'] == true,
      violatedConstraints: _stringList(json['violatedConstraints']),
    );
  }
}

class GeneratedItinerary {
  const GeneratedItinerary({
    required this.originName,
    this.originLatitude,
    this.originLongitude,
    required this.totalDays,
    required this.totalStops,
    required this.totalDistanceKm,
    required this.totalTravelMinutes,
    required this.totalVisitMinutes,
    required this.recalculationTimeMs,
    required this.lesserKnownCount,
    required this.lesserKnownRatio,
    required this.expenseBreakdown,
    required this.feasibilityReport,
    required this.days,
    this.savedId,
  });

  final String originName;
  final double? originLatitude;
  final double? originLongitude;
  final int totalDays;
  final int totalStops;
  final double totalDistanceKm;
  final int totalTravelMinutes;
  final int totalVisitMinutes;
  final int recalculationTimeMs;
  final int lesserKnownCount;
  final double lesserKnownRatio;
  final ItineraryExpenseBreakdown expenseBreakdown;
  final FeasibilityReport feasibilityReport;
  final List<ItineraryDayPlan> days;
  final int? savedId;

  factory GeneratedItinerary.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'];
    final originCoords =
        origin is Map<String, dynamic> ? origin['coordinates'] : null;
    final rawDays = json['days'];
    final expense = json['expenseBreakdown'];
    final feasibility = json['feasibilityReport'];

    return GeneratedItinerary(
      originName: origin is Map<String, dynamic>
          ? _string(origin['name'], fallback: 'Laoag City')
          : 'Laoag City',
      originLatitude: originCoords is Map<String, dynamic>
          ? _doubleNullable(originCoords['latitude'])
          : null,
      originLongitude: originCoords is Map<String, dynamic>
          ? _doubleNullable(originCoords['longitude'])
          : null,
      totalDays: _int(json['totalDays'], fallback: 1),
      totalStops: _int(json['totalStops']),
      totalDistanceKm: _doubleNullable(json['totalDistanceKm']) ?? 0,
      totalTravelMinutes: _int(json['totalTravelMinutes']),
      totalVisitMinutes: _int(json['totalVisitMinutes']),
      recalculationTimeMs: _int(json['recalculationTimeMs'], fallback: 1),
      lesserKnownCount: _int(json['lesserKnownCount']),
      lesserKnownRatio: _doubleNullable(json['lesserKnownRatio']) ?? 0,
      expenseBreakdown: ItineraryExpenseBreakdown.fromJson(
        expense is Map<String, dynamic> ? expense : const {},
      ),
      feasibilityReport: FeasibilityReport.fromJson(
        feasibility is Map<String, dynamic> ? feasibility : const {},
      ),
      days: rawDays is List
          ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(ItineraryDayPlan.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  GeneratedItinerary copyWith({int? savedId}) {
    return GeneratedItinerary(
      originName: originName,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      totalDays: totalDays,
      totalStops: totalStops,
      totalDistanceKm: totalDistanceKm,
      totalTravelMinutes: totalTravelMinutes,
      totalVisitMinutes: totalVisitMinutes,
      recalculationTimeMs: recalculationTimeMs,
      lesserKnownCount: lesserKnownCount,
      lesserKnownRatio: lesserKnownRatio,
      expenseBreakdown: expenseBreakdown,
      feasibilityReport: feasibilityReport,
      days: days,
      savedId: savedId ?? this.savedId,
    );
  }
}

class SavedItinerarySummary {
  const SavedItinerarySummary({
    required this.id,
    required this.title,
    required this.totalDays,
    required this.totalEstimatedCost,
    required this.stopCount,
    this.updatedAt,
  });

  final int id;
  final String title;
  final int totalDays;
  final double totalEstimatedCost;
  final int stopCount;
  final String? updatedAt;

  factory SavedItinerarySummary.fromJson(Map<String, dynamic> json) {
    return SavedItinerarySummary(
      id: _int(json['id']),
      title: _string(json['title'], fallback: 'Saved trip'),
      totalDays: _int(json['totalDays'], fallback: 1),
      totalEstimatedCost: _doubleNullable(json['totalEstimatedCost']) ?? 0,
      stopCount: _int(json['stopCount']),
      updatedAt: json['updatedAt'] is String ? json['updatedAt'] as String : null,
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num || value is bool) return value.toString();
  return fallback;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double? _doubleNullable(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList(growable: false);
}

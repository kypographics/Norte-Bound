import '../../../core/utils/json_parse.dart';

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
    this.originName,
    this.originLatitude,
    this.originLongitude,
    this.overnightLguCode,
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
  final String? originName;
  final double? originLatitude;
  final double? originLongitude;
  final String? overnightLguCode;
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
      categories: jsonStringList(json['categories']),
      interestTags: jsonStringList(json['interestTags']),
      preferredScenery: jsonStringList(json['preferredScenery']),
      preferredLgus: jsonStringList(json['preferredLgus']),
      preferredClusters: jsonStringList(json['preferredClusters']),
      budgetAmount: jsonDouble(json['budgetAmount']) ?? 2500,
      budgetLevel: jsonString(json['budgetLevel'], fallback: 'moderate'),
      budgetScope: jsonString(json['budgetScope'], fallback: 'perPerson'),
      availableDays: jsonInt(json['availableDays'], fallback: 1).clamp(1, 7),
      availableHoursPerDay: (jsonDouble(json['availableHoursPerDay']) ?? 9)
          .clamp(2, 14),
      startTime: jsonString(json['startTime'], fallback: '08:00'),
      endTime: jsonString(json['endTime'], fallback: '18:00'),
      originLguCode:
          originLguCode ??
          jsonString(json['originLguCode'], fallback: 'laoag-city'),
      originName: jsonStringNullable(json['originName']),
      overnightLguCode: jsonStringNullable(json['overnightLguCode']),
      groupSize: jsonInt(json['groupSize'], fallback: 1).clamp(1, 50),
      transportMode: jsonString(json['transportMode'], fallback: 'motorcycle'),
      pacing: jsonString(json['pacing'], fallback: 'moderate'),
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
      if (originName != null && originName!.isNotEmpty)
        'originName': originName,
      if (originLatitude != null && originLongitude != null)
        'originCoordinates': {
          'latitude': originLatitude,
          'longitude': originLongitude,
        },
      if (overnightLguCode != null && overnightLguCode!.isNotEmpty)
        'overnightLguCode': overnightLguCode,
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
    String? originName,
    bool clearOriginName = false,
    double? originLatitude,
    double? originLongitude,
    bool clearOriginCoords = false,
    String? overnightLguCode,
    bool clearOvernightLgu = false,
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
      originName: clearOriginName ? null : (originName ?? this.originName),
      originLatitude: clearOriginCoords
          ? null
          : (originLatitude ?? this.originLatitude),
      originLongitude: clearOriginCoords
          ? null
          : (originLongitude ?? this.originLongitude),
      overnightLguCode: clearOvernightLgu
          ? null
          : (overnightLguCode ?? this.overnightLguCode),
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
    final origin = jsonString(json['originLguCode'], fallback: 'laoag-city');
    final extracted = json['extractedPreferences'];
    return ParsedIntentResult(
      source: jsonString(json['source'], fallback: 'deterministic-rule-parser'),
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
      lesserKnownCount: jsonInt(json['lesserKnownCount']),
      totalCount: jsonInt(json['totalCount']),
      lesserKnownRatio: jsonDouble(json['lesserKnownRatio']) ?? 0,
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
      type: jsonString(json['type']),
      label: jsonString(json['label']),
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
    this.imageUrl,
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
  final String? imageUrl;

  String get entryLabel => isFree || entryFeePhp <= 0
      ? 'Free entry'
      : '₱${entryFeePhp.round()} entry';

  factory RecommendedStop.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'];
    final coords = json['coordinates'];
    final entryFee = pricing is Map<String, dynamic>
        ? (jsonDouble(pricing['singleVisitPerPersonCost']) ??
              jsonDouble(pricing['entranceFeeAdult']) ??
              0)
        : 0.0;
    final isFree = pricing is Map<String, dynamic> && pricing['isFree'] == true;

    return RecommendedStop(
      id: jsonInt(json['id']),
      slug: jsonString(json['slug']),
      name: jsonString(json['name']),
      lguCode: jsonString(json['lguCode']),
      lguName: jsonString(json['lguName']),
      tourismCluster: jsonString(json['tourismCluster']),
      categoryCode: jsonString(json['categoryCode']),
      categoryName: jsonString(json['categoryName']),
      popularityTier: jsonString(json['popularityTier'], fallback: 'moderate'),
      isCommunityBased: json['isCommunityBased'] == true,
      isLesserKnown: json['isLesserKnown'] == true,
      recommendedDurationMinutes: jsonInt(
        json['recommendedDurationMinutes'],
        fallback: 60,
      ),
      matchPercentage: jsonInt(json['matchPercentage'], fallback: 80),
      distanceKm: jsonDouble(json['distanceKm']) ?? 0,
      estimatedTravelMinutes: jsonInt(json['estimatedTravelMinutes']),
      entryFeePhp: entryFee,
      isFree: isFree,
      explanationReasons: jsonStringList(json['explanationReasons']),
      latitude: coords is Map<String, dynamic>
          ? jsonDouble(coords['latitude'])
          : null,
      longitude: coords is Map<String, dynamic>
          ? jsonDouble(coords['longitude'])
          : null,
      imageUrl: jsonStringNullable(json['imageUrl'] ?? json['image_url']),
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
          ? jsonString(origin['name'], fallback: 'Laoag City')
          : 'Laoag City',
      totalMatches: jsonInt(json['totalMatches']),
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
    this.imageUrl,
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
  final String? imageUrl;

  ItineraryStopItem copyWith({
    int? sequenceOrder,
    String? mealWindow,
    String? startTime,
    String? endTime,
    int? travelTimeFromPrevMinutes,
    double? distanceFromPrevKm,
    double? legTransportCostPhp,
  }) {
    return ItineraryStopItem(
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      destinationId: destinationId,
      slug: slug,
      name: name,
      lguCode: lguCode,
      lguName: lguName,
      categoryCode: categoryCode,
      categoryName: categoryName,
      popularityTier: popularityTier,
      isCommunityBased: isCommunityBased,
      isLesserKnown: isLesserKnown,
      mealWindow: mealWindow ?? this.mealWindow,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedDurationMinutes: estimatedDurationMinutes,
      travelTimeFromPrevMinutes:
          travelTimeFromPrevMinutes ?? this.travelTimeFromPrevMinutes,
      distanceFromPrevKm: distanceFromPrevKm ?? this.distanceFromPrevKm,
      legTransportCostPhp: legTransportCostPhp ?? this.legTransportCostPhp,
      entryCostPhp: entryCostPhp,
      estimatedMealCostPhp: estimatedMealCostPhp,
      operatingWindowLabel: operatingWindowLabel,
      isOpenCompliant: isOpenCompliant,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
    );
  }

  factory ItineraryStopItem.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'];
    return ItineraryStopItem(
      sequenceOrder: jsonInt(json['sequenceOrder'], fallback: 1),
      destinationId: jsonInt(json['destinationId']),
      slug: jsonString(json['slug']),
      name: jsonString(json['name']),
      lguCode: jsonString(json['lguCode']),
      lguName: jsonString(json['lguName']),
      categoryCode: jsonString(json['categoryCode']),
      categoryName: jsonString(json['categoryName']),
      popularityTier: jsonString(json['popularityTier'], fallback: 'moderate'),
      isCommunityBased: json['isCommunityBased'] == true,
      isLesserKnown: json['isLesserKnown'] == true,
      mealWindow: json['mealWindow'] is String
          ? json['mealWindow'] as String
          : null,
      startTime: jsonString(json['startTime'], fallback: '08:00'),
      endTime: jsonString(json['endTime'], fallback: '09:00'),
      estimatedDurationMinutes: jsonInt(
        json['estimatedDurationMinutes'],
        fallback: 60,
      ),
      travelTimeFromPrevMinutes: jsonInt(json['travelTimeFromPrevMinutes']),
      distanceFromPrevKm: jsonDouble(json['distanceFromPrevKm']) ?? 0,
      legTransportCostPhp: jsonDouble(json['legTransportCostPhp']) ?? 0,
      entryCostPhp: jsonDouble(json['entryCostPhp']) ?? 0,
      estimatedMealCostPhp: jsonDouble(json['estimatedMealCostPhp']) ?? 0,
      operatingWindowLabel: jsonString(
        json['operatingWindowLabel'],
        fallback: 'Open',
      ),
      isOpenCompliant: json['isOpenCompliant'] != false,
      latitude: coords is Map<String, dynamic>
          ? jsonDouble(coords['latitude'])
          : null,
      longitude: coords is Map<String, dynamic>
          ? jsonDouble(coords['longitude'])
          : null,
      imageUrl: jsonStringNullable(json['imageUrl'] ?? json['image_url']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sequenceOrder': sequenceOrder,
    'destinationId': destinationId,
    'slug': slug,
    'name': name,
    'lguCode': lguCode,
    'lguName': lguName,
    'categoryCode': categoryCode,
    'categoryName': categoryName,
    'popularityTier': popularityTier,
    'isCommunityBased': isCommunityBased,
    'isLesserKnown': isLesserKnown,
    'mealWindow': mealWindow,
    'startTime': startTime,
    'endTime': endTime,
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'travelTimeFromPrevMinutes': travelTimeFromPrevMinutes,
    'distanceFromPrevKm': distanceFromPrevKm,
    'legTransportCostPhp': legTransportCostPhp,
    'entryCostPhp': entryCostPhp,
    'estimatedMealCostPhp': estimatedMealCostPhp,
    'operatingWindowLabel': operatingWindowLabel,
    'isOpenCompliant': isOpenCompliant,
    'imageUrl': imageUrl,
    if (latitude != null && longitude != null)
      'coordinates': {'latitude': latitude, 'longitude': longitude},
  };
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

  ItineraryDayPlan copyWith({
    String? startTime,
    String? endTime,
    List<ItineraryStopItem>? stops,
  }) {
    return ItineraryDayPlan(
      dayNumber: dayNumber,
      dayOfWeek: dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      stops: stops ?? this.stops,
    );
  }

  factory ItineraryDayPlan.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    return ItineraryDayPlan(
      dayNumber: jsonInt(json['dayNumber'], fallback: 1),
      dayOfWeek: jsonInt(json['dayOfWeek']),
      startTime: jsonString(json['startTime'], fallback: '08:00'),
      endTime: jsonString(json['endTime'], fallback: '18:00'),
      stops: rawStops is List
          ? rawStops
                .whereType<Map<String, dynamic>>()
                .map(ItineraryStopItem.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'dayNumber': dayNumber,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'stops': stops.map((s) => s.toJson()).toList(growable: false),
  };
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
      entranceAndActivityCost: jsonDouble(json['entranceAndActivityCost']) ?? 0,
      parkingCost: jsonDouble(json['parkingCost']) ?? 0,
      mealsCost: jsonDouble(json['mealsCost']) ?? 0,
      transportCost: jsonDouble(json['transportCost']) ?? 0,
      totalEstimatedCost: jsonDouble(json['totalEstimatedCost']) ?? 0,
      budgetAmount: jsonDouble(json['budgetAmount']),
      remainingBudget: jsonDouble(json['remainingBudget']),
    );
  }

  Map<String, dynamic> toJson() => {
    'entranceAndActivityCost': entranceAndActivityCost,
    'parkingCost': parkingCost,
    'mealsCost': mealsCost,
    'transportCost': transportCost,
    'totalEstimatedCost': totalEstimatedCost,
    'budgetAmount': budgetAmount,
    'remainingBudget': remainingBudget,
  };
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
    final map = checks is Map<String, dynamic>
        ? checks
        : const <String, dynamic>{};
    return FeasibilityReport(
      isFeasible: json['isFeasible'] == true,
      timeBudgetCompliant: map['timeBudgetCompliant'] == true,
      operatingHoursCompliant: map['operatingHoursCompliant'] == true,
      financialBudgetCompliant: map['financialBudgetCompliant'] == true,
      timeWindowCompliant: map['timeWindowCompliant'] == true,
      routesCalculable: map['routesCalculable'] == true,
      violatedConstraints: jsonStringList(json['violatedConstraints']),
    );
  }

  Map<String, dynamic> toJson() => {
    'isFeasible': isFeasible,
    'violatedConstraints': violatedConstraints,
    'checks': {
      'timeBudgetCompliant': timeBudgetCompliant,
      'operatingHoursCompliant': operatingHoursCompliant,
      'financialBudgetCompliant': financialBudgetCompliant,
      'timeWindowCompliant': timeWindowCompliant,
      'routesCalculable': routesCalculable,
    },
  };
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
    final originCoords = origin is Map<String, dynamic>
        ? origin['coordinates']
        : null;
    final rawDays = json['days'];
    final expense = json['expenseBreakdown'];
    final feasibility = json['feasibilityReport'];

    return GeneratedItinerary(
      originName: origin is Map<String, dynamic>
          ? jsonString(origin['name'], fallback: 'Laoag City')
          : 'Laoag City',
      originLatitude: originCoords is Map<String, dynamic>
          ? jsonDouble(originCoords['latitude'])
          : null,
      originLongitude: originCoords is Map<String, dynamic>
          ? jsonDouble(originCoords['longitude'])
          : null,
      totalDays: jsonInt(json['totalDays'], fallback: 1),
      totalStops: jsonInt(json['totalStops']),
      totalDistanceKm: jsonDouble(json['totalDistanceKm']) ?? 0,
      totalTravelMinutes: jsonInt(json['totalTravelMinutes']),
      totalVisitMinutes: jsonInt(json['totalVisitMinutes']),
      recalculationTimeMs: jsonInt(json['recalculationTimeMs'], fallback: 1),
      lesserKnownCount: jsonInt(json['lesserKnownCount']),
      lesserKnownRatio: jsonDouble(json['lesserKnownRatio']) ?? 0,
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

  GeneratedItinerary copyWith({
    List<ItineraryDayPlan>? days,
    double? totalDistanceKm,
    int? totalTravelMinutes,
    ItineraryExpenseBreakdown? expenseBreakdown,
    int? savedId,
  }) {
    return GeneratedItinerary(
      originName: originName,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      totalDays: totalDays,
      totalStops: totalStops,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalTravelMinutes: totalTravelMinutes ?? this.totalTravelMinutes,
      totalVisitMinutes: totalVisitMinutes,
      recalculationTimeMs: recalculationTimeMs,
      lesserKnownCount: lesserKnownCount,
      lesserKnownRatio: lesserKnownRatio,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
      feasibilityReport: feasibilityReport,
      days: days ?? this.days,
      savedId: savedId ?? this.savedId,
    );
  }

  Map<String, dynamic> toJson() => {
    'origin': {
      'name': originName,
      if (originLatitude != null && originLongitude != null)
        'coordinates': {
          'latitude': originLatitude,
          'longitude': originLongitude,
        },
    },
    'totalDays': totalDays,
    'totalStops': totalStops,
    'totalDistanceKm': totalDistanceKm,
    'totalTravelMinutes': totalTravelMinutes,
    'totalVisitMinutes': totalVisitMinutes,
    'recalculationTimeMs': recalculationTimeMs,
    'lesserKnownCount': lesserKnownCount,
    'lesserKnownRatio': lesserKnownRatio,
    'expenseBreakdown': expenseBreakdown.toJson(),
    'feasibilityReport': feasibilityReport.toJson(),
    'days': days.map((d) => d.toJson()).toList(growable: false),
  };
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
      id: jsonInt(json['id']),
      title: jsonString(json['title'], fallback: 'Saved trip'),
      totalDays: jsonInt(json['totalDays'], fallback: 1),
      totalEstimatedCost: jsonDouble(json['totalEstimatedCost']) ?? 0,
      stopCount: jsonInt(json['stopCount']),
      updatedAt: json['updatedAt'] is String
          ? json['updatedAt'] as String
          : null,
    );
  }
}

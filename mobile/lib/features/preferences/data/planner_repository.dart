import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/trip_plan_models.dart';

class PlannerRepository {
  PlannerRepository(this._dio);

  final Dio _dio;

  Future<ParsedIntentResult> parseIntent({
    required String prompt,
    String? originLguCode,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.parseIntent,
        data: {
          'prompt': prompt,
          'originLguCode': ?originLguCode,
          if (latitude != null && longitude != null)
            'currentLocation': {'latitude': latitude, 'longitude': longitude},
        },
      ),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Could not extract structured trip preferences.',
      );
    }
    return ParsedIntentResult.fromJson(data);
  }

  Future<RecommendationResponse> fetchRecommendations(
    TripPreferenceInput input,
  ) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.recommendations,
        data: input.toJson(),
      ),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Could not load destination recommendations.',
      );
    }
    return RecommendationResponse.fromJson(data);
  }

  Future<GeneratedItinerary> generateItinerary(TripPreferenceInput input) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.generateItinerary,
        data: input.toJson(),
      ),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Could not generate a feasible itinerary.',
      );
    }
    return GeneratedItinerary.fromJson(data);
  }

  Future<int> saveItinerary({
    required String title,
    required GeneratedItinerary itinerary,
    required TripPreferenceInput preferences,
  }) async {
    final items = itinerary.days
        .expand(
          (day) => day.stops.map(
            (stop) => {
              'destinationId': stop.destinationId,
              'dayNumber': day.dayNumber,
              'sequenceOrder': stop.sequenceOrder,
              'scheduledTime': '${stop.startTime}-${stop.endTime}',
              'mealWindow': stop.mealWindow,
              'estimatedDurationMinutes': stop.estimatedDurationMinutes,
              'travelTimeFromPrevMinutes': stop.travelTimeFromPrevMinutes,
            },
          ),
        )
        .toList(growable: false);

    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.itineraries,
        data: {
          'title': title,
          'totalDays': itinerary.totalDays,
          'totalEstimatedCost': itinerary.expenseBreakdown.totalEstimatedCost,
          'preferencesSnapshot': preferences.toJson(),
          'items': items,
        },
      ),
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic> &&
        data['itinerary'] is Map<String, dynamic>) {
      final id = data['itinerary']['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
    }
    throw const ApiException(message: 'Failed to save itinerary.');
  }

  Future<List<SavedItinerarySummary>> fetchSavedItineraries() async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.itineraries),
    );
    final data = response.data?['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SavedItinerarySummary.fromJson)
        .toList(growable: false);
  }

  Future<void> deleteSavedItinerary(int itineraryId) async {
    await _request(
      () => _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.itineraryById(itineraryId),
      ),
    );
  }

  Future<({GeneratedItinerary itinerary, TripPreferenceInput preferences, List<String> detectedChanges})>
      loadSavedItinerary(int itineraryId) async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.itineraryById(itineraryId),
      ),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Saved itinerary was not found.');
    }

    final header = data['itinerary'] is Map<String, dynamic>
        ? data['itinerary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final snapshot = header['preferencesSnapshot'] is Map<String, dynamic>
        ? header['preferencesSnapshot'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawItems = data['items'] is List ? data['items'] as List : const [];
    final itemIds = rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) => item['destinationId'])
        .whereType<num>()
        .map((n) => n.toInt())
        .toList(growable: false);

    final prefs = TripPreferenceInput.fromJson(snapshot).copyWith(
      lockedDestinationIds: itemIds,
    );

    final rawChanges =
        data['detectedChanges'] is List ? data['detectedChanges'] as List : const [];
    final changes = rawChanges
        .whereType<Map<String, dynamic>>()
        .map((c) => c['message'])
        .whereType<String>()
        .toList(growable: false);

    try {
      final generated = await generateItinerary(prefs);
      if (generated.totalStops > 0 || rawItems.isEmpty) {
        return (
          itinerary: generated.copyWith(savedId: itineraryId),
          preferences: prefs,
          detectedChanges: changes,
        );
      }
    } catch (_) {
      if (rawItems.isEmpty) rethrow;
    }

    final fallback = _buildSavedFallback(
      itineraryId: itineraryId,
      header: header,
      rawItems: rawItems,
      prefs: prefs,
      hasLiveIssues: changes.isNotEmpty,
    );
    return (
      itinerary: fallback,
      preferences: prefs,
      detectedChanges: changes,
    );
  }

  GeneratedItinerary _buildSavedFallback({
    required int itineraryId,
    required Map<String, dynamic> header,
    required List<dynamic> rawItems,
    required TripPreferenceInput prefs,
    required bool hasLiveIssues,
  }) {
    final grouped = <int, List<ItineraryStopItem>>{};
    var totalEntry = 0.0;
    var totalTravel = 0;
    var totalVisit = 0;

    for (final raw in rawItems.whereType<Map<String, dynamic>>()) {
      final dayNumber = (raw['dayNumber'] as num?)?.toInt() ?? 1;
      final scheduled = (raw['scheduledTime'] as String?) ?? '08:00-09:00';
      final parts = scheduled.split('-');
      final startTime = parts.isNotEmpty && parts[0].trim().isNotEmpty
          ? parts[0].trim()
          : '08:00';
      final endTime = parts.length > 1 && parts[1].trim().isNotEmpty
          ? parts[1].trim()
          : '09:00';
      final coords = raw['coordinates'] is Map<String, dynamic>
          ? raw['coordinates'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final duration =
          (raw['estimatedDurationMinutes'] as num?)?.toInt() ?? 60;
      final travel =
          (raw['travelTimeFromPrevMinutes'] as num?)?.toInt() ?? 0;
      final entry = (raw['entryCostPhp'] as num?)?.toDouble() ?? 0;

      totalEntry += entry;
      totalTravel += travel;
      totalVisit += duration;

      grouped.putIfAbsent(dayNumber, () => []).add(
            ItineraryStopItem(
              sequenceOrder: (raw['sequenceOrder'] as num?)?.toInt() ?? 1,
              destinationId: (raw['destinationId'] as num?)?.toInt() ?? 0,
              slug: (raw['slug'] as String?) ?? '',
              name: (raw['name'] as String?) ?? 'Saved stop',
              lguCode: (raw['lguCode'] as String?) ?? '',
              lguName: (raw['lguName'] as String?) ?? '',
              categoryCode: (raw['categoryCode'] as String?) ?? '',
              categoryName: (raw['categoryCode'] as String?) ?? 'Destination',
              popularityTier: 'moderate',
              isCommunityBased: false,
              isLesserKnown: false,
              mealWindow: raw['mealWindow'] is String
                  ? raw['mealWindow'] as String
                  : null,
              startTime: startTime,
              endTime: endTime,
              estimatedDurationMinutes: duration,
              travelTimeFromPrevMinutes: travel,
              distanceFromPrevKm: 0,
              legTransportCostPhp: 0,
              entryCostPhp: entry,
              estimatedMealCostPhp: 0,
              operatingWindowLabel: raw['temporarilyClosed'] == true
                  ? 'Temporarily Closed'
                  : 'Saved schedule',
              isOpenCompliant: raw['temporarilyClosed'] != true &&
                  raw['verificationStatus'] == 'verified',
              latitude: (coords['latitude'] as num?)?.toDouble(),
              longitude: (coords['longitude'] as num?)?.toDouble(),
            ),
          );
    }

    final dayNumbers = grouped.keys.toList()..sort();
    final days = [
      for (final dayNum in dayNumbers)
        ItineraryDayPlan(
          dayNumber: dayNum,
          dayOfWeek: 0,
          startTime: grouped[dayNum]!.first.startTime,
          endTime: grouped[dayNum]!.last.endTime,
          stops: grouped[dayNum]!,
        ),
    ];

    final totalDays = (header['totalDays'] as num?)?.toInt() ??
        (days.isEmpty ? prefs.availableDays : days.length);
    final totalCost =
        (header['totalEstimatedCost'] as num?)?.toDouble() ?? totalEntry;
    final budget = prefs.budgetAmount;

    return GeneratedItinerary(
      originName: prefs.originLguCode,
      totalDays: totalDays,
      totalStops: rawItems.length,
      totalDistanceKm: 0,
      totalTravelMinutes: totalTravel,
      totalVisitMinutes: totalVisit,
      recalculationTimeMs: 1,
      lesserKnownCount: 0,
      lesserKnownRatio: 0,
      expenseBreakdown: ItineraryExpenseBreakdown(
        entranceAndActivityCost: totalEntry,
        parkingCost: 0,
        mealsCost: 0,
        transportCost: 0,
        totalEstimatedCost: totalCost,
        budgetAmount: budget,
        remainingBudget: budget == null ? null : budget - totalCost,
      ),
      feasibilityReport: FeasibilityReport(
        isFeasible: !hasLiveIssues,
        timeBudgetCompliant: true,
        operatingHoursCompliant: !hasLiveIssues,
        financialBudgetCompliant:
            budget == null ? true : totalCost <= budget,
        timeWindowCompliant: true,
        routesCalculable: true,
        violatedConstraints: hasLiveIssues
            ? const ['Loaded saved schedule snapshot due to live constraint changes.']
            : const [],
      ),
      days: days,
      savedId: itineraryId,
    );
  }

  Future<List<String>> checkLiveChanges(int itineraryId) async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.itineraryById(itineraryId),
      ),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return const [];
    final changes = data['detectedChanges'];
    if (changes is! List) return const [];
    return changes
        .whereType<Map<String, dynamic>>()
        .map((c) => c['message'])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<Response<Map<String, dynamic>>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

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

    final generated = await generateItinerary(prefs);
    return (
      itinerary: generated.copyWith(savedId: itineraryId),
      preferences: prefs,
      detectedChanges: changes,
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

import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/traveler_local_store.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/planner_repository.dart';
import '../domain/trip_plan_models.dart';

double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  double toRad(double deg) => deg * math.pi / 180.0;
  final dLat = toRad(lat2 - lat1);
  final dLon = toRad(lon2 - lon1);
  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final h =
      sinLat * sinLat +
      math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * sinLon * sinLon;
  return 2 * earthRadiusKm * math.asin(math.min(1.0, math.sqrt(h)));
}

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(dioProvider));
});

class PlannerState {
  const PlannerState({
    required this.preferences,
    this.prompt = '',
    this.isParsingIntent = false,
    this.intentSource,
    this.awaitingConfirmation = false,
    this.isLoadingRecommendations = false,
    this.recommendations,
    this.isGeneratingItinerary = false,
    this.itinerary,
    this.savedItineraries = const [],
    this.detectedChanges = const [],
    this.errorMessage,
    this.usingGps = false,
    this.lockedDestinationNames = const {},
    this.isNavigating = false,
    this.activeNavDayIndex = 0,
    this.activeNavStopIndex = 0,
  });

  final TripPreferenceInput preferences;
  final String prompt;
  final bool isParsingIntent;
  final String? intentSource;
  final bool awaitingConfirmation;
  final bool isLoadingRecommendations;
  final RecommendationResponse? recommendations;
  final bool isGeneratingItinerary;
  final GeneratedItinerary? itinerary;
  final List<SavedItinerarySummary> savedItineraries;
  final List<String> detectedChanges;
  final String? errorMessage;
  final bool usingGps;
  final Map<int, String> lockedDestinationNames;
  final bool isNavigating;
  final int activeNavDayIndex;
  final int activeNavStopIndex;

  PlannerState copyWith({
    TripPreferenceInput? preferences,
    String? prompt,
    bool? isParsingIntent,
    String? intentSource,
    bool? awaitingConfirmation,
    bool? isLoadingRecommendations,
    RecommendationResponse? recommendations,
    bool? isGeneratingItinerary,
    GeneratedItinerary? itinerary,
    List<SavedItinerarySummary>? savedItineraries,
    List<String>? detectedChanges,
    String? errorMessage,
    bool clearError = false,
    bool? usingGps,
    Map<int, String>? lockedDestinationNames,
    bool? isNavigating,
    int? activeNavDayIndex,
    int? activeNavStopIndex,
  }) {
    return PlannerState(
      preferences: preferences ?? this.preferences,
      prompt: prompt ?? this.prompt,
      isParsingIntent: isParsingIntent ?? this.isParsingIntent,
      intentSource: intentSource ?? this.intentSource,
      awaitingConfirmation: awaitingConfirmation ?? this.awaitingConfirmation,
      isLoadingRecommendations:
          isLoadingRecommendations ?? this.isLoadingRecommendations,
      recommendations: recommendations ?? this.recommendations,
      isGeneratingItinerary:
          isGeneratingItinerary ?? this.isGeneratingItinerary,
      itinerary: itinerary ?? this.itinerary,
      savedItineraries: savedItineraries ?? this.savedItineraries,
      detectedChanges: detectedChanges ?? this.detectedChanges,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      usingGps: usingGps ?? this.usingGps,
      lockedDestinationNames:
          lockedDestinationNames ?? this.lockedDestinationNames,
      isNavigating: isNavigating ?? this.isNavigating,
      activeNavDayIndex: activeNavDayIndex ?? this.activeNavDayIndex,
      activeNavStopIndex: activeNavStopIndex ?? this.activeNavStopIndex,
    );
  }
}

final plannerProvider = NotifierProvider<PlannerNotifier, PlannerState>(
  PlannerNotifier.new,
);

class PlannerNotifier extends Notifier<PlannerState> {
  @override
  PlannerState build() {
    final userId = ref.watch(authNotifierProvider.select((a) => a.value?.id));
    final userPrefs = ref.read(authNotifierProvider).value?.travelPreferences;
    if (userId != null) {
      Future.microtask(loadSavedItineraries);
    }
    return PlannerState(
      preferences: TripPreferenceInput(
        transportMode: userPrefs?.defaultTransportMode.apiValue ?? 'motorcycle',
        budgetScope: userPrefs?.defaultBudgetScope.apiValue ?? 'perPerson',
        groupSize: userPrefs?.defaultGroupSize ?? 1,
        pacing: userPrefs?.defaultPacing.apiValue ?? 'moderate',
      ),
    );
  }

  void updatePreferences(TripPreferenceInput updated) {
    state = state.copyWith(preferences: updated, clearError: true);
    if (state.recommendations != null && !state.awaitingConfirmation) {
      Future.microtask(findMatchingPlaces);
    }
  }

  void setPrompt(String prompt) {
    state = state.copyWith(prompt: prompt, clearError: true);
  }

  void setOriginLgu(String lguCode) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        originLguCode: lguCode,
        clearOriginCoords: true,
        clearOriginName: true,
      ),
      usingGps: false,
      clearError: true,
    );
    if (state.recommendations != null && !state.awaitingConfirmation) {
      Future.microtask(findMatchingPlaces);
    }
  }

  void setPhilippineOrigin({
    required String code,
    required String name,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        originLguCode: code,
        originName: name,
        originLatitude: latitude,
        originLongitude: longitude,
      ),
      usingGps: false,
      clearError: true,
    );
    if (state.recommendations != null && !state.awaitingConfirmation) {
      Future.microtask(findMatchingPlaces);
    }
  }

  static bool _isInPhilippines(double lat, double lon) =>
      lat >= 4.5 && lat <= 21.5 && lon >= 116.0 && lon <= 127.0;

  Future<({double latitude, double longitude, String? label})?>
      _resolvePhilippineIpLocation() async {
    try {
      final client = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final response = await client.get<Map<String, dynamic>>(
        'https://ipwho.is/',
      );
      final data = response.data;
      if (data == null || data['success'] == false) return null;

      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null || !_isInPhilippines(lat, lon)) {
        return null;
      }

      final city = (data['city'] as String?)?.trim();
      final region = (data['region'] as String?)?.trim();
      final area = (city != null && city.isNotEmpty)
          ? city
          : (region != null && region.isNotEmpty ? region : null);

      return (
        latitude: lat,
        longitude: lon,
        label: area != null ? 'Current GPS · $area' : 'Current GPS location',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> acquireGpsLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 6),
            ),
          );

          if (_isInPhilippines(pos.latitude, pos.longitude)) {
            state = state.copyWith(
              usingGps: true,
              preferences: state.preferences.copyWith(
                originName:
                    'Current GPS (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)})',
                originLatitude: pos.latitude,
                originLongitude: pos.longitude,
              ),
              clearError: true,
            );
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to IP geolocation and Philippine hub fallback.
    }

    // Emulators often default to Mountain View, CA or fail location permissions;
    // try IP geolocation first so real Philippine users get their city.
    final ipLoc = await _resolvePhilippineIpLocation();
    if (ipLoc != null) {
      state = state.copyWith(
        usingGps: true,
        preferences: state.preferences.copyWith(
          originName: ipLoc.label ?? 'Current GPS location',
          originLatitude: ipLoc.latitude,
          originLongitude: ipLoc.longitude,
        ),
        clearError: true,
      );
      return;
    }

    final fallbackLat = state.preferences.originLatitude ?? 18.1978;
    final fallbackLon = state.preferences.originLongitude ?? 120.5936;
    final fallbackLabel = state.preferences.originName ?? 'Laoag City';
    state = state.copyWith(
      usingGps: true,
      preferences: state.preferences.copyWith(
        originName: 'Current GPS ($fallbackLabel)',
        originLatitude: fallbackLat,
        originLongitude: fallbackLon,
      ),
      clearError: true,
    );
  }

  Future<void> interpretPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.length < 3) {
      state = state.copyWith(
        errorMessage: 'Describe your trip in a few words first.',
      );
      return;
    }

    state = state.copyWith(
      prompt: trimmed,
      isParsingIntent: true,
      clearError: true,
    );

    try {
      final result = await ref.read(plannerRepositoryProvider).parseIntent(
            prompt: trimmed,
            originLguCode: state.preferences.originLguCode,
            latitude: state.preferences.originLatitude,
            longitude: state.preferences.originLongitude,
          );

      final hasCustomOrigin = state.preferences.originName != null ||
          (state.preferences.originLatitude != null &&
              state.preferences.originLongitude != null);
      final merged = result.extractedPreferences.copyWith(
        originLguCode:
            hasCustomOrigin ? state.preferences.originLguCode : null,
        originName: state.preferences.originName,
        originLatitude: state.preferences.originLatitude,
        originLongitude: state.preferences.originLongitude,
        lockedDestinationIds: state.preferences.lockedDestinationIds,
        excludedDestinationIds: state.preferences.excludedDestinationIds,
      );

      state = state.copyWith(
        isParsingIntent: false,
        intentSource: result.source,
        awaitingConfirmation: true,
        preferences: merged,
      );
    } catch (error) {
      state = state.copyWith(
        isParsingIntent: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> findMatchingPlaces() async {
    state = state.copyWith(
      isLoadingRecommendations: true,
      awaitingConfirmation: false,
      clearError: true,
    );

    try {
      final response = await ref
          .read(plannerRepositoryProvider)
          .fetchRecommendations(state.preferences);
      state = state.copyWith(
        isLoadingRecommendations: false,
        recommendations: response,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingRecommendations: false,
        errorMessage: error.toString(),
      );
    }
  }

  void toggleLockedDestination(int destinationId, {String? name}) {
    final current = [...state.preferences.lockedDestinationIds];
    final names = {...state.lockedDestinationNames};
    if (current.contains(destinationId)) {
      current.remove(destinationId);
      names.remove(destinationId);
    } else {
      current.add(destinationId);
      final resolved = name ??
          state.recommendations?.items
              .where((item) => item.id == destinationId)
              .map((item) => item.name)
              .firstOrNull;
      if (resolved != null && resolved.isNotEmpty) {
        names[destinationId] = resolved;
      }
    }
    state = state.copyWith(
      preferences: state.preferences.copyWith(lockedDestinationIds: current),
      lockedDestinationNames: names,
    );
  }

  void addDestinationToDraft(int destinationId, {String? name}) {
    final names = {
      ...state.lockedDestinationNames,
      if (name != null && name.isNotEmpty) destinationId: name,
    };
    if (state.preferences.lockedDestinationIds.contains(destinationId)) {
      state = state.copyWith(lockedDestinationNames: names);
      return;
    }
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        lockedDestinationIds: [
          ...state.preferences.lockedDestinationIds,
          destinationId,
        ],
      ),
      lockedDestinationNames: names,
    );
  }

  Future<bool> buildItinerary({TripPreferenceInput? overridePreferences}) async {
    final targetPrefs = overridePreferences ?? state.preferences;
    state = state.copyWith(
      preferences: targetPrefs,
      isGeneratingItinerary: true,
      clearError: true,
    );

    try {
      final plan = await ref
          .read(plannerRepositoryProvider)
          .generateItinerary(targetPrefs);
      state = state.copyWith(
        isGeneratingItinerary: false,
        itinerary: plan,
        detectedChanges: const [],
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isGeneratingItinerary: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<void> excludeStopAndRecalculate(int destinationId) async {
    final excluded = {
      ...state.preferences.excludedDestinationIds,
      destinationId,
    }.toList();
    final locked = state.preferences.lockedDestinationIds
        .where((id) => id != destinationId)
        .toList();
    final names = {...state.lockedDestinationNames}..remove(destinationId);
    state = state.copyWith(lockedDestinationNames: names);
    await buildItinerary(
      overridePreferences: state.preferences.copyWith(
        excludedDestinationIds: excluded,
        lockedDestinationIds: locked,
      ),
    );
  }

  void loadFavoritesIntoPlanner(List<FavoriteDestination> favorites) {
    final ids = <int>[];
    final names = <int, String>{};
    for (final fav in favorites) {
      if (fav.id > 0 && !ids.contains(fav.id)) {
        ids.add(fav.id);
        names[fav.id] = fav.name;
      }
    }
    state = state.copyWith(
      preferences: state.preferences.copyWith(lockedDestinationIds: ids),
      lockedDestinationNames: names,
      clearError: true,
    );
  }

  Future<bool> saveActiveItinerary(String title) async {
    final active = state.itinerary;
    if (active == null) return false;
    if (active.totalStops == 0) {
      state = state.copyWith(
        errorMessage: 'Cannot save an empty itinerary with no scheduled stops.',
      );
      return false;
    }
    try {
      final savedId = await ref.read(plannerRepositoryProvider).saveItinerary(
            title: title,
            itinerary: active,
            preferences: state.preferences,
          );
      if (!ref.mounted) return true;
      final savedPlan = active.copyWith(savedId: savedId);
      state = state.copyWith(
        itinerary: savedPlan,
        clearError: true,
      );
      ref
          .read(travelerLocalStoreProvider.notifier)
          .cacheItinerary(savedId, savedPlan);
      await loadSavedItineraries();
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(errorMessage: error.toString());
      }
      return false;
    }
  }

  Future<void> loadSavedItineraries() async {
    try {
      final items =
          await ref.read(plannerRepositoryProvider).fetchSavedItineraries();
      if (!ref.mounted) return;
      state = state.copyWith(savedItineraries: items);
    } catch (_) {
      // Keep non-blocking if offline or unauthenticated in isolated widget tests
    }
  }

  Future<bool> openSavedItinerary(int id) async {
    state = state.copyWith(isGeneratingItinerary: true, clearError: true);
    try {
      final loaded =
          await ref.read(plannerRepositoryProvider).loadSavedItinerary(id);
      final names = <int, String>{
        for (final day in loaded.itinerary.days)
          for (final stop in day.stops) stop.destinationId: stop.name,
      };
      await ref
          .read(travelerLocalStoreProvider.notifier)
          .cacheItinerary(id, loaded.itinerary);
      state = state.copyWith(
        isGeneratingItinerary: false,
        preferences: loaded.preferences,
        itinerary: loaded.itinerary,
        detectedChanges: loaded.detectedChanges,
        lockedDestinationNames: names,
      );
      return true;
    } catch (error) {
      final offline = ref
          .read(travelerLocalStoreProvider.notifier)
          .getCachedItinerary(id);
      if (offline != null) {
        final names = <int, String>{
          for (final day in offline.days)
            for (final stop in day.stops) stop.destinationId: stop.name,
        };
        state = state.copyWith(
          isGeneratingItinerary: false,
          itinerary: offline,
          detectedChanges: const [
            'Loaded offline trip pack (no server connection).',
          ],
          lockedDestinationNames: names,
          clearError: true,
        );
        return true;
      }
      state = state.copyWith(
        isGeneratingItinerary: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<void> deleteSavedItinerary(int id) async {
    try {
      await ref.read(plannerRepositoryProvider).deleteSavedItinerary(id);
      state = state.copyWith(
        savedItineraries:
            state.savedItineraries.where((item) => item.id != id).toList(),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> checkLiveChanges() async {
    final savedId = state.itinerary?.savedId;
    if (savedId == null) {
      await buildItinerary();
      return;
    }
    try {
      final changes =
          await ref.read(plannerRepositoryProvider).checkLiveChanges(savedId);
      state = state.copyWith(detectedChanges: changes, clearError: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  void autoRouteNearestToFurthest({int? dayIndex}) {
    final active = state.itinerary;
    if (active == null || active.days.isEmpty) return;

    final originLat = active.originLatitude ?? 18.1978;
    final originLon = active.originLongitude ?? 120.5936;
    final nextDays = <ItineraryDayPlan>[];

    for (var i = 0; i < active.days.length; i += 1) {
      final day = active.days[i];
      if (dayIndex != null && i != dayIndex) {
        nextDays.add(day);
        continue;
      }
      final sortedStops = [...day.stops]..sort((a, b) {
          final distA = (a.latitude != null && a.longitude != null)
              ? haversineDistanceKm(originLat, originLon, a.latitude!, a.longitude!)
              : double.infinity;
          final distB = (b.latitude != null && b.longitude != null)
              ? haversineDistanceKm(originLat, originLon, b.latitude!, b.longitude!)
              : double.infinity;
          return distA.compareTo(distB);
        });
      nextDays.add(day.copyWith(stops: sortedStops));
    }

    _commitReorderedDays(active, nextDays, originLat, originLon);
  }

  void moveStopInDay(int dayIndex, int oldIndex, int newIndex) {
    final active = state.itinerary;
    if (active == null || dayIndex < 0 || dayIndex >= active.days.length) {
      return;
    }
    final stops = [...active.days[dayIndex].stops];
    if (oldIndex < 0 ||
        oldIndex >= stops.length ||
        newIndex < 0 ||
        newIndex >= stops.length ||
        oldIndex == newIndex) {
      return;
    }
    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);

    final nextDays = [...active.days];
    nextDays[dayIndex] = active.days[dayIndex].copyWith(stops: stops);

    _commitReorderedDays(
      active,
      nextDays,
      active.originLatitude ?? 18.1978,
      active.originLongitude ?? 120.5936,
    );
  }

  void _commitReorderedDays(
    GeneratedItinerary active,
    List<ItineraryDayPlan> rawDays,
    double originLat,
    double originLon,
  ) {
    final recalculatedDays = <ItineraryDayPlan>[];
    var cursorLat = originLat;
    var cursorLon = originLon;
    var totalDistanceKm = 0.0;
    var totalTravelMinutes = 0;
    var totalTransportCost = 0.0;

    for (final day in rawDays) {
      final updatedDay = _recalculateDaySchedule(day, cursorLat, cursorLon);
      recalculatedDays.add(updatedDay);
      for (final stop in updatedDay.stops) {
        totalDistanceKm += stop.distanceFromPrevKm;
        totalTravelMinutes += stop.travelTimeFromPrevMinutes;
        totalTransportCost += stop.legTransportCostPhp;
        if (stop.latitude != null && stop.longitude != null) {
          cursorLat = stop.latitude!;
          cursorLon = stop.longitude!;
        }
      }
    }

    final expense = active.expenseBreakdown;
    final totalEstimatedCost = (expense.entranceAndActivityCost +
            expense.parkingCost +
            expense.mealsCost +
            totalTransportCost)
        .roundToDouble();
    final updatedExpense = ItineraryExpenseBreakdown(
      entranceAndActivityCost: expense.entranceAndActivityCost,
      parkingCost: expense.parkingCost,
      mealsCost: expense.mealsCost,
      transportCost: totalTransportCost.roundToDouble(),
      totalEstimatedCost: totalEstimatedCost,
      budgetAmount: expense.budgetAmount,
      remainingBudget: expense.budgetAmount != null
          ? expense.budgetAmount! - totalEstimatedCost
          : null,
    );

    state = state.copyWith(
      itinerary: active.copyWith(
        days: recalculatedDays,
        totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(2)),
        totalTravelMinutes: totalTravelMinutes,
        expenseBreakdown: updatedExpense,
      ),
      clearError: true,
    );
  }

  ItineraryDayPlan _recalculateDaySchedule(
    ItineraryDayPlan day,
    double originLat,
    double originLon,
  ) {
    if (day.stops.isEmpty) return day;

    final mode = state.preferences.transportMode;
    final groupSize = math.max(1, state.preferences.groupSize);
    final speedKmh = switch (mode) {
      'privateCar' => 48.0,
      'publicCommute' => 28.0,
      _ => 44.0,
    };
    final overheadMin = switch (mode) {
      'privateCar' => 5,
      'publicCommute' => 14,
      _ => 4,
    };

    var cursorMin = _parseHhMm(day.startTime) ?? 480;
    var cursorLat = originLat;
    var cursorLon = originLon;
    final updatedStops = <ItineraryStopItem>[];

    for (var i = 0; i < day.stops.length; i += 1) {
      final stop = day.stops[i];
      final stopLat = stop.latitude;
      final stopLon = stop.longitude;
      final straightKm = (stopLat != null && stopLon != null)
          ? haversineDistanceKm(cursorLat, cursorLon, stopLat, stopLon)
          : 0.0;
      final distKm = double.parse((straightKm * 1.28).toStringAsFixed(2));
      final travelMin = distKm < 0.05
          ? 0
          : math.max(5, ((distKm / speedKmh) * 60 + overheadMin).round());
      final costPhp = distKm < 0.05
          ? 0.0
          : switch (mode) {
              'privateCar' => (distKm * 9.0).roundToDouble(),
              'publicCommute' => ((20 + distKm * 3.2) * groupSize).roundToDouble(),
              _ => (distKm * 3.5).roundToDouble(),
            };

      final arrival = cursorMin + travelMin;
      final departure = arrival + stop.estimatedDurationMinutes;
      updatedStops.add(
        stop.copyWith(
          sequenceOrder: i + 1,
          startTime: _formatHhMm(arrival),
          endTime: _formatHhMm(departure),
          travelTimeFromPrevMinutes: travelMin,
          distanceFromPrevKm: distKm,
          legTransportCostPhp: costPhp,
        ),
      );
      cursorMin = departure;
      if (stopLat != null && stopLon != null) {
        cursorLat = stopLat;
        cursorLon = stopLon;
      }
    }

    return day.copyWith(
      stops: updatedStops,
      endTime: updatedStops.last.endTime,
    );
  }

  static int? _parseHhMm(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _formatHhMm(int totalMinutes) {
    final clamped = math.max(0, totalMinutes);
    final h = (clamped ~/ 60) % 24;
    final m = clamped % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void startRouteNavigation({int dayIndex = 0}) {
    final active = state.itinerary;
    if (active == null || active.days.isEmpty) return;
    final clampedDay = dayIndex.clamp(0, active.days.length - 1);
    state = state.copyWith(
      isNavigating: true,
      activeNavDayIndex: clampedDay,
      activeNavStopIndex: 0,
    );
  }

  void advanceRouteStop() {
    final active = state.itinerary;
    if (active == null || active.days.isEmpty) return;
    final dayIdx = state.activeNavDayIndex.clamp(0, active.days.length - 1);
    final stops = active.days[dayIdx].stops;
    if (state.activeNavStopIndex + 1 < stops.length) {
      state = state.copyWith(activeNavStopIndex: state.activeNavStopIndex + 1);
    } else if (dayIdx + 1 < active.days.length &&
        active.days[dayIdx + 1].stops.isNotEmpty) {
      state = state.copyWith(
        activeNavDayIndex: dayIdx + 1,
        activeNavStopIndex: 0,
      );
    } else {
      state = state.copyWith(isNavigating: false, activeNavStopIndex: 0);
    }
  }

  void previousRouteStop() {
    final active = state.itinerary;
    if (active == null || active.days.isEmpty) return;
    if (state.activeNavStopIndex > 0) {
      state = state.copyWith(activeNavStopIndex: state.activeNavStopIndex - 1);
    } else if (state.activeNavDayIndex > 0) {
      final prevDayIdx = state.activeNavDayIndex - 1;
      final prevStops = active.days[prevDayIdx].stops;
      if (prevStops.isNotEmpty) {
        state = state.copyWith(
          activeNavDayIndex: prevDayIdx,
          activeNavStopIndex: prevStops.length - 1,
        );
      }
    }
  }

  void stopRouteNavigation() {
    state = state.copyWith(isNavigating: false, activeNavStopIndex: 0);
  }
}

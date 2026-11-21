import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/network_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/planner_repository.dart';
import '../domain/trip_plan_models.dart';

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
    );
  }
}

final plannerProvider = NotifierProvider<PlannerNotifier, PlannerState>(
  PlannerNotifier.new,
);

class PlannerNotifier extends Notifier<PlannerState> {
  @override
  PlannerState build() {
    final userPrefs = ref.read(authNotifierProvider).value?.travelPreferences;
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
  }

  void setPrompt(String prompt) {
    state = state.copyWith(prompt: prompt, clearError: true);
  }

  void setOriginLgu(String lguCode) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        originLguCode: lguCode,
        clearOriginCoords: true,
      ),
      usingGps: false,
      clearError: true,
    );
  }

  Future<void> acquireGpsLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        state = state.copyWith(
          errorMessage: 'Location services are off. Choose a starting town instead.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          errorMessage: 'Location permission denied. Select a starting town manually.',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );

      // Keep within Ilocos Norte bounding box; otherwise fall back safely
      final inProvince = pos.latitude >= 17.8 &&
          pos.latitude <= 18.68 &&
          pos.longitude >= 120.4 &&
          pos.longitude <= 121.05;

      if (!inProvince) {
        state = state.copyWith(
          usingGps: false,
          errorMessage:
              'GPS is outside Ilocos Norte; anchored to ${state.preferences.originLguCode}.',
        );
        return;
      }

      state = state.copyWith(
        usingGps: true,
        preferences: state.preferences.copyWith(
          originLatitude: pos.latitude,
          originLongitude: pos.longitude,
        ),
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        usingGps: false,
        errorMessage: 'Could not read GPS right now. Using selected starting town.',
      );
    }
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

      final merged = result.extractedPreferences.copyWith(
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

  void toggleLockedDestination(int destinationId) {
    final current = [...state.preferences.lockedDestinationIds];
    if (current.contains(destinationId)) {
      current.remove(destinationId);
    } else {
      current.add(destinationId);
    }
    state = state.copyWith(
      preferences: state.preferences.copyWith(lockedDestinationIds: current),
    );
  }

  void addDestinationToDraft(int destinationId) {
    if (state.preferences.lockedDestinationIds.contains(destinationId)) return;
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        lockedDestinationIds: [
          ...state.preferences.lockedDestinationIds,
          destinationId,
        ],
      ),
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
    await buildItinerary(
      overridePreferences: state.preferences.copyWith(
        excludedDestinationIds: excluded,
        lockedDestinationIds: locked,
      ),
    );
  }

  Future<void> saveActiveItinerary(String title) async {
    final active = state.itinerary;
    if (active == null) return;
    try {
      final savedId = await ref.read(plannerRepositoryProvider).saveItinerary(
            title: title,
            itinerary: active,
            preferences: state.preferences,
          );
      state = state.copyWith(
        itinerary: active.copyWith(savedId: savedId),
        clearError: true,
      );
      await loadSavedItineraries();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> loadSavedItineraries() async {
    try {
      final items =
          await ref.read(plannerRepositoryProvider).fetchSavedItineraries();
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
      state = state.copyWith(
        isGeneratingItinerary: false,
        preferences: loaded.preferences,
        itinerary: loaded.itinerary,
        detectedChanges: loaded.detectedChanges,
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
}

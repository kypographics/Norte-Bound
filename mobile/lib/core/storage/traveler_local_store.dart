import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/discovery/domain/lgu.dart';
import '../../features/preferences/domain/trip_plan_models.dart';

class FavoriteDestination {
  const FavoriteDestination({
    required this.id,
    required this.slug,
    required this.name,
    required this.lguName,
    required this.categoryCode,
    this.imageUrl,
  });

  final int id;
  final String slug;
  final String name;
  final String lguName;
  final String categoryCode;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'lguName': lguName,
    'categoryCode': categoryCode,
    'imageUrl': imageUrl,
  };

  factory FavoriteDestination.fromJson(Map<String, dynamic> json) {
    return FavoriteDestination(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      lguName: (json['lguName'] as String?) ?? '',
      categoryCode: (json['categoryCode'] as String?) ?? 'natural_attraction',
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : null,
    );
  }
}

class TravelerLocalState {
  const TravelerLocalState({
    this.favorites = const [],
    this.stampedLgus = const {},
    this.offlinePlans = const {},
  });

  final List<FavoriteDestination> favorites;
  final Set<String> stampedLgus;
  final Map<int, Map<String, dynamic>> offlinePlans;

  bool isFavorite(int id) => favorites.any((item) => item.id == id);

  bool hasOfflinePlan(int id) => offlinePlans.containsKey(id);

  TravelerLocalState copyWith({
    List<FavoriteDestination>? favorites,
    Set<String>? stampedLgus,
    Map<int, Map<String, dynamic>>? offlinePlans,
  }) {
    return TravelerLocalState(
      favorites: favorites ?? this.favorites,
      stampedLgus: stampedLgus ?? this.stampedLgus,
      offlinePlans: offlinePlans ?? this.offlinePlans,
    );
  }
}

final travelerLocalStoreProvider =
    NotifierProvider<TravelerLocalStoreNotifier, TravelerLocalState>(
      TravelerLocalStoreNotifier.new,
    );

class TravelerLocalStoreNotifier extends Notifier<TravelerLocalState> {
  static const _favKey = 'nb_favorites_v1';
  static const _passportKey = 'nb_passport_lgus_v1';
  static const _offlineKey = 'nb_offline_plans_v1';

  @override
  TravelerLocalState build() {
    Future.microtask(_loadFromPrefs);
    return const TravelerLocalState();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawFavs = prefs.getString(_favKey);
      final rawLgus = prefs.getStringList(_passportKey) ?? const [];
      final rawOffline = prefs.getString(_offlineKey);

      final favorites = <FavoriteDestination>[];
      if (rawFavs != null && rawFavs.isNotEmpty) {
        final decoded = jsonDecode(rawFavs);
        if (decoded is List) {
          for (final item in decoded.whereType<Map<String, dynamic>>()) {
            favorites.add(FavoriteDestination.fromJson(item));
          }
        }
      }

      final offlinePlans = <int, Map<String, dynamic>>{};
      if (rawOffline != null && rawOffline.isNotEmpty) {
        final decoded = jsonDecode(rawOffline);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final id = int.tryParse(entry.key);
            if (id != null && entry.value is Map<String, dynamic>) {
              offlinePlans[id] = entry.value as Map<String, dynamic>;
            }
          }
        }
      }

      state = state.copyWith(
        favorites: favorites,
        stampedLgus: rawLgus.toSet(),
        offlinePlans: offlinePlans,
      );
    } catch (_) {
      // Widget tests or uninitialized platform storage stay in memory cleanly.
    }
  }

  Future<void> toggleFavorite(FavoriteDestination destination) async {
    final current = [...state.favorites];
    final existingIdx = current.indexWhere((f) => f.id == destination.id);
    if (existingIdx >= 0) {
      current.removeAt(existingIdx);
    } else {
      current.insert(0, destination);
    }
    state = state.copyWith(favorites: current);
    await _persistFavorites(current);
  }

  Future<void> stampLgu(String lguCode) async {
    if (lguCode.isEmpty || state.stampedLgus.contains(lguCode)) return;
    final next = {...state.stampedLgus, lguCode};
    state = state.copyWith(stampedLgus: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_passportKey, next.toList(growable: false));
    } catch (_) {}
  }

  Future<({String? lguCode, String? lguName, double? distanceKm})>
  checkInNearestLgu(List<Lgu> lgus) async {
    if (lgus.isEmpty) {
      return (lguCode: null, lguName: null, distanceKm: null);
    }

    double? lat;
    double? lon;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          );
          if (pos.latitude >= 17.5 &&
              pos.latitude <= 19.0 &&
              pos.longitude >= 120.2 &&
              pos.longitude <= 121.3) {
            lat = pos.latitude;
            lon = pos.longitude;
          }
        }
      }
    } catch (_) {}

    if (lat == null || lon == null) {
      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ),
        );
        final res = await dio.get<Map<String, dynamic>>('https://ipwho.is/');
        final data = res.data;
        final iLat = (data?['latitude'] as num?)?.toDouble();
        final iLon = (data?['longitude'] as num?)?.toDouble();
        if (iLat != null &&
            iLon != null &&
            iLat >= 17.5 &&
            iLat <= 19.0 &&
            iLon >= 120.2 &&
            iLon <= 121.3) {
          lat = iLat;
          lon = iLon;
        }
      } catch (_) {}
    }

    final checkLat = lat ?? 18.1978;
    final checkLon = lon ?? 120.5936;
    Lgu? nearest;
    var bestKm = double.infinity;
    for (final lgu in lgus) {
      final cLat = lgu.centerLatitude;
      final cLon = lgu.centerLongitude;
      if (cLat == null || cLon == null) continue;
      final d = _haversineKm(checkLat, checkLon, cLat, cLon);
      if (d < bestKm) {
        bestKm = d;
        nearest = lgu;
      }
    }

    if (nearest == null) {
      return (lguCode: null, lguName: null, distanceKm: null);
    }
    await stampLgu(nearest.lguCode);
    return (lguCode: nearest.lguCode, lguName: nearest.name, distanceKm: bestKm);
  }

  Future<void> cacheItinerary(int savedId, GeneratedItinerary plan) async {
    final next = {
      ...state.offlinePlans,
      savedId: plan.copyWith(savedId: savedId).toJson(),
    };
    state = state.copyWith(offlinePlans: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, dynamic>{
        for (final entry in next.entries) entry.key.toString(): entry.value,
      };
      await prefs.setString(_offlineKey, jsonEncode(encoded));
    } catch (_) {}
  }

  GeneratedItinerary? getCachedItinerary(int savedId) {
    final raw = state.offlinePlans[savedId];
    if (raw == null) return null;
    try {
      return GeneratedItinerary.fromJson(raw).copyWith(savedId: savedId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistFavorites(List<FavoriteDestination> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _favKey,
        jsonEncode(favorites.map((f) => f.toJson()).toList(growable: false)),
      );
    } catch (_) {}
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthKm = 6371.0;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final sLat = math.sin(dLat / 2);
    final sLon = math.sin(dLon / 2);
    final h =
        sLat * sLat +
        math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * sLon * sLon;
    return 2 * earthKm * math.asin(math.min(1.0, math.sqrt(h)));
  }
}

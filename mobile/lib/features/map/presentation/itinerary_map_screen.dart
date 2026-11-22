import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../preferences/domain/trip_plan_models.dart';
import '../../preferences/presentation/planner_providers.dart';

class ItineraryMapScreen extends ConsumerStatefulWidget {
  const ItineraryMapScreen({super.key});

  @override
  ConsumerState<ItineraryMapScreen> createState() => _ItineraryMapScreenState();
}

class _ItineraryMapScreenState extends ConsumerState<ItineraryMapScreen> {
  int _selectedDayIndex = 0;
  List<LatLng> _routePoints = const [];
  bool _loadingRoute = false;
  bool _hasLiveRoadRoute = false;
  String? _lastRouteKey;
  CancelToken? _routeCancelToken;
  List<LatLng> _activeLegPoints = const [];
  double? _activeLegRoadKm;
  int? _activeLegRoadMinutes;
  String? _lastActiveLegKey;
  CancelToken? _activeLegCancelToken;
  StreamSubscription<Position>? _gpsSub;
  Position? _livePosition;
  bool _gpsListening = false;

  @override
  void dispose() {
    _routeCancelToken?.cancel('disposed');
    _activeLegCancelToken?.cancel('disposed');
    _gpsSub?.cancel();
    super.dispose();
  }

  void _syncGpsStream(bool active) {
    if (!active) {
      if (_gpsListening) {
        _gpsSub?.cancel();
        _gpsSub = null;
        _gpsListening = false;
      }
      return;
    }
    if (_gpsListening) return;
    _gpsListening = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_gpsListening) return;
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled || !mounted) return;
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          return;
        }
        _gpsSub =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 15,
              ),
            ).listen((pos) {
              if (mounted &&
                  pos.latitude >= 4.5 &&
                  pos.latitude <= 21.5 &&
                  pos.longitude >= 116.0 &&
                  pos.longitude <= 127.0) {
                setState(() => _livePosition = pos);
              }
            }, onError: (_) {});
      } catch (_) {}
    });
  }

  Future<void> _openExternalNav(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _syncRoute(List<LatLng> waypoints) {
    if (waypoints.length < 2) {
      if (_routePoints.isNotEmpty || _lastRouteKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _lastRouteKey = null;
            _routePoints = waypoints;
            _hasLiveRoadRoute = false;
            _loadingRoute = false;
          });
        });
      }
      return;
    }

    final key = waypoints
        .map(
          (p) =>
              '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}',
        )
        .join(';');
    if (key == _lastRouteKey) return;

    _lastRouteKey = key;
    final corridor = _buildRoadCorridorPolyline(waypoints);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _routePoints = corridor;
        _hasLiveRoadRoute = false;
        _loadingRoute = true;
      });
      unawaited(_fetchOsrmRoadRoute(waypoints, key));
    });
  }

  void _syncActiveLeg(LatLng? from, LatLng? to) {
    if (from == null || to == null) {
      if (_lastActiveLegKey != null || _activeLegPoints.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _lastActiveLegKey = null;
            _activeLegPoints = const [];
            _activeLegRoadKm = null;
            _activeLegRoadMinutes = null;
          });
        });
      }
      return;
    }

    final key =
        '${from.latitude.toStringAsFixed(4)},${from.longitude.toStringAsFixed(4)};${to.latitude.toStringAsFixed(4)},${to.longitude.toStringAsFixed(4)}';
    if (key == _lastActiveLegKey) return;

    _lastActiveLegKey = key;
    final fallback = _buildRoadCorridorPolyline([from, to]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _activeLegPoints = fallback;
        _activeLegRoadKm = null;
        _activeLegRoadMinutes = null;
      });
      unawaited(_fetchOsrmActiveLeg(from, to, key));
    });
  }

  Future<void> _fetchOsrmActiveLeg(
    LatLng from,
    LatLng to,
    String requestKey,
  ) async {
    _activeLegCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _activeLegCancelToken = cancelToken;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );
    try {
      final coords =
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
      final response = await dio.get<Map<String, dynamic>>(
        'https://router.project-osrm.org/route/v1/driving/$coords',
        queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
        cancelToken: cancelToken,
      );
      if (!mounted || _lastActiveLegKey != requestKey) return;

      final parsed = _parseOsrmRoute(response.data);
      if (parsed != null && mounted) {
        setState(() {
          _activeLegPoints = parsed.points;
          _activeLegRoadKm = parsed.distanceKm;
          _activeLegRoadMinutes = parsed.durationMinutes;
        });
      }
    } catch (_) {
      // Keep corridor fallback when offline or OSRM unavailable
    } finally {
      dio.close(force: true);
    }
  }

  static ({List<LatLng> points, double? distanceKm, int? durationMinutes})?
  _parseOsrmRoute(Map<String, dynamic>? data) {
    final routes = data?['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) return null;
    final route = routes.first as Map;
    final geometry = route['geometry'];
    final rawCoords = geometry is Map ? geometry['coordinates'] : null;
    if (rawCoords is! List || rawCoords.length < 2) return null;

    final roadPoints = <LatLng>[];
    for (final item in rawCoords) {
      if (item is List && item.length >= 2 && item[0] is num && item[1] is num) {
        roadPoints.add(
          LatLng((item[1] as num).toDouble(), (item[0] as num).toDouble()),
        );
      }
    }
    if (roadPoints.length < 2) return null;

    final meters = (route['distance'] as num?)?.toDouble();
    final seconds = (route['duration'] as num?)?.toDouble();
    return (
      points: roadPoints,
      distanceKm: meters != null
          ? double.parse((meters / 1000).toStringAsFixed(1))
          : null,
      durationMinutes: seconds != null
          ? math.max(1, (seconds / 60).round())
          : null,
    );
  }

  Future<void> _fetchOsrmRoadRoute(
    List<LatLng> waypoints,
    String requestKey,
  ) async {
    _routeCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _routeCancelToken = cancelToken;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );
    try {
      final coords = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final response = await dio.get<Map<String, dynamic>>(
        'https://router.project-osrm.org/route/v1/driving/$coords',
        queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
        cancelToken: cancelToken,
      );
      if (!mounted || _lastRouteKey != requestKey) return;

      final parsed = _parseOsrmRoute(response.data);
      if (parsed != null && mounted) {
        setState(() {
          _routePoints = parsed.points;
          _hasLiveRoadRoute = true;
          _loadingRoute = false;
        });
      }
    } catch (_) {
      // Keep curved road-corridor fallback when offline or OSRM unavailable
    } finally {
      dio.close(force: true);
      if (mounted && _lastRouteKey == requestKey) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  static List<LatLng> _buildRoadCorridorPolyline(List<LatLng> waypoints) {
    if (waypoints.length < 2) return waypoints;
    const stepsPerLeg = 8;
    final points = <LatLng>[];

    for (var i = 0; i < waypoints.length - 1; i += 1) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      final dLat = b.latitude - a.latitude;
      final dLon = b.longitude - a.longitude;
      final legSpan = math.sqrt(dLat * dLat + dLon * dLon);
      final bowScale = math.min(0.015, legSpan * 0.14);
      final nx = legSpan > 0 ? -dLon / legSpan : 0.0;
      final ny = legSpan > 0 ? dLat / legSpan : 0.0;

      for (var s = 0; s < stepsPerLeg; s += 1) {
        final t = s / stepsPerLeg;
        final arch = math.sin(t * math.pi) * bowScale;
        points.add(
          LatLng(
            a.latitude + dLat * t + nx * arch,
            a.longitude + dLon * t + ny * arch,
          ),
        );
      }
    }
    points.add(waypoints.last);
    return points;
  }

  static _TrafficEstimate _estimateTraffic(ItineraryStopItem stop) {
    const urbanHubs = {'laoag-city', 'san-nicolas', 'batac-city'};
    const highwayCorridors = {
      'paoay',
      'currimao',
      'bacarra',
      'pasuquin',
      'pagudpud',
      'sarrat',
      'dingras',
    };
    final parts = stop.startTime.split(':');
    final hour = parts.isNotEmpty
        ? (int.tryParse(parts[0]) ?? DateTime.now().hour)
        : DateTime.now().hour;
    final isPeak = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 18);

    if (urbanHubs.contains(stop.lguCode) && isPeak) {
      return const _TrafficEstimate(
        label: 'Heavy traffic',
        detail: 'Peak urban corridor',
        multiplier: 1.30,
        isHeavy: true,
      );
    }
    if (urbanHubs.contains(stop.lguCode) ||
        (highwayCorridors.contains(stop.lguCode) && hour >= 8 && hour <= 17)) {
      return const _TrafficEstimate(
        label: 'Moderate traffic',
        detail: 'Steady highway flow',
        multiplier: 1.15,
        isModerate: true,
      );
    }
    return const _TrafficEstimate(
      label: 'Light traffic',
      detail: 'Clear road conditions',
      multiplier: 1.0,
    );
  }

  static String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerProvider);
    final itinerary = plannerState.itinerary;
    final textTheme = Theme.of(context).textTheme;

    if (itinerary == null) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        appBar: AppBar(title: const Text('Route Map')),
        body: const Center(
          child: Text('Generate an itinerary to view the route map.'),
        ),
      );
    }

    final isNavigating = plannerState.isNavigating;
    _syncGpsStream(isNavigating);
    final dayIdx = itinerary.days.isEmpty
        ? 0
        : (isNavigating ? plannerState.activeNavDayIndex : _selectedDayIndex)
              .clamp(0, itinerary.days.length - 1);
    final activeDay = itinerary.days.isNotEmpty ? itinerary.days[dayIdx] : null;
    final stops = activeDay?.stops ?? const <ItineraryStopItem>[];
    final activeStopIdx = stops.isEmpty
        ? 0
        : plannerState.activeNavStopIndex.clamp(0, stops.length - 1);

    final originLat = itinerary.originLatitude ?? 18.1978;
    final originLon = itinerary.originLongitude ?? 120.5936;

    var startLat = originLat;
    var startLon = originLon;
    if (dayIdx > 0) {
      for (var d = dayIdx - 1; d >= 0; d -= 1) {
        final prevStops = itinerary.days[d].stops;
        if (prevStops.isNotEmpty &&
            prevStops.last.latitude != null &&
            prevStops.last.longitude != null) {
          startLat = prevStops.last.latitude!;
          startLon = prevStops.last.longitude!;
          break;
        }
      }
    }

    final waypoints = <LatLng>[
      LatLng(startLat, startLon),
      for (final stop in stops)
        if (stop.latitude != null && stop.longitude != null)
          LatLng(stop.latitude!, stop.longitude!),
    ];

    _syncRoute(waypoints);

    final polylinePoints = _routePoints.length >= 2 ? _routePoints : waypoints;

    // Active navigation leg points & metrics
    LatLng? activeFrom;
    LatLng? activeTo;
    ItineraryStopItem? nextStop;
    double legDistanceKm = 0;
    int etaMinutes = 0;
    String etaClock = '';
    _TrafficEstimate? traffic;
    var arrivedNearby = false;

    if (isNavigating && stops.isNotEmpty) {
      nextStop = stops[activeStopIdx];
      final prevStop = activeStopIdx > 0 ? stops[activeStopIdx - 1] : null;
      activeFrom = _livePosition != null
          ? LatLng(_livePosition!.latitude, _livePosition!.longitude)
          : LatLng(
              prevStop?.latitude ?? startLat,
              prevStop?.longitude ?? startLon,
            );
      activeTo = LatLng(
        nextStop.latitude ?? startLat,
        nextStop.longitude ?? startLon,
      );
      final directKm = haversineDistanceKm(
        activeFrom.latitude,
        activeFrom.longitude,
        activeTo.latitude,
        activeTo.longitude,
      );
      arrivedNearby = _livePosition != null && directKm <= 0.25;
      _syncActiveLeg(activeFrom, activeTo);
      final computedKm = directKm * 1.28;
      legDistanceKm = _activeLegRoadKm ??
          (_livePosition == null && nextStop.distanceFromPrevKm > 0
              ? nextStop.distanceFromPrevKm
              : double.parse(computedKm.toStringAsFixed(1)));
      final baseMinutes = _activeLegRoadMinutes ??
          (_livePosition == null && nextStop.travelTimeFromPrevMinutes > 0
              ? nextStop.travelTimeFromPrevMinutes
              : math.max(1, (legDistanceKm / 42 * 60).round()));
      traffic = _estimateTraffic(nextStop);
      etaMinutes = math.max(1, (baseMinutes * traffic.multiplier).round());
      etaClock = _formatClock(
        DateTime.now().add(Duration(minutes: etaMinutes)),
      );
    } else {
      _syncActiveLeg(null, null);
    }

    final activeLegPoints = _activeLegPoints.length >= 2
        ? _activeLegPoints
        : (activeFrom != null && activeTo != null)
        ? _buildRoadCorridorPolyline([activeFrom, activeTo])
        : const <LatLng>[];
    final initialCenter = activeTo ?? waypoints.first;

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: AppColors.warmSand,
        title: Text(
          isNavigating
              ? 'Active Route · Day ${dayIdx + 1}'
              : '${itinerary.totalDays}-Day Route (${itinerary.totalDistanceKm} km)',
        ),
        actions: [
          if (stops.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                final notifier = ref.read(plannerProvider.notifier);
                if (isNavigating) {
                  notifier.stopRouteNavigation();
                } else {
                  notifier.startRouteNavigation(dayIndex: dayIdx);
                }
              },
              icon: Icon(
                isNavigating
                    ? CupertinoIcons.stop_circle
                    : CupertinoIcons.location_north_fill,
                size: 16,
              ),
              label: Text(isNavigating ? 'End route' : 'Navigate'),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: isNavigating ? 11.4 : 10.6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ph.nortebound.mobile',
              ),
              if (polylinePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: isNavigating ? 3.5 : 4.5,
                      borderStrokeWidth: 1.8,
                      borderColor: AppColors.ivorySand,
                      color: isNavigating
                          ? AppColors.terracotta.withValues(alpha: 0.45)
                          : AppColors.terracotta,
                    ),
                    if (isNavigating && activeLegPoints.length >= 2)
                      Polyline(
                        points: activeLegPoints,
                        strokeWidth: 5.5,
                        borderStrokeWidth: 2,
                        borderColor: AppColors.ivorySand,
                        color: AppColors.deepForest,
                      ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_livePosition != null)
                    Marker(
                      point: LatLng(
                        _livePosition!.latitude,
                        _livePosition!.longitude,
                      ),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.ivorySand,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  Marker(
                    point: LatLng(startLat, startLon),
                    width: 34,
                    height: 34,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.deepForest,
                      child: Icon(
                        CupertinoIcons.location_fill,
                        size: 16,
                        color: AppColors.ivorySand,
                      ),
                    ),
                  ),
                  for (var i = 0; i < stops.length; i += 1)
                    if (stops[i].latitude != null && stops[i].longitude != null)
                      Marker(
                        point: LatLng(stops[i].latitude!, stops[i].longitude!),
                        width: isNavigating && i == activeStopIdx ? 38 : 32,
                        height: isNavigating && i == activeStopIdx ? 38 : 32,
                        child: Container(
                          decoration: isNavigating && i == activeStopIdx
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.deepForest,
                                    width: 3,
                                  ),
                                )
                              : null,
                          child: CircleAvatar(
                            backgroundColor: isNavigating && i == activeStopIdx
                                ? AppColors.deepForest
                                : AppColors.terracotta,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppColors.ivorySand,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),
          if (isNavigating && nextStop != null && traffic != null)
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const ShapeDecoration(
                            color: AppColors.skyBlueWash,
                            shape: StadiumBorder(),
                          ),
                          child: Text(
                            'NEXT DESTINATION · STOP ${activeStopIdx + 1} OF ${stops.length}',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.deepForest,
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: traffic.isHeavy
                                ? AppColors.terracottaWash
                                : AppColors.skyBlueWash,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            traffic.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: traffic.isHeavy
                                  ? AppColors.terracotta
                                  : AppColors.deepForest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      arrivedNearby
                          ? 'Arrived at ${nextStop.name}!'
                          : nextStop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: arrivedNearby
                            ? AppColors.terracotta
                            : AppColors.deepForest,
                      ),
                    ),
                    Text(
                      '${nextStop.lguName} · ${nextStop.operatingWindowLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HudMetric(
                            label: 'DISTANCE',
                            value: '${legDistanceKm.toStringAsFixed(1)} km',
                          ),
                        ),
                        Expanded(
                          child: _HudMetric(
                            label: 'ETA',
                            value: '$etaClock ($etaMinutes mins)',
                          ),
                        ),
                        Expanded(
                          child: _HudMetric(
                            label: 'TRAFFIC',
                            value: traffic.detail,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (activeTo != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openExternalNav(
                              Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination=${activeTo!.latitude},${activeTo.longitude}',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.map, size: 13),
                            label: const Text('Google Maps'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openExternalNav(
                              Uri.parse(
                                'https://waze.com/ul?ll=${activeTo!.latitude},${activeTo.longitude}&navigate=yes',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                            icon: const Icon(
                              CupertinoIcons.arrow_turn_up_right,
                              size: 13,
                            ),
                            label: const Text('Waze'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        if (activeStopIdx > 0 || dayIdx > 0)
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(plannerProvider.notifier)
                                  .previousRouteStop();
                            },
                            icon: const Icon(
                              CupertinoIcons.chevron_left,
                              size: 14,
                            ),
                            label: const Text('Previous'),
                          ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(plannerProvider.notifier)
                                .advanceRouteStop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: AppColors.ivorySand,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 15,
                          ),
                          label: Text(
                            activeStopIdx + 1 < stops.length ||
                                    dayIdx + 1 < itinerary.days.length
                                ? 'Arrived · Next stop'
                                : 'Finish route',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          DraggableScrollableSheet(
            initialChildSize: isNavigating ? 0.24 : 0.34,
            minChildSize: 0.18,
            maxChildSize: 0.72,
            builder: (context, controller) {
              return Container(
                decoration: const ShapeDecoration(
                  color: AppColors.ivorySand,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stops.length} stops · ${itinerary.totalTravelMinutes} mins travel',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: AppTypography.tabularFigures,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hasLiveRoadRoute
                                    ? 'Live road route · nearest to furthest editable'
                                    : _loadingRoute
                                    ? 'Loading road route...'
                                    : 'Estimated road corridor · nearest to furthest editable',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.mutedForest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (!isNavigating && stops.isNotEmpty)
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(plannerProvider.notifier)
                                  .startRouteNavigation(dayIndex: dayIdx);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.deepForest,
                              foregroundColor: AppColors.ivorySand,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            icon: const Icon(
                              CupertinoIcons.location_north_fill,
                              size: 14,
                            ),
                            label: const Text('Start route'),
                          ),
                        FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(plannerProvider.notifier)
                                .autoRouteNearestToFurthest(dayIndex: dayIdx);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ordered stops from nearest to furthest.',
                                  ),
                                  backgroundColor: AppColors.deepForest,
                                ),
                              );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: AppColors.ivorySand,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          icon: const Icon(CupertinoIcons.compass, size: 14),
                          label: const Text('Nearest → Furthest'),
                        ),
                      ],
                    ),
                    if (!isNavigating && itinerary.days.length > 1) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < itinerary.days.length; i += 1)
                            ChoiceChip(
                              label: Text('Day ${itinerary.days[i].dayNumber}'),
                              selected: dayIdx == i,
                              selectedColor: AppColors.skyBlueWash,
                              onSelected: (_) =>
                                  setState(() => _selectedDayIndex = i),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    for (var i = 0; i < stops.length; i += 1)
                      _MapStopTile(
                        index: i + 1,
                        stop: stops[i],
                        highlighted: isNavigating && i == activeStopIdx,
                        distFromOriginKm:
                            (stops[i].latitude != null &&
                                stops[i].longitude != null)
                            ? haversineDistanceKm(
                                originLat,
                                originLon,
                                stops[i].latitude!,
                                stops[i].longitude!,
                              )
                            : 0,
                        canMoveUp: i > 0,
                        canMoveDown: i < stops.length - 1,
                        onMoveUp: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(plannerProvider.notifier)
                              .moveStopInDay(dayIdx, i, i - 1);
                        },
                        onMoveDown: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(plannerProvider.notifier)
                              .moveStopInDay(dayIdx, i, i + 1);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrafficEstimate {
  const _TrafficEstimate({
    required this.label,
    required this.detail,
    required this.multiplier,
    this.isHeavy = false,
    this.isModerate = false,
  });

  final String label;
  final String detail;
  final double multiplier;
  final bool isHeavy;
  final bool isModerate;
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.mutedForest,
            fontSize: 8.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.deepForest,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}

class _MapStopTile extends StatelessWidget {
  const _MapStopTile({
    required this.index,
    required this.stop,
    required this.highlighted,
    required this.distFromOriginKm,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int index;
  final ItineraryStopItem stop;
  final bool highlighted;
  final double distFromOriginKm;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: highlighted
            ? AppColors.deepForest
            : AppColors.terracotta,
        child: Text(
          '$index',
          style: const TextStyle(
            color: AppColors.ivorySand,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        stop.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: highlighted
            ? const TextStyle(fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: Text(
        '${stop.startTime}–${stop.endTime} · ${stop.lguName} · ${distFromOriginKm.toStringAsFixed(1)} km from start',
        style: const TextStyle(fontFeatures: AppTypography.tabularFigures),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Move earlier',
            visualDensity: VisualDensity.compact,
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(CupertinoIcons.chevron_up, size: 16),
          ),
          IconButton(
            tooltip: 'Move later',
            visualDensity: VisualDensity.compact,
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(CupertinoIcons.chevron_down, size: 16),
          ),
        ],
      ),
    );
  }
}

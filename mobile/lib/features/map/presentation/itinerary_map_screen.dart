import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../preferences/presentation/planner_providers.dart';

class ItineraryMapScreen extends ConsumerWidget {
  const ItineraryMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerary = ref.watch(plannerProvider).itinerary;
    final textTheme = Theme.of(context).textTheme;

    if (itinerary == null) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        appBar: AppBar(title: const Text('Route Map')),
        body: const Center(child: Text('Generate an itinerary to view the route map.')),
      );
    }

    final stops = itinerary.days.expand((d) => d.stops).toList(growable: false);
    final points = <LatLng>[
      if (itinerary.originLatitude != null && itinerary.originLongitude != null)
        LatLng(itinerary.originLatitude!, itinerary.originLongitude!),
      for (final stop in stops)
        if (stop.latitude != null && stop.longitude != null)
          LatLng(stop.latitude!, stop.longitude!),
    ];

    final initialCenter =
        points.isNotEmpty ? points.first : const LatLng(18.1978, 120.5936);

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: AppColors.warmSand,
        title: Text('${itinerary.totalDays}-Day Route (${itinerary.totalDistanceKm} km)'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 10.2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ph.nortebound.mobile',
              ),
              if (points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 4,
                      color: AppColors.terracotta,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (itinerary.originLatitude != null &&
                      itinerary.originLongitude != null)
                    Marker(
                      point: LatLng(
                        itinerary.originLatitude!,
                        itinerary.originLongitude!,
                      ),
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
                        width: 32,
                        height: 32,
                        child: CircleAvatar(
                          backgroundColor: AppColors.terracotta,
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
                ],
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.16,
            maxChildSize: 0.65,
            builder: (context, controller) {
              return Container(
                decoration: const ShapeDecoration(
                  color: AppColors.ivorySand,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                ),
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  itemCount: stops.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${stops.length} scheduled stops · ${itinerary.totalTravelMinutes} mins travel',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      );
                    }
                    final stop = stops[index - 1];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.terracotta,
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: AppColors.ivorySand,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(stop.name),
                      subtitle: Text(
                        '${stop.startTime}–${stop.endTime} · ${stop.lguName}',
                        style: TextStyle(fontFeatures: AppTypography.tabularFigures),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

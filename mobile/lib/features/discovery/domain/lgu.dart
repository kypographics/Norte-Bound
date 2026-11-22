import '../../../core/utils/json_parse.dart';

abstract final class TourismClusterInfo {
  static const northernCoast = 'northern_coast';
  static const centralUrbanHeritage = 'central_urban_heritage';
  static const southernHeritageCoast = 'southern_heritage_coast';
  static const easternAgriHighland = 'eastern_agri_highland';

  static const orderedCodes = <String>[
    northernCoast,
    centralUrbanHeritage,
    southernHeritageCoast,
    easternAgriHighland,
  ];

  static const labels = <String, String>{
    northernCoast: 'Northern Coast',
    centralUrbanHeritage: 'Central Heritage',
    southernHeritageCoast: 'Southern Coast',
    easternAgriHighland: 'Eastern Highland',
  };

  static String labelFor(String? code) {
    if (code == null || code.isEmpty) {
      return 'Ilocos Norte';
    }

    return labels[code] ?? _humanize(code);
  }

  static String descriptionFor(String code) {
    return switch (code) {
      northernCoast => 'Wind, dunes, and the open coastal edge.',
      centralUrbanHeritage =>
        'Old churches, public squares, and living history.',
      southernHeritageCoast => 'Heritage towns meeting the southern shoreline.',
      easternAgriHighland => 'Farms, forests, and highland roads.',
      _ => 'Verified places across Ilocos Norte.',
    };
  }

  static String _humanize(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class Lgu {
  const Lgu({
    required this.lguCode,
    required this.name,
    required this.lguType,
    required this.tourismCluster,
    this.centerLatitude,
    this.centerLongitude,
    required this.terrainType,
    required this.isMajorHub,
    required this.baselineDispersalBonus,
  });

  final String lguCode;
  final String name;
  final String lguType;
  final String tourismCluster;
  final double? centerLatitude;
  final double? centerLongitude;
  final String terrainType;
  final bool isMajorHub;
  final double baselineDispersalBonus;

  bool get isCity => lguType == 'component_city' || lguType == 'city';

  String get clusterLabel => TourismClusterInfo.labelFor(tourismCluster);

  String get typeLabel => isCity ? 'City' : 'Municipality';

  factory Lgu.fromJson(Map<String, dynamic> json, {required String cluster}) {
    final coordinates = json['coordinates'];

    return Lgu(
      lguCode: jsonString(json['lguCode'] ?? json['code']),
      name: jsonString(json['name']),
      lguType: jsonString(
        json['lguType'] ?? json['type'],
        fallback: 'municipality',
      ),
      tourismCluster: jsonString(
        json['tourismCluster'] ?? json['cluster'],
        fallback: cluster,
      ),
      centerLatitude: jsonDouble(
        json['centerLatitude'] ??
            (coordinates is Map<String, dynamic>
                ? coordinates['latitude']
                : null),
      ),
      centerLongitude: jsonDouble(
        json['centerLongitude'] ??
            (coordinates is Map<String, dynamic>
                ? coordinates['longitude']
                : null),
      ),
      terrainType: jsonString(
        json['terrainType'] ?? json['terrain_type'],
        fallback: 'rolling_inland',
      ),
      isMajorHub: jsonBool(json['isMajorHub'] ?? json['is_major_hub']),
      baselineDispersalBonus:
          jsonDouble(
            json['baselineDispersalBonus'] ?? json['baseline_dispersal_bonus'],
          ) ??
          0,
    );
  }
}

class LguCluster {
  const LguCluster({
    required this.cluster,
    required this.label,
    required this.lgus,
  });

  final String cluster;
  final String label;
  final List<Lgu> lgus;

  int get total => lgus.length;

  factory LguCluster.fromJson(Map<String, dynamic> json) {
    final cluster = jsonString(json['cluster']);
    final rawLgus = json['lgus'];

    return LguCluster(
      cluster: cluster,
      label: TourismClusterInfo.labelFor(cluster),
      lgus: rawLgus is List
          ? rawLgus
                .whereType<Map<String, dynamic>>()
                .map((item) => Lgu.fromJson(item, cluster: cluster))
                .toList(growable: false)
          : const [],
    );
  }
}

class LguDirectory {
  const LguDirectory({required this.clusters});

  final List<LguCluster> clusters;

  List<Lgu> get lgus =>
      clusters.expand((cluster) => cluster.lgus).toList(growable: false);

  int get totalLgus =>
      clusters.fold(0, (total, cluster) => total + cluster.total);

  List<LguCluster> get orderedClusters {
    final byCode = {for (final cluster in clusters) cluster.cluster: cluster};

    return [
      for (final code in TourismClusterInfo.orderedCodes)
        if (byCode[code] != null) byCode[code]!,
      for (final cluster in clusters)
        if (!TourismClusterInfo.orderedCodes.contains(cluster.cluster)) cluster,
    ];
  }

  Lgu? lguByCode(String? code) {
    if (code == null) {
      return null;
    }

    for (final cluster in clusters) {
      for (final lgu in cluster.lgus) {
        if (lgu.lguCode == code) {
          return lgu;
        }
      }
    }

    return null;
  }

  factory LguDirectory.fromJson(List<dynamic> clustersJson) {
    return LguDirectory(
      clusters: clustersJson
          .whereType<Map<String, dynamic>>()
          .map(LguCluster.fromJson)
          .toList(growable: false),
    );
  }
}

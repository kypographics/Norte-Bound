enum TransportMode {
  motorcycle('motorcycle', 'Motorcycle'),
  privateCar('privateCar', 'Private car'),
  publicCommute('publicCommute', 'Public commute');

  const TransportMode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TransportMode fromApi(String? value) {
    return TransportMode.values.firstWhere(
      (mode) => mode.apiValue == value,
      orElse: () => TransportMode.motorcycle,
    );
  }
}

enum BudgetScope {
  perPerson('perPerson', 'Per person'),
  totalGroup('totalGroup', 'Total group');

  const BudgetScope(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static BudgetScope fromApi(String? value) {
    return BudgetScope.values.firstWhere(
      (scope) => scope.apiValue == value,
      orElse: () => BudgetScope.perPerson,
    );
  }
}

enum TravelPacing {
  relaxed('relaxed', 'Relaxed'),
  moderate('moderate', 'Moderate'),
  packed('packed', 'Packed');

  const TravelPacing(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TravelPacing fromApi(String? value) {
    return TravelPacing.values.firstWhere(
      (pace) => pace.apiValue == value,
      orElse: () => TravelPacing.moderate,
    );
  }
}

class TravelPreferences {
  const TravelPreferences({
    required this.defaultTransportMode,
    required this.defaultBudgetScope,
    required this.defaultGroupSize,
    required this.defaultPacing,
    this.favoriteTags = const [],
  });

  static const defaults = TravelPreferences(
    defaultTransportMode: TransportMode.motorcycle,
    defaultBudgetScope: BudgetScope.perPerson,
    defaultGroupSize: 1,
    defaultPacing: TravelPacing.moderate,
  );

  final TransportMode defaultTransportMode;
  final BudgetScope defaultBudgetScope;
  final int defaultGroupSize;
  final TravelPacing defaultPacing;
  final List<String> favoriteTags;

  factory TravelPreferences.fromJson(Map<String, dynamic> json) {
    final transportMode = json['defaultTransportMode'];
    final budgetScope = json['defaultBudgetScope'];
    final groupSize = json['defaultGroupSize'];
    final pacing = json['defaultPacing'];
    final tags = json['favoriteTags'];

    return TravelPreferences(
      defaultTransportMode: TransportMode.fromApi(
        transportMode is String ? transportMode : null,
      ),
      defaultBudgetScope: BudgetScope.fromApi(
        budgetScope is String ? budgetScope : null,
      ),
      defaultGroupSize: groupSize is num
          ? groupSize.toInt().clamp(1, 50)
          : defaults.defaultGroupSize,
      defaultPacing: TravelPacing.fromApi(pacing is String ? pacing : null),
      favoriteTags: tags is List
          ? List.unmodifiable(
              tags
                  .whereType<String>()
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty),
            )
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultTransportMode': defaultTransportMode.apiValue,
      'defaultBudgetScope': defaultBudgetScope.apiValue,
      'defaultGroupSize': defaultGroupSize,
      'defaultPacing': defaultPacing.apiValue,
      'favoriteTags': favoriteTags,
    };
  }

  TravelPreferences copyWith({
    TransportMode? defaultTransportMode,
    BudgetScope? defaultBudgetScope,
    int? defaultGroupSize,
    TravelPacing? defaultPacing,
    List<String>? favoriteTags,
  }) {
    return TravelPreferences(
      defaultTransportMode: defaultTransportMode ?? this.defaultTransportMode,
      defaultBudgetScope: defaultBudgetScope ?? this.defaultBudgetScope,
      defaultGroupSize: defaultGroupSize ?? this.defaultGroupSize,
      defaultPacing: defaultPacing ?? this.defaultPacing,
      favoriteTags: favoriteTags ?? this.favoriteTags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TravelPreferences) return false;

    if (defaultTransportMode != other.defaultTransportMode ||
        defaultBudgetScope != other.defaultBudgetScope ||
        defaultGroupSize != other.defaultGroupSize ||
        defaultPacing != other.defaultPacing ||
        favoriteTags.length != other.favoriteTags.length) {
      return false;
    }

    for (var index = 0; index < favoriteTags.length; index += 1) {
      if (favoriteTags[index] != other.favoriteTags[index]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      defaultTransportMode,
      defaultBudgetScope,
      defaultGroupSize,
      defaultPacing,
      Object.hashAll(favoriteTags),
    );
  }
}

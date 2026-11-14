import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/features/auth/domain/models/travel_preferences.dart';
import 'package:norte_bound/features/auth/domain/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('maps the API user payload', () {
      final user = User.fromJson({
        'id': 7,
        'email': 'traveler@example.com',
        'fullName': 'Maria Santos',
        'role': 'tourist',
        'createdAt': '2026-01-02T03:04:05.000Z',
        'updatedAt': '2026-01-03T04:05:06.000Z',
      });

      expect(user.id, 7);
      expect(user.email, 'traveler@example.com');
      expect(user.fullName, 'Maria Santos');
      expect(user.role, UserRole.tourist);
      expect(user.travelPreferences, isNull);
      expect(user.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(user.updatedAt, DateTime.utc(2026, 1, 3, 4, 5, 6));
    });

    test('maps baseline travel preferences', () {
      final user = User.fromJson({
        'id': 8,
        'email': 'traveler@example.com',
        'fullName': 'Maria Santos',
        'role': 'tourist',
        'travelPreferences': {
          'defaultTransportMode': 'privateCar',
          'defaultBudgetScope': 'totalGroup',
          'defaultGroupSize': 4,
          'defaultPacing': 'relaxed',
          'favoriteTags': ['beaches', 'heritage'],
        },
      });

      final preferences = user.travelPreferences;

      expect(preferences, isNotNull);
      expect(preferences!.defaultTransportMode, TransportMode.privateCar);
      expect(preferences.defaultBudgetScope, BudgetScope.totalGroup);
      expect(preferences.defaultGroupSize, 4);
      expect(preferences.defaultPacing, TravelPacing.relaxed);
      expect(preferences.favoriteTags, ['beaches', 'heritage']);
      expect(preferences.toJson()['defaultTransportMode'], 'privateCar');
    });

    test('maps admin users and ignores unknown roles', () {
      final admin = User.fromJson({
        'id': 1,
        'email': 'curator@example.com',
        'fullName': 'Curator',
        'role': 'admin',
      });
      final fallback = User.fromJson({
        'id': 2,
        'email': 'guest@example.com',
        'fullName': 'Guest',
        'role': 'unexpected',
      });

      expect(admin.role, UserRole.admin);
      expect(fallback.role, UserRole.tourist);
    });

    test('rejects incomplete payloads', () {
      expect(
        () => User.fromJson({'id': 1, 'email': 'missing@example.com'}),
        throwsFormatException,
      );
    });
  });
}

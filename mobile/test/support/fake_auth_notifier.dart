import 'package:norte_bound/features/auth/domain/models/travel_preferences.dart';
import 'package:norte_bound/features/auth/domain/models/user.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';

class FixedAuthNotifier extends AuthNotifier {
  FixedAuthNotifier(this.user);

  final User? user;

  @override
  Future<User?> build() async => user;
}

const testTravelPreferences = TravelPreferences(
  defaultTransportMode: TransportMode.privateCar,
  defaultBudgetScope: BudgetScope.totalGroup,
  defaultGroupSize: 3,
  defaultPacing: TravelPacing.relaxed,
  favoriteTags: ['beaches', 'heritage'],
);

const testTourist = User(
  id: 11,
  email: 'traveler@example.com',
  fullName: 'Maria Santos',
  role: UserRole.tourist,
  travelPreferences: testTravelPreferences,
  createdAt: null,
);

const testAdmin = User(
  id: 12,
  email: 'curator@example.com',
  fullName: 'Norte Bound Curator',
  role: UserRole.admin,
);

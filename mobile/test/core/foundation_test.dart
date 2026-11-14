import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/core/constants/api_endpoints.dart';
import 'package:norte_bound/core/constants/app_config.dart';
import 'package:norte_bound/core/router/app_routes.dart';

void main() {
  test('API endpoints match the versioned backend contract', () {
    expect(ApiEndpoints.health, '/health');
    expect(ApiEndpoints.login, '/auth/login');
    expect(ApiEndpoints.destinations, '/destinations');
    expect(
      ApiEndpoints.destinationDetail('saud-beach'),
      '/destinations/saud-beach',
    );
    expect(
      ApiEndpoints.adminDestinationStatus(12),
      '/admin/destinations/12/status',
    );
  });

  test('API base URL includes the versioned prefix', () {
    expect(AppConfig.apiBaseUrl, endsWith('/api/v1'));
  });

  test('splash route is the application entry point', () {
    expect(AppRoutes.splash, '/');
    expect(AppRoutes.discovery, '/discovery');
    expect(AppRoutes.login, '/login');
    expect(AppRoutes.register, '/register');
  });
}

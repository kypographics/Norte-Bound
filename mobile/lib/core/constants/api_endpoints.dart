abstract final class ApiEndpoints {
  static const health = '/health';

  static const register = '/auth/register';
  static const login = '/auth/login';
  static const me = '/auth/me';

  static const destinations = '/destinations';
  static const lgus = '/destinations/lgus';
  static const taxonomy = '/destinations/taxonomy';

  static String destinationDetail(String slug) => '/destinations/$slug';

  static const adminDestinations = '/admin/destinations';

  static String adminDestination(int id) => '/admin/destinations/$id';

  static String adminDestinationStatus(int id) =>
      '/admin/destinations/$id/status';
}

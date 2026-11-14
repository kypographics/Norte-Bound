import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/models/auth_session.dart';
import '../domain/models/travel_preferences.dart';
import '../domain/models/user.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login(String email, String password) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      ),
    );

    return _parseSession(response.data);
  }

  Future<AuthSession> register(
    String fullName,
    String email,
    String password,
    UserRole role, {
    String? adminInviteCode,
  }) async {
    final data = <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role.apiValue,
    };

    if (adminInviteCode != null && adminInviteCode.isNotEmpty) {
      data['adminInviteCode'] = adminInviteCode;
    }

    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(ApiEndpoints.register, data: data),
    );

    return _parseSession(response.data);
  }

  Future<User> getMe(String token) async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      ),
    );

    return _parseUser(response.data);
  }

  Future<User> updateProfile({
    String? fullName,
    TravelPreferences? travelPreferences,
  }) async {
    final data = <String, dynamic>{};

    if (fullName != null) {
      data['fullName'] = fullName;
    }

    if (travelPreferences != null) {
      data['travelPreferences'] = travelPreferences.toJson();
    }

    final response = await _request(
      () => _dio.put<Map<String, dynamic>>(ApiEndpoints.profile, data: data),
    );

    return _parseUser(response.data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _request(
      () => _dio.put<Map<String, dynamic>>(
        ApiEndpoints.password,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  AuthSession _parseSession(Map<String, dynamic>? data) {
    final user = _parseUser(data);
    final token = data?['token'];

    if (token is! String || token.isEmpty) {
      throw const ApiException(
        message: 'The authentication response did not include a valid token.',
      );
    }

    return AuthSession(user: user, token: token);
  }

  User _parseUser(Map<String, dynamic>? data) {
    final userJson = data?['user'];

    if (userJson is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The authentication response did not include a valid user.',
      );
    }

    try {
      return User.fromJson(userJson);
    } on FormatException {
      throw const ApiException(
        message: 'The authentication response contained an invalid user.',
      );
    }
  }
}

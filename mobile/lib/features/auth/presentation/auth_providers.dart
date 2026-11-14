import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/storage/auth_token_store.dart';
import '../data/auth_repository.dart';
import '../domain/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  AuthTokenStore get _tokenStore => ref.read(authTokenStoreProvider);

  @override
  Future<User?> build() async {
    AuthTokenStore tokenStore;

    try {
      tokenStore = _tokenStore;
    } catch (_) {
      return null;
    }

    String? token;

    try {
      token = await tokenStore.readAccessToken();
    } catch (_) {
      return null;
    }

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final user = await _repository.getMe(token);
      await tokenStore.saveSession(
        accessToken: token,
        role: user.role.apiValue,
      );
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await tokenStore.clearSession();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User> login({required String email, required String password}) async {
    final session = await _repository.login(email, password);

    await _tokenStore.saveSession(
      accessToken: session.token,
      role: session.user.role.apiValue,
    );

    state = AsyncData(session.user);
    return session.user;
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final session = await _repository.register(fullName, email, password, role);

    await _tokenStore.saveSession(
      accessToken: session.token,
      role: session.user.role.apiValue,
    );

    state = AsyncData(session.user);
    return session.user;
  }

  Future<void> logout() async {
    await _tokenStore.clearSession();
    state = const AsyncData(null);
  }
}

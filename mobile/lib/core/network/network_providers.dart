import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../constants/app_config.dart';
import '../storage/auth_token_store.dart';
import 'auth_interceptor.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => AuthTokenStore(ref.watch(secureStorageProvider)),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      ref.watch(authTokenStoreProvider),
      onUnauthorized: () {
        unawaited(ref.read(authNotifierProvider.notifier).logout());
      },
    ),
  );

  ref.onDispose(() => dio.close(force: true));

  return dio;
});

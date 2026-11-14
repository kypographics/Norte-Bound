import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/auth_token_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore, {this.onUnauthorized});

  final AuthTokenStore _tokenStore;
  final VoidCallback? onUnauthorized;

  static const _tokenAttachedKey = 'auth.token.attached';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.readAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_tokenAttachedKey] = true;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final tokenWasAttached =
        err.requestOptions.extra[_tokenAttachedKey] == true;

    if (err.response?.statusCode == 401 && tokenWasAttached) {
      unawaited(_tokenStore.clearSession());
      onUnauthorized?.call();
    }

    handler.next(err);
  }
}

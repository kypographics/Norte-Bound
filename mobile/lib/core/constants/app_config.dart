import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const appName = 'NORTE BOUND';
  static const appTagline = 'Find your north.';
  static const apiVersion = 'v1';
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
  static const sendTimeout = Duration(seconds: 20);

  static const _apiBaseUrlOverride = String.fromEnvironment('http://10.0.2.2:5000/api/v1');

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/$apiVersion';
    }

    return 'http://localhost:5000/api/$apiVersion';
  }
}

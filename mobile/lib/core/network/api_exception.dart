import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Object? details;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final responseData = response?.data;

    String? code;
    String? message;
    Object? details;

    if (responseData is Map<String, dynamic>) {
      details = responseData['error'];

      if (details is Map<String, dynamic>) {
        code = details['code'] as String?;
        message = details['message'] as String?;
      }
    }

    message ??= switch (error.type) {
      DioExceptionType.connectionTimeout => 'The connection timed out.',
      DioExceptionType.sendTimeout => 'The request took too long to send.',
      DioExceptionType.receiveTimeout => 'The server took too long to respond.',
      DioExceptionType.connectionError =>
        'Unable to reach NORTE BOUND. Check your connection.',
      DioExceptionType.cancel => 'The request was cancelled.',
      _ => 'Something went wrong. Please try again.',
    };

    return ApiException(
      message: message,
      statusCode: response?.statusCode,
      code: code,
      details: details,
    );
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' [$statusCode]';
    final errorCode = code == null ? '' : ' $code';
    return 'ApiException$status$errorCode: $message';
  }
}

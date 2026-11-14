import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/destination_filter.dart';
import '../domain/destination_summary.dart';
import '../domain/lgu.dart';
import '../domain/taxonomy.dart';

class DestinationRepository {
  DestinationRepository(this._dio);

  final Dio _dio;

  Future<LguDirectory> fetchLgus() async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.lgus),
    );
    final data = response.data?['data'];

    if (data is! List) {
      throw const ApiException(
        message: 'The LGU response did not include a valid directory.',
      );
    }

    try {
      return LguDirectory.fromJson(data);
    } on FormatException {
      throw const ApiException(
        message: 'The LGU directory contained invalid records.',
      );
    }
  }

  Future<DestinationTaxonomy> fetchTaxonomy() async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.taxonomy),
    );
    final data = response.data?['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The taxonomy response did not include valid categories.',
      );
    }

    try {
      return DestinationTaxonomy.fromJson(data);
    } on FormatException {
      throw const ApiException(
        message: 'The destination taxonomy contained invalid records.',
      );
    }
  }

  Future<DestinationPage> fetchDestinations(DestinationFilter filter) async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.destinations,
        queryParameters: filter.toQueryParameters(),
      ),
    );
    final data = response.data;

    if (data == null) {
      throw const ApiException(message: 'The destination response was empty.');
    }

    try {
      return DestinationPage.fromJson(data);
    } on FormatException {
      throw const ApiException(
        message: 'The destination response contained invalid records.',
      );
    }
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
}

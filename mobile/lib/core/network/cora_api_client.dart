import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coraApiClientProvider = Provider<CoraApiClient>((ref) {
  return CoraApiClient();
});

class ProblemDetailsException implements Exception {
  final String type;
  final String title;
  final int status;
  final String detail;
  final String code;
  final String? instance;

  ProblemDetailsException({
    required this.type,
    required this.title,
    required this.status,
    required this.detail,
    required this.code,
    this.instance,
  });

  factory ProblemDetailsException.fromJson(Map<String, dynamic> json) {
    return ProblemDetailsException(
      type: json['type'] as String? ?? 'urn:cora:error:unknown',
      title: json['title'] as String? ?? 'Unknown Error',
      status: json['status'] as int? ?? 500,
      detail: json['detail'] as String? ?? 'An unexpected error occurred.',
      code: json['code'] as String? ?? 'unknown',
      instance: json['instance'] as String?,
    );
  }

  @override
  String toString() =>
      'ProblemDetailsException($code): $detail (status: $status)';
}

class CoraApiClient {
  final Dio dio;

  CoraApiClient({String baseUrl = 'http://localhost:8000/api/v1'})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          if (error.response?.data is Map<String, dynamic>) {
            final data = error.response!.data as Map<String, dynamic>;
            if (data.containsKey('type') && data.containsKey('status')) {
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  error: ProblemDetailsException.fromJson(data),
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}

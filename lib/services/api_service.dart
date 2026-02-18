import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../models/api_error.dart';
import '../models/api_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  String? _authToken;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://192.168.137.1:3000/hr',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // Add pretty logger untuk debugging (hanya di dev)
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// Setup auth token (call setelah login)
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear auth token (call setelah logout)
  void clearAuthToken() {
    _authToken = null;
  }

  /// Request interceptor - add auth header
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token jika tersedia
    if (_authToken != null) {
      options.headers['Authorization'] = 'Bearer $_authToken';
    }

    // Add common headers
    options.headers['Accept'] = 'application/json';

    debugPrint('🔵 [API] ${options.method} ${options.path}');
    return handler.next(options);
  }

  /// Response interceptor
  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    debugPrint('🟢 [API] ${response.statusCode} ${response.requestOptions.path}');
    return handler.next(response);
  }

  /// Error interceptor - handle errors with retry logic
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    debugPrint('🔴 [API] Error: ${error.message}');

    // Handle 401 Unauthorized (token expired) - bisa tambah refresh token logic di sini
    if (error.response?.statusCode == 401) {
      debugPrint('🟡 [API] Unauthorized - token mungkin expired');
      // TODO: Implement token refresh logic
      // await _refreshToken();
    }

    return handler.next(error);
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        dataParser,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiError(
        message: 'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        dataParser,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiError(
        message: 'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        dataParser,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiError(
        message: 'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        dataParser,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiError(
        message: 'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        dataParser,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiError(
        message: 'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// Handle DioException dan convert ke ApiError
  ApiError _handleDioException(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        // Error dari server
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic>) {
          message = responseData['message'] ?? 'Bad response from server';
        } else {
          message = 'Bad response: ${error.response?.statusCode}';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          message = 'No internet connection';
        } else {
          message = 'Unknown error occurred';
        }
        break;
      default:
        message = error.message ?? 'An error occurred';
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      originalError: error,
    );
  }
}

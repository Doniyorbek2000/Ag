import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to the ADM AI backend (see /backend). Configure [baseUrl] to point
/// at your deployed server — defaults to a local dev server address.
class ApiClient {
  static const String defaultBaseUrl = 'http://10.0.2.2:4000/api';

  final Dio _dio;
  String? _token;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: defaultBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
    ));
    _restoreToken();
  }

  Future<void> _restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('backend_token');
  }

  void setBaseUrl(String url) => _dio.options.baseUrl = url;

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('backend_token');
    } else {
      await prefs.setString('backend_token', token);
    }
  }

  String? get token => _token;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    final msg = (data is Map && data['error'] is String)
        ? data['error'] as String
        : 'Server bilan bog\'lanishda xato yuz berdi';
    return ApiException(msg, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}

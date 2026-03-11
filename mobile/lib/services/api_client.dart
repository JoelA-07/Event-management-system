import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isConfigured = false;

  Dio get dio {
    if (!_isConfigured) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await _storage.read(key: "jwt_token");
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
        ),
      );
      _isConfigured = true;
    }
    return _dio;
  }
}

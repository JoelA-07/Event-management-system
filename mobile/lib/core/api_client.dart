import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio = Dio();
  final Dio _refreshDio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isConfigured = false;
  Future<String?>? _refreshFuture;

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
          onError: (error, handler) async {
            final statusCode = error.response?.statusCode;
            final options = error.requestOptions;
            if (statusCode == 401 && options.extra['retry'] != true) {
              final token = await _refreshAccessToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
                options.extra['retry'] = true;
                try {
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(error);
                }
              }
            }
            return handler.next(error);
          },
        ),
      );
      _isConfigured = true;
    }
    return _dio;
  }

  Future<String?> _refreshAccessToken() async {
    _refreshFuture ??= () async {
      final refresh = await _storage.read(key: "refresh_token");
      if (refresh == null || refresh.isEmpty) {
        return null;
      }
      try {
        final res = await _refreshDio.post(
          AppConstants.refreshUrl,
          data: {"refreshToken": refresh},
        );
        if (res.statusCode == 200) {
          final token = res.data['token'] as String?;
          final newRefresh = res.data['refreshToken'] as String?;
          if (token != null) {
            await _storage.write(key: "jwt_token", value: token);
          }
          if (newRefresh != null) {
            await _storage.write(key: "refresh_token", value: newRefresh);
          }
          return token;
        }
      } catch (_) {}
      return null;
    }();

    final result = await _refreshFuture;
    _refreshFuture = null;
    return result;
  }
}

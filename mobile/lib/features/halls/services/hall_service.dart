import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/features/halls/models/hall_model.dart';
import 'package:mobile/core/api_client.dart';

class HallService {
  final Dio _dio = ApiClient().dio;

  Future<Response?> addHall(dynamic data) async {
    try {
      return await _dio.post(AppConstants.addHallUrl, data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<List<HallModel>> fetchHalls({String? eventType}) async {
    try {
      final response = await _dio.get(
        AppConstants.allHallsUrl,
        queryParameters: eventType == null ? null : {"eventType": eventType},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => HallModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load halls");
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchHallsPage({
    int page = 1,
    int limit = 20,
    String? eventType,
  }) async {
    try {
      final params = {
        "page": page,
        "limit": limit,
        if (eventType != null) "eventType": eventType,
      };
      final response = await _dio.get(AppConstants.allHallsUrl, queryParameters: params);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map && body['data'] is List && body['meta'] is Map) {
          final list = List<dynamic>.from(body['data']);
          return {
            "items": list.map((json) => HallModel.fromJson(json)).toList(),
            "meta": Map<String, dynamic>.from(body['meta']),
          };
        }
        if (body is List) {
          return {
            "items": body.map((json) => HallModel.fromJson(json)).toList(),
            "meta": {"page": 1, "limit": body.length, "total": body.length, "totalPages": 1},
          };
        }
      }
    } catch (_) {}
    return {
      "items": <HallModel>[],
      "meta": {"page": page, "limit": limit, "total": 0, "totalPages": 1},
    };
  }
}

import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api_client.dart';

class ReviewService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> fetchHallReviews(int hallId) async {
    try {
      final response = await _dio.get("${AppConstants.baseUrl}/reviews/hall/$hallId");
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> fetchServiceReviews(int serviceId) async {
    try {
      final response = await _dio.get("${AppConstants.baseUrl}/reviews/service/$serviceId");
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }

  Future<Response?> createReview({
    int? hallId,
    int? serviceId,
    required int rating,
    String? comment,
  }) async {
    try {
      return await _dio.post(
        "${AppConstants.baseUrl}/reviews",
        data: {
          "hallId": hallId,
          "serviceId": serviceId,
          "rating": rating,
          "comment": comment ?? '',
        },
      );
    } on DioException catch (e) {
      return e.response;
    }
  }
}

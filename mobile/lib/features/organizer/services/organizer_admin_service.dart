import 'package:dio/dio.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/constants.dart';

class OrganizerAdminService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> fetchApprovals({int page = 1, int limit = 20}) async {
    final res = await _dio.get(
      "${AppConstants.baseUrl}/organizer/approvals",
      queryParameters: {"page": page, "limit": limit},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Response<dynamic>> updateHallApproval(int id, String status, {String? reason}) {
    return _dio.patch(
      "${AppConstants.baseUrl}/organizer/approvals/halls/$id",
      data: {"status": status, if (reason != null) "reason": reason},
    );
  }

  Future<Response<dynamic>> updateServiceApproval(int id, String status, {String? reason}) {
    return _dio.patch(
      "${AppConstants.baseUrl}/organizer/approvals/services/$id",
      data: {"status": status, if (reason != null) "reason": reason},
    );
  }

  Future<Map<String, dynamic>> fetchPayouts({int page = 1, int limit = 20}) async {
    final res = await _dio.get(
      "${AppConstants.baseUrl}/organizer/payouts",
      queryParameters: {"page": page, "limit": limit},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> fetchDisputes({String? status, int page = 1, int limit = 20}) async {
    final params = {"page": page, "limit": limit, if (status != null) "status": status};
    final res = await _dio.get(
      "${AppConstants.baseUrl}/disputes",
      queryParameters: params,
    );
    if (res.data is Map && res.data['data'] is List) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {
      "data": List<dynamic>.from(res.data as List),
      "meta": {"page": 1, "limit": (res.data as List).length, "total": (res.data as List).length, "totalPages": 1},
    };
  }

  Future<Response<dynamic>> updateDispute(int id, String status, {String? resolutionNotes}) {
    return _dio.patch(
      "${AppConstants.baseUrl}/disputes/$id",
      data: {"status": status, if (resolutionNotes != null) "resolutionNotes": resolutionNotes},
    );
  }

  Future<Map<String, dynamic>> fetchReviewReports({String status = 'open', int page = 1, int limit = 20}) async {
    final res = await _dio.get(
      "${AppConstants.baseUrl}/reviews/reports",
      queryParameters: {"status": status, "page": page, "limit": limit},
    );
    if (res.data is Map && res.data['data'] is List) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {
      "data": List<dynamic>.from(res.data as List),
      "meta": {"page": 1, "limit": (res.data as List).length, "total": (res.data as List).length, "totalPages": 1},
    };
  }

  Future<Response<dynamic>> resolveReviewReport(int id) {
    return _dio.patch("${AppConstants.baseUrl}/reviews/reports/$id/resolve");
  }

  Future<Response<dynamic>> moderateReview(int reviewId, String status) {
    return _dio.patch(
      "${AppConstants.baseUrl}/reviews/$reviewId/moderate",
      data: {"status": status},
    );
  }

  Future<Map<String, dynamic>?> fetchReviewDetails(int reviewId, {int? hallId, int? serviceId}) async {
    try {
      if (hallId != null) {
        final res = await _dio.get("${AppConstants.baseUrl}/reviews/hall/$hallId");
        final list = List<dynamic>.from(res.data as List);
        return list.cast<Map<String, dynamic>>().firstWhere((r) => r['id'] == reviewId, orElse: () => {});
      }
      if (serviceId != null) {
        final res = await _dio.get("${AppConstants.baseUrl}/reviews/service/$serviceId");
        final list = List<dynamic>.from(res.data as List);
        return list.cast<Map<String, dynamic>>().firstWhere((r) => r['id'] == reviewId, orElse: () => {});
      }
    } catch (_) {}
    return null;
  }
}

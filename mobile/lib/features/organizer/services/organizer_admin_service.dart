import 'package:dio/dio.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/constants.dart';

class OrganizerAdminService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> fetchApprovals() async {
    final res = await _dio.get("${AppConstants.baseUrl}/organizer/approvals");
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

  Future<Map<String, dynamic>> fetchPayouts() async {
    final res = await _dio.get("${AppConstants.baseUrl}/organizer/payouts");
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<dynamic>> fetchDisputes({String? status}) async {
    final res = await _dio.get(
      "${AppConstants.baseUrl}/disputes",
      queryParameters: status == null ? null : {"status": status},
    );
    return List<dynamic>.from(res.data as List);
  }

  Future<Response<dynamic>> updateDispute(int id, String status, {String? resolutionNotes}) {
    return _dio.patch(
      "${AppConstants.baseUrl}/disputes/$id",
      data: {"status": status, if (resolutionNotes != null) "resolutionNotes": resolutionNotes},
    );
  }

  Future<List<dynamic>> fetchReviewReports({String status = 'open'}) async {
    final res = await _dio.get(
      "${AppConstants.baseUrl}/reviews/reports",
      queryParameters: {"status": status},
    );
    return List<dynamic>.from(res.data as List);
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

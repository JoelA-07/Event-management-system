import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api_client.dart';

class VendorStatsService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> fetchStats(String vendorId) async {
    try {
      final response = await _dio.get("${AppConstants.vendorsUrl}/stats/$vendorId");
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        "totalEarnings": 0,
        "activeServices": 0,
        "activeMenus": 0,
        "sampleRequests": 0,
      };
    }
  }
}

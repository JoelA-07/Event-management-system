import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api_client.dart';

class OrganizerService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> fetchOverview() async {
    try {
      final response = await _dio.get("${AppConstants.baseUrl}/organizer/overview");
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        "totals": {
          "totalHallBookings": 0,
          "totalVendorBookings": 0,
          "totalVendors": 0,
          "totalHalls": 0,
          "totalUsers": 0,
        },
        "recentHallBookings": [],
        "recentVendorBookings": [],
      };
    }
  }

  Future<Map<String, dynamic>> fetchAnalytics({int? year}) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/organizer/analytics",
        queryParameters: year == null ? null : {"year": year},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        "year": DateTime.now().year,
        "totals": {"hallRevenue": 0, "vendorRevenue": 0, "totalRevenue": 0},
        "monthly": List.generate(12, (i) => {
              "month": i + 1,
              "hallRevenue": 0,
              "vendorRevenue": 0,
              "totalRevenue": 0,
            }),
      };
    }
  }
}

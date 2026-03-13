import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api_client.dart';

class PackageService {
  final Dio _dio = ApiClient().dio;

  // 1. Fetch EVERYTHING (Halls + Vendor Services) so Organizer can pick
  Future<Map<String, List<dynamic>>> fetchAllSelectables() async {
    try {
      final hallRes = await _dio.get("${AppConstants.baseUrl}/halls/all");
      final vendorRes = await _dio.get("${AppConstants.vendorsUrl}/all");
      
      return {
        "halls": hallRes.data,
        "vendors": vendorRes.data,
      };
    } catch (e) {
      return {"halls": [], "vendors": []};
    }
  }

  // 2. Save the new package
  Future<Response?> createPackage(Map<String, dynamic> data) async {
    try {
      return await _dio.post("${AppConstants.baseUrl}/packages/add", data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<List<dynamic>> fetchPackages({String? eventType}) async {
    try {
      final response = await _dio.get(
        AppConstants.allPackagesUrl,
        queryParameters: eventType == null ? null : {"eventType": eventType},
      );
      return List<dynamic>.from(response.data);
    } catch (e) {
      return [];
    }
  }
}

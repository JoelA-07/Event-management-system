import 'package:dio/dio.dart';
import '../utils/constants.dart';

class PackageService {
  final Dio _dio = Dio();

  // 1. Fetch EVERYTHING (Halls + Vendor Services) so Organizer can pick
  Future<Map<String, List<dynamic>>> fetchAllSelectables() async {
    try {
      final hallRes = await _dio.get("${AppConstants.baseUrl}/halls/all");
      // Note: You'll need to add endpoints for all photographers/caterers in backend
      final vendorRes = await _dio.get("${AppConstants.baseUrl}/vendors/all"); 
      
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
}
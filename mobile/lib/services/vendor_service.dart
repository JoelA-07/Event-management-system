import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../models/vendor_model.dart';

class VendorService {
  final Dio _dio = Dio();

  Future<List<VendorModel>> fetchServices(String category) async {
    try {
      final response = await _dio.get("${AppConstants.vendorsUrl}/$category");
      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((json) => VendorModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<VendorModel>> fetchEventRecommendations(String eventType) async {
    try {
      final response = await _dio.get("${AppConstants.vendorsUrl}/event/$eventType");
      if (response.statusCode == 200) {
        final data = List<dynamic>.from(response.data);
        return data.map((json) => VendorModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<VendorModel>> fetchMyServices(String vendorId) async {
    try {
      final response = await _dio.get("${AppConstants.vendorsUrl}/my-services/$vendorId");
      if (response.statusCode == 200) {
        final data = List<dynamic>.from(response.data);
        return data.map((json) => VendorModel.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Response?> addService(Map<String, dynamic> data) async {
    try {
      return await _dio.post("${AppConstants.vendorsUrl}/add", data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> deleteService(int id) async {
    try {
      return await _dio.delete("${AppConstants.vendorsUrl}/delete/$id");
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<List<dynamic>> fetchMyMenus(String vendorId) async {
    try {
      final response = await _dio.get("${AppConstants.vendorsUrl}/menus/$vendorId");
      if (response.statusCode == 200) {
        return List<dynamic>.from(response.data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Response?> addMenu(Map<String, dynamic> data) async {
    try {
      return await _dio.post("${AppConstants.vendorsUrl}/add-menu", data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> deleteMenu(int id) async {
    try {
      return await _dio.delete("${AppConstants.vendorsUrl}/menu/$id");
    } on DioException catch (e) {
      return e.response;
    }
  }
}

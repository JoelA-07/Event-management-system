import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/core/api_client.dart';

class VendorService {
  final Dio _dio = ApiClient().dio;

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

  Future<Response?> addServiceWithImage(FormData data) async {
    try {
      return await _dio.post("${AppConstants.vendorsUrl}/add-with-image", data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> updateServiceWithImage(int id, FormData data) async {
    try {
      return await _dio.put("${AppConstants.vendorsUrl}/$id", data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> uploadServiceImages(int id, List<XFile> files) async {
    try {
      final multipartFiles = await Future.wait(
        files.map(
          (file) async => kIsWeb
              ? MultipartFile.fromBytes(
                  await file.readAsBytes(),
                  filename: file.name,
                )
              : await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split(RegExp(r'[\\/]')).last,
                ),
        ),
      );
      final data = FormData.fromMap({
        "images": multipartFiles,
      });
      return await _dio.post("${AppConstants.vendorsUrl}/$id/images", data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> deleteServiceImage(int id, String url) async {
    try {
      return await _dio.delete(
        "${AppConstants.vendorsUrl}/$id/images",
        data: {"url": url},
      );
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

  Future<List<dynamic>> fetchMenusPublic(String vendorId) async {
    try {
      final response = await _dio.get("${AppConstants.vendorsUrl}/menus-public/$vendorId");
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

  Future<Response?> addMenuWithImage(FormData data) async {
    try {
      return await _dio.post("${AppConstants.vendorsUrl}/add-menu-with-image", data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> updateMenuWithImage(int id, FormData data) async {
    try {
      return await _dio.put("${AppConstants.vendorsUrl}/menu/$id", data: data);
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

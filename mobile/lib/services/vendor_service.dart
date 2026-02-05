import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../models/vendor_model.dart';

class VendorService {
  final Dio _dio = Dio();

  Future<List<VendorModel>> fetchServices(String category) async {
    try {
      final response = await _dio.get("${AppConstants.baseUrl}/vendors/$category");
      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((json) => VendorModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
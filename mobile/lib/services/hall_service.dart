import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../models/hall_model.dart';
import 'api_client.dart';

class HallService {
  final Dio _dio = ApiClient().dio;


  // Inside HallService class
Future<Response?> addHall(dynamic data) async {
  try {
    return await _dio.post(AppConstants.addHallUrl, data: data);
  } on DioException catch (e) {
    return e.response;
  }
}

  // Fetch all halls from the backend
  Future<List<HallModel>> fetchHalls({String? eventType}) async {
    try {
      final response = await _dio.get(
        AppConstants.allHallsUrl,
        queryParameters: eventType == null ? null : {"eventType": eventType},
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => HallModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load halls");
      }
    } catch (e) {
      print("Error fetching halls: $e");
      return [];
    }
  }
}

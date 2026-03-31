import 'package:dio/dio.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/constants.dart';

class OrganizerNotificationService {
  final Dio _dio = ApiClient().dio;

  Future<String?> sendBroadcast({
    required String title,
    required String body,
    String? type,
  }) async {
    try {
      final response = await _dio.post(
        "${AppConstants.baseUrl}/notifications/broadcast",
        data: {
          'title': title,
          'body': body,
          'data': type != null && type.isNotEmpty ? {'type': type} : {},
        },
      );
      return response.data?['message']?.toString() ?? 'Broadcast sent';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Failed to send broadcast';
    }
  }

  Future<String?> sendToEmail({
    required String email,
    required String title,
    required String body,
    String? type,
  }) async {
    try {
      final response = await _dio.post(
        "${AppConstants.baseUrl}/notifications/send",
        data: {
          'email': email,
          'title': title,
          'body': body,
          'data': type != null && type.isNotEmpty ? {'type': type} : {},
        },
      );
      return response.data?['message']?.toString() ?? 'Notification sent';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Failed to send notification';
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/users/search",
        queryParameters: {'query': query},
      );
      final data = response.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } on DioException {
      return [];
    }
    return [];
  }
}

import 'package:dio/dio.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/constants.dart';

class UserSettingsApiService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final response = await _dio.get(AppConstants.userMeUrl);
      return (response.data as Map).cast<String, dynamic>();
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await _dio.patch(
        AppConstants.userMeUrl,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
        },
      );
      return (response.data as Map).cast<String, dynamic>();
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSettings() async {
    try {
      final response = await _dio.get(AppConstants.userSettingsUrl);
      return (response.data as Map).cast<String, dynamic>();
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateSettings(Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch(
        AppConstants.userSettingsUrl,
        data: updates,
      );
      return (response.data as Map).cast<String, dynamic>();
    } on DioException {
      return null;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.userChangePasswordUrl,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return response.data?['message']?.toString();
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Failed to update password';
    }
  }
}

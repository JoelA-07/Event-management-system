import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/features/auth/models/user_model.dart';

class AuthService {
  // Dio is a powerful library for making HTTP requests (like Postman but in code)
  final Dio _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10), // Increase to 10 seconds
  receiveTimeout: const Duration(seconds: 10),
));
  
  // This is used to save the JWT token safely on the phone's memory
  final _storage = const FlutterSecureStorage();


  // 1. REGISTER FUNCTION
  Future<Response?> register(String name, String email, String password, String phone, String role) async {
        print("DEBUG: Inside AuthService.register function"); // Add this
    try {
      Response response = await _dio.post(
        AppConstants.registerUrl,
        data: {
          "name": name,
          "email": email,
          "password": password,
          "phone": phone,
          "role": role, // Make sure to send this!
        },
      );
      return response;
    } catch (e) {
       print("DEBUG: Dio Error inside Service: $e");
       return null;
    }
  }

  // 2. LOGIN FUNCTION
  Future<Response?> login(String email, String password) async {
    try {
      Response response = await _dio.post(
        AppConstants.loginUrl,
        data: {
          "email": email,
          "password": password,
        },
      );

      // If login is successful, your backend returns { token, user: {...} }
      // Inside the login function in auth_service.dart
// Inside the login function in auth_service.dart
if (response.statusCode == 200) {
  String token = response.data['token'];
  String role = response.data['user']['role'];
  String name = response.data['user']['name'];
  String id = response.data['user']['id'].toString(); // Get the ID from backend

  await _storage.write(key: "jwt_token", value: token);
  await _storage.write(key: "role", value: role);
  await _storage.write(key: "name", value: name);
  await _storage.write(key: "userId", value: id); // Save the User ID!
}
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  // 3. LOGOUT FUNCTION
  Future<void> logout() async {
    await _storage.delete(key: "jwt_token");
  }

  // 4. GET SAVED TOKEN (To check if user is already logged in)
  Future<String?> getToken() async {
    return await _storage.read(key: "jwt_token");
  }
}
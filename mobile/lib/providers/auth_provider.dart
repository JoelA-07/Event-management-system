import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // This handles the Login logic for the UI
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners(); // Tells the UI to show a loading spinner

    final response = await _authService.login(email, password);

    _isLoading = false;
    notifyListeners(); // Tells the UI to stop the loading spinner

    if (response?.statusCode == 200) {
      return null; // Success (No error message)
    } else {
      // Return the error message from your Node.js backend
      return response?.data['message'] ?? "Login failed";
    }
  }
}
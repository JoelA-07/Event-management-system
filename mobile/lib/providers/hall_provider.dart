import 'package:flutter/material.dart';
import '../models/hall_model.dart';
import '../services/hall_service.dart';

class HallProvider with ChangeNotifier {
  final HallService _hallService = HallService();

  List<HallModel> _halls = [];
  bool _isLoading = false;

  List<HallModel> get halls => _halls;
  bool get isLoading => _isLoading;

  Future<String?> addHall(dynamic hallData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // We will create this 'addHall' method in HallService next
      final response = await _hallService.addHall(hallData);
      
      if (response?.statusCode == 201) {
        await loadHalls(); // Refresh the list automatically
        return null; // Success
      } else {
        return "Failed to add hall";
      }
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHalls() async {
    _isLoading = true;
    notifyListeners();

    _halls = await _hallService.fetchHalls();

    _isLoading = false;
    notifyListeners();
  }
} 
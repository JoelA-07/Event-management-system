import 'package:flutter/material.dart';
import 'package:mobile/features/halls/models/hall_model.dart';
import 'package:mobile/features/halls/services/hall_service.dart';

class HallProvider with ChangeNotifier {
  final HallService _hallService = HallService();

  List<HallModel> _halls = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 1;
  int _limit = 20;
  bool _hasMore = true;
  String? _eventType;

  List<HallModel> get halls => _halls;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<String?> addHall(dynamic hallData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _hallService.addHall(hallData);

      if (response?.statusCode == 201) {
        await loadHalls();
        return null;
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

  Future<void> loadHalls({bool reset = true, String? eventType}) async {
    if (reset) {
      _isLoading = true;
      _page = 1;
      _hasMore = true;
      _eventType = eventType;
      notifyListeners();
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    final result = await _hallService.fetchHallsPage(
      page: _page,
      limit: _limit,
      eventType: _eventType,
    );

    final items = List<HallModel>.from(result['items'] as List);
    final meta = Map<String, dynamic>.from(result['meta'] as Map);
    final totalPages = (meta['totalPages'] ?? 1) as int;

    if (reset) {
      _halls = items;
    } else {
      _halls = [..._halls, ...items];
    }

    _page += 1;
    _hasMore = _page <= totalPages;

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    await loadHalls(reset: false);
  }
}

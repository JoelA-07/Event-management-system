import 'package:flutter/material.dart';
import 'package:mobile/features/bookings/services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _service = BookingService();
  
  List<String> _bookedDates = [];
  bool _isLoading = false;

  List<String> get bookedDates => _bookedDates;
  bool get isLoading => _isLoading;

  // Load dates to disable them in the calendar
  Future<void> loadBookedDates(int hallId) async {
    _isLoading = true;
    notifyListeners();
    _bookedDates = await _service.getBookedDates(hallId);
    _isLoading = false;
    notifyListeners();
  }

  // Handle the booking action
  Future<String?> bookHall(
    int hallId,
    int customerId,
    String date, {
    String slotType = 'full_day',
    String? startTime,
    String? endTime,
    String? slotLabel,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await _service.createBooking(
      hallId,
      customerId,
      date,
      slotType: slotType,
      startTime: startTime,
      endTime: endTime,
      slotLabel: slotLabel,
    );

    _isLoading = false;
    notifyListeners();

    if (res?.statusCode == 201) {
      return null; // Success
    } else {
      return res?.data['message'] ?? "Booking failed";
    }
  }

  Future<List<dynamic>> fetchBookedSlots(int hallId, String date) async {
    return _service.getBookedSlots(hallId, date);
  }
}

import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class BookingService {
  final Dio _dio = ApiClient().dio;

  // 1. Fetch dates that are already taken
  Future<List<String>> getBookedDates(int hallId) async {
    try {
      final response = await _dio.get("${AppConstants.bookedDatesUrl}/$hallId");
      if (response.statusCode == 200) {
        return List<String>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Send the booking request to the backend
  Future<Response?> createBooking(
    int hallId,
    int customerId,
    String date, {
    String slotType = 'full_day',
    String? startTime,
    String? endTime,
    String? slotLabel,
  }) async {
    try {
      return await _dio.post(
        AppConstants.createBookingUrl,
        data: {
          "hallId": hallId,
          "customerId": customerId,
          "bookingDate": date, // Format: YYYY-MM-DD
          "slotType": slotType,
          "startTime": startTime,
          "endTime": endTime,
          "slotLabel": slotLabel,
        },
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<List<dynamic>> getBookedSlots(int hallId, String date) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/bookings/booked-slots/$hallId",
        queryParameters: {"date": date},
      );
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }

Future<List<dynamic>> fetchUserBookings(int userId, String role) async {
    try {
      final response = await _dio.get("${AppConstants.baseUrl}/bookings/user/$userId/$role");
      return response.data;
    } catch (e) {
      return [];
    }
  }

}


import 'package:dio/dio.dart';
import '../utils/constants.dart';

class BookingService {
  final Dio _dio = Dio();

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
  Future<Response?> createBooking(int hallId, int customerId, String date) async {
    try {
      return await _dio.post(
        AppConstants.createBookingUrl,
        data: {
          "hallId": hallId,
          "customerId": customerId,
          "bookingDate": date, // Format: YYYY-MM-DD
        },
      );
    } on DioException catch (e) {
      return e.response;
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


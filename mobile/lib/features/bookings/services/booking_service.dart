import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api_client.dart';

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

  Future<Map<String, dynamic>> fetchUserBookingsPaged({
    required int userId,
    required String role,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/bookings/user/$userId/$role",
        queryParameters: {"page": page, "limit": limit},
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map && body['data'] is List && body['meta'] is Map) {
          return Map<String, dynamic>.from(body);
        }
        if (body is List) {
          return {
            "data": body,
            "meta": {"page": 1, "limit": body.length, "total": body.length, "totalPages": 1},
          };
        }
      }
    } catch (_) {}
    return {
      "data": <dynamic>[],
      "meta": {"page": page, "limit": limit, "total": 0, "totalPages": 1},
    };
  }

  Future<Response?> cancelBooking({
    required int bookingId,
    String? reason,
    double? refundAmount,
    String? refundMethod,
    bool? autoRefund,
  }) async {
    try {
      return await _dio.post(
        "${AppConstants.baseUrl}/bookings/$bookingId/cancel",
        data: {
          if (reason != null) "reason": reason,
          if (refundAmount != null) "refundAmount": refundAmount,
          if (refundMethod != null) "refundMethod": refundMethod,
          if (autoRefund != null) "autoRefund": autoRefund,
        },
      );
    } on DioException catch (e) {
      return e.response;
    }
  }
}

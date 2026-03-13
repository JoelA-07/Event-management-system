import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api_client.dart';

class VendorBookingService {
  final Dio _dio = ApiClient().dio;

  Future<Response?> createBooking({
    required int vendorId,
    required int serviceId,
    required int customerId,
    required String bookingDate,
    String? notes,
  }) async {
    try {
      return await _dio.post(
        "${AppConstants.baseUrl}/vendor-bookings/create",
        data: {
          "vendorId": vendorId,
          "serviceId": serviceId,
          "customerId": customerId,
          "bookingDate": bookingDate,
          "notes": notes,
        },
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<List<dynamic>> fetchVendorBookings(int vendorId) async {
    try {
      final response = await _dio.get("${AppConstants.baseUrl}/vendor-bookings/vendor/$vendorId");
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> fetchCustomerBookings(int customerId) async {
    try {
      final response = await _dio.get("${AppConstants.baseUrl}/vendor-bookings/customer/$customerId");
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }
}

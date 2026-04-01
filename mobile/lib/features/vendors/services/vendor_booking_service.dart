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
    String slotType = 'full_day',
    String? startTime,
    String? endTime,
    String? slotLabel,
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

  Future<List<dynamic>> fetchVendorBookedSlots({
    required int vendorId,
    required int serviceId,
    required String date,
  }) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/vendor-bookings/vendor/$vendorId/service/$serviceId/booked-slots",
        queryParameters: {"date": date},
      );
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> fetchVendorUnavailableSlots({
    required int vendorId,
    required int serviceId,
    required String date,
  }) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/vendor-bookings/vendor/$vendorId/service/$serviceId/unavailable-slots",
        queryParameters: {"date": date},
      );
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }

  Future<Response?> blockVendorSlot({
    required int vendorId,
    required int serviceId,
    required String date,
    String slotType = 'full_day',
    String? startTime,
    String? endTime,
    String? slotLabel,
    String? reason,
  }) async {
    try {
      return await _dio.post(
        "${AppConstants.baseUrl}/vendor-bookings/vendor/$vendorId/service/$serviceId/unavailable-slots",
        data: {
          "date": date,
          "slotType": slotType,
          "startTime": startTime,
          "endTime": endTime,
          "slotLabel": slotLabel,
          "reason": reason,
        },
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> unblockVendorSlot(int id) async {
    try {
      return await _dio.delete(
        "${AppConstants.baseUrl}/vendor-bookings/vendor/unavailable-slots/$id",
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      return await _dio.patch(
        "${AppConstants.baseUrl}/vendor-bookings/$bookingId/status",
        data: {"status": status},
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> cancelVendorBooking({
    required int bookingId,
    String? reason,
    double? refundAmount,
    String? refundMethod,
    bool? autoRefund,
  }) async {
    try {
      return await _dio.post(
        "${AppConstants.baseUrl}/vendor-bookings/$bookingId/cancel",
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

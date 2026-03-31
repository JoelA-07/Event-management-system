import 'package:dio/dio.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/constants.dart';

class PaymentService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>?> fetchSummary({
    required String bookingType,
    required int bookingId,
  }) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/payments/booking/$bookingType/$bookingId",
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException {
      return null;
    }
  }

  Future<String?> createPaymentLink({
    required String bookingType,
    required int bookingId,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        "${AppConstants.baseUrl}/payments/link",
        data: {
          'bookingType': bookingType,
          'bookingId': bookingId,
          'type': type,
        },
      );
      return response.data?['url']?.toString();
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString();
    }
  }

  Future<String?> markCash({
    required String bookingType,
    required int bookingId,
    required double amount,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        "${AppConstants.baseUrl}/payments/mark-cash",
        data: {
          'bookingType': bookingType,
          'bookingId': bookingId,
          'amount': amount,
          'type': type,
        },
      );
      return response.data?['message']?.toString();
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Failed to record cash';
    }
  }

  Future<String?> updatePlan({
    required int paymentId,
    required double advanceAmount,
    double? organizerFeePercent,
  }) async {
    try {
      final response = await _dio.patch(
        "${AppConstants.baseUrl}/payments/plan/$paymentId",
        data: {
          'advanceAmount': advanceAmount,
          'organizerFeePercent': organizerFeePercent,
        },
      );
      return response.data?['message']?.toString();
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Failed to update plan';
    }
  }

  Future<String?> recordPayout({
    required int paymentId,
    required int vendorId,
    required double amount,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        "${AppConstants.baseUrl}/payments/payouts",
        data: {
          'paymentId': paymentId,
          'vendorId': vendorId,
          'amount': amount,
          'notes': notes,
        },
      );
      return response.data?['message']?.toString();
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Failed to record payout';
    }
  }
}

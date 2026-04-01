import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api_client.dart';

class PaymentService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>?> fetchSummary({
    required String bookingType,
    required int bookingId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        "${AppConstants.baseUrl}/payments/booking/$bookingType/$bookingId",
        queryParameters: {"page": page, "limit": limit},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (_) {}
    return null;
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
          "bookingType": bookingType,
          "bookingId": bookingId,
          "type": type,
        },
      );
      if (response.statusCode == 200) {
        return response.data['url']?.toString();
      }
    } catch (e) {
      if (e is DioException) {
        return e.response?.data['message']?.toString();
      }
    }
    return null;
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
          "advanceAmount": advanceAmount,
          if (organizerFeePercent != null) "organizerFeePercent": organizerFeePercent,
        },
      );
      if (response.statusCode == 200) {
        return response.data['message']?.toString();
      }
    } catch (e) {
      if (e is DioException) return e.response?.data['message']?.toString();
    }
    return null;
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
          "bookingType": bookingType,
          "bookingId": bookingId,
          "amount": amount,
          "type": type,
        },
      );
      if (response.statusCode == 200) {
        return response.data['message']?.toString();
      }
    } catch (e) {
      if (e is DioException) return e.response?.data['message']?.toString();
    }
    return null;
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
          "paymentId": paymentId,
          "vendorId": vendorId,
          "amount": amount,
          if (notes != null) "notes": notes,
        },
      );
      if (response.statusCode == 200) {
        return response.data['message']?.toString();
      }
    } catch (e) {
      if (e is DioException) return e.response?.data['message']?.toString();
    }
    return null;
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  static const _storage = FlutterSecureStorage();

  static const bookingAlertsKey = "setting_booking_alerts";
  static const paymentAlertsKey = "setting_payment_alerts";
  static const promoAlertsKey = "setting_promo_alerts";
  static const profileVisibleKey = "setting_profile_visible";
  static const analyticsKey = "setting_analytics";

  Future<bool> readBool(String key, {required bool defaultValue}) async {
    final value = await _storage.read(key: key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> writeBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<String?> readValue(String key) async {
    return _storage.read(key: key);
  }

  Future<void> clearSettingsOnly() async {
    await _storage.delete(key: bookingAlertsKey);
    await _storage.delete(key: paymentAlertsKey);
    await _storage.delete(key: promoAlertsKey);
    await _storage.delete(key: profileVisibleKey);
    await _storage.delete(key: analyticsKey);
  }

  Future<void> clearAllLocalData() async {
    await _storage.deleteAll();
  }
}

class AppConstants {
  // Use 10.0.2.2 if using Android Emulator
  static const String baseUrl = "http://localhost:5000/api";
  
  // Endpoints
  static const String loginUrl = "$baseUrl/auth/login";
  static const String registerUrl = "$baseUrl/auth/register";
  static const String googleLoginUrl = "$baseUrl/auth/google";
  static const String firebaseLoginUrl = "$baseUrl/auth/firebase";
  static const String refreshUrl = "$baseUrl/auth/refresh";
  static const String logoutUrl = "$baseUrl/auth/logout";
  static const String fcmTokenUrl = "$baseUrl/auth/fcm-token";

  // Google OAuth (web client ID from Google Cloud Console)
  static const String googleWebClientId = "644785458469-jtqi6be6ras593ck4gfd0p8i7ikugc49.apps.googleusercontent.com";

  // Web Push (Firebase Console -> Cloud Messaging -> Web Push certificates)
  static const String webPushVapidKey = "BFqY47rR49Ao1zfZ9WvRNeIgYnY6vd0l4FFFwQpW51Mz5KbdL23XIdFXFal4m_58Nhi-7dS03aTIRoGnB1NwfKY";

  // Hall Endpoints
  static const String allHallsUrl = "$baseUrl/halls/all";
  static const String addHallUrl = "$baseUrl/halls/add";

  // Booking Endpoints
  static const String createBookingUrl = "$baseUrl/bookings/create";
  static const String bookedDatesUrl = "$baseUrl/bookings/booked-dates";

    // User Settings
  static const String userMeUrl = "$baseUrl/users/me";
  static const String userSettingsUrl = "$baseUrl/users/me/settings";
  static const String userChangePasswordUrl = "$baseUrl/users/me/change-password";
  // Vendor Endpoints
  static const String vendorsUrl = "$baseUrl/vendors";

  // Package Endpoints
  static const String allPackagesUrl = "$baseUrl/packages/all";

  // UI Limits
  static const int maxPortfolioImages = 10;

  static String resolveMediaUrl(String url) {
    if (url.startsWith('http')) return url;
    return "${baseUrl.replaceAll('/api', '')}$url";
  }
}


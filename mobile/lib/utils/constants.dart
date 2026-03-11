class AppConstants {
  // Use 10.0.2.2 if using Android Emulator
  static const String baseUrl = "http://10.235.113.7/api";
  
  // Endpoints
  static const String loginUrl = "$baseUrl/auth/login";
  static const String registerUrl = "$baseUrl/auth/register";

  // Hall Endpoints
  static const String allHallsUrl = "$baseUrl/halls/all";
  static const String addHallUrl = "$baseUrl/halls/add";

  // Booking Endpoints
  static const String createBookingUrl = "$baseUrl/bookings/create";
  static const String bookedDatesUrl = "$baseUrl/bookings/booked-dates";

  // Vendor Endpoints
  static const String vendorsUrl = "$baseUrl/vendors";

  // Package Endpoints
  static const String allPackagesUrl = "$baseUrl/packages/all";
}

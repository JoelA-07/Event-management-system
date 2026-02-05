class AppConstants {
  // Use 10.0.2.2 if using Android Emulator
  // Use your Laptop's IP (e.g., 192.168.1.15) if using a real phone
  static const String baseUrl = "http://172.31.144.7:5000/api"; 
  
  // Endpoints
  static const String loginUrl = "$baseUrl/auth/login";
  static const String registerUrl = "$baseUrl/auth/register";

  // Hall Endpoints
  static const String allHallsUrl = "$baseUrl/halls/all";
  static const String addHallUrl = "$baseUrl/halls/add";

  // Booking Endpoints
  static const String createBookingUrl = "$baseUrl/bookings/create";
  static const String bookedDatesUrl = "$baseUrl/bookings/booked-dates"; 
}
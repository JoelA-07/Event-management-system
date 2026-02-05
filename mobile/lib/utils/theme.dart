import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors (Deep Purple & Elegant Gold)
  static const Color primaryColor = Color(0xFF4A148C); // Royal Purple
  static const Color accentColor = Color(0xFFD4AF37);  // Metallic Gold
  static const Color secondaryColor = Color(0xFF7B1FA2);
  static const Color bgColor = Color(0xFFF8F9FA);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: bgColor,
    textTheme: GoogleFonts.poppinsTextTheme(), // Modern, clean font
    
    // Modern Input Decoration (Rounded & Soft)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),

    // Elevated Button Theme (Grand & Shiny)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
    ),
  );
}
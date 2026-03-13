import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/halls/providers/hall_provider.dart';
import 'package:mobile/features/bookings/providers/booking_provider.dart';
import 'package:mobile/features/vendors/providers/sample_cart_provider.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/core/theme.dart';

void main() {
  runApp(
    // MultiProvider allows us to add more providers later (like HallProvider, VendorProvider)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HallProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
         ChangeNotifierProvider(create: (_) => SampleCartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Management App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), 
      // ADD THIS: Named routes table
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

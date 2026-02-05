import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/hall_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/sample_cart_provider.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';

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
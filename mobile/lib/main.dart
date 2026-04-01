import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/halls/providers/hall_provider.dart';
import 'package:mobile/features/bookings/providers/booking_provider.dart';
import 'package:mobile/features/vendors/providers/sample_cart_provider.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/auth/screens/dashboard_selector.dart';
import 'package:mobile/core/theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBv92aYV9N3kgIPs8xcoijVqpTUfdu12qA',
        authDomain: 'jirehevent.firebaseapp.com',
        projectId: 'jirehevent',
        storageBucket: 'jirehevent.firebasestorage.app',
        messagingSenderId: '644785458469',
        appId: '1:644785458469:web:3e711bc30906ca25e19ecc',
        measurementId: 'G-FH3QYD9FCB',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();

  runApp(
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
      home: const AuthGate(),
      builder: (context, child) => FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: child ?? const SizedBox.shrink(),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, String?>> _restoreSession() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: "jwt_token");
    String? role = await storage.read(key: "role");
    final refresh = await storage.read(key: "refresh_token");

    if ((token != null && token.isNotEmpty) && (role == null || role.isEmpty)) {
      final decodedRole = _decodeRole(token);
      if (decodedRole != null) {
        role = decodedRole;
        await storage.write(key: "role", value: decodedRole);
      }
    }

    if ((token == null || token.isEmpty) && refresh != null && refresh.isNotEmpty) {
      final res = await _refreshWithToken(refresh);
      if (res != null) {
        token = res['token'];
        role = res['role'];
        if (res['token'] != null) {
          await storage.write(key: "jwt_token", value: res['token']!);
        }
        if (res['refreshToken'] != null) {
          await storage.write(key: "refresh_token", value: res['refreshToken']!);
        }
        if (res['role'] != null) {
          await storage.write(key: "role", value: res['role']!);
        }
        if (res['name'] != null) {
          await storage.write(key: "name", value: res['name']!);
        }
        if (res['userId'] != null) {
          await storage.write(key: "userId", value: res['userId']!);
        }
      }
    }

    return {"token": token, "role": role};
  }

  String? _decodeRole(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return data['role']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String?>?> _refreshWithToken(String refreshToken) async {
    try {
      final dio = Dio();
      final res = await dio.post(
        AppConstants.refreshUrl,
        data: {"refreshToken": refreshToken},
      );
      if (res.statusCode == 200) {
        final user = res.data['user'] as Map<String, dynamic>?;
        return {
          "token": res.data['token']?.toString(),
          "refreshToken": res.data['refreshToken']?.toString(),
          "role": user?['role']?.toString(),
          "name": user?['name']?.toString(),
          "userId": user?['id']?.toString(),
        };
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _restoreSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final token = snapshot.data?['token'];
        final role = snapshot.data?['role'];
        if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
          return DashboardSelector(role: role);
        }
        return const LoginScreen();
      },
    );
  }
}

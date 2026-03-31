import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/core/constants.dart';

class AuthService {
  // Dio is a powerful library for making HTTP requests (like Postman but in code)
  final Dio _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10), // Increase to 10 seconds
  receiveTimeout: const Duration(seconds: 10),
));
  
  // This is used to save the JWT token safely on the phone's memory
  final _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile', 'openid'],
  );
  static bool _fcmListenerAttached = false;


  // 1. REGISTER FUNCTION
  Future<Response?> register(String name, String email, String password, String phone, String role) async {
        print("DEBUG: Inside AuthService.register function"); // Add this
    try {
      Response response = await _dio.post(
        AppConstants.registerUrl,
        data: {
          "name": name,
          "email": email,
          "password": password,
          "phone": phone,
          "role": role, // Make sure to send this!
        },
      );
      return response;
    } catch (e) {
       print("DEBUG: Dio Error inside Service: $e");
       return null;
    }
  }

  // 2. LOGIN FUNCTION
  Future<Response?> login(String email, String password) async {
    try {
      Response response = await _dio.post(
        AppConstants.loginUrl,
        data: {
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        await _persistAuthResponse(response);
      }
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> googleLogin() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
        final firebaseIdToken = await userCredential.user?.getIdToken();
        if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
          return Response(
            requestOptions: RequestOptions(path: AppConstants.firebaseLoginUrl),
            statusCode: 400,
            data: {"message": "Missing Firebase ID token"},
          );
        }

        final response = await _dio.post(
          AppConstants.firebaseLoginUrl,
          data: {
            "idToken": firebaseIdToken,
          },
        );

        if (response.statusCode == 200) {
          await _persistAuthResponse(response);
        }
        return response;
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        return Response(
          requestOptions: RequestOptions(path: AppConstants.firebaseLoginUrl),
          statusCode: 400,
          data: {"message": "Google sign-in cancelled"},
        );
      }

      final auth = await account.authentication;
      if (auth.idToken == null) {
        return Response(
          requestOptions: RequestOptions(path: AppConstants.firebaseLoginUrl),
          statusCode: 400,
          data: {"message": "Missing Google ID token"},
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        return Response(
          requestOptions: RequestOptions(path: AppConstants.firebaseLoginUrl),
          statusCode: 400,
          data: {"message": "Missing Firebase ID token"},
        );
      }

      final response = await _dio.post(
        AppConstants.firebaseLoginUrl,
        data: {
          "idToken": firebaseIdToken,
        },
      );

      if (response.statusCode == 200) {
        await _persistAuthResponse(response);
      }

      return response;
    } on DioException catch (e) {
      return e.response;
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: AppConstants.firebaseLoginUrl),
        statusCode: 500,
        data: {"message": "Google sign-in failed"},
      );
    }
  }

  Future<void> _persistAuthResponse(Response response) async {
    String token = response.data['token'];
    String? refreshToken = response.data['refreshToken'];
    String role = response.data['user']['role'];
    String name = response.data['user']['name'];
    String id = response.data['user']['id'].toString();

    await _storage.write(key: "jwt_token", value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: "refresh_token", value: refreshToken);
    }
    await _storage.write(key: "role", value: role);
    await _storage.write(key: "name", value: name);
    await _storage.write(key: "userId", value: id);
    await _syncFcmToken();
  }

  Future<void> _syncFcmToken() async {
    try {
      final token = await _storage.read(key: "jwt_token");
      if (token == null || token.isNotEmpty == false) return;

      String? fcmToken;
      final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
      if (kIsWeb && AppConstants.webPushVapidKey.isNotEmpty) {
        fcmToken = await FirebaseMessaging.instance.getToken(
          vapidKey: AppConstants.webPushVapidKey,
        );
      } else {
        fcmToken = await FirebaseMessaging.instance.getToken();
      }

      if (fcmToken == null || fcmToken.isEmpty) return;

      await _dio.post(
        AppConstants.fcmTokenUrl,
        data: {"fcmToken": fcmToken, "platform": platform},
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (!kIsWeb) {
        await FirebaseMessaging.instance.subscribeToTopic('all');
      }

      if (!_fcmListenerAttached) {
        _fcmListenerAttached = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          final currentToken = await _storage.read(key: "jwt_token");
          if (currentToken == null || currentToken.isEmpty) return;
          await _dio.post(
            AppConstants.fcmTokenUrl,
            data: {"fcmToken": newToken, "platform": platform},
            options: Options(
              headers: {"Authorization": "Bearer $currentToken"},
            ),
          );
        });
      }
    } catch (_) {}
  }

  Future<Response?> refreshToken() async {
    try {
      final refresh = await _storage.read(key: "refresh_token");
      if (refresh == null || refresh.isEmpty) return null;
      return await _dio.post(
        AppConstants.refreshUrl,
        data: {"refreshToken": refresh},
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: "refresh_token");
  }
  // 3. LOGOUT FUNCTION
  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: "refresh_token");
      if (refresh != null && refresh.isNotEmpty) {
        await _dio.post(AppConstants.logoutUrl, data: {"refreshToken": refresh});
      }
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _storage.delete(key: "jwt_token");
    await _storage.delete(key: "refresh_token");
    await _storage.delete(key: "role");
    await _storage.delete(key: "name");
    await _storage.delete(key: "userId");
  }

  // 4. GET SAVED TOKEN (To check if user is already logged in)
  Future<String?> getToken() async {
    return await _storage.read(key: "jwt_token");
  }
}

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  // --dart-define=GOOGLE_AUTH_CLIENT_ID=xxx sets this at compile time.
  // If empty, pass null so google_sign_in_web falls back to the
  // <meta name="google-signin-client_id"> tag in web/index.html.
  static const String _envClientId =
      String.fromEnvironment('GOOGLE_AUTH_CLIENT_ID', defaultValue: '');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _envClientId.isNotEmpty ? _envClientId : null,
    scopes: ['email', 'profile'],
  );

  late firebase_auth.FirebaseAuth _firebaseAuth;

  AuthRepository({required this.apiClient}) {
    _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  }


  /// Sign in with Google, then send the ID token to our backend.
  Future<AuthResponse> signInWithGoogle() async {
    print('🔐 [GoogleSignIn] Starting Google Sign-In flow...');
    print('🔐 [GoogleSignIn] Client ID configured: $_envClientId');
    
    // Trigger Google Sign-In flow (works on both web and mobile)
    try {
      print('🔐 [GoogleSignIn] Calling _googleSignIn.signIn()...');
      final account = await _googleSignIn.signIn();
      print('🔐 [GoogleSignIn] signIn() returned: $account');
      
      if (account == null) {
        print('❌ [GoogleSignIn] signIn() returned null - user cancelled');
        throw ApiException(message: 'Google sign-in was cancelled');
      }

      print('✅ [GoogleSignIn] Account obtained: ${account.email}');
      
      // Get authentication tokens
      print('🔐 [GoogleSignIn] Getting authentication tokens...');
      final auth = await account.authentication;
      print('🔐 [GoogleSignIn] Authentication object: $auth');
      
      final idToken = auth.idToken;
      print('🔐 [GoogleSignIn] ID Token length: ${idToken?.length ?? 0}');
      
      if (idToken == null || idToken.isEmpty) {
        print('❌ [GoogleSignIn] Failed to get ID token');
        throw ApiException(message: 'Failed to get Google ID token');
      }

      print('✅ [GoogleSignIn] ID Token obtained successfully');
      
      // Send ID token to our backend
      print('🔐 [GoogleSignIn] Sending ID token to backend...');
      print('🔐 [GoogleSignIn] Backend endpoint: ${ApiEndpoints.googleLogin}');
      
      try {
        final response = await apiClient.post(
          ApiEndpoints.googleLogin,
          data: {'id_token': idToken},
        );
        print('✅ [GoogleSignIn] Backend responded successfully');
        print('🔐 [GoogleSignIn] Response data: ${response.data}');
        
        final authResponse = AuthResponse.fromJson(response.data['data']);
        await apiClient.saveTokens(authResponse.token, authResponse.refreshToken);
        print('✅ [GoogleSignIn] Tokens saved. User: ${authResponse.user.email}');
        return authResponse;
      } on DioException catch (e) {
        print('❌ [GoogleSignIn] Backend request failed: ${e.message}');
        print('❌ [GoogleSignIn] Status code: ${e.response?.statusCode}');
        print('❌ [GoogleSignIn] Response: ${e.response?.data}');
        throw ApiException.fromDioError(e);
      }
    } catch (e) {
      print('❌ [GoogleSignIn] Unexpected error: $e');
      print('❌ [GoogleSignIn] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Sign out of Google and clear local tokens.
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors
    }
  }

  /// Sign in with Facebook via Firebase
  Future<AuthResponse> signInWithFacebook() async {
    try {
      // Firebase handles Facebook authentication
      // In production, configure Facebook provider in Firebase Console
      // For now, we'll use Firebase's built-in support
      
      // Get the current Firebase user after authentication
      final user = _firebaseAuth.currentUser;
      if (user == null || user.uid.isEmpty) {
        throw ApiException(message: 'Facebook authentication failed');
      }

      // Get the ID token from Firebase
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(message: 'Failed to get Facebook ID token');
      }

      // Send to backend Firebase endpoint
      final response = await apiClient.post(
        ApiEndpoints.firebaseLogin, // endpoint: /auth/firebase
        data: {'id_token': idToken, 'provider': 'facebook'},
      );
      final authResponse = AuthResponse.fromJson(response.data['data']);
      await apiClient.saveTokens(authResponse.token, authResponse.refreshToken);
      return authResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: 'Facebook sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in with Microsoft via Firebase
  Future<AuthResponse> signInWithMicrosoft() async {
    try {
      // Firebase handles Microsoft authentication
      // In production, configure Microsoft provider in Firebase Console
      
      // Get the current Firebase user after authentication
      final user = _firebaseAuth.currentUser;
      if (user == null || user.uid.isEmpty) {
        throw ApiException(message: 'Microsoft authentication failed');
      }

      // Get the ID token from Firebase
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(message: 'Failed to get Microsoft ID token');
      }

      // Send to backend Firebase endpoint
      final response = await apiClient.post(
        ApiEndpoints.firebaseLogin, // endpoint: /auth/firebase
        data: {'id_token': idToken, 'provider': 'microsoft'},
      );
      final authResponse = AuthResponse.fromJson(response.data['data']);
      await apiClient.saveTokens(authResponse.token, authResponse.refreshToken);
      return authResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: 'Microsoft sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password (admin only)
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final authResponse = AuthResponse.fromJson(response.data['data']);
      await apiClient.saveTokens(authResponse.token, authResponse.refreshToken);
      return authResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get current user profile from the backend.
  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.get(ApiEndpoints.profile);
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Log out: clear tokens and Google session.
  Future<void> logout() async {
    await signOutGoogle();
    await apiClient.clearTokens();
  }

  /// Check if user has a saved auth token.
  Future<bool> isLoggedIn() async {
    return apiClient.isAuthenticated();
  }
}

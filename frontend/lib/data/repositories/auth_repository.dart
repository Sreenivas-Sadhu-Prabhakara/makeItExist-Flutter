import 'package:dio/dio.dart';
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

  AuthRepository({required this.apiClient});

  /// Sign in with Google, then send the ID token to our backend.
  Future<AuthResponse> signInWithGoogle() async {
    // Trigger Google Sign-In flow
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw ApiException(message: 'Google sign-in was cancelled');
    }

    // Get authentication tokens
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(message: 'Failed to get Google ID token');
    }

    // Send ID token to our backend
    try {
      final response = await apiClient.post(
        ApiEndpoints.googleLogin,
        data: {'id_token': idToken},
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      await apiClient.saveTokens(authResponse.token, authResponse.refreshToken);
      return authResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
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

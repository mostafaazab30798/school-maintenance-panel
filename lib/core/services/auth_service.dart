import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/auth_state.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  // Sign-up functionality has been removed as per requirements

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with magic link (OTP)
  ///
  /// Sends a magic link to the provided email address.
  /// The user will receive an email with a link to sign in.
  Future<void> signInWithMagicLink(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  /// Verify the OTP (one-time password) sent to the user's email
  ///
  /// This is used in the mobile app to complete the magic link sign-in process.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    String type = 'magiclink',
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.magiclink,
    );
  }

  Future<void> signOut() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      // Clear the verification status in app_router.dart
      clearUserVerificationStatus(currentUser.id);
    }
    await _client.auth.signOut();
  }

  // Helper method to clear admin verification status
  void clearUserVerificationStatus(String userId) {
    // Use the function from auth_state.dart
    clearAdminVerificationStatus(userId);
  }

  Future<User?> getCurrentUser() async {
    return _client.auth.currentUser;
  }

  Stream<AuthState> onAuthStateChange() {
    return _client.auth.onAuthStateChange;
  }

  Future<bool> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
    return true;
  }
}

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';

class AuthService {
  static bool _googleReady = false;

  GoTrueClient get _auth => supabase.auth;

  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  /// Current user id, or null when signed out. Handy for screens that only
  /// need the id.
  static String? get uid => supabase.auth.currentUser?.id;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: kGoogleServerClientId,
    );
    _googleReady = true;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // Fail fast with a clear message instead of spinning indefinitely on a
    // flaky connection (a late success still lands the user on the home
    // screen via onAuthStateChange).
    return _auth
        .signInWithPassword(email: email.trim(), password: password)
        .timeout(const Duration(seconds: 20));
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) {
    return _auth
        .signUp(email: email.trim(), password: password)
        .timeout(const Duration(seconds: 20));
  }

  /// One-tap "Continue with Google": the Google account becomes a Supabase
  /// identity (native id-token exchange); the app profile is completed on the
  /// first sign-in.
  ///
  /// Requires the Google provider enabled in Supabase and the app's
  /// release/debug SHA-1 fingerprint registered on the Android OAuth client.
  Future<AuthResponse> signInWithGoogle() async {
    await _ensureGoogleReady();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception('google-sign-in provider-config');
      }
      return await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on AuthException {
      rethrow; // authErrorMessage maps the Supabase messages.
    } on GoogleSignInException catch (e) {
      // The platform reports walled flows through typed exceptions: a user
      // closing the sheet is not an error, a misconfigured client is.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        throw Exception('google-sign-in aborted-by-user');
      }
      throw Exception('google-sign-in provider-config');
    } catch (e) {
      // e.g. PlatformException from account.authentication (SHA-1 mismatch is
      // surfaced as "10: INVALID_CLIENT_APPLICATION / authentication").
      throw Exception(e.toString());
    }
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(email.trim());
  }

  Future<void> logout() async {
    try {
      await _ensureGoogleReady();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

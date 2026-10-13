import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _googleReady = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    // Fail fast with a clear message instead of spinning indefinitely on a
    // flaky connection (a late success still lands the user on the home
    // screen via authStateChanges).
    return await _auth
        .signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// One-tap "Continue with Google": the Google account becomes a Firebase
  /// identity (free tier; then the app profile is completed on first sign-in).
  ///
  /// Requires the Google provider enabled in the Firebase console and the
  /// app's release/debug SHA-1 certificate fingerprint registered there.
  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleReady();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow; // authErrorMessage maps the Firebase codes.
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

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    await _ensureGoogleReady();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}

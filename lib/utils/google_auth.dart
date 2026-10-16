import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'errors.dart';

/// Runs the "Continue with Google" flow.
///
/// It only performs the sign-in and reports failures; routing is owned by
/// `AuthGate`, which sends a first-time Google identity (no/!complete profile)
/// to the completion screen and everyone else to the home shell. This avoids
/// the race where the session appears before the profile exists — pushing a
/// screen here would fight the gate and could drop the user straight into the
/// app without a profile.
///
/// Returns true when a session was established.
Future<bool> handleGoogleSignIn(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await AuthService().signInWithGoogle();
    return true;
  } on AuthException catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(authErrorMessage(context, e))),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(authErrorMessage(context, e))),
      );
    }
    return false;
  }
}

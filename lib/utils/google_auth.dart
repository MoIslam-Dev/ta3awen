import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth_gate.dart';
import '../screens/auth/social_setup_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'errors.dart';

/// Runs the "Continue with Google" flow and lands the user on the right
/// screen:
/// * profile already exists -> home shell (fresh AuthGate), or
/// * first sign-in -> a short completion screen (name + wilaya + commune)
///   because every Ta3awen profile needs a location.
///
/// Returns true when the flow ended on the home screen.
Future<bool> handleGoogleSignIn(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final cred = await AuthService().signInWithGoogle();
    final user = cred.user;
    if (user == null) return false;
    final existing = await UserService().getById(user.uid);
    if (!context.mounted) return false;
    if (existing != null) {
      await _goHome(context);
      return true;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialSetupScreen(user: user),
      ),
    );
    return true;
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return false;
    messenger.showSnackBar(
      SnackBar(content: Text(authErrorMessage(context, e))),
    );
    return false;
  } catch (e) {
    if (!context.mounted) return false;
    messenger.showSnackBar(
      SnackBar(content: Text(authErrorMessage(context, e))),
    );
    return false;
  }
}

Future<void> _goHome(BuildContext context) async {
  if (!context.mounted) return;
  await Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthGate()),
    (route) => false,
  );
}
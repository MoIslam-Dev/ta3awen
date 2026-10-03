import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'home/home_shell.dart';

/// Watches the Firebase auth state and shows login or the home shell.
///
/// Every auth flow (login, register, logout) navigates back to a fresh
/// AuthGate instead of pushing bare screens, so this widget can never be
/// removed from the navigator — otherwise authStateChanges would go
/// unobserved and login would never reach the home page.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}

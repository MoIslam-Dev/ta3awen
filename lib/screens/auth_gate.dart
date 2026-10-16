import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/ext.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'home/home_shell.dart';

/// Watches the Supabase auth state and shows login or the home shell.
///
/// The waiting state doubles as the in-app splash: it continues the native
/// green launch screen (logo on brand green) instead of a bare spinner.
///
/// Every auth flow (login, register, logout) navigates back to a fresh
/// AuthGate instead of pushing bare screens, so this widget can never be
/// removed from the navigator — otherwise authStateChanges would go
/// unobserved and login would never reach the home page.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.primaryDark,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo/launch_logo.png',
                      width: 96,
                      height: 96,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.data?.session != null) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}

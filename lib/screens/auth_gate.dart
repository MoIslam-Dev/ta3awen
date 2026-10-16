import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/ext.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/errors.dart';
import '../widgets/state_views.dart';
import 'auth/login_screen.dart';
import 'auth/social_setup_screen.dart';
import 'home/home_shell.dart';

/// Watches the Supabase auth state and routes the user:
/// * no session -> [LoginScreen]
/// * session but no/!complete profile -> [SocialSetupScreen] (first Google
///   sign-in, or an account whose profile was never filled in)
/// * session and a complete profile -> [HomeShell]
///
/// The profile check is what makes "Continue with Google" safe: a brand-new
/// Google identity has a session the instant it signs in, so we must NOT show
/// the app until a wilaya/commune profile actually exists.
///
/// The waiting state doubles as the in-app splash: it continues the native
/// green launch screen (logo on brand green) instead of a bare spinner.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final session = snapshot.data?.session;
        if (session == null) return const LoginScreen();
        return _ProfileGate(
          key: ValueKey(session.user.id),
          user: session.user,
        );
      },
    );
  }
}

/// Loads the signed-in user's profile and decides between the completion
/// screen and the home shell.
class _ProfileGate extends StatefulWidget {
  const _ProfileGate({super.key, required this.user});

  final User user;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  final _users = UserService();
  late Future<AppUser?> _future = _users.getById(widget.user.id);

  void _reload() => setState(() => _future = _users.getById(widget.user.id));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: ErrorView(
              message: dataErrorMessage(context, snapshot.error!),
              onRetry: _reload,
            ),
          );
        }
        final profile = snapshot.data;
        final complete = profile != null &&
            profile.wilaya.isNotEmpty &&
            profile.commune.isNotEmpty;
        if (!complete) return SocialSetupScreen(user: widget.user);
        return const HomeShell();
      },
    );
  }
}

/// Branded splash shared by the auth-state and profile wait states.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../widgets/publish_sheet.dart';
import '../auth_gate.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_screen.dart';
import 'ask_screen.dart';
import 'blood_screen.dart';
import 'give_screen.dart';

/// Top-level navigation built on the app's core model: what the community
/// *gives* (donations + barters), what it *asks for*, blood as its own
/// urgent door, and the personal hub. A single FAB opens the publish
/// sheet, so there is exactly one place to create anything.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Tabs are created lazily so logging in only starts the feed query
  // instead of firing every listener at once.
  final List<Widget?> _pages = List<Widget?>.filled(4, null);

  void _ensurePage(int i) {
    if (_pages[i] != null) return;
    switch (i) {
      case 0:
        _pages[0] = const GiveScreen();
      case 1:
        _pages[1] = const AskScreen();
      case 2:
        _pages[2] = const BloodScreen();
      default:
        _pages[3] = ProfileScreen(onLogoutRequested: _confirmLogout);
    }
  }

  void _select(int i) {
    setState(() {
      _index = i;
      _ensurePage(i);
    });
  }

  @override
  void initState() {
    super.initState();
    _ensurePage(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  Future<void> _maybeShowOnboarding() async {
    if (!await OnboardingScreen.shouldShow()) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  String _title() {
    switch (_index) {
      case 0:
        return context.l10n.navGive;
      case 1:
        return context.l10n.navAsk;
      case 2:
        return context.l10n.navBlood;
      default:
        return context.l10n.tabProfile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final onProfile = _index == 3;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_index == 0) ...[
              Image.asset(
                'assets/logo/launch_logo.png',
                width: 26,
                height: 26,
              ),
              const SizedBox(width: 8),
            ],
            Text(_title()),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          for (final page in _pages) page ?? const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: onProfile
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showPublishSheet(context),
              icon: const Icon(Icons.add),
              label: Text(l.publishTitle),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.redeem_outlined),
            selectedIcon: const Icon(Icons.redeem),
            label: l.navGive,
          ),
          NavigationDestination(
            icon: const Icon(Icons.volunteer_activism_outlined),
            selectedIcon: const Icon(Icons.volunteer_activism),
            label: l.navAsk,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bloodtype_outlined),
            selectedIcon: const Icon(Icons.bloodtype),
            label: l.navBlood,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l.tabProfile,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final l = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logoutTitle),
        content: Text(l.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.logout),
          ),
        ],
      ),
    );
    if (yes == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }
}

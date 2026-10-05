import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../auth_gate.dart';
import 'feed_screen.dart';
import '../listing/listing_form_screen.dart';
import '../my_listings/my_listings_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Tabs are created lazily so that logging in only starts the feed query
  // instead of firing feed + myListings + profile/admin requests at once.
  final List<Widget?> _pages = List<Widget?>.filled(3, null);

  void _ensurePage(int i) {
    if (_pages[i] != null) return;
    switch (i) {
      case 0:
        _pages[0] = const FeedScreen();
      case 1:
        _pages[1] = const MyListingsScreen();
      default:
        _pages[2] = ProfileScreen(onLogoutRequested: _confirmLogout);
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
  }

  String _title() {
    switch (_index) {
      case 0:
        return context.l10n.appName;
      case 1:
        return context.l10n.tabMyListings;
      default:
        return context.l10n.tabProfile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ListingFormScreen.create(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l.addListing),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l.tabMyListings,
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
        // Return to a fresh AuthGate (never a bare LoginScreen) so that the
        // auth state stays observed and the next login can navigate.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }
}

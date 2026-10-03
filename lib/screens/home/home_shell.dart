import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  static const _titles = ['تعاون', 'إعلاناتي', 'حسابي'];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
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
              label: const Text('إضافة إعلان'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'إعلاناتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
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

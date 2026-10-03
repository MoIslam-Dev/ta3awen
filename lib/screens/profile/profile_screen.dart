import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';
import '../../services/user_service.dart';
import '../../utils/errors.dart';
import '../../widgets/state_views.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogoutRequested;

  const ProfileScreen({super.key, required this.onLogoutRequested});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final _users = UserService();
  final _admin = AdminService();

  AppUser? _user;
  bool _isAdmin = false;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'يجب تسجيل الدخول';
      });
      return;
    }
    try {
      final user = await _users.getById(uid);
      final isAdmin = await _admin.isAdmin(uid);
      if (mounted) {
        setState(() {
          _user = user;
          _isAdmin = isAdmin;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dataErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final user = _user;
    final auth = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName.characters.first
                          : '؟',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    auth?.email ?? '',
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 8),
                    Text('${user.wilaya} - ${user.commune}',
                        style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('لوحة الإدارة'),
                subtitle: const Text('إدارة الإعلانات والبلاغات والمستخدمين'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              ),
            ),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline,
                  color: theme.colorScheme.primary),
              title: const Text('عن تطبيق تعاون'),
              subtitle: const Text(
                'تطبيق جزائري للتبرع بالغرض الذي لم يعد يُستخدم\nليحتاجه شخص آخر.\nمشروع خيري في ذكرى والدتي - رحمها الله.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: widget.onLogoutRequested,
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

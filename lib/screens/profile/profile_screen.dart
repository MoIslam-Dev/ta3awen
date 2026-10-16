import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../state/app_settings.dart';
import '../../utils/errors.dart';
import '../../widgets/state_views.dart';
import '../admin/admin_screen.dart';
import '../my_listings/my_listings_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../requests/my_requests_screen.dart';
import 'edit_profile_screen.dart';

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
    final uid = AuthService.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = context.l10n.loginRequired;
      });
      return;
    }
    try {
      final userFuture = _users.getById(uid);
      final adminFuture = _admin.isAdmin(uid);
      final user = await userFuture;
      final isAdmin = await adminFuture;
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
          _error = dataErrorMessage(context, e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _editProfile(AppUser user) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _pickLanguage() async {
    final settings = AppSettings.instance;
    final current = settings.locale.value.languageCode;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        Widget option(String code, String name) {
          final selected = code == current;
          return ListTile(
            leading: selected
                ? Icon(Icons.check_circle,
                    color: Theme.of(ctx).colorScheme.primary)
                : const Icon(Icons.language_outlined),
            title: Text(name),
            onTap: () {
              Navigator.pop(ctx);
              settings.setLocale(Locale(code));
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  context.l10n.languageTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              option('ar', 'العربية'),
              option('fr', 'Français'),
              option('en', 'English'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTheme() async {
    final settings = AppSettings.instance;
    final current = settings.themeMode.value;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final l = context.l10n;
        Widget option(ThemeMode mode, IconData icon, String name) {
          final selected = mode == current;
          return ListTile(
            leading: selected
                ? Icon(Icons.check_circle,
                    color: Theme.of(ctx).colorScheme.primary)
                : Icon(icon),
            title: Text(name),
            onTap: () {
              Navigator.pop(ctx);
              settings.setThemeMode(mode);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l.themeTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              option(ThemeMode.light, Icons.light_mode_outlined, l.themeLight),
              option(ThemeMode.dark, Icons.dark_mode_outlined, l.themeDark),
              option(ThemeMode.system, Icons.brightness_auto_outlined,
                  l.themeSystem),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _languageName() {
    switch (AppSettings.instance.locale.value.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'العربية';
    }
  }

  String _themeName() {
    final l = context.l10n;
    switch (AppSettings.instance.themeMode.value) {
      case ThemeMode.light:
        return l.themeLight;
      case ThemeMode.dark:
        return l.themeDark;
      case ThemeMode.system:
        return l.themeSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    if (_loading) return LoadingView(message: l.loading);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final user = _user;
    final auth = AuthService().currentUser;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Identity card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor:
                          theme.colorScheme.onPrimaryContainer,
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false)
                            ? user!.fullName.characters.first
                            : '؟',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user?.fullName ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (user != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: l.editProfileTitle,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editProfile(user),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth?.email ?? '',
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.wilaya} - ${user.commune}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // My content — publications and board posts
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l.myListings),
                  subtitle: Text(l.myListingsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MyListingsScreen()),
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.forum_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l.myRequests),
                  subtitle: Text(l.myRequestsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MyRequestsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings: language + theme
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.translate_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l.languageTitle),
                  subtitle: Text(_languageName()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickLanguage,
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.dark_mode_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l.themeTitle),
                  subtitle: Text(_themeName()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTheme,
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l.profileHowItWorks),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OnboardingScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isAdmin)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l.adminPanel),
                subtitle: Text(l.adminPanelSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              ),
            ),
          if (_isAdmin) const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: Icon(
                Icons.favorite_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(l.aboutTitle),
              subtitle: Text(
                l.aboutBody,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: widget.onLogoutRequested,
            icon: const Icon(Icons.logout),
            label: Text(l.logoutButton),
            style: FilledButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

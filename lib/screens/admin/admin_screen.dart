import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/app_user.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../services/admin_service.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../utils/labels.dart';
import '../../widgets/state_views.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _admin = AdminService();

  bool _checking = true;
  bool _authorized = false;

  List<Listing> _listings = [];
  List<Report> _reports = [];
  List<AppUser> _users = [];
  bool _loadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _checking = false);
      return;
    }
    final ok = await _admin.isAdmin(uid);
    if (mounted) {
      setState(() {
        _authorized = ok;
        _checking = false;
      });
      if (ok) _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
      _error = null;
    });
    try {
      final listings = await _admin.allListings();
      final reports = await _admin.allReports();
      final users = await _admin.allUsers();
      if (mounted) {
        setState(() {
          _listings = listings;
          _reports = reports;
          _users = users;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dataErrorMessage(context, e);
          _loadingData = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteListing(Listing l) async {
    final loc = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteListingTitle),
        content: Text(loc.deleteListingBody(l.title)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _admin.deleteListing(l.id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    }
  }

  Future<void> _deleteReport(Report r) async {
    try {
      await _admin.deleteReport(r.id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    }
  }

  Future<void> _toggleUser(AppUser u) async {
    try {
      await _admin.setUserDisabled(u.uid, !u.disabled);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_checking) {
      return Scaffold(
        appBar: AppBar(title: Text(l.adminTitle)),
        body: LoadingView(message: l.loading),
      );
    }
    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(title: Text(l.adminTitle)),
        body: EmptyView(
          icon: Icons.lock_outline,
          message: l.noAdminPermission,
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.adminTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.tabListings),
              Tab(text: l.tabReports),
              Tab(text: l.tabUsers),
            ],
          ),
        ),
        body: _loadingData
            ? LoadingView(message: l.loading)
            : _error != null
                ? ErrorView(message: _error!, onRetry: _loadData)
                : TabBarView(
                    children: [
                      _listingsTab(),
                      _reportsTab(),
                      _usersTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _listingsTab() {
    final l = context.l10n;
    if (_listings.isEmpty) {
      return EmptyView(
        icon: Icons.inventory_2_outlined,
        message: l.noListings,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _listings.length,
        itemBuilder: (context, i) {
          final item = _listings[i];
          final theme = Theme.of(context);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${item.ownerName} • ${item.wilaya} • ${formatDate(item.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: () => _confirmDeleteListing(item),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _reportsTab() {
    final l = context.l10n;
    final theme = Theme.of(context);
    if (_reports.isEmpty) {
      return EmptyView(icon: Icons.flag_outlined, message: l.noReports);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _reports.length,
        itemBuilder: (context, i) {
          final r = _reports[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(
                l.reportPrefix(r.listingTitle),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    l.reportMeta(
                      reportReasonLabel(context, r.reason),
                      r.reporterName,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.description != null && r.description!.isNotEmpty)
                    Text(
                      r.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    formatDateTime(r.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: () => _deleteReport(r),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _usersTab() {
    final l = context.l10n;
    final theme = Theme.of(context);
    if (_users.isEmpty) {
      return EmptyView(icon: Icons.people_outlined, message: l.noUsers);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _users.length,
        itemBuilder: (context, i) {
          final u = _users[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwitchListTile(
              title: Text(
                u.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${u.email} • ${u.wilaya}',
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: !u.disabled,
              onChanged: (_) => _toggleUser(u),
              secondary: Icon(
                u.disabled ? Icons.block : Icons.check_circle_outline,
                color: u.disabled
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

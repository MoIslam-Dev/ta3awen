import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../services/admin_service.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
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
          _error = dataErrorMessage(e);
          _loadingData = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteListing(Listing l) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('حذف "${l.title}" نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
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
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(e))));
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
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(e))));
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
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: LoadingView());
    }
    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة الإدارة')),
        body: const EmptyView(
          icon: Icons.lock_outline,
          message: 'ليست لديك صلاحية الدخول إلى لوحة الإدارة',
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الإعلانات'),
              Tab(text: 'البلاغات'),
              Tab(text: 'المستخدمون'),
            ],
          ),
        ),
        body: _loadingData
            ? const LoadingView()
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
    if (_listings.isEmpty) {
      return const EmptyView(
          icon: Icons.inventory_2_outlined, message: 'لا توجد إعلانات');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _listings.length,
        itemBuilder: (context, i) {
          final l = _listings[i];
          return ListTile(
            title: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${l.ownerName} • ${l.wilaya} • ${formatDate(l.createdAt)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDeleteListing(l),
            ),
          );
        },
      ),
    );
  }

  Widget _reportsTab() {
    if (_reports.isEmpty) {
      return const EmptyView(
          icon: Icons.flag_outlined, message: 'لا توجد بلاغات');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _reports.length,
        itemBuilder: (context, i) {
          final r = _reports[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('بلاغ: ${r.listingTitle}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('السبب: ${r.reason} • المُبلِّغ: ${r.reporterName}'),
                  if (r.description != null && r.description!.isNotEmpty)
                    Text(r.description!,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(formatDateTime(r.createdAt),
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteReport(r),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _usersTab() {
    if (_users.isEmpty) {
      return const EmptyView(
          icon: Icons.people_outlined, message: 'لا توجد مستخدمين');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, i) {
          final u = _users[i];
          return SwitchListTile(
            title: Text(u.fullName),
            subtitle: Text(
              '${u.email} • ${u.wilaya}',
              textDirection: TextDirection.ltr,
            ),
            value: !u.disabled,
            onChanged: (_) => _toggleUser(u),
            secondary: Icon(
              u.disabled ? Icons.block : Icons.check_circle_outline,
              color: u.disabled ? Colors.red : Colors.green,
            ),
          );
        },
      ),
    );
  }
}

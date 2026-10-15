import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../services/admin_service.dart';
import '../../widgets/state_views.dart';
import 'admin_dashboard_tab.dart';
import 'admin_listings_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_requests_tab.dart';
import 'admin_users_tab.dart';

/// Admin console. Access is verified once, then each tab loads its own
/// data lazily and paginated — the console never opens several full-collection
/// listeners at once.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _admin = AdminService();

  bool _checking = true;
  bool _authorized = false;

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
        body: EmptyView(icon: Icons.lock_outline, message: l.noAdminPermission),
      );
    }
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.adminTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l.tabDashboard),
              Tab(text: l.tabReports),
              Tab(text: l.tabListings),
              Tab(text: l.tabUsers),
              Tab(text: l.tabRequests),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminDashboardTab(),
            AdminReportsTab(),
            AdminListingsTab(),
            AdminUsersTab(),
            AdminRequestsTab(),
          ],
        ),
      ),
    );
  }
}

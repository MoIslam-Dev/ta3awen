import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/app_user.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../models/request_post.dart';
import '../../services/admin_service.dart';
import '../../widgets/state_views.dart';
import 'admin_dashboard_tab.dart';
import 'admin_listings_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_requests_tab.dart';
import 'admin_users_tab.dart';

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
        body: EmptyView(
          icon: Icons.lock_outline,
          message: l.noAdminPermission,
        ),
      );
    }
    return DefaultTabController(
      length: 5,
      child: Builder(builder: (context) {
        final controller = DefaultTabController.of(context);
        return Scaffold(
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
          body: StreamBuilder<List<Listing>>(
            stream: _admin.listingsStream(),
            builder: (context, listingsSnap) => StreamBuilder<List<Report>>(
              stream: _admin.reportsStream(),
              builder: (context, reportsSnap) => StreamBuilder<List<AppUser>>(
                stream: _admin.usersStream(),
                builder: (context, usersSnap) =>
                    StreamBuilder<List<RequestPost>>(
                  stream: _admin.requestsStream(),
                  builder: (context, requestsSnap) {
                    if (listingsSnap.hasError ||
                        reportsSnap.hasError ||
                        usersSnap.hasError ||
                        requestsSnap.hasError) {
                      return ErrorView(
                        message: l.errorGeneric,
                        onRetry: () => setState(() {}),
                      );
                    }
                    if (!listingsSnap.hasData ||
                        !reportsSnap.hasData ||
                        !usersSnap.hasData ||
                        !requestsSnap.hasData) {
                      return LoadingView(message: l.loading);
                    }
                    final listings = listingsSnap.data!;
                    final reports = reportsSnap.data!;
                    final users = usersSnap.data!;
                    final requests = requestsSnap.data!;
                    return TabBarView(
                      children: [
                        AdminDashboardTab(
                          listings: listings,
                          reports: reports,
                          users: users,
                          requests: requests,
                          onOpenReports: () => controller.animateTo(1),
                        ),
                        AdminReportsTab(
                          reports: reports,
                          listings: listings,
                        ),
                        AdminListingsTab(listings: listings),
                        AdminUsersTab(users: users, listings: listings, reports: reports),
                        AdminRequestsTab(requests: requests),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

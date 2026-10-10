import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/app_user.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../models/request_post.dart';
import '../../services/admin_service.dart';
import '../../utils/errors.dart';

class AdminDashboardTab extends StatefulWidget {
  final List<Listing> listings;
  final List<Report> reports;
  final List<AppUser> users;
  final List<RequestPost> requests;
  final VoidCallback onOpenReports;

  const AdminDashboardTab({
    super.key,
    required this.listings,
    required this.reports,
    required this.users,
    required this.requests,
    required this.onOpenReports,
  });

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _admin = AdminService();
  bool _cleaning = false;

  List<String> get _seedIds => widget.listings
      .where((l) => l.id.startsWith('seed-'))
      .map((l) => l.id)
      .toList();

  Future<void> _confirmSeedCleanup() async {
    final loc = context.l10n;
    final theme = Theme.of(context);
    final count = _seedIds.length;
    if (count == 0) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.seedCleanupTitle),
        content: Text(loc.seedCleanupBody(count)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _cleaning = true);
    try {
      final ids = await _admin.seedListingIds();
      final deleted = await _admin.deleteListings(ids);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.seedCleanupDone(deleted))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    } finally {
      if (mounted) setState(() => _cleaning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final listings = widget.listings;
    final reports = widget.reports;
    final users = widget.users;
    final requests = widget.requests;

    final openReports = reports.where((r) => r.isOpen).length;
    final available =
        listings.where((s) => s.status == statusAvailable).length;
    final reserved =
        listings.where((s) => s.status == statusReserved).length;
    final given = listings.where((s) => s.status == statusGiven).length;
    final openReq = requests.where((r) => r.isOpen).length;
    final matchedReq = requests.where((r) => r.isMatched).length;
    final bloodReq = requests.where((r) => r.isBlood).length;
    final disabledUsers = users.where((u) => u.disabled).length;

    final stats = <_Stat>[
      _Stat(l.tabUsers, users.length, Icons.people_outline),
      _Stat(l.statDisabledUsers, disabledUsers, Icons.block_outlined),
      _Stat(l.tabListings, listings.length, Icons.inventory_2_outlined),
      _Stat(l.statListingsAvailable, available, Icons.check_circle_outline),
      _Stat(l.statListingsReserved, reserved, Icons.bookmark_outline),
      _Stat(l.statListingsGiven, given, Icons.card_giftcard_outlined),
      _Stat(l.statReportsOpen, openReports, Icons.flag_outlined,
          highlight: openReports > 0, onTap: widget.onOpenReports),
      _Stat(l.tabRequests, requests.length, Icons.handshake_outlined),
      _Stat(l.statRequestsOpen, openReq, Icons.radio_button_unchecked),
      _Stat(l.statRequestsMatched, matchedReq, Icons.link_outlined),
      _Stat(l.statBloodRequests, bloodReq, Icons.bloodtype_outlined),
    ];

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: [
              for (final s in stats) _statCard(s, theme),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.seedCleanupTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _seedIds.isEmpty
                        ? l.seedCleanupNone
                        : l.seedCleanupBody(_seedIds.length),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          _seedIds.isEmpty || _cleaning ? null : _confirmSeedCleanup,
                      icon: _cleaning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_sweep_outlined),
                      label: Text(l.seedCleanupAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(_Stat s, ThemeData theme) {
    final color = s.highlight ? theme.colorScheme.error : theme.colorScheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: s.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(s.icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${s.value}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: s.highlight ? theme.colorScheme.error : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;

  _Stat(this.label, this.value, this.icon, {this.highlight = false, this.onTap});
}

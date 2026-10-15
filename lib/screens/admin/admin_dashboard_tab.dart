import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../models/request_post.dart';
import '../../services/admin_service.dart';
import '../../utils/errors.dart';
import '../../widgets/state_views.dart';

/// Dashboard built from cheap count aggregations — no documents are loaded
/// to render the statistics.
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _admin = AdminService();
  bool _loading = true;
  bool _cleaning = false;
  String? _error;

  int _users = 0, _disabled = 0;
  int _listings = 0, _available = 0, _reserved = 0, _given = 0;
  int _requests = 0, _openReq = 0, _matchedReq = 0, _bloodReq = 0;
  int _reports = 0, _reportsResolved = 0, _reportsDismissed = 0;
  int _seeds = 0;

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
    try {
      final results = await Future.wait<int>([
        _admin.countUsers(),
        _admin.countUsers(disabled: true),
        _admin.countListings(),
        _admin.countListings(status: statusAvailable),
        _admin.countListings(status: statusReserved),
        _admin.countListings(status: statusGiven),
        _admin.countRequests(),
        _admin.countRequests(status: requestStatusOpen),
        _admin.countRequests(status: requestStatusMatched),
        _admin.countRequests(kind: requestKindBlood),
        _admin.countReports(),
        _admin.countReports(status: reportStatusResolved),
        _admin.countReports(status: reportStatusDismissed),
        _admin.countSeedListings(),
      ]);
      if (!mounted) return;
      setState(() {
        _users = results[0];
        _disabled = results[1];
        _listings = results[2];
        _available = results[3];
        _reserved = results[4];
        _given = results[5];
        _requests = results[6];
        _openReq = results[7];
        _matchedReq = results[8];
        _bloodReq = results[9];
        _reports = results[10];
        _reportsResolved = results[11];
        _reportsDismissed = results[12];
        _seeds = results[13];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = dataErrorMessage(context, e);
        _loading = false;
      });
    }
  }

  int get _openReports => _reports - _reportsResolved - _reportsDismissed;

  Future<void> _confirmSeedCleanup() async {
    final loc = context.l10n;
    final theme = Theme.of(context);
    if (_seeds == 0) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.seedCleanupTitle),
        content: Text(loc.seedCleanupBody(_seeds)),
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
        await _load();
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
    if (_loading) return LoadingView(message: l.loading);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final theme = Theme.of(context);

    final stats = <_Stat>[
      _Stat(l.tabUsers, _users, Icons.people_outline),
      _Stat(l.statDisabledUsers, _disabled, Icons.block_outlined),
      _Stat(l.tabListings, _listings, Icons.inventory_2_outlined),
      _Stat(l.statListingsAvailable, _available, Icons.check_circle_outline),
      _Stat(l.statListingsReserved, _reserved, Icons.bookmark_outline),
      _Stat(l.statListingsGiven, _given, Icons.card_giftcard_outlined),
      _Stat(l.statReportsOpen, _openReports < 0 ? 0 : _openReports,
          Icons.flag_outlined,
          highlight: _openReports > 0),
      _Stat(l.tabRequests, _requests, Icons.handshake_outlined),
      _Stat(l.statRequestsOpen, _openReq, Icons.radio_button_unchecked),
      _Stat(l.statRequestsMatched, _matchedReq, Icons.link_outlined),
      _Stat(l.statBloodRequests, _bloodReq, Icons.bloodtype_outlined),
    ];

    return RefreshIndicator(
      onRefresh: _load,
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
                    _seeds == 0 ? l.seedCleanupNone : l.seedCleanupBody(_seeds),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          _seeds == 0 || _cleaning ? null : _confirmSeedCleanup,
                      icon: _cleaning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
    final color =
        s.highlight ? theme.colorScheme.error : theme.colorScheme.primary;
    return Card(
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
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final IconData icon;
  final bool highlight;

  _Stat(this.label, this.value, this.icon, {this.highlight = false});
}

import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../services/admin_service.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';

class AdminUsersTab extends StatefulWidget {
  final List<AppUser> users;
  final List<Listing> listings;
  final List<Report> reports;

  const AdminUsersTab({
    super.key,
    required this.users,
    required this.listings,
    required this.reports,
  });

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _admin = AdminService();
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppUser> get _visible {
    final q = _query.toLowerCase();
    final all = widget.users;
    if (q.isEmpty) return all;
    return all
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.wilaya.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _toggleUser(AppUser u) async {
    final loc = context.l10n;
    if (u.disabled) {
      final ok = await _run(() => _admin.setUserDisabled(u.uid, false));
      if (ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.userEnabledToast)));
      }
      return;
    }
    final reason = await _askDisableReason(loc);
    if (reason == null) return;
    final ok = await _run(
        () => _admin.setUserDisabled(u.uid, true, reason: reason));
    if (ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.userDisabledToast)));
    }
  }

  Future<String?> _askDisableReason(AppLocalizations loc) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.disableUserTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: loc.disableReasonHint,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(loc.disableAction),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
      return false;
    }
  }

  void _openDetail(AppUser u) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final userListings =
        widget.listings.where((s) => s.ownerId == u.uid).length;
    final filed = widget.reports.where((r) => r.reporterId == u.uid).length;
    final myListingIds =
        widget.listings.where((s) => s.ownerId == u.uid).map((s) => s.id).toSet();
    final against = widget.reports
        .where((r) => r.listingId.isNotEmpty && myListingIds.contains(r.listingId))
        .length;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      u.fullName.isNotEmpty
                          ? u.fullName.characters.first
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          u.email,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(l.userDetailPhone, u.contactPhone ?? '—'),
              _detailRow(l.userDetailLocation,
                  '${u.commune.isNotEmpty ? '${u.commune}, ' : ''}${u.wilaya}'),
              _detailRow(l.userDetailJoined, formatDate(u.createdAt)),
              if (u.disabled)
                _detailRow(
                    l.userDetailDisabledReason,
                    u.disabledReason?.isNotEmpty == true
                        ? u.disabledReason!
                        : '—'),
              const SizedBox(height: 8),
              Text(
                '${l.userListingsCount(userListings)}  •  ${l.userReportsFiled(filed)}  •  ${l.userReportsAgainst(against)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: u.disabled
                    ? FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _toggleUser(u);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l.enableAction),
                      )
                    : FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _toggleUser(u);
                        },
                        icon: const Icon(Icons.block),
                        label: Text(l.disableAction),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final visible = _visible;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: l.adminSearchUsers,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _search.clear(),
                    ),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyView(
                  icon: _query.isEmpty ? Icons.people_outlined : Icons.search_off,
                  message: _query.isEmpty ? l.noUsers : l.emptySearchResults,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final u = visible[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          u.disabled
                              ? Icons.block
                              : Icons.check_circle_outline,
                          color: u.disabled
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
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
                        onTap: () => _openDetail(u),
                        trailing: IconButton(
                          tooltip: u.disabled ? l.enableAction : l.disableAction,
                          icon: Icon(
                            u.disabled ? Icons.restart_alt : Icons.block,
                            color: u.disabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                          onPressed: () => _toggleUser(u),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

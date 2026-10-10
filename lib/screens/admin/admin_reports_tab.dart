import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../services/admin_service.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../utils/labels.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';

class AdminReportsTab extends StatefulWidget {
  final List<Report> reports;
  final List<Listing> listings;

  const AdminReportsTab({
    super.key,
    required this.reports,
    required this.listings,
  });

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _admin = AdminService();
  String _filter = reportStatusOpen;

  List<Report> get _visible => _filter == 'all'
      ? widget.reports
      : widget.reports.where((r) => r.status == _filter).toList();

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

  void _toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openContent(Report r) async {
    if (r.listingId.isEmpty) return;
    final exists = widget.listings.any((l) => l.id == r.listingId);
    if (!exists) {
      _toast(context.l10n.reportListingMissing);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListingDetailsScreen(listingId: r.listingId)),
    );
  }

  Future<void> _confirmDeleteContent(Report r) async {
    final loc = context.l10n;
    final theme = Theme.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.reportDeleteContentTitle),
        content: Text(loc.reportDeleteContentBody(r.listingTitle)),
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
    final ok = await _run(() => _admin.resolveReportWithContent(r));
    if (ok) _toast(loc.reportResolvedToast);
  }

  Future<void> _confirmDeleteReport(Report r) async {
    final loc = context.l10n;
    final theme = Theme.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.delete),
        content: Text(loc.reportPrefix(r.listingTitle)),
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
    await _run(() => _admin.deleteReport(r.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final visible = _visible;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(l.reportStatusOpen, reportStatusOpen),
                _filterChip(l.reportStatusResolved, reportStatusResolved),
                _filterChip(l.reportStatusDismissed, reportStatusDismissed),
                _filterChip(l.reportFilterAll, 'all'),
              ],
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyView(icon: Icons.flag_outlined, message: l.noReports)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => _reportCard(visible[i], l, theme),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _reportCard(Report r, AppLocalizations l, ThemeData theme) {
    final statusColor = r.isOpen
        ? theme.colorScheme.error
        : r.isResolved
            ? theme.colorScheme.primary
            : theme.colorScheme.outline;
    final statusLabel = r.isOpen
        ? l.reportStatusOpen
        : r.isResolved
            ? l.reportStatusResolved
            : l.reportStatusDismissed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.reportPrefix(r.listingTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.reportMeta(
                reportReasonLabel(context, r.reason),
                r.reporterName,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            if (r.description != null && r.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                r.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              formatDateTime(r.createdAt),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (r.listingId.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openContent(r),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l.reportOpenListing),
                  ),
                if (r.isOpen) ...[
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _run(() => _admin.setReportStatus(r.id, reportStatusResolved))
                            .then((_) => _toast(l.reportResolvedToast)),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(l.reportResolve),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _run(() => _admin.setReportStatus(r.id, reportStatusDismissed))
                            .then((_) => _toast(l.reportDismissedToast)),
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(l.reportDismiss),
                  ),
                  if (r.listingId.isNotEmpty)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => _confirmDeleteContent(r),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(l.reportDeleteContent),
                    ),
                ],
                IconButton(
                  tooltip: l.delete,
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error, size: 20),
                  onPressed: () => _confirmDeleteReport(r),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

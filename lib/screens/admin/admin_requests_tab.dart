import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/request_post.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';
import '../requests/request_details_screen.dart';

class AdminRequestsTab extends StatefulWidget {
  final List<RequestPost> requests;

  const AdminRequestsTab({super.key, required this.requests});

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<AdminRequestsTab> {
  String _kind = 'all';
  String _status = 'all';

  List<RequestPost> get _visible => widget.requests
      .where((r) =>
          (_kind == 'all' ||
              (_kind == requestKindBlood
                  ? r.isBlood
                  : r.kind == requestKindGeneral)) &&
          (_status == 'all' || r.status == _status))
      .toList();

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
                _chip(l.reportFilterAll, 'all', () => setState(() => _kind = 'all'),
                    selected: _kind == 'all'),
                _chip(l.reqKindGeneralLabel, requestKindGeneral,
                    () => setState(() => _kind = requestKindGeneral),
                    selected: _kind == requestKindGeneral),
                _chip(l.reqKindBlood, requestKindBlood,
                    () => setState(() => _kind = requestKindBlood),
                    selected: _kind == requestKindBlood),
                const SizedBox(width: 8),
                _chip(l.reqStatusOpen, requestStatusOpen,
                    () => setState(() => _status = requestStatusOpen),
                    selected: _status == requestStatusOpen),
                _chip(l.reqStatusMatched, requestStatusMatched,
                    () => setState(() => _status = requestStatusMatched),
                    selected: _status == requestStatusMatched),
                _chip(l.reqStatusClosed, requestStatusClosed,
                    () => setState(() => _status = requestStatusClosed),
                    selected: _status == requestStatusClosed),
                _chip(l.reportFilterAll, 'all',
                    () => setState(() => _status = 'all'),
                    selected: _status == 'all'),
              ],
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyView(icon: Icons.handshake_outlined, message: l.noRequests)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final r = visible[i];
                    final statusLabel = r.isOpen
                        ? l.reqStatusOpen
                        : r.isMatched
                            ? l.reqStatusMatched
                            : l.reqStatusClosed;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${r.userName} • ${r.wilaya} • ${_typeLabel(l, r)} • $statusLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Icon(
                          r.isBlood ? Icons.bloodtype : Icons.handshake_outlined,
                          color: r.isBlood
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RequestDetailsScreen(requestId: r.id),
                          ),
                        ),
                        trailing: Text(
                          formatDate(r.createdAt),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _typeLabel(AppLocalizations l, RequestPost r) =>
      r.isBlood
          ? '${l.reqKindBlood}${r.bloodType != null ? ' • ${r.bloodType}' : ''}'
          : (r.type == 'need' ? l.reqTypeNeed : l.reqTypeOffer);

  Widget _chip(
    String label,
    String value,
    VoidCallback onTap, {
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

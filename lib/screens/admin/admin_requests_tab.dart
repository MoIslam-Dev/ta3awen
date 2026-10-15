import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/request_post.dart';
import '../../services/admin_service.dart';
import '../../state/paged_list.dart';
import '../../utils/errors.dart';
import '../../widgets/state_views.dart';
import '../requests/request_details_screen.dart';

class AdminRequestsTab extends StatefulWidget {
  const AdminRequestsTab({super.key});

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<AdminRequestsTab>
    with AutomaticKeepAliveClientMixin {
  final _admin = AdminService();

  late final PagedList<RequestPost> _paged = PagedList<RequestPost>(
    headBuilder: (limit) => _admin.requestsHead(status: _status, limit: limit),
    moreBuilder: (cursor, limit) =>
        _admin.requestsMore(_status, cursor, limit: limit),
    idOf: (r) => r.id,
  );

  String? _status;
  String _kind = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _paged.start();
  }

  @override
  void dispose() {
    _paged.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _paged.start();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _loadMore() async {
    try {
      await _paged.loadMore();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dataErrorMessage(context, e))),
      );
    }
  }

  void _setStatus(String? status) {
    if (_status == status) return;
    setState(() => _status = status);
    _paged.start();
  }

  List<RequestPost> get _visible => _paged.items
      .where((r) =>
          _kind == 'all' ||
          (_kind == requestKindBlood
              ? r.isBlood
              : r.kind == requestKindGeneral))
      .toList();

  Future<void> _confirmDelete(RequestPost r) async {
    final loc = context.l10n;
    final theme = Theme.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.reqDeleteTitle),
        content: Text(loc.reqDeleteBody(r.title)),
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
    try {
      await _admin.deleteRequest(r.id);
      _paged.remove(r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    final theme = Theme.of(context);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _chip(l.reportFilterAll, 'all',
                  () => setState(() => _kind = 'all'),
                  selected: _kind == 'all'),
              _chip(l.reqKindGeneralLabel, requestKindGeneral,
                  () => setState(() => _kind = requestKindGeneral),
                  selected: _kind == requestKindGeneral),
              _chip(l.reqKindBlood, requestKindBlood,
                  () => setState(() => _kind = requestKindBlood),
                  selected: _kind == requestKindBlood),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _chip(l.reqStatusOpen, requestStatusOpen,
                  () => _setStatus(requestStatusOpen),
                  selected: _status == requestStatusOpen),
              _chip(l.reqStatusMatched, requestStatusMatched,
                  () => _setStatus(requestStatusMatched),
                  selected: _status == requestStatusMatched),
              _chip(l.reqStatusClosed, requestStatusClosed,
                  () => _setStatus(requestStatusClosed),
                  selected: _status == requestStatusClosed),
              _chip(l.reportFilterAll, 'all', () => _setStatus(null),
                  selected: _status == null),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _paged,
            builder: (context, _) {
              if (_paged.loading) return LoadingView(message: l.loading);
              final error = _paged.error;
              if (error != null) {
                return ErrorView(
                  message: dataErrorMessage(context, error),
                  onRetry: _load,
                );
              }
              final visible = _visible;
              if (visible.isEmpty) {
                return EmptyView(
                    icon: Icons.handshake_outlined, message: l.noRequests);
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length + (_paged.hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= visible.length) {
                      return LoadMoreFooter(
                        loading: _paged.loadingMore,
                        onLoadMore: _loadMore,
                      );
                    }
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
                          r.isBlood
                              ? Icons.bloodtype
                              : Icons.handshake_outlined,
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
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: theme.colorScheme.error),
                          onPressed: () => _confirmDelete(r),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _typeLabel(AppLocalizations l, RequestPost r) => r.isBlood
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

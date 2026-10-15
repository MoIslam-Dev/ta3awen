import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/listing.dart';
import '../../services/admin_service.dart';
import '../../state/paged_list.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';

class AdminListingsTab extends StatefulWidget {
  const AdminListingsTab({super.key});

  @override
  State<AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends State<AdminListingsTab>
    with AutomaticKeepAliveClientMixin {
  final _admin = AdminService();
  final _search = TextEditingController();

  late final PagedList<Listing> _paged = PagedList<Listing>(
    headBuilder: (limit) => _admin.listingsHead(status: _status, limit: limit),
    moreBuilder: (cursor, limit) =>
        _admin.listingsMore(_status, cursor, limit: limit),
    idOf: (l) => l.id,
  );

  String? _status;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
    _paged.start();
  }

  @override
  void dispose() {
    _paged.dispose();
    _search.dispose();
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

  List<Listing> get _visible {
    final q = _query.toLowerCase();
    if (q.isEmpty) return _paged.items;
    return _paged.items
        .where((l) =>
            l.title.toLowerCase().contains(q) ||
            l.ownerName.toLowerCase().contains(q) ||
            l.wilaya.toLowerCase().contains(q) ||
            l.id.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _confirmDelete(Listing l) async {
    final loc = context.l10n;
    final theme = Theme.of(context);
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
      await _admin.deleteListing(l.id);
      _paged.remove(l);
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: l.adminSearchListings,
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _chip(l.reportFilterAll, null),
              _chip(l.statusAvailable, statusAvailable),
              _chip(l.statusReserved, statusReserved),
              _chip(l.statusGiven, statusGiven),
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
                  icon: _query.isEmpty
                      ? Icons.inventory_2_outlined
                      : Icons.search_off,
                  message: _query.isEmpty ? l.noListings : l.emptySearchResults,
                );
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
                    final item = visible[i];
                    final seed = item.id.startsWith('seed-');
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.ownerName} • ${item.wilaya} • ${item.status} • ${formatDate(item.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: seed
                            ? Icon(Icons.science_outlined,
                                color: theme.colorScheme.outline)
                            : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ListingDetailsScreen(listingId: item.id),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: theme.colorScheme.error),
                          onPressed: () => _confirmDelete(item),
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

  Widget _chip(String label, String? value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _status == value,
        onSelected: (_) => _setStatus(value),
      ),
    );
  }
}

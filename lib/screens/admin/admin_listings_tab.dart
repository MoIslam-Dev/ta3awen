import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/listing.dart';
import '../../services/admin_service.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';

class AdminListingsTab extends StatefulWidget {
  final List<Listing> listings;

  const AdminListingsTab({super.key, required this.listings});

  @override
  State<AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends State<AdminListingsTab> {
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

  List<Listing> get _visible {
    final q = _query.toLowerCase();
    final all = widget.listings;
    if (q.isEmpty) return all;
    return all
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    }
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
        Expanded(
          child: visible.isEmpty
              ? EmptyView(
                  icon: _query.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
                  message: _query.isEmpty ? l.noListings : l.emptySearchResults,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
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
        ),
      ],
    );
  }
}

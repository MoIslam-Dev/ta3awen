import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../state/paged_list.dart';
import '../../utils/errors.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';
import '../listing/listing_form_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _service = ListingService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final PagedList<Listing>? _mine;
  late final PagedList<Listing>? _res;
  int _tab = 0;
  bool _loginError = false;

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    if (uid == null) {
      _loginError = true;
      _mine = null;
      _res = null;
      return;
    }
    _mine = PagedList<Listing>(
      headBuilder: (limit) => _service.myHead(uid, limit: limit),
      moreBuilder: (cursor, limit) => _service.myMore(uid, cursor, limit: limit),
      idOf: (l) => l.id,
    )..start();
    _res = PagedList<Listing>(
      headBuilder: (limit) => _service.reservationsHead(uid, limit: limit),
      moreBuilder: (cursor, limit) =>
          _service.reservationsMore(uid, cursor, limit: limit),
      idOf: (l) => l.id,
    );
  }

  @override
  void dispose() {
    _mine?.dispose();
    _res?.dispose();
    super.dispose();
  }

  void _ensureTab() {
    final res = _res;
    if (_tab == 1 && res != null && res.loading && res.isEmpty) {
      res.start();
    }
  }

  Future<void> _load() async {
    _active?.start();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _loadMore() async {
    try {
      await _active?.loadMore();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dataErrorMessage(context, e))),
      );
    }
  }

  PagedList<Listing>? get _active => _tab == 0 ? _mine : _res;

  void _snack(String Function(BuildContext) message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message(context))));
  }

  Future<void> _toggleStatus(Listing listing) async {
    final newStatus = listing.isAvailable ? statusGiven : statusAvailable;
    try {
      await _service.setStatus(listing.id, newStatus);
    } catch (e) {
      _snack((c) => dataErrorMessage(c, e));
    }
  }

  Future<void> _confirmDelivery(Listing listing) async {
    try {
      await _service.confirmDelivery(listing.id);
      _snack((c) => c.l10n.deliveryConfirmed);
    } catch (e) {
      _snack((c) => dataErrorMessage(c, e));
    }
  }

  Future<void> _release(Listing listing) async {
    try {
      await _service.cancelClaim(listing.id);
      _snack((c) => c.l10n.claimCancelled);
    } catch (e) {
      _snack((c) => dataErrorMessage(c, e));
    }
  }

  Future<void> _delete(Listing listing) async {
    final l = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteListingTitle),
        content: Text(l.deleteListingBody(listing.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _service.delete(listing.id);
      _active?.remove(listing);
      _snack((c) => c.l10n.listingDeleted);
    } catch (e) {
      _snack((c) => dataErrorMessage(context, e));
    }
  }

  Future<void> _edit(Listing listing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingFormScreen.edit(listing),
      ),
    );
  }

  Widget _segmentButton(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: 0,
            label: Text(l.tabMyListings),
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
          ),
          ButtonSegment(
            value: 1,
            label: Text(l.myReservations),
            icon: const Icon(Icons.bookmark_outline, size: 18),
          ),
        ],
        selected: {_tab},
        onSelectionChanged: (s) => setState(() {
          _tab = s.first;
          _ensureTab();
        }),
      ),
    );
  }

  Widget? _trailing(Listing listing, AppLocalizations l) {
    if (_tab == 1) {
      if (!listing.isReserved) return null;
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (v) async {
          if (v == 'release') await _release(listing);
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'release',
            child: ListTile(
              leading: const Icon(Icons.bookmark_remove_outlined),
              contentPadding: EdgeInsets.zero,
              title: Text(l.claimCancel),
            ),
          ),
        ],
      );
    }
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        switch (v) {
          case 'edit':
            await _edit(listing);
            break;
          case 'status':
            await _toggleStatus(listing);
            break;
          case 'confirm':
            await _confirmDelivery(listing);
            break;
          case 'release':
            await _release(listing);
            break;
          case 'delete':
            await _delete(listing);
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            contentPadding: EdgeInsets.zero,
            title: Text(l.edit),
          ),
        ),
        if (listing.isReserved) ...[
          PopupMenuItem(
            value: 'confirm',
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              contentPadding: EdgeInsets.zero,
              title: Text(l.confirmDelivery),
            ),
          ),
          PopupMenuItem(
            value: 'release',
            child: ListTile(
              leading: const Icon(Icons.lock_open_outlined),
              contentPadding: EdgeInsets.zero,
              title: Text(l.claimRelease),
            ),
          ),
        ] else
          PopupMenuItem(
            value: 'status',
            child: ListTile(
              leading: Icon(listing.isAvailable
                  ? Icons.volunteer_activism_outlined
                  : Icons.undo_outlined),
              contentPadding: EdgeInsets.zero,
              title: Text(listing.isAvailable ? l.markGiven : l.markAvailable),
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(ctx).colorScheme.error,
            ),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.delete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_loginError) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tabMyListings)),
        body: EmptyView(icon: Icons.lock_outline, message: l.loginRequired),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.tabMyListings)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _segmentButton(l),
          Expanded(child: _buildList(l)),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l) {
    final paged = _active!;
    return ListenableBuilder(
      listenable: paged,
      builder: (context, _) {
        if (paged.loading) {
          return const SkeletonList(kind: SkeletonKind.listing);
        }
        final error = paged.error;
        if (error != null) {
          return ErrorView(
            message: dataErrorMessage(context, error),
            onRetry: _load,
          );
        }
        if (paged.isEmpty) {
          return RefreshIndicator(
            onRefresh: _load,
            child: EmptyView(
              icon: _tab == 0
                  ? Icons.playlist_add_outlined
                  : Icons.bookmark_outline,
              message: _tab == 0 ? l.myListingsEmpty : l.reservationsEmpty,
              action: _tab == 0
                  ? FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ListingFormScreen.create(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l.addFirstListing),
                    )
                  : null,
            ),
          );
        }
        final items = paged.items;
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: items.length + (paged.hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= items.length) {
                return LoadMoreFooter(
                  loading: paged.loadingMore,
                  onLoadMore: _loadMore,
                );
              }
              final listing = items[i];
              return ListingCard(
                listing: listing,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ListingDetailsScreen(listingId: listing.id),
                    ),
                  );
                },
                trailing: _trailing(listing, l),
              );
            },
          ),
        );
      },
    );
  }
}

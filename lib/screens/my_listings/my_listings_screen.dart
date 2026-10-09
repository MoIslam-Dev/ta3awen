import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../utils/errors.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';
import '../listing/listing_form_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with AutomaticKeepAliveClientMixin {
  final _service = ListingService();
  List<Listing> _items = [];
  List<Listing> _reservations = [];
  int _tab = 0;
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Listing>>? _sub;
  StreamSubscription<List<Listing>>? _resSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _resSub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
    _resSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = context.l10n.loginRequired;
      });
      return;
    }
    _sub = _service.myStream(uid).listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = dataErrorMessage(context, e);
          _loading = false;
        });
      },
    );
    _resSub = _service.reservationsStream(uid).listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _reservations = items;
          _loading = false;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = dataErrorMessage(context, e);
          _loading = false;
        });
      },
    );
  }

  /// Re-subscribes; used by pull-to-refresh and the error retry button.
  Future<void> _load() async {
    _subscribe();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _snack(String Function(BuildContext) message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message(context))));
  }

  Future<void> _toggleStatus(Listing listing) async {
    final newStatus =
        listing.isAvailable ? 'تم التبرع به' : 'متاح';
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

  /// Owner releases a claimant's reservation (or the claimant cancels
  /// their own — same security path, same message).
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
      _snack((c) => c.l10n.listingDeleted);
    } catch (e) {
      _snack((c) => dataErrorMessage(c, e));
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
        onSelectionChanged: (s) => setState(() => _tab = s.first),
      ),
    );
  }

  Widget? _trailing(Listing listing, AppLocalizations l) {
    if (_tab == 1) {
      // Reservations: only actionable while still reserved by me.
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
    // My listings: status-aware actions.
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
              title: Text(listing.isAvailable
                  ? l.markGiven
                  : l.markAvailable),
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
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    if (_loading) return LoadingView(message: l.loading);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final items = _tab == 0 ? _items : _reservations;
    final empty = items.isEmpty
        ? RefreshIndicator(
            onRefresh: _load,
            child: EmptyView(
              icon: _tab == 0
                  ? Icons.playlist_add_outlined
                  : Icons.bookmark_outline,
              message:
                  _tab == 0 ? l.myListingsEmpty : l.reservationsEmpty,
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
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: items.length,
              itemBuilder: (context, i) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _segmentButton(l),
        Expanded(child: empty),
      ],
    );
  }
}

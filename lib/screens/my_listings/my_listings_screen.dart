import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
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
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Listing>>? _sub;

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
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
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
  }

  /// Re-subscribes; used by pull-to-refresh and the error retry button.
  Future<void> _load() async {
    _subscribe();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _toggleStatus(Listing listing) async {
    final newStatus =
        listing.isAvailable ? 'تم التبرع به' : 'متاح';
    try {
      await _service.setStatus(listing.id, newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.listingDeleted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    }
  }

  Future<void> _edit(Listing listing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingFormScreen.edit(listing),
      ),
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
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(
          icon: Icons.playlist_add_outlined,
          message: l.myListingsEmpty,
          action: FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ListingFormScreen.create(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(l.addFirstListing),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final listing = _items[i];
          return ListingCard(
            listing: listing,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListingDetailsScreen(listingId: listing.id),
                ),
              );
            },
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    await _edit(listing);
                    break;
                  case 'status':
                    await _toggleStatus(listing);
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
            ),
          );
        },
      ),
    );
  }
}

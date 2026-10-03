import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
        _error = 'يجب تسجيل الدخول';
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
          _error = dataErrorMessage(e);
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
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(e))));
      }
    }
  }

  Future<void> _delete(Listing listing) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('هل تريد حذف "${listing.title}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _service.delete(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حذف الإعلان')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(e))));
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
    if (_loading) return const LoadingView(message: 'جاري التحميل...');
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(
          icon: Icons.playlist_add_outlined,
          message: 'لم تنشر أي إعلان بعد',
            action: FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ListingFormScreen.create(),
                  ),
                );
              },
              child: const Text('أضف إعلانك الأول'),
            ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                PopupMenuItem(
                  value: 'status',
                  child: Text(listing.isAvailable
                      ? 'تعليم كـ "تم التبرع به"'
                      : 'إعادة إلى "متاح"'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/algeria_data.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 20;

  final _service = ListingService();
  final _searchCtrl = TextEditingController();

  /// Live head region: the newest matches, kept up to date by the head
  /// stream (items pushed out of the server window stay until refresh).
  List<Listing> _head = [];

  /// Older pages loaded via the المزيد button (one-shot, no live updates).
  List<Listing> _tail = [];

  bool _loading = true;
  String? _error;
  String? _category;
  String? _wilaya;
  String? _commune;
  String _query = '';
  String _rawQuery = '';
  FeedQuery _feedQuery = const FeedQuery();
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  StreamSubscription<FeedPage>? _sub;
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  FeedQuery _currentQuery() => FeedQuery(
        search: _query.isEmpty ? null : _query,
        category: _category,
        wilaya: _wilaya,
        commune: _commune,
      );

  /// Cancels everything and restarts from page 1 with the current query —
  /// used on init, filter/search changes, pull-to-refresh and retry.
  void _subscribe() {
    _debounce?.cancel();
    _sub?.cancel();
    _feedQuery = _currentQuery();
    _head = [];
    _tail = [];
    _cursor = null;
    _hasMore = false;
    _loadingMore = false;
    _loading = true;
    _error = null;
    _sub = _service.feedHead(_feedQuery, limit: _pageSize).listen(
      (page) {
        if (!mounted) return;
        final boundary = page.boundary;
        setState(() {
          _head = [
            ...page.items,
            // Keep previously seen items older than the new window edge;
            // drop ones the server no longer returns (deleted / status
            // changed) that sat inside the window.
            ..._head.where((l) =>
                !page.rawIds.contains(l.id) &&
                boundary != null &&
                l.createdAt != null &&
                l.createdAt!.isBefore(boundary)),
          ];
          if (_cursor == null) {
            _cursor = page.cursor;
            _hasMore = page.hasMore;
          }
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page =
          await _service.feedMore(_feedQuery, _cursor!, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        final seen = <String>{
          for (final l in _head) l.id,
          for (final l in _tail) l.id,
        };
        _tail.addAll(page.items.where((l) => !seen.contains(l.id)));
        if (page.hasMore) _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dataErrorMessage(e))),
      );
    }
  }

  bool get _hasFilters =>
      _category != null ||
      _wilaya != null ||
      _commune != null ||
      _query.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _category = null;
      _wilaya = null;
      _commune = null;
      _query = '';
      _rawQuery = '';
      _searchCtrl.clear();
    });
    _subscribe();
  }

  void _onSearchChanged(String v) {
    setState(() => _rawQuery = v);
    final trimmed = v.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (trimmed == _query) return;
      setState(() => _query = trimmed);
      _subscribe();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
    });
    _subscribe();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث عن إعلان...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _rawQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              FilterChip(
                label: Text(_category ?? 'التصنيف'),
                selected: _category != null,
                avatar: const Icon(Icons.category_outlined, size: 18),
                onSelected: (_) => _pickCategory(),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_wilaya ?? 'الولاية'),
                selected: _wilaya != null,
                avatar: const Icon(Icons.place_outlined, size: 18),
                onSelected: (_) => _pickWilaya(),
              ),
              if (_wilaya != null) ...[
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_commune ?? 'البلدية'),
                  selected: _commune != null,
                  avatar: const Icon(Icons.location_city_outlined, size: 18),
                  onSelected: (_) => _pickCommune(),
                ),
              ],
              if (_hasFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.close, size: 18),
                  label: const Text('مسح'),
                  onPressed: _clearFilters,
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'جاري تحميل الإعلانات...');
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final items = [..._head, ..._tail];
    if (items.isEmpty && !_hasMore) {
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(
          icon: Icons.inventory_2_outlined,
          message: _hasFilters
              ? 'لا توجد نتائج مطابقة للبحث'
              : 'لا توجد إعلانات بعد، كن أول من ينشر إعلاناً',
          action: _hasFilters
              ? OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('مسح عوامل التصفية'),
                )
              : null,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: _loadMore,
                        child: const Text('المزيد'),
                      ),
              ),
            );
          }
          final listing = items[i];
          return ListingCard(
            listing: listing,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListingDetailsScreen(listingId: listing.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('كل التصنيفات'),
              leading: const Icon(Icons.category_outlined),
              onTap: () => Navigator.pop(ctx, '__all__'),
            ),
            ...kCategories.map(
              (c) => ListTile(
                title: Text(c),
                selected: _category == c,
                onTap: () => Navigator.pop(ctx, c),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _category = selected == '__all__' ? null : selected;
    });
    _subscribe();
  }

  Future<void> _pickWilaya() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('كل الولايات'),
              leading: const Icon(Icons.place_outlined),
              onTap: () => Navigator.pop(ctx, '__all__'),
            ),
            ...AlgeriaData.wilayas.map(
              (w) => ListTile(
                title: Text(w),
                selected: _wilaya == w,
                onTap: () => Navigator.pop(ctx, w),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _wilaya = selected == '__all__' ? null : selected;
      _commune = null;
    });
    _subscribe();
  }

  Future<void> _pickCommune() async {
    if (_wilaya == null) return;
    final communes = AlgeriaData.communesOf(_wilaya!);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('كل البلديات'),
              leading: const Icon(Icons.location_city_outlined),
              onTap: () => Navigator.pop(ctx, '__all__'),
            ),
            ...communes.map(
              (c) => ListTile(
                title: Text(c),
                selected: _commune == c,
                onTap: () => Navigator.pop(ctx, c),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _commune = selected == '__all__' ? null : selected;
    });
    _subscribe();
  }
}

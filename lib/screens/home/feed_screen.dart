import 'dart:async';

import 'package:flutter/material.dart';
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
  final _service = ListingService();
  final _searchCtrl = TextEditingController();

  List<Listing> _all = [];
  bool _loading = true;
  String? _error;
  String? _category;
  String? _wilaya;
  String? _commune;
  String _query = '';
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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = _service.recentStream().listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _all = items;
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

  bool get _hasFilters => _category != null ||
        _wilaya != null ||
        _commune != null ||
        _query.isNotEmpty;

  List<Listing> get _filtered {
    return _all.where((l) {
      if (!l.isAvailable) return false;
      if (_category != null && l.category != _category) return false;
      if (_wilaya != null && l.wilaya != _wilaya) return false;
      if (_commune != null && l.commune != _commune) return false;
      if (_query.isNotEmpty && !l.title.contains(_query)) return false;
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _category = null;
      _wilaya = null;
      _commune = null;
      _query = '';
      _searchCtrl.clear();
    });
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
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
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
    final items = _filtered;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(
          icon: Icons.inventory_2_outlined,
          message: _hasFilters || _query.isNotEmpty
              ? 'لا توجد نتائج مطابقة للبحث'
              : 'لا توجد إعلانات بعد، كن أول من ينشر إعلاناً',
          action: _hasFilters || _query.isNotEmpty
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
        itemCount: items.length,
        itemBuilder: (context, i) {
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
  }
}

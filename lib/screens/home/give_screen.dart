import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/algeria_data.dart';
import '../../l10n/ext.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../utils/labels.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';

/// "أعطي" — everything the community gives away: free donations and
/// barters. The intent (donation / exchange) is the screen's primary
/// segmented control; categories and location are secondary filters.
class GiveScreen extends StatefulWidget {
  const GiveScreen({super.key});

  @override
  State<GiveScreen> createState() => _GiveScreenState();
}

class _GiveScreenState extends State<GiveScreen>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 20;
  static const String _all = '__all__';

  final _service = ListingService();
  final _searchCtrl = TextEditingController();

  List<Listing> _head = [];
  List<Listing> _tail = [];

  bool _loading = true;
  String? _error;
  String _kind = _all;
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
        kind: _kind == _all ? null : _kind,
      );

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
          _error = dataErrorMessage(context, e);
          _loading = false;
        });
      },
    );
  }

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
        SnackBar(content: Text(dataErrorMessage(context, e))),
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

  void _selectKind(String kind) {
    if (_kind == kind) return;
    setState(() => _kind = kind);
    _subscribe();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _all, label: Text(l.filterAll)),
              ButtonSegment(
                value: listingKindDonation,
                label: Text(l.giveDonate),
              ),
              ButtonSegment(
                value: listingKindExchange,
                label: Text(l.giveExchange),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => _selectKind(s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.searchHint,
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
          height: 68,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              FilterChip(
                label: Text(
                  _category != null
                      ? categoryLabel(context, _category!)
                      : l.filterCategory,
                ),
                selected: _category != null,
                avatar: Icon(
                  Icons.category_outlined,
                  size: 18,
                  color: _category != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (_) => _pickCategory(),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_wilaya ?? l.filterWilaya),
                selected: _wilaya != null,
                avatar: Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: _wilaya != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (_) => _pickWilaya(),
              ),
              if (_wilaya != null) ...[
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_commune ?? l.filterCommune),
                  selected: _commune != null,
                  avatar: Icon(
                    Icons.location_city_outlined,
                    size: 18,
                    color: _commune != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (_) => _pickCommune(),
                ),
              ],
              if (_hasFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.close, size: 18),
                  label: Text(l.clear),
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
    final l = context.l10n;
    if (_loading) return LoadingView(message: l.loadingFeed);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final items = [..._head, ..._tail];
    if (items.isEmpty && !_hasMore) {
      final filtered = _hasFilters || _kind != _all;
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(
          icon: _kind == listingKindExchange
              ? Icons.swap_horiz
              : Icons.inventory_2_outlined,
          message: filtered ? l.noResults : l.emptyFeed,
          action: filtered
              ? OutlinedButton(
                  onPressed: () {
                    setState(() => _kind = _all);
                    _clearFilters();
                  },
                  child: Text(l.clearFilters),
                )
              : null,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 80),
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
                        child: Text(l.loadMore),
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

  Widget _sheetOption(
    BuildContext ctx, {
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(ctx).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }

  Future<void> _pickCategory() async {
    final l = context.l10n;
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            _sheetOption(ctx,
                title: l.allCategories,
                icon: Icons.category_outlined,
                selected: false,
                onTap: () => Navigator.pop(ctx, '__all__')),
            ...kCategories.map(
              (c) => _sheetOption(ctx,
                  title: categoryLabel(ctx, c),
                  icon: Icons.category_outlined,
                  selected: _category == c,
                  onTap: () => Navigator.pop(ctx, c)),
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
    final l = context.l10n;
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            _sheetOption(ctx,
                title: l.allWilayas,
                icon: Icons.place_outlined,
                selected: false,
                onTap: () => Navigator.pop(ctx, '__all__')),
            ...AlgeriaData.wilayas.map(
              (w) => _sheetOption(ctx,
                  title: w,
                  icon: Icons.place_outlined,
                  selected: _wilaya == w,
                  onTap: () => Navigator.pop(ctx, w)),
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
    final l = context.l10n;
    final communes = AlgeriaData.communesOf(_wilaya!);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            _sheetOption(ctx,
                title: l.allCommunes,
                icon: Icons.location_city_outlined,
                selected: false,
                onTap: () => Navigator.pop(ctx, '__all__')),
            ...communes.map(
              (c) => _sheetOption(ctx,
                  title: c,
                  icon: Icons.location_city_outlined,
                  selected: _commune == c,
                  onTap: () => Navigator.pop(ctx, c)),
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

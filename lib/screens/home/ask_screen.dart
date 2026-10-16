import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/request_post.dart';
import '../../services/auth_service.dart';
import '../../services/request_service.dart';
import '../../state/paged_list.dart';
import '../../utils/errors.dart';
import '../../utils/request_filters.dart';
import '../../widgets/location_filter_chips.dart';
import '../../widgets/request_card.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../requests/request_details_screen.dart';

/// "أطلب" — the community board of open general posts: what people need
/// and what they offer. Blood lives on its own screen. Reads are paged.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen>
    with AutomaticKeepAliveClientMixin {
  static const String _all = '__all__';

  final _service = RequestService();
  final _searchCtrl = TextEditingController();

  late final PagedList<RequestPost> _paged = PagedList<RequestPost>(
    headBuilder: (limit) => _service.boardHead(
      kind: requestKindGeneral,
      type: _type == _all ? null : _type,
      limit: limit,
    ),
    moreBuilder: (cursor, limit) => _service.boardMore(
      kind: requestKindGeneral,
      type: _type == _all ? null : _type,
      cursor: cursor,
      limit: limit,
    ),
    idOf: (r) => r.id,
  );

  String _type = _all;
  String? _wilaya;
  String? _commune;
  String _query = '';
  String _rawQuery = '';
  String? _loginError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (AuthService.uid == null) {
      _loginError = 'login'; // resolved in build with l10n
    } else {
      _paged.start();
    }
  }

  @override
  void dispose() {
    _paged.dispose();
    _searchCtrl.dispose();
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

  bool get _hasFilters =>
      _query.isNotEmpty || _wilaya != null || _commune != null;

  void _clearFilters() {
    setState(() {
      _wilaya = null;
      _commune = null;
      _query = '';
      _rawQuery = '';
      _searchCtrl.clear();
    });
  }

  void _onSearchChanged(String v) {
    setState(() => _rawQuery = v);
    final trimmed = v.trim();
    if (trimmed == _query) return;
    setState(() => _query = trimmed);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
    });
  }

  void _selectType(String type) {
    if (_type == type) return;
    setState(() => _type = type);
    _paged.start();
  }

  List<RequestPost> get _items => filterRequests(
        _paged.items,
        bloodSeparation: false,
        wilaya: _wilaya,
        commune: _commune,
        query: _query,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    if (_loginError != null) {
      return EmptyView(icon: Icons.lock_outline, message: l.loginRequired);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _all, label: Text(l.filterAll)),
              ButtonSegment(
                value: requestTypeNeed,
                label: Text(l.reqTypeNeed),
              ),
              ButtonSegment(
                value: requestTypeOffer,
                label: Text(l.reqTypeOffer),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => _selectType(s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.reqSearchHint,
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
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: LocationFilterChips(
                  wilaya: _wilaya,
                  commune: _commune,
                  onWilayaChanged: (w) => setState(() {
                    _wilaya = w;
                    _commune = null;
                  }),
                  onCommuneChanged: (c) => setState(() => _commune = c),
                ),
              ),
              if (_hasFilters)
                ActionChip(
                  avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(l.clearFilters),
                  onPressed: _clearFilters,
                ),
            ],
          ),
        ),
        Expanded(child: _buildBody(l)),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l) {
    return ListenableBuilder(
      listenable: _paged,
      builder: (context, _) {
        if (_paged.loading) {
          return const SkeletonList(kind: SkeletonKind.request);
        }
        final error = _paged.error;
        if (error != null) {
          return ErrorView(
            message: dataErrorMessage(context, error),
            onRetry: _load,
          );
        }
        final items = _items;
        final filtered = _hasFilters || _type != _all;
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _load,
            child: EmptyView(
              icon: filtered ? Icons.search_off : Icons.forum_outlined,
              message: filtered ? l.noResults : l.reqEmptyBoard,
              action: filtered
                  ? OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _type = _all);
                        _clearFilters();
                        _paged.start();
                      },
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: Text(l.clearFilters),
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
            itemCount: items.length + (_paged.hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= items.length) {
                return LoadMoreFooter(
                  loading: _paged.loadingMore,
                  onLoadMore: _loadMore,
                );
              }
              final request = items[i];
              return RequestCard(
                request: request,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestDetailsScreen(requestId: request.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

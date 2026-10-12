import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/request_post.dart';
import '../../services/request_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../utils/request_filters.dart';
import '../../widgets/location_filter_chips.dart';
import '../../widgets/request_card.dart';
import '../../widgets/state_views.dart';
import '../requests/request_details_screen.dart';
import '../requests/request_form_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with AutomaticKeepAliveClientMixin {
  final _service = RequestService();
  final _searchCtrl = TextEditingController();

  /// 0 = public board (open posts), 1 = my posts (any status).
  int _segment = 0;

  /// Board type filter for general posts: null = all, otherwise need / offer.
  String? _typeFilter;

  /// When true the board shows only blood donation posts.
  bool _bloodBoard = false;

  /// Optional blood-type narrowing on the blood board (client-side).
  String? _bloodTypeFilter;

  /// Location narrowing on the general board (client-side).
  String? _wilaya;
  String? _commune;

  String _query = '';
  String _rawQuery = '';

  List<RequestPost> _board = [];
  List<RequestPost> _mine = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<RequestPost>>? _boardSub;
  StreamSubscription<List<RequestPost>>? _mineSub;
  Timer? _debounce;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
    _boardSub?.cancel();
    _mineSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _subscribe() {
    _debounce?.cancel();
    _boardSub?.cancel();
    _mineSub?.cancel();
    final uid = _uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = context.l10n.loginRequired;
      });
      return;
    }
    _boardSub = _service
        .boardStream(
          type: _bloodBoard ? null : _typeFilter,
          kind: _bloodBoard ? requestKindBlood : null,
        )
        .listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _board = items;
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
    _mineSub = _service.myStream(uid).listen(
      (items) {
        if (!mounted) return;
        setState(() => _mine = items);
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() => _error = dataErrorMessage(context, e));
      },
    );
  }

  /// Re-subscribes; used by pull-to-refresh and the error retry button.
  Future<void> _load() async {
    _subscribe();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _onSearchChanged(String v) {
    setState(() => _rawQuery = v);
    final trimmed = v.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (trimmed == _query) return;
      setState(() => _query = trimmed);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
    });
  }

  bool get _hasBoardFilters =>
      _query.isNotEmpty ||
      _typeFilter != null ||
      _bloodTypeFilter != null ||
      _wilaya != null ||
      _commune != null;

  /// Clears every board narrowing (search, type, blood type, location) and
  /// restores the server stream when a server-side type filter was active.
  void _clearBoardFilters() {
    _debounce?.cancel();
    final needsResub = _typeFilter != null;
    _searchCtrl.clear();
    setState(() {
      _rawQuery = '';
      _query = '';
      _typeFilter = null;
      _bloodTypeFilter = null;
      _wilaya = null;
      _commune = null;
    });
    // _segment == 1 (my requests) never sets a type filter, so this is a
    // board-only concern.
    if (needsResub) _subscribe();
  }

  /// The visible posts, after all board-side rules are applied.
  ///
  /// The general board never mixes blood posts, the blood board shows blood
  /// posts only, and "My requests" shows every post owned by the user (only
  /// narrowed by the search box).
  List<RequestPost> get _items {
    final onBoard = _segment == 0;
    return filterRequests(
      onBoard ? _board : _mine,
      bloodSeparation: onBoard,
      bloodBoard: onBoard && _bloodBoard,
      typeFilter: onBoard && !_bloodBoard ? _typeFilter : null,
      bloodTypeFilter: _bloodBoard ? _bloodTypeFilter : null,
      wilaya: onBoard && !_bloodBoard ? _wilaya : null,
      commune: onBoard && !_bloodBoard ? _commune : null,
      query: _query,
    );
  }

  void _selectType(String? type) {
    if (!_bloodBoard && _typeFilter == type) return;
    setState(() {
      _bloodBoard = false;
      _bloodTypeFilter = null;
      _typeFilter = type;
    });
    _subscribe();
  }

  void _selectBloodBoard() {
    if (_bloodBoard) return;
    setState(() {
      _bloodBoard = true;
      _typeFilter = null;
      _bloodTypeFilter = null;
    });
    _subscribe();
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequestFormScreen.create(initialType: _typeFilter),
      ),
    );
  }

  void _openCreateBlood() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RequestFormScreen.create(
          initialKind: requestKindBlood,
        ),
      ),
    );
  }

  Widget _boardChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _chipRow({required List<Widget> children}) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: children,
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
    final items = _items;
    final onBoard = _segment == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 0,
                label: Text(l.reqSegmentBoard),
                icon: const Icon(Icons.forum_outlined, size: 18),
              ),
              ButtonSegment(
                value: 1,
                label: Text(l.reqSegmentMine),
                icon: const Icon(Icons.person_pin_outlined, size: 18),
              ),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => setState(() => _segment = s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
        if (onBoard) ...[
          // Board scope chips: general / need / offer / blood, plus a
          // clear-filter action whenever anything narrows the board.
          _chipRow(
            children: [
              _boardChip(
                label: l.reqKindGeneralLabel,
                selected: !_bloodBoard && _typeFilter == null,
                onTap: () => _selectType(null),
              ),
              _boardChip(
                label: l.reqTypeNeed,
                selected: !_bloodBoard && _typeFilter == requestTypeNeed,
                onTap: () => _selectType(requestTypeNeed),
              ),
              _boardChip(
                label: l.reqTypeOffer,
                selected: !_bloodBoard && _typeFilter == requestTypeOffer,
                onTap: () => _selectType(requestTypeOffer),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  avatar: const Icon(Icons.bloodtype_outlined, size: 18),
                  label: Text(l.reqKindBlood),
                  selected: _bloodBoard,
                  onSelected: (_) => _selectBloodBoard(),
                ),
              ),
              if (_hasBoardFilters)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: Text(l.clearFilters),
                    onPressed: _clearBoardFilters,
                  ),
                ),
            ],
          ),
          // Location narrowing on the general board.
          if (!_bloodBoard)
            _chipRow(
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
              ],
            ),
          // Blood board: quick create + blood-type narrowing.
          if (_bloodBoard)
            _chipRow(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l.reqAddBlood),
                    onPressed: _openCreateBlood,
                  ),
                ),
                _boardChip(
                  label: l.reqTypeAll,
                  selected: _bloodTypeFilter == null,
                  onTap: () => setState(() => _bloodTypeFilter = null),
                ),
                for (final t in kBloodTypes)
                  _boardChip(
                    label: t,
                    selected: _bloodTypeFilter == t,
                    onTap: () => setState(() => _bloodTypeFilter = t),
                  ),
              ],
            ),
        ],
        Expanded(child: _buildBody(items, l)),
      ],
    );
  }

  Widget _buildBody(List<RequestPost> items, AppLocalizations l) {
    if (items.isEmpty) {
      final boarded = _segment == 0;
      final filtered = boarded && _hasBoardFilters;
      final IconData icon;
      final String empty;
      Widget? action;
      if (_segment == 1) {
        icon = Icons.person_pin_outlined;
        empty = l.reqEmptyMine;
        action = FilledButton.tonalIcon(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: Text(l.reqAddFirst),
        );
      } else if (_bloodBoard && !filtered) {
        icon = Icons.bloodtype_outlined;
        empty = l.reqBloodEmpty;
        action = FilledButton.tonalIcon(
          onPressed: _openCreateBlood,
          icon: const Icon(Icons.bloodtype_outlined),
          label: Text(l.reqAddBlood),
        );
      } else if (!_bloodBoard && !filtered) {
        icon = Icons.forum_outlined;
        empty = l.reqEmptyBoard;
        action = FilledButton.tonalIcon(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: Text(l.reqAddFirst),
        );
      } else {
        icon = Icons.search_off;
        empty = l.noResults;
        action = OutlinedButton.icon(
          onPressed: _clearBoardFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: Text(l.clearFilters),
        );
      }
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(icon: icon, message: empty, action: action),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: items.length,
        itemBuilder: (context, i) {
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
  }
}
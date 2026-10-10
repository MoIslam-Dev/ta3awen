import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/request_post.dart';
import '../../services/request_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
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

  List<RequestPost> get _visible {
    var source = _segment == 0 ? _board : _mine;
    // The need/offer chips mean "general" posts only; blood posts are
    // type need but live behind the dedicated Blood chip.
    if (_segment == 0 && !_bloodBoard && _typeFilter != null) {
      source = source.where((r) => !r.isBlood).toList();
    }
    if (_segment == 0 && _bloodBoard && _bloodTypeFilter != null) {
      source = source.where((r) => r.bloodType == _bloodTypeFilter).toList();
    }
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return source.where((r) {
      final hay =
          '${r.title} ${r.description} ${r.category} ${r.wilaya} ${r.commune}'
              .toLowerCase();
      return hay.contains(q);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    if (_loading) return LoadingView(message: l.loading);
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final items = _visible;
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
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // General type chips (All / need / offer) — mutually
              // exclusive with the Blood board.
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(l.reqTypeAll),
                  selected: !_bloodBoard && _typeFilter == null,
                  onSelected: (_) {
                    if (!_bloodBoard && _typeFilter == null) return;
                    setState(() {
                      _bloodBoard = false;
                      _bloodTypeFilter = null;
                      _typeFilter = null;
                    });
                    _subscribe();
                  },
                ),
              ),
              for (final entry in [
                (requestTypeNeed, l.reqTypeNeed),
                (requestTypeOffer, l.reqTypeOffer),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: !_bloodBoard && _typeFilter == entry.$1,
                    onSelected: (_) {
                      if (!_bloodBoard && _typeFilter == entry.$1) return;
                      setState(() {
                        _bloodBoard = false;
                        _bloodTypeFilter = null;
                        _typeFilter = entry.$1;
                      });
                      _subscribe();
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  avatar: const Icon(Icons.bloodtype_outlined, size: 18),
                  label: Text(l.reqKindBlood),
                  selected: _bloodBoard,
                  onSelected: (_) {
                    if (_bloodBoard) return;
                    setState(() {
                      _bloodBoard = true;
                      _typeFilter = null;
                      _bloodTypeFilter = null;
                    });
                    _subscribe();
                  },
                ),
              ),
            ],
          ),
        ),
        if (_bloodBoard)
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l.reqAddBlood),
                    onPressed: _openCreateBlood,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(l.reqTypeAll),
                    selected: _bloodTypeFilter == null,
                    onSelected: (_) =>
                        setState(() => _bloodTypeFilter = null),
                  ),
                ),
                for (final t in kBloodTypes)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _bloodTypeFilter == t,
                      onSelected: (_) =>
                          setState(() => _bloodTypeFilter = t),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: _buildBody(items, l)),
      ],
    );
  }

  Widget _buildBody(List<RequestPost> items, AppLocalizations l) {
    if (items.isEmpty) {
      final filtered = _query.isNotEmpty ||
          _typeFilter != null ||
          _bloodTypeFilter != null;
      final String empty;
      if (_segment == 1) {
        empty = l.reqEmptyMine;
      } else if (_bloodBoard && !filtered) {
        empty = l.reqBloodEmpty;
      } else {
        empty = l.noResults;
      }
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(
          icon: _bloodBoard
              ? Icons.bloodtype_outlined
              : _segment == 0
                  ? Icons.forum_outlined
                  : Icons.person_pin_outlined,
          message: empty,
          action: _segment == 1
              ? FilledButton.tonalIcon(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add),
                  label: Text(l.reqAddFirst),
                )
              : (_bloodBoard && !filtered
                  ? FilledButton.tonalIcon(
                      onPressed: _openCreateBlood,
                      icon: const Icon(Icons.bloodtype_outlined),
                      label: Text(l.reqAddBlood),
                    )
                  : null),
        ),
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

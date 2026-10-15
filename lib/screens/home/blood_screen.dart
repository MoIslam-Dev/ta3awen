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
import '../../widgets/request_card.dart';
import '../../widgets/state_views.dart';
import '../requests/request_details_screen.dart';
import '../requests/request_form_screen.dart';

/// "الدم" — the dedicated blood-donation board. Urgency deserves its own
/// door: a red-accented screen with one-tap blood-type narrowing.
class BloodScreen extends StatefulWidget {
  const BloodScreen({super.key});

  @override
  State<BloodScreen> createState() => _BloodScreenState();
}

class _BloodScreenState extends State<BloodScreen>
    with AutomaticKeepAliveClientMixin {
  final _service = RequestService();
  final _searchCtrl = TextEditingController();

  String? _bloodType;
  String _query = '';
  String _rawQuery = '';

  List<RequestPost> _board = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<RequestPost>>? _sub;
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

  void _subscribe() {
    _debounce?.cancel();
    _sub?.cancel();
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _loading = false;
        _error = context.l10n.loginRequired;
      });
      return;
    }
    _sub = _service.boardStream(kind: requestKindBlood).listen(
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
  }

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

  Future<void> _openCreateBlood() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RequestFormScreen.create(
          initialKind: requestKindBlood,
        ),
      ),
    );
  }

  List<RequestPost> get _items => filterRequests(
        _board,
        bloodSeparation: false,
        bloodBoard: true,
        bloodTypeFilter: _bloodType,
        query: _query,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    if (_loading) return LoadingView(message: l.loading);
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final items = _items;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
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
            ],
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
                child: FilledButton.tonalIcon(
                  onPressed: _openCreateBlood,
                  icon: const Icon(Icons.bloodtype_outlined, size: 18),
                  label: Text(l.reqAddBlood),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
              ChoiceChip(
                label: Text(l.reqTypeAll),
                selected: _bloodType == null,
                onSelected: (_) => setState(() => _bloodType = null),
              ),
              for (final t in kBloodTypes) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(t),
                  selected: _bloodType == t,
                  onSelected: (_) => setState(() => _bloodType = t),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildBody(items, l)),
      ],
    );
  }

  Widget _buildBody(List<RequestPost> items, AppLocalizations l) {
    final filtered = _query.isNotEmpty || _bloodType != null;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: EmptyView(
          icon: filtered ? Icons.search_off : Icons.bloodtype_outlined,
          message: filtered ? l.noResults : l.reqBloodEmpty,
          action: filtered
              ? OutlinedButton.icon(
                  onPressed: () {
                    _clearSearch();
                    setState(() => _bloodType = null);
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: Text(l.clearFilters),
                )
              : FilledButton.tonalIcon(
                  onPressed: _openCreateBlood,
                  icon: const Icon(Icons.bloodtype_outlined),
                  label: Text(l.reqAddBlood),
                ),
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
                  builder: (_) => RequestDetailsScreen(requestId: request.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

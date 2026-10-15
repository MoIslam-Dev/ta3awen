import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/request_post.dart';
import '../../services/request_service.dart';
import '../../utils/errors.dart';
import '../../widgets/request_card.dart';
import '../../widgets/state_views.dart';
import 'request_details_screen.dart';
import 'request_form_screen.dart';

/// The user's own board posts (any status), opened from the profile hub.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with AutomaticKeepAliveClientMixin {
  final _service = RequestService();
  List<RequestPost> _items = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<RequestPost>>? _sub;

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

  Future<void> _load() async {
    _subscribe();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.tabRequests)),
      body: Builder(
        builder: (context) {
          if (_loading) return LoadingView(message: l.loading);
          if (_error != null) return ErrorView(message: _error!, onRetry: _load);
          if (_items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _load,
              child: EmptyView(
                icon: Icons.forum_outlined,
                message: l.reqEmptyMine,
                action: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RequestFormScreen.create(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l.reqAddFirst),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final request = _items[i];
                return RequestCard(
                  request: request,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestDetailsScreen(requestId: request.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

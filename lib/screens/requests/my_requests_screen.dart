import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/request_post.dart';
import '../../services/request_service.dart';
import '../../state/paged_list.dart';
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

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _service = RequestService();
  PagedList<RequestPost>? _paged;
  bool _loginError = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _loginError = true;
    } else {
      _paged = PagedList<RequestPost>(
        headBuilder: (limit) => _service.myHead(uid, limit: limit),
        moreBuilder: (cursor, limit) =>
            _service.myMore(uid, cursor, limit: limit),
        idOf: (r) => r.id,
      )..start();
    }
  }

  @override
  void dispose() {
    _paged?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _paged?.start();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _loadMore() async {
    try {
      await _paged?.loadMore();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dataErrorMessage(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_loginError) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tabRequests)),
        body: EmptyView(icon: Icons.lock_outline, message: l.loginRequired),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.tabRequests)),
      body: ListenableBuilder(
        listenable: _paged!,
        builder: (context, _) {
          final paged = _paged!;
          if (paged.loading) return LoadingView(message: l.loading);
          final error = paged.error;
          if (error != null) {
            return ErrorView(
              message: dataErrorMessage(context, error),
              onRetry: _load,
            );
          }
          if (paged.isEmpty) {
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
          final items = paged.items;
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: items.length + (paged.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= items.length) {
                  return LoadMoreFooter(
                    loading: paged.loadingMore,
                    onLoadMore: _loadMore,
                  );
                }
                final request = items[i];
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

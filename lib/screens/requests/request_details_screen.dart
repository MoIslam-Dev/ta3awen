import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/request_post.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../utils/labels.dart';
import '../../widgets/state_views.dart';
import 'request_form_screen.dart';

class RequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final _requestService = RequestService();
  final _userService = UserService();

  RequestPost? _request;
  bool _loading = true;
  String? _error;
  bool _showContact = false;
  bool _acting = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get _isAuthor => _uid != null && _uid == _request?.uid;

  bool get _isMatcher =>
      _uid != null && _uid == _request?.matchedBy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final request = await _requestService.byId(widget.requestId);
      if (request == null) {
        if (mounted && !quiet) {
          setState(() {
            _error = context.l10n.reqNotFound;
            _loading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _request = request;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !quiet) {
        setState(() {
          _error = dataErrorMessage(context, e);
          _loading = false;
        });
      }
    }
  }

  void _snack(String Function(BuildContext) message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message(context))));
  }

  /// Run one board action; on rules denial probe the document — if another
  /// user matched first, surface "taken", otherwise the normal error.
  Future<void> _act(
    Future<void> Function() action, {
    String Function(BuildContext)? success,
    bool probeTaken = false,
  }) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action();
      await _load(quiet: true);
      if (success != null) _snack(success);
    } catch (e) {
      RequestPost? fresh;
      try {
        fresh = await _requestService.byId(widget.requestId);
      } catch (_) {}
      await _load(quiet: true);
      if (probeTaken && fresh != null && fresh.isMatched) {
        _snack((c) => c.l10n.reqMatchTaken);
      } else {
        _snack((c) => dataErrorMessage(c, e));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _match() async {
    final uid = _uid;
    if (uid == null) return;
    final user = await _userService.getById(uid);
    await _act(
      () => _requestService.match(
        widget.requestId,
        uid: uid,
        name: user?.fullName ?? 'مستخدم',
      ),
      success: (c) => c.l10n.reqMatchSuccess,
      probeTaken: true,
    );
  }

  Future<void> _unmatch() async {
    await _act(
      () => _requestService.unmatch(widget.requestId),
      success: (c) => c.l10n.reqMatchWithdrawn,
    );
  }

  Future<void> _finalize() async {
    await _act(
      () => _requestService.setStatus(widget.requestId, requestStatusClosed),
      success: (c) => c.l10n.reqMatchFinalized,
    );
  }

  Future<void> _release() async {
    await _act(
      () => _requestService.unmatch(widget.requestId),
      success: (c) => c.l10n.reqMatchReleased,
    );
  }

  Future<void> _toggleClosed() async {
    final r = _request!;
    final next = r.isClosed ? requestStatusOpen : requestStatusClosed;
    await _act(
      () => _requestService.setStatus(widget.requestId, next),
      success: (c) =>
          r.isClosed ? c.l10n.reqReopened : c.l10n.reqClosed,
    );
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequestFormScreen.edit(_request!),
      ),
    );
    await _load(quiet: true);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.reqDeleteTitle),
        content: Text(l.reqDeleteBody(_request!.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _requestService.delete(widget.requestId);
      if (mounted) {
        _snack((c) => c.l10n.reqDeleted);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _snack((c) => dataErrorMessage(c, e));
    }
  }

  /// Role/status-driven action area:
  /// * open + visitor        -> match button
  /// * open + author         -> nothing here (popup handles edit/close/delete)
  /// * matched + author      -> finalize + release
  /// * matched + matcher     -> withdraw
  /// * matched + visitor     -> info card only
  /// * closed + author       -> reopen (popup handles edit/delete)
  Widget _buildActions(RequestPost r, ThemeData theme, AppLocalizations l) {
    if (r.isOpen && !_isAuthor) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _acting ? null : _match,
          icon: const Icon(Icons.handshake_outlined),
          label: Text(l.reqMatchHelp),
        ),
      );
    }
    if (r.isMatched) {
      final name = r.matchedName ?? '—';
      return Card(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isMatcher
                          ? l.reqMatchedWithYou
                          : l.reqMatchedByUser(name),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isAuthor) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _acting ? null : _finalize,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l.reqFinalizeMatch),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _acting ? null : _release,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: Text(l.reqReleaseMatch),
                ),
              ] else if (_isMatcher) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _acting ? null : _unmatch,
                  icon: const Icon(Icons.undo_outlined),
                  label: Text(l.reqWithdrawMatch),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget? _authorMenu(RequestPost r, AppLocalizations l) {
    if (!_isAuthor) return null;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        switch (v) {
          case 'edit':
            await _edit();
            break;
          case 'toggle':
            await _toggleClosed();
            break;
          case 'delete':
            await _delete();
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            contentPadding: EdgeInsets.zero,
            title: Text(l.edit),
          ),
        ),
        // Matched posts already expose finalize/release buttons below.
        if (!r.isMatched)
          PopupMenuItem(
            value: 'toggle',
            child: ListTile(
              leading: Icon(r.isOpen
                  ? Icons.lock_outline
                  : Icons.lock_open_outlined),
              contentPadding: EdgeInsets.zero,
              title: Text(r.isOpen ? l.reqClose : l.reqReopen),
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(ctx).colorScheme.error,
            ),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.delete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: LoadingView(message: context.l10n.loading),
      );
    }
    if (_error != null || _request == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: _error ?? context.l10n.errGeneric,
          onRetry: _load,
        ),
      );
    }
    final r = _request!;
    final theme = Theme.of(context);
    final l = context.l10n;
    final isNeed = r.type == requestTypeNeed;

    // The matcher may reveal the author's phone once matched; the author
    // always sees their own; plain visitors never do.
    final revealPhone =
        r.contactPhone != null && r.contactPhone!.isNotEmpty && (
            _isAuthor ||
            (_isMatcher && r.isMatched) ||
            (r.isOpen && !_isAuthor));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.reqDetailsTitle),
        actions: [_authorMenu(r, l) ?? const SizedBox.shrink()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: r.isMatched
                        ? theme.colorScheme.secondaryContainer
                        : r.isClosed
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    requestStatusLabel(context, r.status),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: r.isMatched
                          ? theme.colorScheme.onSecondaryContainer
                          : r.isClosed
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(
                  icon: isNeed
                      ? Icons.help_outline
                      : Icons.volunteer_activism_outlined,
                  label: requestTypeLabel(context, r.type),
                ),
                if (r.isBlood && r.bloodType != null)
                  InfoChip(
                    icon: Icons.bloodtype_outlined,
                    label: '${l.reqBloodTypeLabel}: ${r.bloodType}',
                  ),
                InfoChip(
                  icon: Icons.category_outlined,
                  label: categoryLabel(context, r.category),
                ),
                InfoChip(
                  icon: Icons.place_outlined,
                  label: '${r.wilaya} - ${r.commune}',
                ),
                InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: formatDate(r.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l.description, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              r.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.userName, style: theme.textTheme.titleSmall),
                          Text(
                            l.reqAuthor,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActions(r, theme, l),
            if (revealPhone) ...[
              if (_showContact)
                Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          r.contactPhone!,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => _showContact = true),
                    icon: const Icon(Icons.contact_phone_outlined),
                    label: Text(l.showPhone),
                  ),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

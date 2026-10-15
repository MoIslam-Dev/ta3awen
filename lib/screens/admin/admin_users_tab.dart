import 'dart:async';

import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';
import '../../state/paged_list.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab>
    with AutomaticKeepAliveClientMixin {
  final _admin = AdminService();
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  PagedList<AppUser>? _paged;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _paged = _make('')..start();
    _search.addListener(_onSearch);
  }

  PagedList<AppUser> _make(String search) => PagedList<AppUser>(
        headBuilder: (limit) => _admin.usersHead(search: search, limit: limit),
        moreBuilder: (cursor, limit) =>
            _admin.usersMore(search, cursor, limit: limit),
        idOf: (u) => u.uid,
      );

  void _onSearch() {
    final v = _search.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (v == _query) return;
      setState(() => _query = v);
      _paged?.dispose();
      _paged = _make(v)..start();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _paged?.dispose();
    _search.dispose();
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

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
      return false;
    }
  }

  void _toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _toggleUser(AppUser u) async {
    final loc = context.l10n;
    if (u.disabled) {
      if (await _run(() => _admin.setUserDisabled(u.uid, false))) {
        _toast(loc.userEnabledToast);
      }
      return;
    }
    final reason = await _askDisableReason(loc);
    if (reason == null) return;
    if (await _run(() => _admin.setUserDisabled(u.uid, true, reason: reason))) {
      _toast(loc.userDisabledToast);
    }
  }

  Future<String?> _askDisableReason(AppLocalizations loc) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.disableUserTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: loc.disableReasonHint,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(loc.disableAction),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _deleteUserData(AppUser u) async {
    final loc = context.l10n;
    final theme = Theme.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteUserDataTitle),
        content: Text(loc.deleteUserDataBody(u.fullName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    if (await _run(() => _admin.deleteUserData(u.uid))) {
      _paged?.remove(u);
      _toast(loc.userDataDeleted);
    }
  }

  void _openDetail(AppUser u) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UserDetailSheet(
        user: u,
        admin: _admin,
        onToggleUser: () => _toggleUser(u),
        onDeleteData: () => _deleteUserData(u),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    final theme = Theme.of(context);
    final paged = _paged!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: l.adminSearchUsers,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _search.clear(),
                    ),
            ),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: paged,
            builder: (context, _) {
              if (paged.loading) return LoadingView(message: l.loading);
              final error = paged.error;
              if (error != null) {
                return ErrorView(
                  message: dataErrorMessage(context, error),
                  onRetry: _load,
                );
              }
              final visible = paged.items;
              if (visible.isEmpty) {
                return EmptyView(
                  icon: _query.isEmpty ? Icons.people_outlined : Icons.search_off,
                  message: _query.isEmpty ? l.noUsers : l.emptySearchResults,
                );
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length + (paged.hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= visible.length) {
                      return LoadMoreFooter(
                        loading: paged.loadingMore,
                        onLoadMore: _loadMore,
                      );
                    }
                    final u = visible[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          u.disabled
                              ? Icons.block
                              : Icons.check_circle_outline,
                          color: u.disabled
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        title: Text(
                          u.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${u.email} • ${u.wilaya}',
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _openDetail(u),
                        trailing: IconButton(
                          tooltip:
                              u.disabled ? l.enableAction : l.disableAction,
                          icon: Icon(
                            u.disabled ? Icons.restart_alt : Icons.block,
                            color: u.disabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                          onPressed: () => _toggleUser(u),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Detail sheet: loads per-user counts and admin membership on open, and
/// exposes the full moderation toolbox.
class _UserDetailSheet extends StatefulWidget {
  final AppUser user;
  final AdminService admin;
  final VoidCallback onToggleUser;
  final VoidCallback onDeleteData;

  const _UserDetailSheet({
    required this.user,
    required this.admin,
    required this.onToggleUser,
    required this.onDeleteData,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  int? _listings;
  int? _requests;
  bool _isAdmin = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.user.uid;
    final results = await Future.wait([
      widget.admin.countUserListings(uid),
      widget.admin.countUserRequests(uid),
      widget.admin.isAdmin(uid),
    ]);
    if (!mounted) return;
    setState(() {
      _listings = results[0] as int;
      _requests = results[1] as int;
      _isAdmin = results[2] as bool;
    });
  }

  Future<void> _toggleAdmin() async {
    final loc = context.l10n;
    setState(() => _busy = true);
    try {
      await widget.admin.setAdmin(widget.user.uid, !_isAdmin);
      if (!mounted) return;
      setState(() => _isAdmin = !_isAdmin);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAdmin ? loc.adminGranted : loc.adminRevoked)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final u = widget.user;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    u.fullName.isNotEmpty ? u.fullName.characters.first : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        u.email,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (_isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.adminBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(l.userDetailPhone, u.contactPhone ?? '—'),
            _detailRow(
              l.userDetailLocation,
              '${u.commune.isNotEmpty ? '${u.commune}, ' : ''}${u.wilaya}',
            ),
            _detailRow(l.userDetailJoined, formatDate(u.createdAt)),
            if (u.disabled)
              _detailRow(
                l.userDetailDisabledReason,
                u.disabledReason?.isNotEmpty == true ? u.disabledReason! : '—',
              ),
            const SizedBox(height: 8),
            Text(
              '${_listings ?? '…'} ${l.tabListings}  •  ${_requests ?? '…'} ${l.tabRequests}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: u.disabled
                  ? FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onToggleUser();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l.enableAction),
                    )
                  : FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onToggleUser();
                      },
                      icon: const Icon(Icons.block),
                      label: Text(l.disableAction),
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _toggleAdmin,
                icon: Icon(_isAdmin
                    ? Icons.remove_moderator_outlined
                    : Icons.add_moderator_outlined),
                label: Text(_isAdmin ? l.adminRevoke : l.adminGrant),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDeleteData();
                },
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l.deleteUserData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/ext.dart';
import '../../models/app_notification.dart';
import '../../state/notification_center.dart';
import '../../theme/app_theme.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../utils/notification_labels.dart';
import '../../widgets/state_views.dart';
import '../listing/listing_details_screen.dart';
import '../requests/request_details_screen.dart';

/// The notification inbox: the recipient's rows, newest first, live. Tapping a
/// row marks it read and opens the referenced listing/post.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.center});

  final NotificationCenter center;

  void _open(BuildContext context, AppNotification n) {
    if (n.listingId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ListingDetailsScreen(listingId: n.listingId!),
        ),
      );
    } else if (n.requestId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequestDetailsScreen(requestId: n.requestId!),
        ),
      );
    }
  }

  void _onTap(BuildContext context, AppNotification n) {
    // Fire-and-forget read receipt; the badge clears optimistically.
    unawaited(center.markRead(n).catchError((Object _) {}));
    _open(context, n);
  }

  Future<void> _markAllRead(BuildContext context) async {
    try {
      await center.markAllRead();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsTitle),
        actions: [
          ListenableBuilder(
            listenable: center,
            builder: (context, _) => center.unreadCount == 0
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _markAllRead(context),
                    child: Text(l.notificationsMarkAllRead),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: center,
        builder: (context, _) {
          if (center.loading) return const LoadingView();
          final error = center.error;
          if (error != null) {
            return ErrorView(
              message: dataErrorMessage(context, error),
              onRetry: center.start,
            );
          }
          final items = center.items;
          if (items.isEmpty) {
            return EmptyView(
              icon: Icons.notifications_none,
              message: l.notificationsEmpty,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final n = items[i];
              return _NotificationTile(
                notification: n,
                unread: center.isUnread(n),
                onTap: () => _onTap(context, n),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.unread,
    required this.onTap,
  });

  final AppNotification notification;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visual = notificationVisual(context, notification);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: unread
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  child: Icon(visual.icon, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visual.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visual.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDateTime(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 8),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

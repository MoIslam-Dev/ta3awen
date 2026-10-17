import 'package:flutter/material.dart';

import '../l10n/ext.dart';
import '../models/app_notification.dart';

/// Localized presentation of a notification: an icon and a title/body pair.
/// Text lives in the ARB files; the stored row only carries a [type], the
/// actor's name and a reference id, so the app renders in ar/en/fr.
class NotificationVisual {
  final IconData icon;
  final String title;
  final String body;

  const NotificationVisual({
    required this.icon,
    required this.title,
    required this.body,
  });
}

NotificationVisual notificationVisual(
  BuildContext context,
  AppNotification n,
) {
  final l = context.l10n;
  // Fall back to a generic name if the actor is somehow missing.
  final name = n.actorName.trim().isEmpty ? l.notifSomeone : n.actorName;

  switch (n.type) {
    case notifyListingClaimed:
      return NotificationVisual(
        icon: Icons.bookmark_added_outlined,
        title: l.notifListingClaimedTitle,
        body: l.notifListingClaimedBody(name),
      );
    case notifyListingReleased:
      return NotificationVisual(
        icon: Icons.bookmark_remove_outlined,
        title: l.notifListingReleasedTitle,
        body: l.notifListingReleasedBody(name),
      );
    case notifyListingGiven:
      return NotificationVisual(
        icon: Icons.check_circle_outline,
        title: l.notifListingGivenTitle,
        body: l.notifListingGivenBody(name),
      );
    case notifyRequestMatched:
      return NotificationVisual(
        icon: Icons.handshake_outlined,
        title: l.notifRequestMatchedTitle,
        body: l.notifRequestMatchedBody(name),
      );
    case notifyBloodMatched:
      return NotificationVisual(
        icon: Icons.bloodtype_outlined,
        title: l.notifBloodMatchedTitle,
        body: l.notifBloodMatchedBody(name),
      );
    case notifyRequestReleased:
      return NotificationVisual(
        icon: Icons.undo_outlined,
        title: l.notifRequestReleasedTitle,
        body: l.notifRequestReleasedBody(name),
      );
    case notifyRequestClosed:
      return NotificationVisual(
        icon: Icons.task_alt_outlined,
        title: l.notifRequestClosedTitle,
        body: l.notifRequestClosedBody(name),
      );
    case notifyReportNew:
      return NotificationVisual(
        icon: Icons.flag_outlined,
        title: l.notifReportNewTitle,
        body: l.notifReportNewBody(name),
      );
    default:
      return NotificationVisual(
        icon: Icons.notifications_none,
        title: l.notificationsTitle,
        body: name,
      );
  }
}

import 'package:flutter/material.dart';

import '../l10n/ext.dart';
import '../models/listing.dart';
import '../models/request_post.dart';
import '../screens/listing/listing_form_screen.dart';
import '../screens/requests/request_form_screen.dart';

/// Single publishing entry point: one FAB, one sheet that asks what the
/// user wants to publish. Keeps the "give vs ask" model unambiguous —
/// nobody has to guess which tab a new post belongs to.
Future<void> showPublishSheet(BuildContext context) async {
  final nav = Navigator.of(context);
  final l = context.l10n;

  void go(Widget screen) {
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => screen));
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l.publishTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ),
            _PublishTile(
              icon: Icons.redeem_outlined,
              color: scheme.primary,
              title: l.publishDonate,
              onTap: () => go(const ListingFormScreen.create()),
            ),
            _PublishTile(
              icon: Icons.swap_horiz,
              color: scheme.tertiary,
              title: l.publishExchange,
              onTap: () => go(
                const ListingFormScreen.create(
                  initialKind: listingKindExchange,
                ),
              ),
            ),
            _PublishTile(
              icon: Icons.volunteer_activism_outlined,
              color: scheme.secondary,
              title: l.publishAsk,
              onTap: () => go(const RequestFormScreen.create()),
            ),
            _PublishTile(
              icon: Icons.bloodtype_outlined,
              color: scheme.error,
              title: l.publishBlood,
              onTap: () => go(
                const RequestFormScreen.create(
                  initialKind: requestKindBlood,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _PublishTile extends StatelessWidget {
  const _PublishTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
        child: Icon(icon, size: 22),
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

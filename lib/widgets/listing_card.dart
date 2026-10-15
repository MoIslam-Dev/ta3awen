import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../utils/formatters.dart';
import '../utils/labels.dart';
import 'base64_image.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.trailing,
  });

  /// Nature pill: free donation vs barter/exchange.
  Widget _kindBadge(BuildContext context) {
    final theme = Theme.of(context);
    final exchange = listing.isExchange;
    final bg = exchange
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.primaryContainer;
    final fg = exchange
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exchange ? Icons.swap_horiz : Icons.redeem_outlined,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            listingKindLabel(context, listing.kind),
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 116,
                  height: 116,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Base64Image(data: listing.image0),
                      if (listing.imageCount > 1)
                        PositionedDirectional(
                          end: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library_outlined,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${listing.imageCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            trailing ?? const SizedBox.shrink(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${categoryLabel(context, listing.category)} • ${conditionLabel(context, listing.condition)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${listing.wilaya} - ${listing.commune}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _kindBadge(context),
                            if (!listing.isAvailable) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: listing.isReserved
                                      ? theme.colorScheme.secondaryContainer
                                      : theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel(context, listing.status),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: listing.isReserved
                                        ? theme
                                            .colorScheme.onSecondaryContainer
                                        : theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              formatDate(listing.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

import 'package:flutter/material.dart';
import '../l10n/ext.dart';
import '../models/request_post.dart';
import '../utils/formatters.dart';
import '../utils/labels.dart';

class RequestCard extends StatelessWidget {
  final RequestPost request;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final isNeed = request.type == requestTypeNeed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNeed
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNeed
                                ? Icons.help_outline
                                : Icons.volunteer_activism_outlined,
                            size: 15,
                            color: isNeed
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            requestTypeLabel(context, request.type),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isNeed
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.title,
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
                const SizedBox(height: 6),
                Text(
                  request.isBlood && request.bloodType != null
                      ? '${categoryLabel(context, request.category)} • ${request.bloodType}'
                      : categoryLabel(context, request.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: request.isBlood
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        request.isBlood ? FontWeight.w700 : null,
                  ),
                ),
                const SizedBox(height: 6),
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
                        '${request.wilaya} - ${request.commune}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    Text(
                      formatDate(request.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                if (request.status != requestStatusOpen) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: request.isMatched
                            ? theme.colorScheme.secondaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request.isMatched && request.matchedName != null
                            ? l.reqMatchedBy(request.matchedName!)
                            : requestStatusLabel(context, request.status),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: request.isMatched
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

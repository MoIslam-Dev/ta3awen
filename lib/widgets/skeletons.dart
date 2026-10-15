import 'package:flutter/material.dart';

/// Animated shimmer sweep used by skeleton placeholders.
///
/// Paints a moving highlight across [child] using [BlendMode.srcIn], so any
/// opaque child (the grey placeholder bars below) picks up the animation.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.surface.withValues(alpha: 0.65),
      base,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final t = _controller.value * 2 - 1;
            return LinearGradient(
              begin: Alignment(-1 + t, 0),
              end: Alignment(1 + t, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Rounded grey placeholder block used to compose skeletons.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Skeleton that mirrors [ListingCard] (thumbnail + text column).
class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: SizedBox(
        height: 116,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SkeletonBox(width: 116, height: 116, radius: 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 150, height: 16),
                    SizedBox(height: 10),
                    SkeletonBox(width: 110, height: 12),
                    SizedBox(height: 10),
                    SkeletonBox(width: 90, height: 12),
                    Spacer(),
                    SkeletonBox(width: 60, height: 18, radius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton that mirrors [RequestCard].
class RequestCardSkeleton extends StatelessWidget {
  const RequestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                SkeletonBox(width: 72, height: 24, radius: 8),
                SizedBox(width: 8),
                Expanded(child: SkeletonBox(height: 16)),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(width: 150, height: 12),
            SizedBox(height: 12),
            SkeletonBox(width: 120, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Which card shape a [SkeletonList] should imitate.
enum SkeletonKind { listing, request }

/// Non-scrolling list of shimmering placeholder cards shown on first load.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.kind = SkeletonKind.listing,
    this.count = 6,
  });

  final SkeletonKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4),
        itemCount: count,
        itemBuilder: (context, _) => kind == SkeletonKind.listing
            ? const ListingCardSkeleton()
            : const RequestCardSkeleton(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/b64_cache.dart';

class Base64Image extends StatelessWidget {
  final String? data;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const Base64Image({
    super.key,
    required this.data,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius,
  });

  /// Soft branded placeholder shown when a listing has no photo (or the
  /// photo fails to decode) — far friendlier than a bare grey block.
  Widget _placeholder(BuildContext context, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.55),
            scheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 34,
          color: scheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (data == null || data!.isEmpty) {
      child = _placeholder(context, Icons.image_outlined);
    } else {
      child = Image.memory(
        B64Cache.get(data!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) =>
            _placeholder(context, Icons.broken_image_outlined),
      );
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

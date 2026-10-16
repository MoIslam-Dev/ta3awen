import 'package:flutter/material.dart';

import '../utils/b64_cache.dart';

/// Renders a listing photo from either a Supabase Storage URL or an inline
/// base64 string (local preview before upload).
class Base64Image extends StatelessWidget {
  final String? data;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const Base64Image({
    super.key,
    required this.data,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  /// Soft branded placeholder shown when a listing has no photo (or the
  /// photo fails to load) — far friendlier than a bare grey block.
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
    final value = data;
    Widget child;
    if (value == null || value.isEmpty) {
      child = _placeholder(context, Icons.image_outlined);
    } else if (value.startsWith('http')) {
      child = Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) =>
            _placeholder(context, Icons.broken_image_outlined),
      );
    } else {
      child = Image.memory(
        B64Cache.get(value),
        width: width,
        height: height,
        fit: fit,
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

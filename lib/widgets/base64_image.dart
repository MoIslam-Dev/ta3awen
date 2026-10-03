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

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (data == null || data!.isEmpty) {
      child = Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        ),
      );
    } else {
      child = Image.memory(
        B64Cache.get(data!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

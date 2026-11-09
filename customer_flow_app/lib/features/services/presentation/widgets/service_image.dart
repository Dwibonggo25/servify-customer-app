import 'package:flutter/material.dart';

final class ServiceImage extends StatelessWidget {
  const ServiceImage({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.color,
    this.iconSize = 30,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.key,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final Color color;
  final double iconSize;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return _fallback();

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : ColoredBox(
                color: color.withValues(alpha: 0.12),
                child: const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() => ColoredBox(
    color: color.withValues(alpha: 0.12),
    child: Center(
      child: Icon(fallbackIcon, color: color, size: iconSize),
    ),
  );
}

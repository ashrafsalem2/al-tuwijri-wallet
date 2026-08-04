import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows the brand image from assets. Until you drop your real image at
/// assets/images/brand_logo.png, it falls back to a styled placeholder so the
/// app still builds and runs.
class BrandLogo extends StatelessWidget {
  final double size;
  final Color? fallbackColor;
  const BrandLogo({super.key, this.size = 120, this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/brand_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => _Placeholder(
        size: size,
        color: fallbackColor ?? AppColors.brand,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;
  final Color color;
  const _Placeholder({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.storefront_rounded,
          color: Colors.white, size: size * 0.5),
    );
  }
}

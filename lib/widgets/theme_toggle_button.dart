import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Compact app-bar button that flips light <-> dark, with a sun/moon glyph.
/// Available on every screen so the theme can be switched from anywhere.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDark,
      builder: (context, isDark, _) {
        return IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.brand.withValues(alpha: 0.12),
            foregroundColor: AppColors.brand,
          ),
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          onPressed: () => ThemeController.toggle(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween(begin: 0.7, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              size: 20,
              color: AppColors.brand,
            ),
          ),
        );
      },
    );
  }
}

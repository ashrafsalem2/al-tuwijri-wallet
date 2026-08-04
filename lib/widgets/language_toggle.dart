import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Compact circular button that flips AR <-> EN with a rotation/fade.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the locale so the glyph always reflects the current language,
    // even though this widget is used as a `const`.
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar';
        return IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.brand.withValues(alpha: 0.10),
            foregroundColor: AppColors.brand,
          ),
          tooltip: 'العربية / English',
          onPressed: () => LocaleController.toggle(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween(begin: 0.6, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              isArabic ? 'EN' : 'ع',
              key: ValueKey(isArabic),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.brand,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated segmented control (العربية | English) used in the profile sheet.
class LanguageSegmented extends StatelessWidget {
  const LanguageSegmented({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _segment(t.arabic, isAr, () => LocaleController.set('ar')),
              _segment(t.english, !isAr, () => LocaleController.set('en')),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

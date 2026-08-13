import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StylishNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const StylishNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A floating, rounded navigation bar. The selected item animates into a
/// filled brand-colored pill that expands to reveal its label.
class StylishBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<StylishNavItem> items;

  const StylishBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < items.length; i++)
              _NavPill(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final StylishNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavPill({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: selected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            // Label reveals only for the selected pill.
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

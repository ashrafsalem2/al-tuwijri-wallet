import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================
///  BRAND THEME — light (maroon + cream) and dark (navy + gold).
///  The AppColors fields are MUTABLE and swapped by [AppColors.apply]
///  whenever the theme mode changes, so the many widgets that read
///  AppColors.* pick up the active palette on rebuild.
/// ============================================================
class AppColors {
  // Active palette (defaults to light; overwritten by [apply]).
  static Color brand = _lightBrand;
  static Color brandDark = _lightBrandDark;
  static Color accent = _gold;
  static Color bg = _lightBg;
  static Color surface = _lightSurface;
  static Color textPrimary = _lightTextPrimary;
  static Color textSecondary = _lightTextSecondary;
  static Color success = _lightSuccess;
  static Color danger = _lightDanger;

  static bool isDark = false;

  // --- Light palette ---
  static const Color _lightBrand = Color(0xFF7B1E2B); // maroon
  static const Color _lightBrandDark = Color(0xFF551017);
  static const Color _gold = Color(0xFFC9A24B);
  static const Color _lightBg = Color(0xFFF7F2EC);
  static const Color _lightSurface = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF2A1418);
  static const Color _lightTextSecondary = Color(0xFF9A8B85);
  static const Color _lightSuccess = Color(0xFF2E7D5B);
  static const Color _lightDanger = Color(0xFFC0392B);

  // --- Dark palette (navy + gold-forward) ---
  static const Color _darkBrand = Color(0xFFD8B15A); // gold as the primary
  static const Color _darkBrandDark = Color(0xFF9C7B2C);
  static const Color _darkBg = Color(0xFF0B0F1E);
  static const Color _darkSurface = Color(0xFF161C2E);
  static const Color _darkTextPrimary = Color(0xFFF3F5FA);
  static const Color _darkTextSecondary = Color(0xFF9AA3B8);
  static const Color _darkSuccess = Color(0xFF3FB98A);
  static const Color _darkDanger = Color(0xFFE5675A);

  /// Swap the active palette. Call before building the MaterialApp theme.
  static void apply(bool dark) {
    isDark = dark;
    brand = dark ? _darkBrand : _lightBrand;
    brandDark = dark ? _darkBrandDark : _lightBrandDark;
    accent = _gold;
    bg = dark ? _darkBg : _lightBg;
    surface = dark ? _darkSurface : _lightSurface;
    textPrimary = dark ? _darkTextPrimary : _lightTextPrimary;
    textSecondary = dark ? _darkTextSecondary : _lightTextSecondary;
    success = dark ? _darkSuccess : _lightSuccess;
    danger = dark ? _darkDanger : _lightDanger;
  }
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Dark mode paints the gold-particle backdrop globally (see app.dart),
      // so scaffolds stay transparent to let it show through every screen.
      scaffoldBackgroundColor: dark ? Colors.transparent : AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: brightness,
        primary: AppColors.brand,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
    );

    final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    // On gold (dark) buttons use dark text; on maroon (light) use white.
    final onBrand = dark ? const Color(0xFF2A1E05) : Colors.white;
    final fieldFill =
        dark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final fieldBorder =
        dark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade200;

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        // A faint dark scrim in dark mode keeps the title readable over the
        // gold-particle backdrop; fully transparent in light mode.
        backgroundColor: dark
            ? const Color(0xFF0B0F1E).withValues(alpha: 0.35)
            : Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: onBrand,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.brand, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

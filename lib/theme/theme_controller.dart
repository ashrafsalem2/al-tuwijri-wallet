import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Holds the light/dark choice and persists it. Widgets listen to [isDark]
/// (the app root rebuilds the MaterialApp on change).
class ThemeController {
  ThemeController._();

  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);
  static const _key = 'dark_mode';

  /// Load the saved choice at startup and apply the palette.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value = prefs.getBool(_key) ?? false;
    AppColors.apply(isDark.value);
  }

  static Future<void> setDark(bool v) async {
    isDark.value = v;
    AppColors.apply(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, v);
  }

  static void toggle() => setDark(!isDark.value);
}

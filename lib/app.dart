import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/gold_particles_background.dart';
import 'screens/splash_screen.dart';

class SalesTrackerApp extends StatelessWidget {
  const SalesTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDark,
      builder: (context, isDark, _) {
        // Keep the mutable palette in sync with the active mode.
        AppColors.apply(isDark);
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.locale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Al Tuwijri Wallet',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              locale: locale,
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // In dark mode every screen sits on the gold-particle backdrop
              // (scaffolds are transparent), so the whole app matches the login.
              builder: (context, child) => isDark
                  ? GoldParticlesBackground(child: child ?? const SizedBox())
                  : (child ?? const SizedBox()),
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

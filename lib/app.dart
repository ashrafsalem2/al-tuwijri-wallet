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
              // A short fade plays whenever the theme or language changes.
              builder: (context, child) {
                final content = _ModeTransition(
                  modeKey: '${isDark ? 'd' : 'l'}:${locale.languageCode}',
                  child: child ?? const SizedBox(),
                );
                return isDark
                    ? GoldParticlesBackground(child: content)
                    : ColoredBox(color: AppColors.bg, child: content);
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

/// Plays a quick fade whenever [modeKey] changes (theme or language switch),
/// briefly revealing the backdrop so the palette swap reads as a smooth
/// transition rather than an instant jump. Keeps the same child (navigation is
/// preserved).
class _ModeTransition extends StatefulWidget {
  final Widget child;
  final String modeKey;
  const _ModeTransition({required this.child, required this.modeKey});

  @override
  State<_ModeTransition> createState() => _ModeTransitionState();
}

class _ModeTransitionState extends State<_ModeTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: 58,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant _ModeTransition old) {
    super.didUpdateWidget(old);
    if (old.modeKey != widget.modeKey) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

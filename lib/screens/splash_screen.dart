import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _textFade;

  // Continuous "breathing" + gold-glow pulse on the logo.
  late final AnimationController _loop;
  late final Animation<double> _breathe;
  // Slow rotation for the gold shimmer halo behind the logo.
  late final AnimationController _halo;

  // Background video.
  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.asset('assets/video/splash_bg.mp4')
      ..setVolume(0)
      ..setLooping(true);
    _video!.initialize().then((_) {
      if (!mounted) return;
      _video!.play();
      setState(() => _videoReady = true);
    }).catchError((_) {
      // If the video can't load, the maroon gradient fallback is used.
    });
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _breathe = CurvedAnimation(parent: _loop, curve: Curves.easeInOut);
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 4200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _loop.dispose();
    _halo.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background video (fills + crops to cover). Falls back to the maroon
          // gradient until it's ready / if it fails to load.
          if (_videoReady && _video != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _video!.value.size.width,
                height: _video!.value.size.height,
                child: VideoPlayer(_video!),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B1E2B), Color(0xFF551017)],
                ),
              ),
            ),
          // Brand scrim over the video so the logo and text stay readable.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brand.withValues(alpha: 0.62),
                  AppColors.brandDark.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Slowly-rotating soft gold shimmer ring behind the logo.
                      AnimatedBuilder(
                        animation: _halo,
                        builder: (context, _) => Transform.rotate(
                          angle: _halo.value * 2 * math.pi,
                          child: ImageFiltered(
                            imageFilter:
                                ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.0),
                                    AppColors.accent.withValues(alpha: 0.55),
                                    AppColors.accent.withValues(alpha: 0.0),
                                    AppColors.accent.withValues(alpha: 0.45),
                                    AppColors.accent.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.2, 0.45, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // The logo card with breathing + gold glow.
                      AnimatedBuilder(
                        animation: _breathe,
                        builder: (context, child) {
                          final v = _breathe.value; // 0..1 eased
                          return Transform.scale(
                            scale: 1.0 + 0.035 * v,
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.30 + 0.35 * v),
                                    blurRadius: 24 + 34 * v,
                                    spreadRadius: 1 + 6 * v,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: const BrandLogo(size: 120),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 28),
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      AppStrings.of(context).appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      AppStrings.of(context).tagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 44),
              FadeTransition(
                opacity: _textFade,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

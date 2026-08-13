import 'dart:math';

import 'package:flutter/material.dart';

/// A dark, premium backdrop with drifting, twinkling gold bokeh particles —
/// recreated natively (no video) to match the dark + gold login concept.
/// Renders [child] on top of the animated background.
class GoldParticlesBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  const GoldParticlesBackground({
    super.key,
    required this.child,
    this.particleCount = 46,
  });

  @override
  State<GoldParticlesBackground> createState() =>
      _GoldParticlesBackgroundState();
}

class _GoldParticlesBackgroundState extends State<GoldParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = Random(7);
    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        radius: 0.8 + rnd.nextDouble() * 2.8,
        drift: 0.01 + rnd.nextDouble() * 0.05, // upward speed (fraction/loop)
        sway: 0.01 + rnd.nextDouble() * 0.03,
        phase: rnd.nextDouble() * pi * 2,
        twinkle: 0.6 + rnd.nextDouble() * 1.8,
        baseAlpha: 0.35 + rnd.nextDouble() * 0.55,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark navy base with a soft warm glow near the top (behind the logo).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B0F1E), Color(0xFF141A30), Color(0xFF0C1020)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.65),
              radius: 0.9,
              colors: [Color(0x33C9A24B), Color(0x00C9A24B)],
            ),
          ),
        ),
        // The animated particles.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particles, _controller.value),
              size: Size.infinite,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  final double x, y, radius, drift, sway, phase, twinkle, baseAlpha;
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.drift,
    required this.sway,
    required this.phase,
    required this.twinkle,
    required this.baseAlpha,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1 loop
  _ParticlePainter(this.particles, this.t);

  static const _coreColor = Color(0xFFF0D68A);
  static const _glowColor = Color(0xFFC9A24B);

  @override
  void paint(Canvas canvas, Size size) {
    final loop = t * 2 * pi;
    for (final p in particles) {
      // Drift slowly upward and sway sideways; wrap around vertically.
      final dy = (p.y - t * p.drift * 8) % 1.0;
      final y = (dy < 0 ? dy + 1.0 : dy) * size.height;
      final x = (p.x + sin(loop * 0.5 + p.phase) * p.sway) * size.width;

      final tw = 0.45 + 0.55 * (0.5 + 0.5 * sin(loop * p.twinkle + p.phase));
      final alpha = (p.baseAlpha * tw).clamp(0.0, 1.0);

      // Soft glow halo.
      canvas.drawCircle(
        Offset(x, y),
        p.radius * 3.2,
        Paint()
          ..color = _glowColor.withValues(alpha: alpha * 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2.2),
      );
      // Bright core.
      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        Paint()..color = _coreColor.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

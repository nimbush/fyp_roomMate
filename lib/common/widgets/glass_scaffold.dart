import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:roommate_finder/config/app_colors.dart';

/// Screen root: mesh-gradient backdrop + slowly drifting blurred blooms.
///
/// Every screen sits on this. The blooms are painted, not blurred with a
/// `BackdropFilter` - they're already soft radial gradients, so blurring them
/// would burn the one blur pass the glass cards need (DESIGN.md "Faux glass").
class GlassScaffold extends StatefulWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
    this.extendBody = true,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final bool? resizeToAvoidBottomInset;

  @override
  State<GlassScaffold> createState() => _GlassScaffoldState();
}

class _GlassScaffoldState extends State<GlassScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    // 30s so the movement reads as ambient rather than as something happening.
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: hold the blooms at their start position instead of
    // looping. The layout is identical either way, only the drift stops.
    if (MediaQuery.of(context).disableAnimations) {
      _drift.stop();
      _drift.value = 0;
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      extendBody: widget.extendBody,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: widget.appBar,
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backdropTop,
                    AppColors.backdropMid,
                    AppColors.backdropBottom,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (_, _) => CustomPaint(
                  painter: _BloomPainter(t: _drift.value),
                ),
              ),
            ),
          ),
          Positioned.fill(child: widget.body),
        ],
      ),
    );
  }
}

/// Three soft radial blooms tracing slow independent circles.
class _BloomPainter extends CustomPainter {
  _BloomPainter({required this.t});

  /// 0..1 drift phase.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Spread wide and pushed toward the corners: clustering them near the top
    // concentrated colour exactly where the content sits, which is what made
    // the page tiring to read.
    final blooms = [
      (
        color: AppColors.bloomA,
        base: Offset(size.width * 1.02, size.height * -0.02),
        radius: size.width * 0.95,
        phase: 0.0,
        travel: 18.0,
      ),
      (
        color: AppColors.bloomB,
        base: Offset(size.width * -0.08, size.height * 0.62),
        radius: size.width * 0.85,
        phase: 0.4,
        travel: 14.0,
      ),
      (
        color: AppColors.bloomC,
        base: Offset(size.width * 0.75, size.height * 1.04),
        radius: size.width * 0.80,
        phase: 0.75,
        travel: 20.0,
      ),
    ];

    for (final b in blooms) {
      final angle = (t + b.phase) * 2 * math.pi;
      final center = b.base +
          Offset(math.cos(angle) * b.travel, math.sin(angle) * b.travel * 0.7);

      canvas.drawCircle(
        center,
        b.radius,
        Paint()
          ..shader = RadialGradient(
            // Front-loaded stops so the tint fades out well before the circle's
            // edge; a linear falloff leaves a faint visible rim.
            colors: [
              b.color,
              b.color.withValues(alpha: b.color.a * 0.35),
              b.color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: b.radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_BloomPainter oldDelegate) => oldDelegate.t != t;
}

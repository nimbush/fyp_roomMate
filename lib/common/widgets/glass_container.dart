import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:roommate_finder/config/app_colors.dart';

/// The glass atom: shadow -> clip -> blur -> fill + rim + content.
///
/// This container carries the entire glass look. Content placed inside must not
/// add its own translucent fills or borders on top - see DESIGN.md "Glass
/// anatomy".
///
/// **One blur at a time.** A `BackdropFilter` is expensive and Impeller must
/// never nest them, so anything already sitting on glass (badges, chips on a
/// card, the deck's floating action buttons) has to pass `faux: true`, which
/// renders fill + rim with no blur.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.fill,
    this.blur = 18,
    this.faux = false,
    this.showShadow = true,
    this.border,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? fill;
  final double blur;

  /// Skip the `BackdropFilter`. Required when this sits on an already-blurred
  /// surface; a nested blur is a correctness bug, not just a cost.
  final bool faux;

  final bool showShadow;
  final BoxBorder? border;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(22.r);
    final resolvedFill = fill ?? AppColors.glassFill;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedFill,
        borderRadius: radius,
        border: border ??
            Border.all(
              color: AppColors.glassBorderInk,
              width: AppColors.isDark ? 1.2 : 1.0,
            ),
      ),
      child: child,
    );

    // The rim only reads against a dark canvas; in light mode the hairline
    // border above is the whole edge treatment.
    if (AppColors.isDark) {
      content = CustomPaint(
        painter: _RimPainter(radius: radius),
        child: content,
      );
    }

    Widget surface = ClipRRect(
      borderRadius: radius,
      child: faux
          ? content
          : BackdropFilter(
              filter: ImageFilter.compose(
                outer: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                // Mild saturation boost keeps colour behind the frost from going
                // flat. Kept close to 1.0 in dark - the old 1.45 amplified every
                // accent behind the glass and made the whole theme read as
                // oversaturated.
                inner: ColorFilter.matrix(
                  _saturation(AppColors.isDark ? 1.05 : 1.2),
                ),
              ),
              child: content,
            ),
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, borderRadius: radius, child: surface),
      );
    }

    return Container(
      margin: margin,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.glassShadowSoft,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: surface,
    );
  }

  /// Saturation as a 5x4 colour matrix, per the standard luminance weights.
  static List<double> _saturation(double v) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    return <double>[
      (1 - v) * lr + v, (1 - v) * lg, (1 - v) * lb, 0, 0,
      (1 - v) * lr, (1 - v) * lg + v, (1 - v) * lb, 0, 0,
      (1 - v) * lr, (1 - v) * lg, (1 - v) * lb + v, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Light-catching gradient rim for dark mode: bright at the top-left where the
/// ambient light would fall, fading to nothing at the bottom-right.
class _RimPainter extends CustomPainter {
  _RimPainter({required this.radius});

  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRRect(radius.toRRect(rect).deflate(0.6), paint);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) => oldDelegate.radius != radius;
}

/// A [GlassContainer] with the standard content padding.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.fill,
    this.faux = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? fill;
  final bool faux;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding ?? EdgeInsets.all(18.r),
      margin: margin,
      borderRadius: borderRadius,
      fill: fill,
      faux: faux,
      onTap: onTap,
      child: child,
    );
  }
}

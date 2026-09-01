import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:roommate_finder/config/app_colors.dart';

enum MkButtonVariant { solid, outline, tonal }

/// The only button in the app (DESIGN.md: never raw `ElevatedButton`/`TextButton`).
///
/// Press state comes from a `Listener`, while the tap itself stays on the inner
/// `InkWell` - one tap owner per button. Adding a second gesture recognizer
/// around a button is how you get double submits.
class MkButton extends StatefulWidget {
  const MkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MkButtonVariant.solid,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height,
    this.danger = false,
  });

  const MkButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height,
    this.danger = false,
  }) : variant = MkButtonVariant.outline;

  const MkButton.tonal({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height,
    this.danger = false,
  }) : variant = MkButtonVariant.tonal;

  final String label;
  final VoidCallback? onPressed;
  final MkButtonVariant variant;
  final IconData? icon;

  /// Shows a spinner and blocks taps. Prevents the double-submit that a plain
  /// disabled flag on the caller side tends to miss.
  final bool loading;

  final bool expand;
  final double? height;
  final bool danger;

  @override
  State<MkButton> createState() => _MkButtonState();
}

class _MkButtonState extends State<MkButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final accent = widget.danger ? AppColors.error : AppColors.primary;
    final radius = BorderRadius.circular(16.r);
    final height = widget.height ?? 54.h;

    final fg = switch (widget.variant) {
      MkButtonVariant.solid => Colors.white,
      MkButtonVariant.outline => accent,
      MkButtonVariant.tonal => widget.danger ? accent : AppColors.accentInk,
    };

    Widget label = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 18.r,
            height: 18.r,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 18.sp, color: fg),
        if (widget.loading || widget.icon != null) SizedBox(width: 10.w),
        Text(
          widget.label,
          style: TextStyle(
            color: fg,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final decoration = switch (widget.variant) {
      MkButtonVariant.solid => BoxDecoration(
          gradient: widget.danger
              ? LinearGradient(colors: [accent, accent.withValues(alpha: 0.82)])
              : AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      MkButtonVariant.outline => BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: accent, width: 1.4),
        ),
      MkButtonVariant.tonal => BoxDecoration(
          color: widget.danger
              ? accent.withValues(alpha: AppColors.isDark ? 0.20 : 0.08)
              : AppColors.primarySoft,
          borderRadius: radius,
          border: Border.all(
            color: AppColors.isDark ? AppColors.accentRing : Colors.transparent,
            width: 1.2,
          ),
        ),
    };

    Widget button = Opacity(
      opacity: _enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? widget.onPressed : null,
            borderRadius: radius,
            child: SizedBox(
              height: height,
              width: widget.expand ? double.infinity : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Center(child: label),
              ),
            ),
          ),
        ),
      ),
    );

    // Solid buttons get a diagonal sheen so they read as glass, not flat paint.
    if (widget.variant == MkButtonVariant.solid) {
      button = Stack(
        children: [
          button,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: radius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (reduceMotion) {
      return _wrapPressListener(button, track: false);
    }

    return _wrapPressListener(
      AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: button,
      ),
      track: true,
    );
  }

  Widget _wrapPressListener(Widget child, {required bool track}) {
    if (!track || !_enabled) return child;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: child,
    );
  }
}

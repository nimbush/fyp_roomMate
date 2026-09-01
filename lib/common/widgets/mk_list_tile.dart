import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';

/// Small rounded-square icon chip: accent glyph on a soft accent tint.
///
/// Used to anchor every settings/FAQ row so labels align on a consistent left
/// edge.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.color,
    this.size,
  });

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    final box = size ?? 34.r;
    return Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        // Low alpha in dark - a stronger tint over a dark card goes opaque and
        // muddy rather than reading as colour. The ring carries the accent.
        color: tint.withValues(alpha: AppColors.isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.isDark
              ? tint.withValues(alpha: 0.38)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Icon(
        icon,
        size: box * 0.52,
        // The glyph keeps the accent hue in both modes; forcing it to near-white
        // in dark made every chip look identical regardless of its category.
        color: tint,
      ),
    );
  }
}

/// A row inside a [MkCardGroup]: icon chip, label, optional trailing, chevron.
class MkListRow extends StatelessWidget {
  const MkListRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.labelColor,
    this.showChevron = true,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool showChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        // 56dp+ row height: comfortable to hit, consistent down the card.
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            IconChip(icon: icon, color: iconColor),
            SizedBox(width: 13.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.textInk,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (showChevron) ...[
              SizedBox(width: 6.w),
              // Disclosure arrows stay plain thin outline, never duotone.
              Icon(SolarIconsOutline.altArrowRight,
                  size: 17.sp, color: AppColors.textFaint),
            ],
          ],
        ),
      ),
    );
  }
}

/// White card wrapping a set of rows, with hairline dividers between them.
class MkCardGroup extends StatelessWidget {
  const MkCardGroup({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.glassBorderInk),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.30 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        // Stretch, or a child that sizes to its content (rather than filling a
        // Row) collapses to its intrinsic width and sits centred in the card.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              // Hairline: `height: 1` is a real device pixel, never scaled.
              Divider(
                height: 1,
                thickness: 0.5,
                // Indent past the icon chip so the rule reads as grouping the
                // rows rather than cutting the card in half.
                indent: 61.w,
                color: AppColors.glassBorderInk,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Small uppercase group label sitting above a [MkCardGroup].
class MkGroupLabel extends StatelessWidget {
  const MkGroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 9.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

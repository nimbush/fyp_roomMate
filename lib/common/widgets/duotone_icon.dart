import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Feature/tile icon treatment: a bold glyph stacked under its outline at 35%
/// opacity, giving the two-tone depth the glass surfaces expect.
///
/// Chevrons and disclosure arrows deliberately do NOT use this - they stay plain
/// thin `SolarIconsOutline` (DESIGN.md).
class DuotoneIcon extends StatelessWidget {
  const DuotoneIcon({
    super.key,
    required this.bold,
    required this.outline,
    required this.color,
    this.size,
  });

  final IconData bold;
  final IconData outline;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final resolved = size ?? 22.sp;
    return SizedBox(
      width: resolved,
      height: resolved,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(bold, size: resolved, color: color.withValues(alpha: 0.35)),
          Icon(outline, size: resolved, color: color),
        ],
      ),
    );
  }
}

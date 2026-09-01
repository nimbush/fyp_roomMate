import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'back_nav.dart';

/// Frosted app bar for pushed screens.
///
/// This owns a `BackdropFilter`, so screens using it must not wrap their body in
/// another blurred surface at the same depth.
class MkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MkAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);


  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        // Keyed to the mode: without it the filter keeps sampling the snapshot
        // taken before a theme switch, leaving a dark bar sitting on a light
        // page until the route is rebuilt from scratch.
        key: ValueKey(AppColors.isDark),
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: AppBar(
          // Frosted, not opaque - content scrolling under the bar should blur
          // through it rather than disappear behind a solid fill.
          backgroundColor: AppColors.glassFillFrosted,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: showBack
              ? IconButton(
                  // Chevrons are plain thin outline icons, never duotone.
                  icon: Icon(SolarIconsOutline.altArrowLeft, size: 24.sp),
                  color: AppColors.textInk,
                  onPressed: onBack ?? () => popRoute(context),
                  tooltip: 'Back',
                )
              : null,
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.textInk,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: actions,
        ),
      ),
    );
  }
}

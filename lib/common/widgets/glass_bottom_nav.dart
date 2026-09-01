import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.bold,
    required this.outline,
    required this.label,
  });

  final IconData bold;
  final IconData outline;
  final String label;
}

/// Frosted pill nav bar.
///
/// Owns a `BackdropFilter`, so the selected-item treatment inside is faux glass
/// (fill + ring, no second blur).
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Starts slightly above the nav so the lightest blur layer eases in
        // rather than switching on exactly at the pill's top edge.
        Positioned(
          left: 0,
          right: 0,
          top: -4.h,
          bottom: 0,
          child: const _BottomEdgeBlur(),
        ),
        _buildPill(context),
      ],
    );
  }

  Widget _buildPill(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: BackdropFilter(
              // Keyed to the mode so a theme switch discards the cached
              // backdrop snapshot instead of blurring the old palette.
              key: ValueKey(AppColors.isDark),
              // Strong blur so content passing under the pill dissolves into
              // frost rather than staying legible through it.
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.glassFillFrosted,
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: AppColors.glassBorderInk,
                    width: AppColors.isDark ? 1.2 : 1.0,
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _NavItem(
                        item: items[i],
                        isActive: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progressive frost under the whole nav region, so content scrolling past
/// the floating pill dissolves at the screen edge instead of staying sharply
/// legible in the gaps beside/below it.
///
/// Three stacked backdrop layers of increasing sigma approximate a gradient
/// blur (a single filter would end in a hard "glass shelf" line at its top
/// edge); a faint scaffold-tinted gradient adds legibility at the very bottom.
class _BottomEdgeBlur extends StatelessWidget {
  const _BottomEdgeBlur();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final (heightFactor, sigma) in const [
            (1.0, 2.5),
            (0.66, 6.0),
            (0.36, 12.0),
          ])
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                widthFactor: 1.0,
                child: ClipRect(
                  child: BackdropFilter(
                    // Keyed to the mode for the same cached-snapshot reason
                    // as the pill's filter above.
                    key: ValueKey('$sigma-${AppColors.isDark}'),
                    filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.scaffoldBackground.withValues(alpha: 0.0),
                  AppColors.scaffoldBackground.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The selected nav label is one of the two documented full-primary
    // exceptions, so it wears `primary` in both modes rather than accentInk.
    // Unselected uses textMuted in light - textFaint is too washed out against
    // the bright bar (it's the right choice only in dark).
    final color = isActive
        ? AppColors.primary
        : (AppColors.isDark ? AppColors.textFaint : AppColors.textMuted);

    return Expanded(
      child: Semantics(
        selected: isActive,
        button: true,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            // The highlight wraps the icon AND its label as one pill, so the
            // selected tab reads as a single unit rather than a badged glyph.
            // 48dp min height keeps the touch target legal regardless.
            constraints: BoxConstraints(minHeight: 48.h),
            padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 4.w),
            decoration: isActive
                ? BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: AppColors.isDark
                          ? AppColors.accentRing
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? item.bold : item.outline,
                  size: 21.sp,
                  color: color,
                ),
                SizedBox(height: 3.h),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The four tabs, in shell order.
const kMainNavItems = <GlassNavItem>[
  GlassNavItem(
    bold: SolarIconsBold.compass,
    outline: SolarIconsOutline.compass,
    label: 'Discover',
  ),
  GlassNavItem(
    bold: SolarIconsBold.heart,
    outline: SolarIconsOutline.heart,
    label: 'Matches',
  ),
  GlassNavItem(
    bold: SolarIconsBold.chatRound,
    outline: SolarIconsOutline.chatRound,
    label: 'Chats',
  ),
  GlassNavItem(
    bold: SolarIconsBold.user,
    outline: SolarIconsOutline.user,
    label: 'Profile',
  ),
];

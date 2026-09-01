import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'mk_button.dart';

/// The one place a screen maps loading / error / empty / success to UI.
///
/// `onLoading` should be a shape-matching placeholder (usually `SkeletonList`).
/// Omitting it falls back to a centred spinner, which is only correct when the
/// whole screen is genuinely unavailable.
///
/// Refresh deliberately does not go through here: keeping stale content on screen
/// during a refresh is the point, so callers pass `isLoading: false` once they
/// have data and let `RefreshIndicator` show the progress.
class UiStateHandler extends StatelessWidget {
  const UiStateHandler({
    super.key,
    required this.isLoading,
    required this.hasData,
    required this.child,
    this.error,
    this.onRetry,
    this.onLoading,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyAction,
  });

  final bool isLoading;
  final bool hasData;
  final Widget child;
  final String? error;
  final VoidCallback? onRetry;
  final Widget Function()? onLoading;
  final String? emptyTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    // Only show the loading state when there's nothing to show yet - never
    // replace existing content with a skeleton.
    if (isLoading && !hasData) {
      return onLoading?.call() ??
          Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
    }

    if (error != null && !hasData) {
      return _Message(
        icon: SolarIconsOutline.wifiRouterMinimalistic,
        title: 'Something went wrong',
        message: error!,
        action: onRetry == null
            ? null
            : MkButton(
                label: 'Try again',
                icon: SolarIconsOutline.refresh,
                expand: false,
                onPressed: onRetry,
              ),
      );
    }

    if (!hasData) {
      return _Message(
        icon: emptyIcon ?? SolarIconsOutline.inbox,
        title: emptyTitle ?? 'Nothing here yet',
        message: emptyMessage ?? '',
        action: emptyAction,
      );
    }

    return child;
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.isDark
                      ? AppColors.accentRing
                      : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Icon(icon, size: 44.sp, color: AppColors.accentInk),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textInk,
              ),
            ),
            if (message.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.45,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: 22.h),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// List entrance: fade + 0.92->1.0 scale, 50ms apart.
///
/// The stagger is **capped at 8 steps** - uncapped, item 40 would sit invisible
/// for two seconds. Wrap the item, not the list.
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    // Cap the stagger at 8 steps: uncapped, item 40 would sit invisible for two
    // full seconds waiting its turn.
    final steps = widget.index.clamp(0, 8);
    Future<void>.delayed(Duration(milliseconds: 50 * steps), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}

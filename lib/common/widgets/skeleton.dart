import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:roommate_finder/config/app_colors.dart';

/// Shimmering block. Under reduced motion the sweep is skipped - the flat block
/// still reads as "loading".
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final highlight = AppColors.isDark
        ? Colors.white.withValues(alpha: 0.11)
        : Colors.black.withValues(alpha: 0.03);
    final radius = BorderRadius.circular(widget.radius ?? 8.r);

    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: base, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 3 * _c.value, 0),
              end: Alignment(1 + 3 * _c.value, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Generic card-shaped placeholder: avatar, title, subtitle, divider, two rows.
///
/// Deliberately generic - it echoes the shared card shape rather than matching
/// any one screen pixel-for-pixel, so nothing jumps when data lands.
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.glassFillSubtle,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.glassBorderInk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonShimmer(width: 52.r, height: 52.r, radius: 26.r),
              SizedBox(width: 14.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonShimmer(width: 140.w, height: 14.h),
                  SizedBox(height: 8.h),
                  SkeletonShimmer(width: 90.w, height: 11.h),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: AppColors.glassBorderInk, height: 1),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonShimmer(width: 80.w, height: 11.h),
              SkeletonShimmer(width: 60.w, height: 11.h),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonShimmer(width: 100.w, height: 11.h),
              SkeletonShimmer(width: 48.w, height: 11.h),
            ],
          ),
        ],
      ),
    );
  }
}

/// The list-shaped loading state. Use this, not a spinner, whenever the screen's
/// structure is already known.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, _) => const SkeletonListCard(),
    );
  }
}

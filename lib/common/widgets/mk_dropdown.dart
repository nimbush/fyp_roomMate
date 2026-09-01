import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';

/// Labeled select field that opens a floating options panel.
///
/// Generic over label and options - it holds no knowledge of what it's
/// selecting, so the same widget serves every dropdown in the app.
///
/// The panel is a solid rounded card, not glass: a translucent fill over
/// arbitrary page content makes the options hard to read, and it would nest a
/// second `BackdropFilter` inside screens that already own one.
class MkDropdown extends StatefulWidget {
  const MkDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.optional = false,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? hint;

  /// Derived by the caller, shown inline under the field.
  final String? errorText;

  final bool optional;

  @override
  State<MkDropdown> createState() => _MkDropdownState();
}

class _MkDropdownState extends State<MkDropdown> {
  final _fieldKey = GlobalKey();

  Future<void> _open() async {
    // Popping a route restores focus to whatever was focused underneath; if that
    // was a TextField the keyboard springs back on dismiss. Unfocus and let it
    // land before the route is pushed.
    final focus = FocusScope.of(context);
    if (focus.hasFocus) {
      focus.unfocus();
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;

    final box =
        _fieldKey.currentContext!.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);

    final selected = await Navigator.of(context).push<String>(
      _DropdownRoute(
        anchorRect: topLeft & box.size,
        overlaySize: overlay.size,
        options: widget.options,
        selected: widget.value,
      ),
    );

    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final hasValue = widget.value != null && widget.value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textInk,
              ),
            ),
            if (widget.optional) ...[
              SizedBox(width: 6.w),
              Text(
                '(optional)',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textFaint),
              ),
            ],
          ],
        ),
        SizedBox(height: 7.h),
        GestureDetector(
          key: _fieldKey,
          onTap: _open,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 54.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.glassFillSubtle,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.glassBorderInk,
                width: hasError ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue
                        ? widget.value!
                        : (widget.hint ?? 'Select ${widget.label.toLowerCase()}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color:
                          hasValue ? AppColors.textInk : AppColors.textFaint,
                    ),
                  ),
                ),
                // Disclosure chevron: plain thin outline, never duotone.
                Icon(SolarIconsOutline.altArrowDown,
                    size: 18.sp, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: EdgeInsets.only(top: 6.h, left: 4.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(SolarIconsOutline.infoCircle,
                          size: 13.sp, color: AppColors.error),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Transparent route so the page stays visible behind the floating panel.
class _DropdownRoute extends PopupRoute<String> {
  _DropdownRoute({
    required this.anchorRect,
    required this.overlaySize,
    required this.options,
    required this.selected,
  });

  final Rect anchorRect;
  final Size overlaySize;
  final List<String> options;
  final String? selected;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.18);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    const margin = 12.0;
    final rowHeight = 52.h;
    // Cap the panel so a long option list can't run off-screen; it scrolls
    // inside instead.
    final maxHeight = (overlaySize.height * 0.45)
        .clamp(rowHeight * 2, rowHeight * 6 + 16.h);
    final desiredHeight =
        (options.length * rowHeight + 16.h).clamp(0.0, maxHeight);

    // Prefer opening below the field; flip above when there isn't room.
    final spaceBelow = overlaySize.height - anchorRect.bottom - margin;
    final openDown = spaceBelow >= desiredHeight || spaceBelow >= 160.h;
    final top = openDown ? anchorRect.bottom + 6.h : null;
    final bottom =
        openDown ? null : overlaySize.height - anchorRect.top + 6.h;

    return Stack(
      children: [
        Positioned(
          left: anchorRect.left,
          width: anchorRect.width,
          top: top,
          bottom: bottom,
          child: _Panel(
            animation: animation,
            openDown: openDown,
            maxHeight: maxHeight,
            rowHeight: rowHeight,
            options: options,
            selected: selected,
          ),
        ),
      ],
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.animation,
    required this.openDown,
    required this.maxHeight,
    required this.rowHeight,
    required this.options,
    required this.selected,
  });

  final Animation<double> animation;
  final bool openDown;
  final double maxHeight;
  final double rowHeight;
  final List<String> options;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final panel = Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.glassBorderInk),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, i) {
            final option = options[i];
            final isSelected = option == selected;
            return InkWell(
              onTap: () => Navigator.pop(context, option),
              child: Container(
                height: rowHeight,
                margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  // Only the selected row carries a fill; the rest stay clear.
                  color: isSelected
                      ? AppColors.primarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.accentInk
                              : AppColors.textInk,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(SolarIconsBold.checkCircle,
                          size: 17.sp, color: AppColors.primary),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (reduceMotion) return panel;

    // Grow from the anchored edge so the panel reads as belonging to the field.
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Align(
          alignment: openDown ? Alignment.topCenter : Alignment.bottomCenter,
          heightFactor: Curves.easeOut.transform(animation.value),
          child: child,
        ),
      ),
      child: panel,
    );
  }
}

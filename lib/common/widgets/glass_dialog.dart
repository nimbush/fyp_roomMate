import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'mk_button.dart';

/// Unfocuses and waits a frame before pushing a route.
///
/// Popping a route restores focus to whatever the route underneath had focused.
/// If that was a `TextField`, the keyboard springs back with a caret in a field
/// the user never tapped. Calling `unfocus()` at the call site does NOT fix it -
/// focus changes apply asynchronously, so the route gets pushed while the field
/// is still focused. Awaiting a frame lets the unfocus land first.
Future<void> dismissKeyboardBeforeRoute(BuildContext context) async {
  final focus = FocusScope.of(context);
  if (!focus.hasFocus) return;
  focus.unfocus();
  await WidgetsBinding.instance.endOfFrame;
}

/// Dialog with a blurred barrier.
///
/// The dialog surface itself is deliberately **solid** - a translucent glass fill
/// disappears against the dark canvas (DESIGN.md).
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) async {
  await dismissKeyboardBeforeRoute(context);
  if (!context.mounted) return null;

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: child,
    ),
  );
}

/// Confirm dialog: outline cancel left, solid action right, in a Row.
///
/// Never `AlertDialog.actions` - those stack vertically as soon as the labels are
/// wide, which reads as two unrelated buttons rather than a choice.
Future<bool> showGlassConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showGlassDialog<bool>(
    context: context,
    // Pop with the dialog route's own context, not the caller's - popping the
    // caller's context would dismiss the screen underneath.
    child: Builder(
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        titlePadding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 8.h),
        contentPadding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 18.h),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textInk,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(
                  child: MkButton.outline(
                    label: cancelLabel,
                    height: 46.h,
                    onPressed: () => Navigator.pop(dialogContext, false),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MkButton(
                    label: confirmLabel,
                    height: 46.h,
                    danger: danger,
                    onPressed: () => Navigator.pop(dialogContext, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

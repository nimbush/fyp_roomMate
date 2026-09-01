import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';

/// Routes that belong to the signed-out flow. Falling back from one of these
/// should land on sign-in, not inside the app shell.
const _authRoutes = {
  '/login',
  '/register',
  '/verify-otp',
  '/forgot-password',
  '/reset-password',
};

/// Goes back through **GoRouter**, not the root Navigator.
///
/// `context.push` puts routes on GoRouter's own stack. Material's `BackButton`
/// and `Navigator.maybePop` target the root Navigator instead, so they find
/// nothing to pop and silently do nothing - the button looks alive but is inert.
///
/// `canPop` is checked because popping the last route leaves a black screen: a
/// screen opened directly (deep link, or after a `go` that replaced the stack)
/// has no history, so it falls back to a sensible destination instead.
void popRoute(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  final location = GoRouterState.of(context).uri.path;
  context.go(_authRoutes.contains(location) ? '/login' : '/home');
}

/// Back chevron for screens that aren't on `MkAppBar` yet.
///
/// Drop-in replacement for `const BackButton()`, which is broken under GoRouter.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(SolarIconsOutline.altArrowLeft, size: 24.sp),
      color: AppColors.textInk,
      tooltip: 'Back',
      onPressed: () => popRoute(context),
    );
  }
}

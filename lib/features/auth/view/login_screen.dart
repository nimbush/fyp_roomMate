import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/common/utils/validators.dart';
import 'package:roommate_finder/features/auth/controller/auth_controller.dart';
import 'package:roommate_finder/common/widgets/glass_container.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/mk_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Field keys in visual order, so submit can scroll to the first invalid one.
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();

  /// Errors stay hidden until the first submit, so untouched fields don't nag.
  bool _showErrors = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Derived from state rather than stored, so a message can't go stale after the
  // user fixes the field.
  String? get _emailError {
    final v = _emailCtrl.text.trim();
    if (v.isEmpty) return 'Enter the email you signed up with';
    if (!isValidEmail(v)) return 'That email looks incomplete - check for typos';
    return null;
  }

  String? get _passwordError =>
      _passwordCtrl.text.isEmpty ? 'Enter your password' : null;

  void _snack(String message, {bool isError = true}) {
    // ScaffoldMessenger queues, so rapid taps would surface messages long after
    // the user stopped tapping. Always clear the current one first.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ));
  }

  Future<void> _login() async {
    if (ref.read(authControllerProvider).isLoading) return;

    setState(() => _showErrors = true);

    // Surface every error at once, then move to the first one - never a chain of
    // snackbars the user has to tap through.
    final firstInvalid = <(GlobalKey, String?)>[
      (_emailKey, _emailError),
      (_passwordKey, _passwordError),
    ].where((e) => e.$2 != null).firstOrNull;

    if (firstInvalid != null) {
      final ctx = firstInvalid.$1.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.15,
          duration: const Duration(milliseconds: 250),
        );
      }
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      _snack(ref.read(authControllerProvider).error ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return GlassScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 22.w,
            right: 22.w,
            top: 20.h,
            // Pad by the keyboard inset so the button can always be scrolled
            // clear of the keyboard on short screens.
            bottom: 28.h + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              _Brand(),
              SizedBox(height: 34.h),
              GlassCard(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textInk,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Sign in to pick up where you left off.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 26.h),
                    MkTextField(
                      key: _emailKey,
                      label: 'Email address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: SolarIconsOutline.letter,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      errorText: _showErrors ? _emailError : null,
                      // Once errors are live, clear each one as it's fixed.
                      onChanged: _showErrors ? (_) => setState(() {}) : null,
                    ),
                    SizedBox(height: 18.h),
                    MkTextField(
                      key: _passwordKey,
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordCtrl,
                      obscureText: true,
                      prefixIcon: SolarIconsOutline.lockPassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      errorText: _showErrors ? _passwordError : null,
                      onChanged: _showErrors ? (_) => setState(() {}) : null,
                    ),
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    MkButton(
                      label: 'Sign in',
                      loading: isLoading,
                      onPressed: _login,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        child: Text(
                          'Create one',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(SolarIconsBold.home, color: Colors.white, size: 26.sp),
        ),
        SizedBox(width: 14.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RoomMate Finder',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textInk,
              ),
            ),
            Text(
              'Find someone you can live with',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

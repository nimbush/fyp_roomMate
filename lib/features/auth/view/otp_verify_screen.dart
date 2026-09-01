import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/features/auth/controller/auth_controller.dart';
import 'package:roommate_finder/common/widgets/glass_container.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_app_bar.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/otp_field.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  String _otp = '';
  int _resendTimer = 60;
  Timer? _timer;

  /// Hidden until the first submit, like every other form in the app.
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _resendTimer = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendTimer == 0) {
        t.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? get _otpError =>
      _otp.length == 6 ? null : 'Enter all 6 digits from the email';

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ));
  }

  Future<void> _verify() async {
    if (ref.read(authControllerProvider).isLoading) return;

    setState(() => _showError = true);
    // Incomplete code is shown inline under the boxes, not as a snackbar.
    if (_otpError != null) return;

    final ok = await ref.read(authControllerProvider.notifier).verifyOtp(_otp);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      _snack(ref.read(authControllerProvider).error ??
          'That code was invalid or has expired');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return GlassScaffold(
      appBar: const MkAppBar(title: 'Verify email'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22.w,
          kToolbarHeight + MediaQuery.of(context).padding.top + 12.h,
          22.w,
          28.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 26.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(SolarIconsBold.letterOpened,
                        size: 36.sp, color: Colors.white),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Check your email',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textInk,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.45,
                        color: AppColors.textMuted,
                      ),
                      children: [
                        const TextSpan(text: 'We sent a 6-digit code to\n'),
                        TextSpan(
                          // Quote the address back, so a typo is obvious here
                          // rather than after a failed verification.
                          text: auth.pendingEmail ?? 'your email',
                          style: TextStyle(
                            color: AppColors.textInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30.h),
                  OtpField(
                    length: 6,
                    onCompleted: (otp) => setState(() => _otp = otp),
                    onChanged: (otp) => setState(() => _otp = otp),
                  ),
                  // AnimatedSize so the layout shift is explained, not abrupt.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: _showError && _otpError != null
                        ? Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(SolarIconsOutline.infoCircle,
                                    size: 13.sp, color: AppColors.error),
                                SizedBox(width: 5.w),
                                Text(
                                  _otpError!,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  SizedBox(height: 26.h),
                  MkButton(
                    label: 'Verify email',
                    loading: auth.isLoading,
                    onPressed: _verify,
                  ),
                  SizedBox(height: 20.h),
                  if (_resendTimer > 0)
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.sp,
                        ),
                        children: [
                          const TextSpan(text: 'Didn\'t get it? Resend in '),
                          TextSpan(
                            text: '${_resendTimer}s',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    MkButton.tonal(
                      label: 'Resend code',
                      icon: SolarIconsOutline.refresh,
                      expand: false,
                      height: 42.h,
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).resendOtp();
                        _startTimer();
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            // Checking spam is the actual fix when the code doesn't arrive.
            GlassContainer(
              showShadow: false,
              fill: AppColors.glassFillSubtle,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
              child: Row(
                children: [
                  Icon(SolarIconsOutline.infoCircle,
                      size: 15.sp, color: AppColors.textFaint),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Text(
                      'Codes expire after 5 minutes. If it hasn\'t arrived, '
                      'check your spam folder.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.4,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

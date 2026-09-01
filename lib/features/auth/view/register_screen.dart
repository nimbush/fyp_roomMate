import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/common/utils/validators.dart';
import 'package:roommate_finder/features/auth/controller/auth_controller.dart';
import 'package:roommate_finder/common/widgets/glass_container.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_app_bar.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/mk_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Field keys in visual order, so submit can scroll to the first invalid one.
  final _firstNameKey = GlobalKey();
  final _lastNameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _confirmKey = GlobalKey();

  /// Errors stay hidden until the first submit, so untouched fields don't nag.
  bool _showErrors = false;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Each error is derived from state, never stored - a stored string goes stale
  // the moment the user fixes the field.
  //
  // Copy names the fix, not the rule: "Enter your first name", not "Required".

  String? get _firstNameError =>
      _firstNameCtrl.text.trim().isEmpty ? 'Enter your first name' : null;

  String? get _lastNameError =>
      _lastNameCtrl.text.trim().isEmpty ? 'Enter your last name' : null;

  String? get _emailError {
    final v = _emailCtrl.text.trim();
    if (v.isEmpty) return 'Enter an email we can send your code to';
    if (!isValidEmail(v)) return 'That email looks incomplete - check for typos';
    return null;
  }

  String? get _phoneError {
    final v = _phoneCtrl.text.trim();
    if (v.isEmpty) return 'Enter a phone number';
    if (v.length < 7) return 'That number looks too short';
    return null;
  }

  String? get _passwordError {
    final v = _passwordCtrl.text;
    if (v.isEmpty) return 'Choose a password';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  String? get _confirmError {
    if (_confirmCtrl.text.isEmpty) return 'Re-enter your password';
    if (_confirmCtrl.text != _passwordCtrl.text) {
      return "This doesn't match the password above";
    }
    return null;
  }

  void _snack(String message) {
    // ScaffoldMessenger queues, so rapid taps would surface stale messages long
    // after the user stopped tapping.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ));
  }

  Future<void> _register() async {
    if (ref.read(authControllerProvider).isLoading) return;

    setState(() => _showErrors = true);

    // Show every error at once, then move to the first one - never a queue of
    // snackbars the user has to tap through to discover problems one at a time.
    final firstInvalid = <(GlobalKey, String?)>[
      (_firstNameKey, _firstNameError),
      (_lastNameKey, _lastNameError),
      (_emailKey, _emailError),
      (_phoneKey, _phoneError),
      (_passwordKey, _passwordError),
      (_confirmKey, _confirmError),
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

    final ok = await ref.read(authControllerProvider.notifier).register(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      context.push('/verify-otp');
    } else {
      _snack(ref.read(authControllerProvider).error ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return GlassScaffold(
      appBar: const MkAppBar(title: 'Create account'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22.w,
          kToolbarHeight + MediaQuery.of(context).padding.top + 8.h,
          22.w,
          // Pad by the keyboard inset so the submit button can always be
          // scrolled clear of the keyboard.
          28.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(SolarIconsBold.userPlus,
                            color: Colors.white, size: 22.sp),
                      ),
                      SizedBox(width: 13.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get started',
                              style: TextStyle(
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textInk,
                              ),
                            ),
                            Text(
                              'Takes about a minute.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MkTextField(
                          key: _firstNameKey,
                          label: 'First name',
                          hint: 'John',
                          controller: _firstNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.givenName],
                          textInputAction: TextInputAction.next,
                          errorText: _showErrors ? _firstNameError : null,
                          onChanged:
                              _showErrors ? (_) => setState(() {}) : null,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: MkTextField(
                          key: _lastNameKey,
                          label: 'Last name',
                          hint: 'Doe',
                          controller: _lastNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.familyName],
                          textInputAction: TextInputAction.next,
                          errorText: _showErrors ? _lastNameError : null,
                          onChanged:
                              _showErrors ? (_) => setState(() {}) : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  MkTextField(
                    key: _emailKey,
                    label: 'Email address',
                    hint: 'john@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: SolarIconsOutline.letter,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    errorText: _showErrors ? _emailError : null,
                    onChanged: _showErrors ? (_) => setState(() {}) : null,
                  ),
                  SizedBox(height: 16.h),
                  MkTextField(
                    key: _phoneKey,
                    label: 'Phone number',
                    hint: '9800000000',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: SolarIconsOutline.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                    ],
                    errorText: _showErrors ? _phoneError : null,
                    onChanged: _showErrors ? (_) => setState(() {}) : null,
                  ),
                  SizedBox(height: 16.h),
                  MkTextField(
                    key: _passwordKey,
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _passwordCtrl,
                    obscureText: true,
                    prefixIcon: SolarIconsOutline.lockPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    errorText: _showErrors ? _passwordError : null,
                    // Also refresh the confirm field's error, since it's derived
                    // from this one.
                    onChanged: _showErrors ? (_) => setState(() {}) : null,
                  ),
                  SizedBox(height: 16.h),
                  MkTextField(
                    key: _confirmKey,
                    label: 'Confirm password',
                    hint: 'Re-enter your password',
                    controller: _confirmCtrl,
                    obscureText: true,
                    prefixIcon: SolarIconsOutline.lockPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _register(),
                    errorText: _showErrors ? _confirmError : null,
                    onChanged: _showErrors ? (_) => setState(() {}) : null,
                  ),
                  SizedBox(height: 22.h),
                  MkButton(
                    label: 'Create account',
                    loading: isLoading,
                    onPressed: _register,
                  ),
                  SizedBox(height: 14.h),
                  // Say what happens next, so the OTP screen isn't a surprise.
                  Row(
                    children: [
                      Icon(SolarIconsOutline.infoCircle,
                          size: 14.sp, color: AppColors.textFaint),
                      SizedBox(width: 7.w),
                      Expanded(
                        child: Text(
                          "We'll email you a 6-digit code to confirm your "
                          'address.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.4,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Text(
                        'Sign in',
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/features/auth/controller/auth_controller.dart';
import 'package:roommate_finder/common/widgets/custom_text_field.dart';
import 'package:roommate_finder/common/widgets/otp_field.dart';
import 'package:roommate_finder/common/widgets/back_nav.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  String _otp = '';
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_otp, _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password reset! Please login.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(authControllerProvider).error ?? 'Reset failed'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.lock_reset_rounded,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Enter the OTP sent to your email',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 24),
              OtpField(
                length: 6,
                onCompleted: (v) => setState(() => _otp = v),
                onChanged: (v) => setState(() => _otp = v),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'New Password',
                hint: 'Min. 8 characters',
                controller: _passwordCtrl,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'Min. 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Confirm New Password',
                hint: 'Re-enter password',
                controller: _confirmCtrl,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: isLoading ? null : _reset,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF8C61)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Reset Password',
                          style: TextStyle(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.w700,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

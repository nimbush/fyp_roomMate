import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/otp_field.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  String _otp = '';
  int _resendTimer = 60;
  Timer? _timer;

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

  Future<void> _verify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the 6-digit code'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(_otp);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Invalid OTP'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF8C61)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_rounded,
                        size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Check Your Email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a code to\n${auth.pendingEmail ?? 'your email'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 48),
                  OtpField(
                    length: 6,
                    onCompleted: (otp) => setState(() => _otp = otp),
                    onChanged: (otp) => setState(() => _otp = otp),
                  ),
                  const SizedBox(height: 40),
                  _buildVerifyButton(auth.isLoading),
                  const SizedBox(height: 28),
                  _resendTimer > 0
                      ? RichText(
                          text: TextSpan(
                            style: const TextStyle(color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'Resend code in  '),
                              TextSpan(
                                text: '${_resendTimer}s',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            context.read<AuthProvider>().resendOtp();
                            _startTimer();
                          },
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _verify,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5722), Color(0xFFFF8C61)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
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
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Text(
                'Verify Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

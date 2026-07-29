import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl,
      _phoneCtrl, _passwordCtrl, _confirmCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Registration failed'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 240,
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
            top: 160,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      IconButton(
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
                      const SizedBox(height: 4),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join thousands finding great roommates',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'First Name',
                            hint: 'John',
                            controller: _firstNameCtrl,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Last Name',
                            hint: 'Doe',
                            controller: _lastNameCtrl,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'john@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!isValidEmail(v)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Phone Number',
                        hint: '9800000000',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
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
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        controller: _confirmCtrl,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (v) => v != _passwordCtrl.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: isLoading ? null : _register,
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
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Text('Create Account',
                                  style: TextStyle(
                                    color: Colors.white, fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'Already have an account?  '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => context.pop(),
                                  child: const Text('Sign In',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

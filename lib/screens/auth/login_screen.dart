import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Login failed'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Orange top section
          Container(
            height: size.height * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF8C61)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative circle
          Positioned(
            top: -50,
            right: -50,
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
            top: 30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // White card
          Positioned(
            top: size.height * 0.28,
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
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                // Pad by the keyboard inset so the Sign In button can always be
                // scrolled above the keyboard on short screens.
                padding: EdgeInsets.only(
                  left: 28,
                  right: 28,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 52),
                      // Form fields
                      _InputLabel('Email Address'),
                      const SizedBox(height: 8),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _InputLabel('Password'),
                      const SizedBox(height: 8),
                      _buildPasswordField(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildLoginButton(isLoading),
                      const SizedBox(height: 28),
                      // Divider
                      Row(children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(color: Colors.grey.shade400)),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ]),
                      const SizedBox(height: 28),
                      // Register
                      _buildRegisterLink(),
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Enter your email',
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.email_rounded,
              color: AppColors.primary, size: 18),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!isValidEmail(v)) return 'Enter a valid email address';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      label: '',
      hint: 'Enter your password',
      controller: _passwordCtrl,
      obscureText: true,
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 18),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _login,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isLoading
              ? LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade300])
              : const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF8C61)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
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
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          children: [
            const TextSpan(text: "Don't have an account?  "),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => context.push('/register'),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

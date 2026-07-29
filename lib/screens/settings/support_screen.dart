import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/profile_provider.dart';
import '../../services/api_service.dart';
import '../../services/static_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final profile = context.read<ProfileProvider>().profile;
      await StaticService.submitSupport(
        username: profile?.fullName ?? 'User',
        phoneNumber: profile?.phoneNumber ?? '',
        email: profile?.email ?? '',
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _titleCtrl.clear();
        _bodyCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(
                e, 'Could not submit your request. Please try again.')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent, color: AppColors.primary, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Fill the form and we\'ll get back to you shortly.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Subject',
                hint: 'Brief description of your issue',
                controller: _titleCtrl,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Message',
                hint: 'Describe your issue in detail...',
                controller: _bodyCtrl,
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Message is required' : null,
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Submit Request',
                onPressed: _submit,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

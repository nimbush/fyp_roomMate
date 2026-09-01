import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/common/utils/generic_state.dart';
import 'package:roommate_finder/features/profile/controller/profile_controller.dart';
import 'package:roommate_finder/features/settings/controller/support_controller.dart';
import 'package:roommate_finder/common/widgets/custom_button.dart';
import 'package:roommate_finder/common/widgets/custom_text_field.dart';
import 'package:roommate_finder/common/widgets/back_nav.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(supportControllerProvider.notifier);
    if (controller.isSubmitting) return;

    final profile = ref.read(profileControllerProvider).profile;
    final error = await controller.submit(
      username: profile?.fullName ?? 'User',
      phoneNumber: profile?.phoneNumber ?? '',
      email: profile?.email ?? '',
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
    );
    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Support request submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _titleCtrl.clear();
      _bodyCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(supportControllerProvider) is Loading<void>;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
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
                child: Row(
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
                isLoading: isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => context.push('/edit-profile'),
          ),
          const _SectionHeader('Support & Legal'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push('/content/NOTIFICATION'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => context.push('/content/PRIVACY'),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => context.push('/content/ABOUT'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => context.push('/content/TERMS'),
          ),
          _SettingsTile(
            icon: Icons.quiz_outlined,
            title: 'FAQ',
            onTap: () => context.push('/content/FAQ'),
          ),
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            title: 'Help & Support',
            onTap: () => context.push('/support'),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Account Actions'),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor = AppColors.textPrimary,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

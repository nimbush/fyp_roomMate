import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/controller/theme_controller.dart';
import 'package:roommate_finder/features/auth/controller/auth_controller.dart';
import 'package:roommate_finder/features/profile/controller/profile_controller.dart';
import 'package:roommate_finder/common/widgets/glass_dialog.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_app_bar.dart';
import 'package:roommate_finder/common/widgets/mk_list_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Settings can be opened without visiting Profile first (deep link, or
    // straight from the nav), so the summary card has to fetch its own data
    // rather than assume the controller is already populated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(profileControllerProvider).profile != null) return;
      final userId = ref.read(authControllerProvider).userId;
      if (userId != null) {
        ref.read(profileControllerProvider.notifier).loadProfile(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).profile;

    return GlassScaffold(
      appBar: const MkAppBar(title: 'Settings'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16.w,
          kToolbarHeight + MediaQuery.of(context).padding.top + 12.h,
          16.w,
          32.h,
        ),
        children: [
          MkCardGroup(
            children: [
              MkListRow(
                icon: SolarIconsOutline.user,
                label: profile?.fullName ?? 'Your profile',
                subtitle: 'View and edit your profile',
                onTap: () => context.push('/edit-profile'),
                trailing: _Avatar(name: profile?.fullName),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          const MkGroupLabel('Appearance'),
          const _AppearanceCard(),
          SizedBox(height: 24.h),
          const MkGroupLabel('Support & legal'),
          MkCardGroup(
            children: [
              MkListRow(
                icon: SolarIconsOutline.bell,
                label: 'Notifications',
                onTap: () => context.push('/content/NOTIFICATION'),
              ),
              MkListRow(
                icon: SolarIconsOutline.shieldCheck,
                label: 'Privacy policy',
                onTap: () => context.push('/content/PRIVACY'),
              ),
              MkListRow(
                icon: SolarIconsOutline.infoCircle,
                label: 'About',
                onTap: () => context.push('/content/ABOUT'),
              ),
              MkListRow(
                icon: SolarIconsOutline.documentText,
                label: 'Terms of service',
                onTap: () => context.push('/content/TERMS'),
              ),
              MkListRow(
                icon: SolarIconsOutline.questionCircle,
                label: 'FAQ',
                onTap: () => context.push('/faq'),
              ),
              MkListRow(
                icon: SolarIconsOutline.chatRound,
                label: 'Help & support',
                onTap: () => context.push('/support'),
              ),
            ],
          ),
          SizedBox(height: 28.h),
          _LogoutButton(onTap: () => _confirmLogout(context)),
          SizedBox(height: 20.h),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showGlassConfirm(
      context: context,
      title: 'Log out?',
      message: "You'll need to sign in again to see your matches.",
      confirmLabel: 'Log out',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    // Drop the cached profile so the next account never sees this one's data.
    ref.read(profileControllerProvider.notifier).clear();
    context.go('/login');
  }
}

/// Light / Dark / System selector.
///
/// Three explicit options rather than a binary switch: "System" is a real
/// preference, and a plain on/off toggle gives the user no way back to it once
/// they've touched it.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);

    return MkCardGroup(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconChip(
                    icon: AppColors.isDark
                        ? SolarIconsOutline.moon
                        : SolarIconsOutline.sun,
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textInk,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _describe(mode),
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _ModeSegments(
                mode: mode,
                onChanged: ref.read(themeControllerProvider.notifier).setMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _describe(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Always light',
        ThemeMode.dark => 'Always dark',
        ThemeMode.system => "Follows your device setting",
      };
}

class _ModeSegments extends StatelessWidget {
  const _ModeSegments({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = <(ThemeMode, String, IconData)>[
    (ThemeMode.light, 'Light', SolarIconsOutline.sun),
    (ThemeMode.dark, 'Dark', SolarIconsOutline.moon),
    (ThemeMode.system, 'System', SolarIconsOutline.smartphone),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.glassFillSubtle,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.glassBorderInk),
      ),
      child: Row(
        children: [
          for (final (value, label, icon) in _options)
            Expanded(
              child: Semantics(
                selected: mode == value,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(value),
                  borderRadius: BorderRadius.circular(11.r),
                  child: AnimatedContainer(
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    // 44dp min target across the segment.
                    constraints: BoxConstraints(minHeight: 40.h),
                    decoration: BoxDecoration(
                      color: mode == value
                          ? AppColors.primarySoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11.r),
                      border: Border.all(
                        color: mode == value && AppColors.isDark
                            ? AppColors.accentRing
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 17.sp,
                          color: mode == value
                              ? AppColors.accentInk
                              : AppColors.textMuted,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: mode == value
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: mode == value
                                ? AppColors.accentInk
                                : AppColors.textMuted,
                          ),
                        ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
          // Still loading - a person glyph reads better than a "?", which looks
          // like the account is broken.
          ? Icon(SolarIconsBold.user, size: 19.sp, color: Colors.white)
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  String get initials => _initials(name);

  /// First letter of the first two words - "Test One" -> "TO".
  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Logout as a tinted action button, not a list row - it's an action, and
/// styling it like the navigation rows above invites mis-taps.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 54.h,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(SolarIconsOutline.logout,
                  size: 18.sp, color: AppColors.accentInk),
              SizedBox(width: 9.w),
              Text(
                'Log out',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

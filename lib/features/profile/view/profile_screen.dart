import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/config/app_config.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/auth/controller/auth_controller.dart';
import 'package:roommate_finder/features/profile/controller/profile_controller.dart';
import 'package:roommate_finder/features/profile/model/user_model.dart';
import 'package:roommate_finder/common/widgets/duotone_icon.dart';
import 'package:roommate_finder/common/widgets/glass_container.dart';
import 'package:roommate_finder/common/widgets/glass_dialog.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/ui_state_handler.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = await ref.read(localStorageProvider).getUserId();
    if (userId != null && mounted) {
      await ref.read(profileControllerProvider.notifier).loadProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    return GlassScaffold(
      body: UiStateHandler(
        isLoading: state.isLoading,
        hasData: profile != null,
        error: state.error,
        onRetry: _load,
        emptyIcon: SolarIconsOutline.user,
        emptyTitle: 'Profile unavailable',
        emptyMessage: "We couldn't load your details. Pull down to try again.",
        emptyAction: MkButton(
          label: 'Try again',
          icon: SolarIconsOutline.refresh,
          expand: false,
          onPressed: _load,
        ),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SafeArea(bottom: false, child: SizedBox(height: 8.h)),
              if (profile != null) ...[
                _ProfileHeader(profile: profile),
                SizedBox(height: 18.h),
                _ActionRow(onLogout: () => _confirmLogout(context)),
                SizedBox(height: 18.h),
                _StatsCard(profile: profile),
                SizedBox(height: 14.h),
                _InfoSection(
                  bold: SolarIconsBold.magnifier,
                  outline: SolarIconsOutline.magnifier,
                  title: 'Looking for',
                  color: AppColors.primary,
                  items: _lookingForItems(profile),
                ),
                SizedBox(height: 14.h),
                _InfoSection(
                  bold: SolarIconsBold.cup,
                  outline: SolarIconsOutline.cup,
                  title: 'Lifestyle',
                  color: AppColors.accentViolet,
                  items: _lifestyleItems(profile),
                ),
                SizedBox(height: 14.h),
                _InfoSection(
                  bold: SolarIconsBold.user,
                  outline: SolarIconsOutline.user,
                  title: 'About me',
                  color: AppColors.accentTeal,
                  items: _aboutItems(profile),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// EARLY_BIRD -> Early bird. Never show a backend enum raw.
  static String _pretty(String raw) {
    final w = raw.toLowerCase().replaceAll('_', ' ');
    return w.isEmpty ? w : w[0].toUpperCase() + w.substring(1);
  }

  List<_Info> _lookingForItems(UserModel p) => [
        _Info(
          SolarIconsOutline.magnifier,
          'Searching',
          p.searchingRoommate == true
              ? 'A roommate'
              : (p.searchingRoom == true ? 'A room' : 'Not specified'),
        ),
        if (p.roommateGender != null)
          _Info(SolarIconsOutline.usersGroupRounded, 'Preferred gender',
              _pretty(p.roommateGender!)),
        if (p.minBudget != null && p.maxBudget != null)
          _Info(SolarIconsOutline.wallet, 'Budget',
              'Rs ${p.minBudget!.toInt()} - ${p.maxBudget!.toInt()}'),
      ];

  List<_Info> _lifestyleItems(UserModel p) => [
        if (p.sleepingSchedule != null)
          _Info(SolarIconsOutline.moon, 'Sleep', _pretty(p.sleepingSchedule!)),
        if (p.diet != null)
          _Info(SolarIconsOutline.chefHat, 'Diet', _pretty(p.diet!)),
        _Info(SolarIconsOutline.leaf, 'Smoking',
            p.smoking == true ? 'Smoker' : 'Non-smoker'),
        // 0 means "not set yet" (backend primitive int), not "least clean".
        if (p.cleanliness != null && p.cleanliness! >= 1)
          _Info(
            SolarIconsOutline.broom,
            'Cleanliness',
            '${'★' * p.cleanliness!.clamp(1, 5)}'
                '${'☆' * (5 - p.cleanliness!.clamp(1, 5))}',
          ),
        if (p.petPreference != null)
          _Info(SolarIconsOutline.paw, 'Pets', _pretty(p.petPreference!)),
      ];

  List<_Info> _aboutItems(UserModel p) => [
        if (p.occupation != null)
          _Info(SolarIconsOutline.case_, 'Occupation', p.occupation!),
        if (p.hobbies != null)
          _Info(SolarIconsOutline.confetti, 'Hobbies', p.hobbies!),
        if (p.musicPreference != null)
          _Info(SolarIconsOutline.musicNote, 'Music', p.musicPreference!),
        if (p.notes != null)
          _Info(SolarIconsOutline.notes, 'Notes', p.notes!),
      ];

  /// Logging out is destructive enough to confirm, but not irreversible - one
  /// dialog, no typed confirmation.
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
    // Drop the cached profile so the next account doesn't see this one's data.
    ref.read(profileControllerProvider.notifier).clear();
    context.go('/login');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserModel profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.images.isNotEmpty
        ? '${AppConfig.imageBaseUrl}${profile.images.first.name}'
        : null;
    final complete = profile.profileCompleted;

    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 92.r,
                height: 92.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(3.r),
                child: ClipOval(
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _AvatarFallback(),
                        )
                      : _AvatarFallback(),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => context.push('/edit-profile'),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorderInk),
                    ),
                    child: Icon(SolarIconsBold.camera,
                        size: 13.sp, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textInk,
              fontSize: 21.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
          ),
          SizedBox(height: 14.h),
          // Faux glass: inside the card's blurred surface already.
          GlassContainer(
            faux: true,
            showShadow: false,
            fill: complete
                ? AppColors.likeGreen.withValues(alpha: 0.12)
                : AppColors.warning.withValues(alpha: 0.14),
            border: Border.all(
              color: (complete ? AppColors.likeGreen : AppColors.warning)
                  .withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(20.r),
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  complete
                      ? SolarIconsBold.verifiedCheck
                      : SolarIconsBold.dangerTriangle,
                  size: 14.sp,
                  color: complete ? AppColors.likeGreen : AppColors.warning,
                ),
                SizedBox(width: 6.w),
                Text(
                  complete ? 'Profile complete' : 'Profile incomplete',
                  style: TextStyle(
                    color: complete ? AppColors.likeGreen : AppColors.warning,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.primary),
      child: Center(
        child: Icon(SolarIconsBold.user, size: 46.sp, color: Colors.white),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MkButton(
            label: 'Edit profile',
            icon: SolarIconsOutline.pen,
            height: 50.h,
            onPressed: () => context.push('/edit-profile'),
          ),
        ),
        SizedBox(width: 10.w),
        _SquareAction(
          icon: SolarIconsOutline.settings,
          tooltip: 'Settings',
          onTap: () => context.push('/settings'),
        ),
        SizedBox(width: 10.w),
        _SquareAction(
          icon: SolarIconsOutline.logout,
          tooltip: 'Log out',
          danger: true,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textMuted;
    return Tooltip(
      message: tooltip,
      child: GlassContainer(
        onTap: onTap,
        width: 50.h,
        height: 50.h,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: danger
              ? AppColors.error.withValues(alpha: 0.55)
              : AppColors.glassBorderInk,
          width: danger ? 1.4 : 1.0,
        ),
        child: Center(child: Icon(icon, color: color, size: 20.sp)),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.profile});

  final UserModel profile;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
      child: Row(
        children: [
          _Stat(
            icon: SolarIconsOutline.gallery,
            value: '${profile.images.length}',
            label: 'Photos',
            color: AppColors.primary,
          ),
          _VertDivider(),
          _Stat(
            icon: SolarIconsOutline.wallet,
            value: profile.minBudget != null
                ? 'Rs ${profile.minBudget!.toInt()}'
                : '-',
            label: 'Min budget',
            color: AppColors.accentTeal,
          ),
          _VertDivider(),
          _Stat(
            icon: profile.searchingRoommate == true
                ? SolarIconsOutline.userPlus
                : SolarIconsOutline.home,
            value: profile.searchingRoommate == true ? 'Roommate' : 'Room',
            label: 'Seeking',
            color: AppColors.accentViolet,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 7.h),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40.h,
      color: AppColors.glassBorderInk,
    );
  }
}

class _Info {
  const _Info(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.bold,
    required this.outline,
    required this.title,
    required this.color,
    required this.items,
  });

  final IconData bold;
  final IconData outline;
  final String title;
  final Color color;
  final List<_Info> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  // Low alpha in dark: a mid-strength tint over a dark card
                  // turns opaque and muddy instead of reading as a coloured
                  // wash. The ring carries the accent instead.
                  color: color.withValues(alpha: AppColors.isDark ? 0.12 : 0.10),
                  borderRadius: BorderRadius.circular(11.r),
                  border: Border.all(
                    color: AppColors.isDark
                        ? color.withValues(alpha: 0.40)
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: DuotoneIcon(
                  bold: bold,
                  outline: outline,
                  color: color,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 11.w),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(color: AppColors.glassBorderInk, height: 1),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              child: Row(
                children: [
                  Icon(items[i].icon, size: 17.sp, color: color),
                  SizedBox(width: 11.w),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      items[i].value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textInk,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

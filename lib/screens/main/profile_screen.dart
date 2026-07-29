import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) await context.read<ProfileProvider>().loadProfile(userId);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : profile == null
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _ProfileSliverAppBar(profile: profile),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildActionButtons(context),
                            const SizedBox(height: 20),
                            _ProfileStats(profile: profile),
                            const SizedBox(height: 20),
                            _InfoSection(
                              icon: Icons.search_rounded,
                              title: 'Looking For',
                              color: AppColors.primary,
                              items: _lookingForItems(profile),
                            ),
                            const SizedBox(height: 12),
                            _InfoSection(
                              icon: Icons.self_improvement_rounded,
                              title: 'Lifestyle',
                              color: const Color(0xFF7C3AED),
                              items: _lifestyleItems(profile),
                            ),
                            const SizedBox(height: 12),
                            _InfoSection(
                              icon: Icons.person_outline_rounded,
                              title: 'About Me',
                              color: const Color(0xFF059669),
                              items: _aboutItems(profile),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<_InfoItem> _lookingForItems(dynamic p) => [
        _InfoItem(Icons.search_rounded,
            'Searching', p.searchingRoommate == true ? 'Roommate' : 'Room'),
        if (p.roommateGender != null)
          _InfoItem(Icons.people_outline_rounded, 'Preferred Gender', p.roommateGender!),
        if (p.minBudget != null && p.maxBudget != null)
          _InfoItem(Icons.attach_money_rounded, 'Budget',
              'Rs ${p.minBudget!.toInt()} – ${p.maxBudget!.toInt()}'),
      ];

  List<_InfoItem> _lifestyleItems(dynamic p) => [
        if (p.sleepingSchedule != null)
          _InfoItem(Icons.bedtime_outlined, 'Sleep', p.sleepingSchedule!),
        if (p.diet != null)
          _InfoItem(Icons.restaurant_outlined, 'Diet', p.diet!),
        _InfoItem(Icons.smoke_free_rounded, 'Smoking',
            p.smoking == true ? 'Smoker' : 'Non-smoker'),
        if (p.cleanliness != null)
          _InfoItem(Icons.cleaning_services_outlined, 'Cleanliness',
              '${'★' * (p.cleanliness as int)}${'☆' * (5 - (p.cleanliness as int))}'),
        if (p.petPreference != null)
          _InfoItem(Icons.pets_rounded, 'Pets', p.petPreference!),
      ];

  List<_InfoItem> _aboutItems(dynamic p) => [
        if (p.occupation != null)
          _InfoItem(Icons.work_outline_rounded, 'Occupation', p.occupation!),
        if (p.hobbies != null)
          _InfoItem(Icons.interests_outlined, 'Hobbies', p.hobbies!),
        if (p.musicPreference != null)
          _InfoItem(Icons.music_note_outlined, 'Music', p.musicPreference!),
        if (p.notes != null)
          _InfoItem(Icons.notes_rounded, 'Notes', p.notes!),
      ];

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/edit-profile'),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.settings_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Profile not loaded',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ProfileSliverAppBar extends StatelessWidget {
  final dynamic profile;
  const _ProfileSliverAppBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.images.isNotEmpty
        ? '${AppConfig.imageBaseUrl}${profile.images.first.name}'
        : null;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF8C61)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: ClipOval(
                          child: imageUrl != null
                              ? Image.network(imageUrl, fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.person, size: 52, color: Colors.white))
                              : const Icon(Icons.person, size: 52, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profile.profileCompleted
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          profile.profileCompleted
                              ? 'Profile Complete'
                              : 'Profile Incomplete',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
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

class _ProfileStats extends StatelessWidget {
  final dynamic profile;
  const _ProfileStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _Stat(
              icon: Icons.photo_library_outlined,
              value: '${profile.images.length}',
              label: 'Photos',
              color: AppColors.primary,
            ),
            _VertDivider(),
            _Stat(
              icon: Icons.attach_money_rounded,
              value: profile.minBudget != null
                  ? 'Rs ${profile.minBudget!.toInt()}'
                  : '–',
              label: 'Min Budget',
              color: const Color(0xFF059669),
            ),
            _VertDivider(),
            _Stat(
              icon: profile.searchingRoommate == true
                  ? Icons.person_search_rounded
                  : Icons.home_outlined,
              value: profile.searchingRoommate == true ? 'Roommate' : 'Room',
              label: 'Seeking',
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.border,
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Stat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<_InfoItem> items;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: color)),
                ],
              ),
            ),
            ...items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  if (e.key > 0)
                    const Divider(height: 1, indent: 20, endIndent: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 16, color: color),
                        const SizedBox(width: 10),
                        Text(item.label,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        const Spacer(),
                        Text(item.value,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  if (isLast) const SizedBox(height: 4),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

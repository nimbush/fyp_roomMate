import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../models/discovery_user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/profile_provider.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final CardSwiperController _swiperCtrl = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final profile = context.read<ProfileProvider>();
    final discovery = context.read<DiscoveryProvider>();
    await profile.loadProfile(userId);
    if (!mounted) return;
    await discovery.loadDiscovery(userId);
  }

  void _swipe(bool liked, int index) {
    final userId = context.read<AuthProvider>().userId;
    final candidates = context.read<DiscoveryProvider>().candidates;
    if (userId == null || index >= candidates.length) return;
    context.read<DiscoveryProvider>().swipe(
          swiperId: userId,
          swipedId: candidates[index].id,
          liked: liked,
        );
  }

  @override
  void dispose() {
    _swiperCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Discover',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
              onPressed: _load,
            ),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (discovery.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Finding matches...',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        if (profile != null && !profile.profileCompleted) {
          return _buildProfileIncomplete(context);
        }
        if (discovery.isEmpty) {
          return _buildEmpty();
        }
        return _buildSwiper(discovery.candidates);
      }),
    );
  }

  Widget _buildSwiper(List<DiscoveryUserModel> candidates) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${candidates.length} people nearby',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Top Matches',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CardSwiper(
            controller: _swiperCtrl,
            cardsCount: candidates.length,
            numberOfCardsDisplayed: candidates.length.clamp(1, 3),
            backCardOffset: const Offset(0, 20),
            scale: 0.92,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onSwipe: (prev, curr, direction) {
              final liked = direction == CardSwiperDirection.right;
              _swipe(liked, prev);
              return true;
            },
            cardBuilder: (ctx, index, percentX, percentY) {
              if (index >= candidates.length) return const SizedBox();
              return _SwipeCard(user: candidates[index]);
            },
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.close_rounded,
            color: AppColors.passRed,
            size: 60,
            label: 'Pass',
            onTap: () => _swiperCtrl.swipe(CardSwiperDirection.left),
          ),
          _ActionButton(
            icon: Icons.star_rounded,
            color: AppColors.warning,
            size: 48,
            label: 'Super',
            onTap: () {},
          ),
          _ActionButton(
            icon: Icons.favorite_rounded,
            color: AppColors.likeGreen,
            size: 60,
            label: 'Like',
            onTap: () => _swiperCtrl.swipe(CardSwiperDirection.right),
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text('You\'re all caught up!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('No more new profiles right now.\nCheck back later!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIncomplete(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('Complete Your Profile',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            const Text(
                'Set up your profile to start discovering\npotential roommates near you.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 28),
            // Without this the empty state is a dead end — there is no other
            // affordance on this tab that reaches the profile form.
            ElevatedButton.icon(
              onPressed: () => context.push('/edit-profile'),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Complete Profile'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeCard extends StatelessWidget {
  final DiscoveryUserModel user;
  const _SwipeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.images.isNotEmpty
        ? '${AppConfig.imageBaseUrl}${user.images.first.name}'
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            imageUrl != null
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _placeholder())
                : _placeholder(),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xE6000000)],
                  begin: Alignment(0, -0.1),
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Image indicators
            if (user.images.length > 1)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(
                    user.images.length.clamp(0, 5),
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Compatibility badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${user.compatibilityScore.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _CardInfo(user: user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 80,
                color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No photo', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final DiscoveryUserModel user;
  const _CardInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (user.occupation != null)
                    Row(
                      children: [
                        const Icon(Icons.work_outline_rounded,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(user.occupation!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (user.sleepingSchedule != null)
              _Chip(Icons.bedtime_outlined, user.sleepingSchedule!),
            if (user.diet != null)
              _Chip(Icons.restaurant_outlined, user.diet!),
            if (user.smoking == false)
              _Chip(Icons.smoke_free_rounded, 'Non-smoker'),
            _Chip(Icons.attach_money_rounded, user.budgetRange),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: size * 0.44),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

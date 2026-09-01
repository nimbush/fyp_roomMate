import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/config/app_config.dart';
import 'package:roommate_finder/features/discovery/controller/discovery_controller.dart';
import 'package:roommate_finder/features/discovery/model/discovery_user_model.dart';
import 'package:roommate_finder/common/widgets/glass_container.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/ui_state_handler.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final CardSwiperController _swiperCtrl = CardSwiperController();

  /// Index of the card currently on top. Only that card runs its photo timer.
  int _frontIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() =>
      ref.read(discoveryControllerProvider.notifier).load();

  void _swipe(bool liked, int index) {
    final candidates = ref.read(discoveryControllerProvider).candidates;
    if (index >= candidates.length) return;
    ref.read(discoveryControllerProvider.notifier).swipe(
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
    final discovery = ref.watch(discoveryControllerProvider);

    // An incomplete profile isn't an error or an empty deck - it's a distinct
    // state with its own way out, so it's checked before the generic handler.
    final profileIncomplete = discovery.profileIncomplete;

    return GlassScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onRefresh: _load),
            Expanded(
              child: profileIncomplete
                  ? _buildProfileIncomplete(context)
                  : UiStateHandler(
                      isLoading: discovery.isLoading,
                      hasData: !discovery.isEmpty,
                      error: discovery.error,
                      onRetry: _load,
                      onLoading: () => const _DeckSkeleton(),
                      emptyIcon: SolarIconsOutline.usersGroupRounded,
                      emptyTitle: "You're all caught up",
                      emptyMessage:
                          'No new profiles match your filters right now. '
                          'Check back later, or widen your budget and gender '
                          'preferences to see more people.',
                      emptyAction: MkButton(
                        label: 'Refresh',
                        icon: SolarIconsOutline.refresh,
                        expand: false,
                        onPressed: _load,
                      ),
                      child: _buildSwiper(discovery.candidates),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwiper(List<DiscoveryUserModel> candidates) {
    // CardSwiper asserts numberOfCardsDisplayed <= cardsCount, and clamp(1, 3)
    // still yields 1 for an empty list - so guard before building the deck at
    // all. UiStateHandler normally catches this, but a list that empties while
    // the deck is already mounted would otherwise crash the screen.
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
          child: Row(
            children: [
              Text(
                '${candidates.length} ${candidates.length == 1 ? 'person' : 'people'} to review',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
              ),
              const Spacer(),
              // Faux glass: this pill sits on the ambient backdrop, but keeping
              // it faux costs nothing and keeps the one-blur budget for the deck.
              GlassContainer(
                faux: true,
                showShadow: false,
                fill: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20.r),
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                border: Border.all(
                  color: AppColors.isDark
                      ? AppColors.accentRing
                      : Colors.transparent,
                  width: 1.2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(SolarIconsBold.fire,
                        size: 13.sp, color: AppColors.accentInk),
                    SizedBox(width: 5.w),
                    Text(
                      'Best matches first',
                      style: TextStyle(
                        color: AppColors.accentInk,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
            backCardOffset: Offset(0, 22.h),
            scale: 0.92,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            onSwipe: (prev, curr, direction) {
              _swipe(direction == CardSwiperDirection.right, prev);
              // Hand the photo timer to the card that just came to the top.
              if (curr != null && mounted) {
                setState(() => _frontIndex = curr);
              }
              return true;
            },
            cardBuilder: (ctx, index, percentX, percentY) {
              if (index >= candidates.length) return const SizedBox();
              return _SwipeCard(
                key: ValueKey(candidates[index].id),
                user: candidates[index],
                // Stamp strength follows drag distance, so the user sees the
                // outcome building before they commit to it.
                dragPercent: percentX,
                isFront: index == _frontIndex,
              );
            },
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    // MainShell sets extendBody, so the floating nav pill overlaps this body -
    // the gap has to be reserved here or the button labels sit under it.
    //
    // The pill is 48.h min item + 8.h*2 padding + 12.h bottom margin = 84.h,
    // and its SafeArea adds the device's bottom inset on top - zero on a
    // button-nav device, ~34.h on a gesture bar, which is why this cannot be
    // a single fixed number. The item can also exceed its 48.h minimum once
    // the label wraps at large font scales, so 16.h of slack sits on top
    // rather than letting the labels graze the pill's shadow.
    final navBarHeight =
        84.h + 16.h + MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: 14.h,
        bottom: navBarHeight + 12.h,
        left: 40.w,
        right: 40.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: SolarIconsOutline.closeCircle,
            color: AppColors.passRed,
            size: 60.r,
            label: 'Pass',
            onTap: () => _swiperCtrl.swipe(CardSwiperDirection.left),
          ),
          _ActionButton(
            icon: SolarIconsBold.star,
            color: AppColors.warning,
            size: 48.r,
            label: 'Super',
            onTap: () => _swiperCtrl.swipe(CardSwiperDirection.top),
          ),
          _ActionButton(
            icon: SolarIconsBold.heart,
            color: AppColors.likeGreen,
            size: 60.r,
            label: 'Like',
            onTap: () => _swiperCtrl.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIncomplete(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 100.h),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(22.r),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(SolarIconsBold.userPlus,
                    size: 42.sp, color: Colors.white),
              ),
              SizedBox(height: 20.h),
              Text(
                'Complete your profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textInk,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'We match on lifestyle, so we need your details before we can '
                'show you anyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14.sp,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 22.h),
              // Without this the state is a dead end - nothing else on this tab
              // reaches the profile form.
              MkButton(
                label: 'Set up my profile',
                icon: SolarIconsOutline.pen,
                onPressed: () => context.push('/edit-profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 16.w, 8.h),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(SolarIconsBold.home, color: Colors.white, size: 19.sp),
          ),
          SizedBox(width: 11.w),
          Text(
            'Discover',
            style: TextStyle(
              fontSize: 21.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textInk,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh the deck',
            onPressed: onRefresh,
            icon: Icon(SolarIconsOutline.tuning,
                color: AppColors.textMuted, size: 22.sp),
          ),
        ],
      ),
    );
  }
}

/// Deck-shaped loading placeholder: one card outline, so the layout doesn't jump.
class _DeckSkeleton extends StatelessWidget {
  const _DeckSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.glassFillSubtle,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: AppColors.glassBorderInk),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16.h),
              Text(
                'Finding people near you...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The deck card. Stateful because it owns the photo carousel: which photo is
/// showing, and the timer that advances it.
class _SwipeCard extends StatefulWidget {
  const _SwipeCard({
    super.key,
    required this.user,
    required this.dragPercent,
    required this.isFront,
  });

  final DiscoveryUserModel user;
  final int dragPercent;

  /// Only the front card auto-advances. Running timers on the buried cards
  /// would burn cycles decoding images nobody is looking at.
  final bool isFront;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard>
    with SingleTickerProviderStateMixin {
  static const _autoAdvance = Duration(seconds: 3);

  final PageController _pages = PageController();

  /// Drives both the dwell countdown and the progress fill, so the bar can
  /// never drift out of step with the photo it is measuring - a separate
  /// Timer for the advance would do exactly that over a long dwell.
  late final AnimationController _dwell = AnimationController(
    vsync: this,
    duration: _autoAdvance,
  )..addStatusListener((s) {
    if (s == AnimationStatus.completed) _advance();
  });

  int _index = 0;

  int get _count => widget.user.images.length;

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  // Reading MediaQuery in initState does not register a dependency, so the
  // reduced-motion check lives here - this also re-runs if the user flips the
  // setting while the deck is open.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _SwipeCard old) {
    super.didUpdateWidget(old);
    // A card promoted to the front starts rotating; one pushed back stops.
    if (old.isFront != widget.isFront) _restartTimer();
  }

  @override
  void dispose() {
    _dwell.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _dwell.stop();
    _dwell.value = 0;
    if (!widget.isFront || _count < 2) return;
    // Respect reduced motion: auto-rotating photos is exactly the kind of
    // unrequested movement that setting asks us to stop. The bar then shows
    // the plain segmented state with no sweep.
    if (_reducedMotion) return;
    _dwell.forward();
  }

  void _advance() {
    if (!mounted || _count < 2) return;
    final next = (_index + 1) % _count;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  /// Tapping the left third goes back, the right two-thirds goes forward -
  /// the gesture people already know from stories and Tinder.
  void _onTapUp(TapUpDetails d, BoxConstraints c) {
    if (_count < 2) return;
    final goBack = d.localPosition.dx < c.maxWidth * 0.33;
    final next = goBack
        ? (_index - 1 + _count) % _count
        : (_index + 1) % _count;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
    _restartTimer(); // manual input resets the dwell time
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final radius = BorderRadius.circular(28.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (ctx, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              if (_count == 0)
                const _CardPlaceholder()
              else
                PageView.builder(
                  controller: _pages,
                  itemCount: _count,
                  // Restart the dwell here rather than in _advance/_onTapUp so
                  // every route to a new photo - auto, tap, or swipe on the
                  // PageView itself - gets a full sweep from zero.
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    _restartTimer();
                  },
                  itemBuilder: (_, i) => Image.network(
                    '${AppConfig.imageBaseUrl}${user.images[i].name}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _CardPlaceholder(),
                  ),
                ),

              // Tap layer sits above the photos but below the info, so the
              // details button underneath still receives its own taps.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (d) => _onTapUp(d, constraints),
                ),
              ),

              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.cardGradient),
                ),
              ),

              if (_count > 1)
                Positioned(
                  top: 14.h,
                  left: 14.w,
                  right: 14.w,
                  child: _PhotoProgress(
                    count: _count,
                    active: _index,
                    dwell: _dwell,
                  ),
                ),

              Positioned(
                top: _count > 1 ? 30.h : 16.h,
                right: 16.w,
                child: _ScoreBadge(score: user.compatibilityScore),
              ),

              // Like / pass stamp, fading in with drag distance past a threshold.
              if (widget.dragPercent.abs() > 12)
                Positioned(
                  top: 60.h,
                  left: widget.dragPercent > 0 ? 20.w : null,
                  right: widget.dragPercent < 0 ? 20.w : null,
                  child: _SwipeStamp(
                    liked: widget.dragPercent > 0,
                    opacity:
                        ((widget.dragPercent.abs() - 12) / 45).clamp(0.0, 1.0),
                  ),
                ),

              Positioned(
                left: 18.w,
                right: 18.w,
                bottom: 18.h,
                child: _CardInfo(
                  user: user,
                  onOpenDetails: () => _openDetails(context, user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, DiscoveryUserModel user) {
    _dwell.stop(); // don't rotate behind the sheet
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileDetailsSheet(user: user),
    ).whenComplete(_restartTimer);
  }
}

/// Segmented bar across the top of the card - one segment per photo. Segments
/// already seen read as full, upcoming ones dim, and the current one fills
/// left-to-right over the dwell so the time left on this photo is visible
/// rather than guessed at. The stories/reels pattern people already know.
class _PhotoProgress extends StatelessWidget {
  const _PhotoProgress({
    required this.count,
    required this.active,
    required this.dwell,
  });

  final int count;
  final int active;

  /// 0 -> 1 across the current photo's dwell. Parked at 0 when auto-advance
  /// is off (buried card, reduced motion), which renders the active segment
  /// as a plain full bar - the final state, readable without animation.
  final Animation<double> dwell;

  @override
  Widget build(BuildContext context) {
    final track = Colors.white.withValues(alpha: 0.4);

    return Row(
      children: List.generate(count, (i) {
        final isPast = i < active;
        final isActive = i == active;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            height: 3.h,
            decoration: BoxDecoration(
              color: isPast ? Colors.white : track,
              borderRadius: BorderRadius.circular(2.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 2,
                ),
              ],
            ),
            child: !isActive
                ? null
                // Repaints only this segment each frame; the sibling segments
                // are outside the builder so they stay static.
                : AnimatedBuilder(
                    animation: dwell,
                    builder: (_, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      // A stopped controller sits at 0, but the active photo
                      // should still read as "here" - show it filled.
                      widthFactor: dwell.isAnimating ? dwell.value : 1.0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.liked, required this.opacity});

  final bool liked;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final color = liked ? AppColors.likeGreen : AppColors.passRed;
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: liked ? -0.22 : 0.22,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color, width: 3),
          ),
          child: Text(
            liked ? 'LIKE' : 'PASS',
            style: TextStyle(
              color: color,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SolarIconsBold.heart, size: 12.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            '${score.toInt()}% match',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(SolarIconsBold.user,
                size: 76.sp, color: Colors.white.withValues(alpha: 0.75)),
            SizedBox(height: 8.h),
            Text(
              'No photo yet',
              style: TextStyle(color: Colors.white70, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.user, required this.onOpenDetails});

  final DiscoveryUserModel user;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Tapping the photo cycles through pictures, so opening the profile
            // needs its own affordance rather than competing for the same tap.
            Semantics(
              button: true,
              label: 'View ${user.fullName}’s full profile',
              child: GestureDetector(
                onTap: onOpenDetails,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  child: Icon(SolarIconsOutline.altArrowUp,
                      color: Colors.white, size: 20.sp),
                ),
              ),
            ),
          ],
        ),
        if (user.occupation != null) ...[
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(SolarIconsOutline.case_,
                  size: 13.sp, color: Colors.white70),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  user.occupation!,
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 9.h),
        Wrap(
          spacing: 7.w,
          runSpacing: 6.h,
          children: [
            if (user.sleepingSchedule != null)
              _CardChip(SolarIconsOutline.moon, _pretty(user.sleepingSchedule!)),
            if (user.diet != null)
              _CardChip(SolarIconsOutline.chefHat, _pretty(user.diet!)),
            // solar_icons has no smoking glyph; `leaf` reads as the clean-air
            // idea without inventing a crossed-out cigarette.
            if (user.smoking == false)
              _CardChip(SolarIconsOutline.leaf, 'Non-smoker'),
            _CardChip(SolarIconsOutline.wallet, user.budgetRange),
          ],
        ),
      ],
    );
  }

  /// EARLY_BIRD -> Early bird. Backend enums shouldn't be shown raw.
  static String _pretty(String raw) {
    final words = raw.toLowerCase().replaceAll('_', ' ');
    return words.isEmpty ? words : words[0].toUpperCase() + words.substring(1);
  }
}

/// The full profile, opened by tapping the card's details button. Tinder-style:
/// photos first, then the detail the card had no room for.
class _ProfileDetailsSheet extends StatelessWidget {
  const _ProfileDetailsSheet({required this.user});

  final DiscoveryUserModel user;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              if (user.images.isNotEmpty)
                SizedBox(
                  height: 360.h,
                  child: PageView.builder(
                    itemCount: user.images.length,
                    itemBuilder: (_, i) => Image.network(
                      '${AppConfig.imageBaseUrl}${user.images[i].name}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _CardPlaceholder(),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textInk,
                            ),
                          ),
                        ),
                        _ScoreBadge(score: user.compatibilityScore),
                      ],
                    ),
                    if (user.occupation != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        user.occupation!,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14.sp),
                      ),
                    ],
                    SizedBox(height: 20.h),
                    _DetailRow(
                      icon: SolarIconsOutline.wallet,
                      label: 'Budget',
                      value: user.budgetRange,
                    ),
                    if (user.sleepingSchedule != null)
                      _DetailRow(
                        icon: SolarIconsOutline.moon,
                        label: 'Sleep schedule',
                        value: _CardInfo._pretty(user.sleepingSchedule!),
                      ),
                    if (user.cleanliness != null)
                      _DetailRow(
                        icon: SolarIconsOutline.broom,
                        label: 'Cleanliness',
                        value: '${user.cleanliness}/5',
                      ),
                    if (user.diet != null)
                      _DetailRow(
                        icon: SolarIconsOutline.chefHat,
                        label: 'Diet',
                        value: _CardInfo._pretty(user.diet!),
                      ),
                    if (user.smoking != null)
                      _DetailRow(
                        icon: SolarIconsOutline.leaf,
                        label: 'Smoking',
                        value: user.smoking! ? 'Smoker' : 'Non-smoker',
                      ),
                    if (user.petPreference != null)
                      _DetailRow(
                        icon: SolarIconsOutline.cat,
                        label: 'Pets',
                        value: _CardInfo._pretty(user.petPreference!),
                      ),
                    if (user.musicPreference != null)
                      _DetailRow(
                        icon: SolarIconsOutline.musicNote,
                        label: 'Music',
                        value: _CardInfo._pretty(user.musicPreference!),
                      ),
                    if (user.studyLevel != null)
                      _DetailRow(
                        icon: SolarIconsOutline.notebook,
                        label: 'Study level',
                        value: _CardInfo._pretty(user.studyLevel!),
                      ),
                    if (user.hobbies != null && user.hobbies!.trim().isNotEmpty)
                      _DetailSection(title: 'Hobbies', body: user.hobbies!),
                    if (user.propertyDescription != null &&
                        user.propertyDescription!.trim().isNotEmpty)
                      _DetailSection(
                          title: 'About their place',
                          body: user.propertyDescription!),
                    if (user.notes != null && user.notes!.trim().isNotEmpty)
                      _DetailSection(title: 'Notes', body: user.notes!),
                    SizedBox(height: 24.h),
                    MkButton(
                      label: 'Close',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: AppColors.accentInk),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textInk,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h, bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textInk,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            body,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14.sp,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Faux glass by necessity: this sits on the card's photo, which is already
/// inside the deck's clip - a real blur here would nest.
class _CardChip extends StatelessWidget {
  const _CardChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.white),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: AppColors.isDark ? 0.55 : 0.20),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: size * 0.44),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

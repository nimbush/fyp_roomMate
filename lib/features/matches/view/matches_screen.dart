import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/config/app_config.dart';
import 'package:roommate_finder/features/matches/controller/matches_controller.dart';
import 'package:roommate_finder/features/matches/model/match_model.dart';
import 'package:roommate_finder/common/widgets/glass_container.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/skeleton.dart';
import 'package:roommate_finder/common/widgets/ui_state_handler.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() =>
      ref.read(matchesControllerProvider.notifier).loadMatches();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(matchesControllerProvider);
    final currentUserId = matches.currentUserId ?? 0;

    return GlassScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
              child: Row(
                children: [
                  Text(
                    'Matches',
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textInk,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
              child: GlassContainer(
                showShadow: false,
                padding: EdgeInsets.all(4.r),
                borderRadius: BorderRadius.circular(16.r),
                child: TabBar(
                  controller: _tabs,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(12.r),
                  tabs: [
                    Tab(
                      text: matches.accepted.isEmpty
                          ? 'Matched'
                          : 'Matched (${matches.accepted.length})',
                    ),
                    Tab(
                      text: matches.pending.isEmpty
                          ? 'Requests'
                          : 'Requests (${matches.pending.length})',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _MatchList(
                    matches: matches.accepted,
                    isLoading: matches.isLoading,
                    error: matches.error,
                    onRetry: _load,
                    emptyIcon: SolarIconsOutline.heart,
                    emptyTitle: 'No matches yet',
                    emptyMessage:
                        'When you and someone else both like each other, '
                        "they'll show up here ready to chat.",
                    builder: (m) =>
                        _MatchCard(match: m, currentUserId: currentUserId),
                  ),
                  _MatchList(
                    matches: matches.pending,
                    isLoading: matches.isLoading,
                    error: matches.error,
                    onRetry: _load,
                    emptyIcon: SolarIconsOutline.hourglass,
                    emptyTitle: 'No requests waiting',
                    emptyMessage:
                        'People who liked you appear here so you can accept '
                        'or pass.',
                    builder: (m) =>
                        _PendingCard(match: m, currentUserId: currentUserId),
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

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.matches,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.builder,
  });

  final List<MatchModel> matches;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final Widget Function(MatchModel) builder;

  @override
  Widget build(BuildContext context) {
    return UiStateHandler(
      isLoading: isLoading,
      hasData: matches.isNotEmpty,
      error: error,
      onRetry: onRetry,
      onLoading: () => const SkeletonList(),
      emptyIcon: emptyIcon,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      // Pull-to-refresh belongs on every list - the gesture is learned on one
      // screen and expected on the next.
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRetry,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (ctx, i) => StaggeredListItem(
            index: i,
            child: builder(matches[i]),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.currentUserId});

  final MatchModel match;
  final int currentUserId;

  @override
  Widget build(BuildContext context) {
    final score = match.matchScore.toInt();
    final name = match.displayName;

    return GlassCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          _Avatar(score: score, imageName: match.otherUserImage,
              initial: match.initial),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: AppColors.textInk,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: BoxDecoration(
                        color: AppColors.likeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Matched',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Faux glass: already inside the card's blurred surface.
          GlassContainer(
            faux: true,
            showShadow: false,
            fill: Colors.transparent,
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(13.r),
            onTap: () => context.push(
                '/chat/${match.id}?name=${Uri.encodeComponent(name)}'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(SolarIconsBold.chatRound,
                        size: 14.sp, color: Colors.white),
                    SizedBox(width: 5.w),
                    Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5.sp,
                      ),
                    ),
                  ],
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
  const _Avatar({
    required this.score,
    this.imageName,
    this.initial = '?',
  });

  final int score;

  /// Filename from the API, resolved against the image host. Null when the
  /// person has not uploaded a photo.
  final String? imageName;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageName != null && imageName!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60.r,
          height: 60.r,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySoft,
            border: Border.all(
              color: AppColors.isDark
                  ? AppColors.accentRing
                  : AppColors.primary.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: hasImage
              ? Image.network(
                  '${AppConfig.imageBaseUrl}$imageName',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _InitialBadge(initial: initial),
                )
              : _InitialBadge(initial: initial),
        ),
        Positioned(
          right: -2.w,
          bottom: -2.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.surfaceColor, width: 1.5),
            ),
            child: Text(
              '$score%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Initials stand in for a missing photo. A letter tied to the person's name
/// reads as "this is them, without a picture"; a generic silhouette makes every
/// row look identical.
class _InitialBadge extends StatelessWidget {
  const _InitialBadge({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: initial == '?'
          ? Icon(SolarIconsBold.user, color: AppColors.accentInk, size: 29.sp)
          : Text(
              initial,
              style: TextStyle(
                color: AppColors.accentInk,
                fontWeight: FontWeight.w800,
                fontSize: 23.sp,
              ),
            ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.match, required this.currentUserId});

  final MatchModel match;
  final int currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = match.displayName;
    final image = match.otherUserImage;
    final hasImage = image != null && image.isNotEmpty;

    return GlassCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 54.r,
            height: 54.r,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: hasImage
                ? Image.network(
                    '${AppConfig.imageBaseUrl}$image',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _PendingInitial(match.initial),
                  )
                : _PendingInitial(match.initial),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: AppColors.textInk,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${match.matchScore.toInt()}% compatible',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5.sp,
                  ),
                ),
              ],
            ),
          ),
          _CircleAction(
            icon: SolarIconsOutline.closeCircle,
            color: AppColors.passRed,
            tooltip: 'Pass on $name',
            onTap: () => ref
                .read(matchesControllerProvider.notifier)
                .rejectMatch(match.id),
          ),
          SizedBox(width: 8.w),
          _CircleAction(
            icon: SolarIconsBold.checkCircle,
            color: AppColors.likeGreen,
            tooltip: 'Accept $name',
            onTap: () => ref
                .read(matchesControllerProvider.notifier)
                .acceptMatch(match.id),
          ),
        ],
      ),
    );
  }
}

/// Pending rows use the warning palette rather than the brand accent, so the
/// initial has to match that tint instead of reusing `_InitialBadge`.
class _PendingInitial extends StatelessWidget {
  const _PendingInitial(this.initial);

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: initial == '?'
          ? Icon(SolarIconsBold.user, color: AppColors.warning, size: 26.sp)
          : Text(
              initial,
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w800,
                fontSize: 21.sp,
              ),
            ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          // 44dp minimum touch target.
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
      ),
    );
  }
}

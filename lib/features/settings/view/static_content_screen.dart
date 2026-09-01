import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/common/utils/generic_state.dart';
import 'package:roommate_finder/features/settings/controller/static_content_controller.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_app_bar.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/mk_list_tile.dart';
import 'package:roommate_finder/common/widgets/skeleton.dart';
import 'package:roommate_finder/common/widgets/ui_state_handler.dart';
import 'content_sections.dart';

/// Renders Notifications / About / Privacy / Terms from backend content.
///
/// All four share this screen so they stay one visual family: a lead sentence,
/// then each distinct point as an icon-chip row inside a white card.
class StaticContentScreen extends ConsumerWidget {
  const StaticContentScreen({super.key, required this.service});

  final String service;

  /// Section label shown above the rows, per service.
  String get _groupLabel => switch (service) {
        'NOTIFICATION' => 'What we notify you about',
        'PRIVACY' => 'How we handle your data',
        'TERMS' => 'The agreement',
        _ => 'How it works',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staticContentControllerProvider(service));
    final data = state.dataOrNull();
    Future<void> load() =>
        ref.read(staticContentControllerProvider(service).notifier).load();

    final raw = (data?['content'] as String?) ?? '';
    final sections = parseSections(raw);

    // The first section is usually an untitled lead sentence; promote it out of
    // the card so it reads as context rather than as another point.
    final hasLead = sections.isNotEmpty && sections.first.heading == null;
    final lead = hasLead ? sections.first.body : null;
    final rest = hasLead ? sections.sublist(1) : sections;

    // Trailing untitled paragraphs (e.g. the About footer, the Notifications
    // security note) belong outside the card too.
    final rows = rest.where((s) => s.heading != null).toList();
    final tail = rest.where((s) => s.heading == null).toList();

    return GlassScaffold(
      appBar: MkAppBar(title: data?['title'] ?? _fallbackTitle),
      body: UiStateHandler(
        isLoading: state is Loading<Map<String, dynamic>>,
        hasData: raw.isNotEmpty,
        error: state.whenOrNull(failure: (message, _) => message),
        onRetry: load,
        onLoading: () => Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
          ),
          child: const SkeletonList(count: 4),
        ),
        emptyIcon: SolarIconsOutline.documentText,
        emptyTitle: 'Nothing here yet',
        emptyMessage: 'This page has not been published.',
        emptyAction: MkButton(
          label: 'Try again',
          icon: SolarIconsOutline.refresh,
          expand: false,
          onPressed: load,
        ),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16.w,
              kToolbarHeight + MediaQuery.of(context).padding.top + 10.h,
              16.w,
              32.h,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (lead != null) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 20.h),
                  child: Text(
                    lead,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      height: 1.55,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
              if (rows.isNotEmpty) ...[
                MkGroupLabel(_groupLabel),
                MkCardGroup(
                  children: [
                    for (final s in rows)
                      MkListRow(
                        icon: iconForHeading(s.heading),
                        label: s.heading!,
                        subtitle: s.body,
                        showChevron: false,
                        onTap: null,
                      ),
                  ],
                ),
              ],
              for (final t in tail) ...[
                SizedBox(height: 16.h),
                _Callout(text: t.body),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _fallbackTitle => switch (service) {
        'NOTIFICATION' => 'Notifications',
        'PRIVACY' => 'Privacy policy',
        'TERMS' => 'Terms of service',
        'ABOUT' => 'About',
        _ => service,
      };
}

/// Tinted note for the trailing paragraphs - security caveats, project footer.
class _Callout extends StatelessWidget {
  const _Callout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(SolarIconsOutline.infoCircle,
              size: 16.sp, color: AppColors.accentInk),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

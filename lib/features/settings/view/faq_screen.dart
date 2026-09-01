import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/common/utils/generic_state.dart';
import 'package:roommate_finder/features/settings/controller/faq_controller.dart';
import 'package:roommate_finder/features/settings/model/faq_entry.dart';
import 'package:roommate_finder/common/widgets/glass_scaffold.dart';
import 'package:roommate_finder/common/widgets/mk_app_bar.dart';
import 'package:roommate_finder/common/widgets/mk_button.dart';
import 'package:roommate_finder/common/widgets/mk_list_tile.dart';
import 'package:roommate_finder/common/widgets/skeleton.dart';
import 'package:roommate_finder/common/widgets/ui_state_handler.dart';

// The parsing helpers moved to the model layer; re-exported so existing
// imports (tests) keep working.
export 'package:roommate_finder/features/settings/model/faq_entry.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  /// Index of the open card, or null when all are collapsed. Only one opens at
  /// a time so the list stays scannable.
  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faqControllerProvider);
    final entries = state.dataOrNull() ?? const <FaqEntry>[];
    Future<void> load() => ref.read(faqControllerProvider.notifier).load();

    return GlassScaffold(
      appBar: const MkAppBar(title: 'FAQ'),
      body: UiStateHandler(
        isLoading: state is Loading<List<FaqEntry>>,
        hasData: entries.isNotEmpty,
        error: state.whenOrNull(failure: (message, _) => message),
        onRetry: load,
        onLoading: () => Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
          ),
          child: const SkeletonList(count: 5),
        ),
        emptyIcon: SolarIconsOutline.questionCircle,
        emptyTitle: 'No questions yet',
        emptyMessage: 'Help articles will appear here once published.',
        emptyAction: MkButton(
          label: 'Try again',
          icon: SolarIconsOutline.refresh,
          expand: false,
          onPressed: load,
        ),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: load,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16.w,
              kToolbarHeight + MediaQuery.of(context).padding.top + 8.h,
              16.w,
              32.h,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: entries.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 16.h),
                  child: Text(
                    'Tap a question to see the answer.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }
              final index = i - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _FaqCard(
                  entry: entries[index],
                  isOpen: _openIndex == index,
                  onTap: () => setState(
                    // Tapping the open card closes it, so there's always a way
                    // back to the scannable all-collapsed view.
                    () => _openIndex = _openIndex == index ? null : index,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.entry,
    required this.isOpen,
    required this.onTap,
  });

  final FaqEntry entry;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return MkCardGroup(
      children: [
        Semantics(
          button: true,
          expanded: isOpen,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const IconChip(icon: SolarIconsOutline.questionCircle),
                      SizedBox(width: 13.w),
                      Expanded(
                        child: Text(
                          entry.question,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: AppColors.textInk,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0,
                        duration: Duration(
                            milliseconds: reduceMotion ? 0 : 200),
                        curve: Curves.easeOut,
                        child: Icon(SolarIconsOutline.altArrowDown,
                            size: 17.sp, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                  // AnimatedSize so the answer slides open rather than snapping,
                  // making it obvious which question it belongs to.
                  AnimatedSize(
                    duration:
                        Duration(milliseconds: reduceMotion ? 0 : 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: isOpen
                        ? Padding(
                            padding: EdgeInsets.only(
                              top: 12.h,
                              left: 47.w,
                              right: 4.w,
                            ),
                            child: Text(
                              entry.answer,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                height: 1.55,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

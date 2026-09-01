import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/generic_state.dart';
import 'package:roommate_finder/features/settings/model/faq_entry.dart';
import 'package:roommate_finder/features/settings/repo/settings_repository.dart';

final faqControllerProvider = StateNotifierProvider.autoDispose<FaqController,
    GenericState<List<FaqEntry>>>(
  (ref) => FaqController(ref.watch(settingsRepoProvider))..load(),
);

class FaqController extends StateNotifier<GenericState<List<FaqEntry>>> {
  FaqController(this._repo) : super(const Empty());

  final SettingsRepository _repo;

  Future<void> load() async {
    final previous = state.dataOrNull();
    // Refresh keeps the current list on screen; only the initial load shows
    // the skeleton.
    if (previous == null) state = const Loading();
    try {
      final data = await _repo.getContent('FAQ');
      state = Success(parseFaq((data['content'] as String?) ?? ''));
    } catch (e) {
      // A failed refresh keeps the last good list rather than replacing it
      // with an error.
      if (previous == null) {
        state = Failure(friendlyError(e, 'We could not load the FAQ just now.'));
      }
    }
  }
}

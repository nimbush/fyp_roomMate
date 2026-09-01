import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/generic_state.dart';
import 'package:roommate_finder/features/settings/repo/settings_repository.dart';

final supportControllerProvider = StateNotifierProvider.autoDispose<
    SupportController, GenericState<void>>(
  (ref) => SupportController(ref.watch(settingsRepoProvider)),
);

/// Submits a help & support request. [state] tracks the in-flight submission
/// so the button can show progress and duplicate taps are ignored.
class SupportController extends StateNotifier<GenericState<void>> {
  SupportController(this._repo) : super(const Empty());

  final SettingsRepository _repo;

  bool get isSubmitting => state is Loading<void>;

  /// Returns null on success, or a user-safe error message on failure.
  Future<String?> submit({
    required String username,
    required String phoneNumber,
    required String email,
    required String title,
    required String body,
  }) async {
    if (isSubmitting) return null;
    state = const Loading();
    try {
      await _repo.submitSupport(
        username: username,
        phoneNumber: phoneNumber,
        email: email,
        title: title,
        body: body,
      );
      state = const Success(null);
      return null;
    } catch (e) {
      final message = friendlyError(
          e, 'Could not submit your request. Please try again.');
      state = Failure(message);
      return message;
    }
  }
}

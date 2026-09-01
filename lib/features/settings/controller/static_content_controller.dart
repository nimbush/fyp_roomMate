import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/generic_state.dart';
import 'package:roommate_finder/features/settings/repo/settings_repository.dart';

/// Per-service static content (NOTIFICATION / PRIVACY / TERMS / ABOUT).
///
/// Family-keyed by service name so each page caches independently;
/// autoDispose so the content is refetched fresh on the next visit.
final staticContentControllerProvider = StateNotifierProvider.autoDispose
    .family<StaticContentController, GenericState<Map<String, dynamic>>,
        String>(
  (ref, service) =>
      StaticContentController(ref.watch(settingsRepoProvider), service)
        ..load(),
);

class StaticContentController
    extends StateNotifier<GenericState<Map<String, dynamic>>> {
  StaticContentController(this._repo, this.service) : super(const Empty());

  final SettingsRepository _repo;
  final String service;

  Future<void> load() async {
    final previous = state.dataOrNull();
    // Refresh keeps the current content on screen; only the initial load
    // shows the skeleton.
    if (previous == null) state = const Loading();
    try {
      state = Success(await _repo.getContent(service));
    } catch (e) {
      // A failed refresh keeps the last good content rather than replacing
      // the page with an error.
      if (previous == null) {
        state = Failure(friendlyError(e, 'This content is not available yet.'));
      }
    }
  }
}

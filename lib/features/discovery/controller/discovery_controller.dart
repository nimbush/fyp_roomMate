import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/discovery/model/discovery_user_model.dart';
import 'package:roommate_finder/features/discovery/repo/discovery_repository.dart';

final discoveryControllerProvider =
    StateNotifierProvider<DiscoveryController, DiscoveryState>(
  (ref) => DiscoveryController(
    ref.watch(discoveryRepoProvider),
    ref.watch(localStorageProvider),
  ),
);

/// Deck state. `profileCompleted` is tri-state: null until the profile has
/// been checked, so an unreadable profile never blocks the deck — mirroring
/// the old `profile != null && !profile.profileCompleted` gate.
class DiscoveryState {
  const DiscoveryState({
    this.candidates = const [],
    this.isLoading = false,
    this.error,
    this.profileCompleted,
  });

  final List<DiscoveryUserModel> candidates;
  final bool isLoading;
  final String? error;
  final bool? profileCompleted;

  bool get isEmpty => candidates.isEmpty;

  /// Only a *known* incomplete profile hides the deck.
  bool get profileIncomplete => profileCompleted == false;

  DiscoveryState copyWith({
    List<DiscoveryUserModel>? candidates,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? profileCompleted,
  }) =>
      DiscoveryState(
        candidates: candidates ?? this.candidates,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        profileCompleted: profileCompleted ?? this.profileCompleted,
      );
}

class DiscoveryController extends StateNotifier<DiscoveryState> {
  DiscoveryController(this._repo, this._storage)
      : super(const DiscoveryState());

  final DiscoveryRepository _repo;
  final LocalStorage _storage;

  /// Checks profile completeness, then loads the ranked deck.
  Future<void> load() async {
    final userId = await _storage.getUserId();
    if (userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    // A failed profile check must not block discovery — the old flow let the
    // deck load even when the profile fetch errored.
    bool? profileCompleted;
    try {
      profileCompleted = await _repo.getProfileCompleted(userId);
    } catch (_) {}

    try {
      final candidates = await _repo.getDiscovery(userId);
      if (!mounted) return;
      state = state.copyWith(
        candidates: candidates,
        isLoading: false,
        clearError: true,
        profileCompleted: profileCompleted,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: friendlyError(e, 'Could not load suggestions.'),
        profileCompleted: profileCompleted,
      );
    }
  }

  /// Records a swipe, removing the card optimistically so the deck advances
  /// without waiting on the network — but remembering the card (and its
  /// position) so a failed swipe can be undone instead of silently discarding
  /// the candidate.
  Future<void> swipe({required int swipedId, required bool liked}) async {
    final swiperId = await _storage.getUserId();
    if (swiperId == null) return;

    final index = state.candidates.indexWhere((c) => c.id == swipedId);
    if (index == -1) return;
    final removed = state.candidates[index];
    state = state.copyWith(
      candidates: [...state.candidates]..removeAt(index),
    );

    try {
      await _repo.recordSwipe(
        swiperId: swiperId,
        swipedId: swipedId,
        liked: liked,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // A duplicate swipe means the server already recorded it — the card is
      // correctly gone, so don't restore it.
      if (e.statusCode != 400) {
        state = state.copyWith(candidates: _restore(removed, index));
      }
      state = state.copyWith(error: e.message);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        candidates: _restore(removed, index),
        error: friendlyError(e, 'Could not save your swipe. Please try again.'),
      );
    }
  }

  List<DiscoveryUserModel> _restore(DiscoveryUserModel card, int index) =>
      [...state.candidates]..insert(index.clamp(0, state.candidates.length), card);

  void clearError() => state = state.copyWith(clearError: true);
}

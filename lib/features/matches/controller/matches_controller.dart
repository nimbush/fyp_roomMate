import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/matches/model/match_model.dart';
import 'package:roommate_finder/features/matches/repo/matches_repository.dart';

/// Sentinel so [MatchesState.copyWith] can tell "leave unchanged" apart from
/// "explicitly set to null" for its nullable fields.
const Object _unset = Object();

class MatchesState {
  const MatchesState({
    this.accepted = const [],
    this.pending = const [],
    this.isLoading = false,
    this.error,
    this.currentUserId,
  });

  final List<MatchModel> accepted;
  final List<MatchModel> pending;
  final bool isLoading;
  final String? error;

  /// The signed-in user's id, resolved from storage on load — cards need it to
  /// work out which side of a match is "the other person".
  final int? currentUserId;

  MatchesState copyWith({
    List<MatchModel>? accepted,
    List<MatchModel>? pending,
    bool? isLoading,
    Object? error = _unset,
    Object? currentUserId = _unset,
  }) =>
      MatchesState(
        accepted: accepted ?? this.accepted,
        pending: pending ?? this.pending,
        isLoading: isLoading ?? this.isLoading,
        error: error == _unset ? this.error : error as String?,
        currentUserId:
            currentUserId == _unset ? this.currentUserId : currentUserId as int?,
      );
}

final matchesControllerProvider =
    StateNotifierProvider<MatchesController, MatchesState>(
  (ref) => MatchesController(
    ref.watch(matchesRepoProvider),
    ref.watch(localStorageProvider),
  ),
);

class MatchesController extends StateNotifier<MatchesState> {
  MatchesController(this._repo, this._storage) : super(const MatchesState());

  final MatchesRepository _repo;
  final LocalStorage _storage;

  Future<void> loadMatches() async {
    final userId = await _storage.getUserId();
    if (userId == null) return;
    state = state.copyWith(isLoading: true, currentUserId: userId);
    try {
      final accepted = await _repo.getAcceptedMatches(userId);
      final pending = await _repo.getPendingMatches(userId);
      state = state.copyWith(accepted: accepted, pending: pending, error: null);
    } catch (e) {
      state = state.copyWith(
          error: friendlyError(e, 'Could not load your matches.'));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> acceptMatch(int matchId) async {
    try {
      final updated = await _repo.acceptMatch(matchId);
      state = state.copyWith(
        pending: state.pending.where((m) => m.id != matchId).toList(),
        accepted: [...state.accepted, updated],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          error: friendlyError(e, 'Could not accept this match.'));
      return false;
    }
  }

  Future<bool> rejectMatch(int matchId) async {
    try {
      await _repo.rejectMatch(matchId);
      state = state.copyWith(
        pending: state.pending.where((m) => m.id != matchId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          error: friendlyError(e, 'Could not decline this match.'));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

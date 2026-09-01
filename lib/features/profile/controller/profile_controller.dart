import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/profile/model/user_model.dart';
import 'package:roommate_finder/features/profile/repo/profile_repository.dart';

/// Sentinel so [ProfileState.copyWith] can tell "leave unchanged" apart from
/// "explicitly set to null" for its nullable fields.
const Object _unset = Object();

/// Profile screen state. Not a plain `GenericState<UserModel>` because the
/// cached profile must survive a failed refresh or save — the screen keeps
/// showing the last good data and surfaces [error] alongside it.
class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  final UserModel? profile;
  final bool isLoading;
  final String? error;

  bool get profileCompleted => profile?.profileCompleted ?? false;

  ProfileState copyWith({
    Object? profile = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) =>
      ProfileState(
        profile: profile == _unset ? this.profile : profile as UserModel?,
        isLoading: isLoading ?? this.isLoading,
        error: error == _unset ? this.error : error as String?,
      );
}

final profileRepoProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(tokenBaseRepoProvider)),
);

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
  (ref) => ProfileController(ref.watch(profileRepoProvider)),
);

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repo) : super(const ProfileState());

  final ProfileRepository _repo;

  Future<void> loadProfile(int userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _repo.getProfile(userId);
      state = state.copyWith(profile: profile, error: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: friendlyError(e, 'Could not load your profile.'),
        isLoading: false,
      );
    }
  }

  /// Returns true on success. On failure the previous profile is kept and
  /// [ProfileState.error] carries a user-safe message.
  Future<bool> updateProfile({
    required int id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    bool? student,
    String? studyLevel,
    String? occupation,
    bool? searchingRoommate,
    bool? searchingRoom,
    String? roommateGender,
    String? propertyDescription,
    String? notes,
    double? minBudget,
    double? maxBudget,
    String? sleepingSchedule,
    int? cleanliness,
    bool? smoking,
    String? diet,
    String? hobbies,
    String? musicPreference,
    String? petPreference,
    bool? preferredMale,
    bool? preferredFemale,
    List<File>? images,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _repo.updateProfile(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        student: student,
        studyLevel: studyLevel,
        occupation: occupation,
        searchingRoommate: searchingRoommate,
        searchingRoom: searchingRoom,
        roommateGender: roommateGender,
        propertyDescription: propertyDescription,
        notes: notes,
        minBudget: minBudget,
        maxBudget: maxBudget,
        sleepingSchedule: sleepingSchedule,
        cleanliness: cleanliness,
        smoking: smoking,
        diet: diet,
        hobbies: hobbies,
        musicPreference: musicPreference,
        petPreference: petPreference,
        preferredMale: preferredMale,
        preferredFemale: preferredFemale,
        images: images,
      );
      state = state.copyWith(profile: profile, error: null, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: friendlyError(e, 'Could not save your profile.'),
        isLoading: false,
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  /// Drops the cached profile on logout, so the next account to sign in never
  /// sees the previous user's details flash on screen.
  void clear() => state = const ProfileState();
}

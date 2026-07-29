import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserModel? _profile;
  bool _isLoading = false;
  String? _error;

  UserModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get profileCompleted => _profile?.profileCompleted ?? false;

  Future<void> loadProfile(int userId) async {
    _setLoading(true);
    try {
      _profile = await ProfileService.getProfile(userId);
      _error = null;
    } catch (e) {
      _error = friendlyError(e, 'Could not load your profile.');
    } finally {
      _setLoading(false);
    }
  }

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
    _setLoading(true);
    try {
      _profile = await ProfileService.updateProfile(
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
      _error = null;
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Could not save your profile.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

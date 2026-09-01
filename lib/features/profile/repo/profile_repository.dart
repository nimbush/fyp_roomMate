import 'dart:io';

import 'package:roommate_finder/common/utils/base_repository/base_repository.dart';
import 'package:roommate_finder/common/utils/base_repository/request_input.dart';
import 'package:roommate_finder/features/profile/model/user_model.dart';

/// Profile endpoints: fetch (`GET /api/profile`) and the multipart update
/// (`PUT /api/profile`) that carries every lifestyle field plus images.
class ProfileRepository {
  ProfileRepository(this._base);

  final BaseRepository _base;

  /// The backend wraps the profile in a `data` envelope — `GET` returns
  /// `{"data": {...}, "profileCompleted": bool}` and `PUT` returns
  /// `{"message": ..., "data": {...}}`. Passing either straight to
  /// `UserModel.fromJson` throws, because `id`/`firstName` sit one level down.
  ///
  /// Visible for testing.
  static Map<String, dynamic> unwrapProfile(dynamic body) {
    final json = body as Map<String, dynamic>;
    final inner = json['data'];
    if (inner is Map<String, dynamic>) {
      return <String, dynamic>{
        ...inner,
        // `profileCompleted` lives on the envelope, not the user object.
        if (json.containsKey('profileCompleted'))
          'profileCompleted': json['profileCompleted'],
      };
    }
    return json;
  }

  Future<UserModel> getProfile(int userId) => _base.get(
        RequestInput(
          path: '/api/profile?userId=$userId',
          parse: (json) => UserModel.fromJson(unwrapProfile(json)),
        ),
      );

  /// Null fields are skipped by the multipart builder, so the backend keeps
  /// its existing values for anything not provided.
  Future<UserModel> updateProfile({
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
  }) =>
      _base.multipart(
        'PUT',
        '/api/profile',
        fields: {
          'id': id,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'student': student,
          'studyLevel': studyLevel,
          'occupation': occupation,
          'searchingRoommate': searchingRoommate,
          'searchingRoom': searchingRoom,
          'roommateGender': roommateGender,
          'propertyDescription': propertyDescription,
          'notes': notes,
          'minBudget': minBudget,
          'maxBudget': maxBudget,
          'sleepingSchedule': sleepingSchedule,
          'cleanliness': cleanliness,
          'smoking': smoking,
          'diet': diet,
          'hobbies': hobbies,
          'musicPreference': musicPreference,
          'petPreference': petPreference,
          'preferredMale': preferredMale,
          'preferredFemale': preferredFemale,
        },
        files: images ?? const [],
        parse: (json) => UserModel.fromJson(unwrapProfile(json)),
      );
}

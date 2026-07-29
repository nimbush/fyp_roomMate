import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ProfileService {
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

  static Future<UserModel> getProfile(int userId) async {
    final data = await ApiService.get('/api/profile?userId=$userId');
    return UserModel.fromJson(unwrapProfile(data));
  }

  static Future<UserModel> updateProfile({
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
    final token = await StorageService.getToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${AppConfig.baseUrl}/api/profile'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    void addField(String key, dynamic value) {
      if (value != null) request.fields[key] = value.toString();
    }

    addField('id', id);
    addField('firstName', firstName);
    addField('lastName', lastName);
    addField('phoneNumber', phoneNumber);
    addField('student', student);
    addField('studyLevel', studyLevel);
    addField('occupation', occupation);
    addField('searchingRoommate', searchingRoommate);
    addField('searchingRoom', searchingRoom);
    addField('roommateGender', roommateGender);
    addField('propertyDescription', propertyDescription);
    addField('notes', notes);
    addField('minBudget', minBudget);
    addField('maxBudget', maxBudget);
    addField('sleepingSchedule', sleepingSchedule);
    addField('cleanliness', cleanliness);
    addField('smoking', smoking);
    addField('diet', diet);
    addField('hobbies', hobbies);
    addField('musicPreference', musicPreference);
    addField('petPreference', petPreference);
    addField('preferredMale', preferredMale);
    addField('preferredFemale', preferredFemale);

    if (images != null) {
      for (final file in images) {
        request.files.add(await http.MultipartFile.fromPath('images', file.path));
      }
    }

    final streamed = await request.send().timeout(AppConfig.connectTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return UserModel.fromJson(unwrapProfile(jsonDecode(response.body)));
    }
    String message = 'Profile update failed';
    try {
      final body = jsonDecode(response.body);
      message = body['error'] ?? body['message'] ?? message;
    } catch (_) {}
    throw ApiException(message, statusCode: response.statusCode);
  }
}

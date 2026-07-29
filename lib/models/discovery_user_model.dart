import 'image_model.dart';

class DiscoveryUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? roommateGender;
  final double? minBudget;
  final double? maxBudget;
  final String? occupation;
  final bool? student;
  final String? studyLevel;
  final String? sleepingSchedule;
  final int? cleanliness;
  final bool? smoking;
  final String? diet;
  final String? hobbies;
  final String? musicPreference;
  final String? petPreference;
  final bool? searchingRoommate;
  final bool? searchingRoom;
  final String? propertyDescription;
  final String? notes;
  final double compatibilityScore;
  final List<ImageModel> images;

  const DiscoveryUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.roommateGender,
    this.minBudget,
    this.maxBudget,
    this.occupation,
    this.student,
    this.studyLevel,
    this.sleepingSchedule,
    this.cleanliness,
    this.smoking,
    this.diet,
    this.hobbies,
    this.musicPreference,
    this.petPreference,
    this.searchingRoommate,
    this.searchingRoom,
    this.propertyDescription,
    this.notes,
    required this.compatibilityScore,
    this.images = const [],
  });

  String get fullName => '$firstName $lastName';

  String get budgetRange {
    if (minBudget != null && maxBudget != null) {
      return 'Rs ${minBudget!.toInt()}–${maxBudget!.toInt()}';
    }
    return 'Not specified';
  }

  factory DiscoveryUserModel.fromJson(Map<String, dynamic> json) =>
      DiscoveryUserModel(
        id: json['id'] as int,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        roommateGender: json['roommateGender'] as String?,
        minBudget: (json['minBudget'] as num?)?.toDouble(),
        maxBudget: (json['maxBudget'] as num?)?.toDouble(),
        occupation: json['occupation'] as String?,
        student: json['student'] as bool?,
        studyLevel: json['studyLevel'] as String?,
        sleepingSchedule: json['sleepingSchedule'] as String?,
        cleanliness: json['cleanliness'] as int?,
        smoking: json['smoking'] as bool?,
        diet: json['diet'] as String?,
        hobbies: json['hobbies'] as String?,
        musicPreference: json['musicPreference'] as String?,
        petPreference: json['petPreference'] as String?,
        searchingRoommate: json['searchingRoommate'] as bool?,
        searchingRoom: json['searchingRoom'] as bool?,
        propertyDescription: json['propertyDescription'] as String?,
        notes: json['notes'] as String?,
        compatibilityScore:
            (json['compatibilityScore'] as num?)?.toDouble() ?? 0.0,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => ImageModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

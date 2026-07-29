import 'image_model.dart';

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final bool? student;
  final String? studyLevel;
  final String? occupation;
  final bool profileCompleted;
  final bool verified;
  final bool? searchingRoommate;
  final bool? searchingRoom;
  final String? roommateGender;
  final String? propertyDescription;
  final String? notes;
  final double? minBudget;
  final double? maxBudget;
  final String? sleepingSchedule;
  final int? cleanliness;
  final bool? smoking;
  final String? diet;
  final String? hobbies;
  final String? musicPreference;
  final String? petPreference;
  final bool? preferredMale;
  final bool? preferredFemale;
  final List<ImageModel> images;
  final int imageCount;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.student,
    this.studyLevel,
    this.occupation,
    required this.profileCompleted,
    required this.verified,
    this.searchingRoommate,
    this.searchingRoom,
    this.roommateGender,
    this.propertyDescription,
    this.notes,
    this.minBudget,
    this.maxBudget,
    this.sleepingSchedule,
    this.cleanliness,
    this.smoking,
    this.diet,
    this.hobbies,
    this.musicPreference,
    this.petPreference,
    this.preferredMale,
    this.preferredFemale,
    this.images = const [],
    this.imageCount = 0,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        student: json['student'] as bool?,
        studyLevel: json['studyLevel'] as String?,
        occupation: json['occupation'] as String?,
        profileCompleted: json['profileCompleted'] as bool? ?? false,
        verified: json['verified'] as bool? ?? false,
        searchingRoommate: json['searchingRoommate'] as bool?,
        searchingRoom: json['searchingRoom'] as bool?,
        roommateGender: json['roommateGender'] as String?,
        propertyDescription: json['propertyDescription'] as String?,
        notes: json['notes'] as String?,
        minBudget: (json['minBudget'] as num?)?.toDouble(),
        maxBudget: (json['maxBudget'] as num?)?.toDouble(),
        sleepingSchedule: json['sleepingSchedule'] as String?,
        cleanliness: json['cleanliness'] as int?,
        smoking: json['smoking'] as bool?,
        diet: json['diet'] as String?,
        hobbies: json['hobbies'] as String?,
        musicPreference: json['musicPreference'] as String?,
        petPreference: json['petPreference'] as String?,
        preferredMale: json['preferredMale'] as bool?,
        preferredFemale: json['preferredFemale'] as bool?,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => ImageModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        imageCount: json['imageCount'] as int? ?? 0,
      );
}

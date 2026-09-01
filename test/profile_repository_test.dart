import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/features/profile/model/user_model.dart';
import 'package:roommate_finder/features/profile/repo/profile_repository.dart';

/// Regression tests for the `data` envelope returned by `/api/profile`.
///
/// Before this was handled, `UserModel.fromJson` received the envelope itself
/// and threw on `json['id'] as int`, so the Profile tab could never load.
void main() {
  // Shape captured from a live GET /api/profile?userId=2 response.
  Map<String, dynamic> getResponse() => {
        'profileCompleted': false,
        'data': {
          'id': 2,
          'firstName': 'Aarav',
          'lastName': 'Shrestha',
          'email': 'qa.aarav.test@example.com',
          'phoneNumber': '9800000001',
          'verified': true,
          'profileCompleted': false,
          'minBudget': 0.0,
          'maxBudget': 0.0,
          'cleanliness': 0,
          'images': <dynamic>[],
          'imageCount': 0,
        },
      };

  group('unwrapProfile', () {
    test('lifts the user object out of a GET envelope', () {
      final unwrapped = ProfileRepository.unwrapProfile(getResponse());

      expect(unwrapped['id'], 2);
      expect(unwrapped['firstName'], 'Aarav');
      expect(unwrapped['email'], 'qa.aarav.test@example.com');
    });

    test('keeps envelope-level profileCompleted', () {
      final unwrapped = ProfileRepository.unwrapProfile(getResponse());
      expect(unwrapped['profileCompleted'], isFalse);
    });

    test('handles the PUT envelope, which carries a message instead', () {
      final put = {
        'message': 'Profile updated successfully',
        'data': {
          'id': 2,
          'firstName': 'Aarav',
          'lastName': 'Shrestha',
          'email': 'qa.aarav.test@example.com',
          'verified': true,
          'profileCompleted': true,
          'images': <dynamic>[],
        },
      };

      final unwrapped = ProfileRepository.unwrapProfile(put);
      expect(unwrapped['id'], 2);
      expect(unwrapped['profileCompleted'], isTrue);
    });

    test('passes a flat body through unchanged', () {
      final flat = {
        'id': 7,
        'firstName': 'Priya',
        'lastName': 'Sharma',
        'email': 'priya@example.com',
        'verified': true,
        'profileCompleted': true,
        'images': <dynamic>[],
      };

      expect(ProfileRepository.unwrapProfile(flat)['id'], 7);
    });

    test('the unwrapped map actually parses into a UserModel', () {
      final user = UserModel.fromJson(
        ProfileRepository.unwrapProfile(getResponse()),
      );

      expect(user.id, 2);
      expect(user.fullName, 'Aarav Shrestha');
      expect(user.profileCompleted, isFalse);
      expect(user.verified, isTrue);
    });
  });
}

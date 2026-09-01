import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/common/utils/validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts ordinary addresses', () {
      expect(isValidEmail('nimesh@example.com'), isTrue);
      expect(isValidEmail('qa.aarav.test@example.com'), isTrue);
      expect(isValidEmail('first+tag@sub.domain.co.uk'), isTrue);
    });

    test('trims surrounding whitespace before validating', () {
      expect(isValidEmail('  nimesh@example.com  '), isTrue);
    });

    test('rejects the near-misses the old `contains("@")` check allowed', () {
      expect(isValidEmail('a@b'), isFalse, reason: 'no dotted domain');
      expect(isValidEmail('user@example'), isFalse, reason: 'no TLD');
      expect(isValidEmail('user@.com'), isFalse, reason: 'empty domain label');
      expect(isValidEmail('@example.com'), isFalse, reason: 'no local part');
    });

    test('rejects empty and null input', () {
      expect(isValidEmail(null), isFalse);
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('   '), isFalse);
    });
  });

  group('validatePassword', () {
    test('accepts 8+ characters, matching the backend rule', () {
      expect(validatePassword('Test@123'), isNull);
    });

    test('rejects short and empty passwords', () {
      expect(validatePassword('Test@12'), isNotNull);
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/features/settings/view/content_sections.dart';
import 'package:roommate_finder/features/settings/view/faq_screen.dart';

void main() {
  group('parseSections', () {
    test('splits "Title - description" lines (Notifications)', () {
      const raw = '''
RoomMate Finder can let you know when something needs your attention:

New matches — when someone you liked likes you back.
New likes — when another user likes your profile.
New messages — when you receive a message in a conversation.
Account activity — verification codes and password reset codes, sent by email.

Verification and password reset emails are always sent, because they are needed to keep your account secure.
''';
      final s = parseSections(raw);

      // Lead paragraph stays untitled so the screen can promote it.
      expect(s.first.heading, isNull);

      final headed = s.where((e) => e.heading != null).toList();
      expect(headed.map((e) => e.heading), [
        'New matches',
        'New likes',
        'New messages',
        'Account activity',
      ]);
      expect(headed.first.body, 'when someone you liked likes you back.');

      // Trailing security note remains untitled -> rendered as a callout.
      expect(s.last.heading, isNull);
      expect(s.last.body, contains('always sent'));
    });

    test('splits "Heading. Body" lines (Privacy)', () {
      const raw = '''
We collect only what the app needs to match you with a roommate: your name and email.

How we use it. Your profile details are used to calculate compatibility scores.

Security. Passwords are stored using BCrypt hashing.
''';
      final headed =
          parseSections(raw).where((e) => e.heading != null).toList();

      expect(headed.map((e) => e.heading), ['How we use it', 'Security']);
      expect(headed.last.body, startsWith('Passwords are stored'));
    });

    test('leaves long lead sentences as plain paragraphs', () {
      // The opening Privacy line contains a period but is far too long to be a
      // heading - it must not be split into a label.
      const raw =
          'We collect only what the app needs to match you with a roommate: '
          'your name, email address, phone number, and the photos you upload.';
      final s = parseSections(raw);
      expect(s.single.heading, isNull);
    });

    test('keeps unmatched text rather than dropping it', () {
      final s = parseSections('just a sentence with no structure');
      expect(s.single.heading, isNull);
      expect(s.single.body, 'just a sentence with no structure');
    });

    test('returns empty for empty input', () {
      expect(parseSections('   '), isEmpty);
    });
  });

  group('iconForHeading', () {
    test('is stable for unknown headings', () {
      // Never throws or returns null - screens render whatever the backend sends.
      expect(iconForHeading('Something we have never seen'), isNotNull);
      expect(iconForHeading(null), isNotNull);
    });
  });

  group('parseFaq', () {
    test('pairs each question with its answer', () {
      const raw = '''
How is my compatibility score calculated?
Your profile is compared across three areas. Profiles with more detail score better.

Why can't I see anyone in Discover?
You need to complete your profile first.
''';
      final faq = parseFaq(raw);

      expect(faq, hasLength(2));
      expect(faq.first.question, 'How is my compatibility score calculated?');
      expect(faq.first.answer, startsWith('Your profile is compared'));
      expect(faq.last.question, "Why can't I see anyone in Discover?");
    });

    test('joins multi-line answers into one paragraph', () {
      const raw = 'A question?\nfirst line\nsecond line';
      expect(parseFaq(raw).single.answer, 'first line second line');
    });

    test('skips blocks with no answer', () {
      // A dangling question would otherwise render as an accordion that opens
      // onto nothing.
      expect(parseFaq('Orphan question with no answer?'), isEmpty);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// One parsed point from a static-content blob: a short heading plus its body.
///
/// [heading] is null for a plain paragraph that has no title of its own - those
/// render as lead/body text rather than as an icon row.
class ContentSection {
  const ContentSection({this.heading, required this.body});

  final String? heading;
  final String body;
}

/// Splits backend static content into headed sections.
///
/// The blobs use two shapes, sometimes in the same document:
///   "Title — description"   (em dash, used by Notifications)
///   "Heading. Body text."   (leading sentence acts as the heading)
/// Anything that matches neither stays a plain paragraph, so unexpected content
/// still renders as readable text instead of being dropped.
///
/// Visible for testing.
List<ContentSection> parseSections(String raw) {
  final out = <ContentSection>[];

  for (final block in raw.trim().split(RegExp(r'\n\s*\n'))) {
    for (final line in block.trim().split('\n')) {
      final text = line.trim();
      if (text.isEmpty) continue;

      // "Title — description"
      final dash = RegExp(r'^(.{2,60}?)\s+[—–-]\s+(.+)$').firstMatch(text);
      if (dash != null) {
        out.add(ContentSection(
          heading: dash.group(1)!.trim(),
          body: dash.group(2)!.trim(),
        ));
        continue;
      }

      // "Heading. Body." - only when the lead sentence is short enough to read
      // as a label rather than as the first sentence of a paragraph.
      final period = RegExp(r'^([A-Z][^.!?]{2,32})\.\s+(.+)$').firstMatch(text);
      if (period != null) {
        out.add(ContentSection(
          heading: period.group(1)!.trim(),
          body: period.group(2)!.trim(),
        ));
        continue;
      }

      out.add(ContentSection(body: text));
    }
  }

  return out;
}

/// Maps a section heading to an icon, so each row is visually distinguishable.
///
/// Falls back to a neutral glyph for headings we don't recognise - the screens
/// render whatever the backend sends, so this can never assume a fixed set.
IconData iconForHeading(String? heading) {
  final h = (heading ?? '').toLowerCase();

  const table = <String, IconData>{
    'match': SolarIconsOutline.heart,
    'like': SolarIconsOutline.heart,
    'message': SolarIconsOutline.chatRound,
    'account': SolarIconsOutline.user,
    'eligib': SolarIconsOutline.userCheckRounded,
    'conduct': SolarIconsOutline.handShake,
    'content': SolarIconsOutline.gallery,
    'liabilit': SolarIconsOutline.scale,
    'securit': SolarIconsOutline.lockPassword,
    'collect': SolarIconsOutline.inbox,
    'never': SolarIconsOutline.shieldCross,
    'see': SolarIconsOutline.eye,
    'control': SolarIconsOutline.settings,
    'use it': SolarIconsOutline.magicStick,
  };

  for (final entry in table.entries) {
    if (h.contains(entry.key)) return entry.value;
  }
  return SolarIconsOutline.checkCircle;
}

/// One question/answer pair.
class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

/// Splits the backend's FAQ blob into entries.
///
/// The content arrives as blank-line-separated blocks, each block being a
/// question on the first line and its answer on the rest. Anything that doesn't
/// fit that shape is skipped rather than rendered as a half-empty card.
///
/// Visible for testing.
List<FaqEntry> parseFaq(String raw) {
  final blocks = raw.trim().split(RegExp(r'\n\s*\n'));
  final entries = <FaqEntry>[];
  for (final block in blocks) {
    final lines =
        block.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) continue;
    entries.add(FaqEntry(
      lines.first.trim(),
      lines.skip(1).join(' ').trim(),
    ));
  }
  return entries;
}

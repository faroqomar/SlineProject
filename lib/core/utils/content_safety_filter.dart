/// Provides lightweight display sanitization for unsafe user-generated copy.
///
/// This is a UI backstop for public dashboard surfaces. It does not replace
/// server-side moderation; it prevents known explicit phrases from being echoed
/// in high-visibility cards before a moderation workflow catches up.
class ContentSafetyFilter {
  const ContentSafetyFilter._();

  static const String replacement = 'Content under review';

  static const List<String> _blockedPhrases = [
    'suck my cock',
    'suck my dick',
    'fuck you',
    'motherfucker',
    'cocksucker',
  ];

  static final List<String> _blockedPhraseKeys = _blockedPhrases
      .map(_foldForModeration)
      .toList(growable: false);

  /// Returns a safe display string for compact public dashboard surfaces.
  static String displayTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return replacement;
    final normalized = _foldForModeration(trimmed);
    final isBlocked = _blockedPhraseKeys.any(normalized.contains);
    return isBlocked ? replacement : trimmed;
  }

  /// Folds user copy for phrase matching while preserving original display copy.
  ///
  /// Dart does not expose Unicode NFKD normalization in the SDK, so this helper
  /// applies the equivalent moderation backstop this app needs: lowercase,
  /// remove combining marks, drop punctuation separators,
  /// and normalize common Latin diacritics used in trivial bypass attempts.
  static String _foldForModeration(String value) {
    final lower = value.toLowerCase();
    final withoutCombiningMarks = lower.replaceAll(
      RegExp(r'[\u0300-\u036f]'),
      '',
    );
    final asciiFolded = withoutCombiningMarks.split('').map(_foldChar).join();
    final alphanumericOnly = asciiFolded.replaceAll(
      RegExp('[^a-z0-9]+'),
      '',
    );
    return alphanumericOnly;
  }

  static String _foldChar(String char) {
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ā': 'a',
      'æ': 'ae',
      'ç': 'c',
      'ć': 'c',
      'č': 'c',
      'ď': 'd',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'ē': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ī': 'i',
      'ñ': 'n',
      'ń': 'n',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ō': 'o',
      'ø': 'o',
      'œ': 'oe',
      'ř': 'r',
      'š': 's',
      'ś': 's',
      'ß': 'ss',
      'ť': 't',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ū': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'ž': 'z',
      'ź': 'z',
      'ż': 'z',
    };
    return replacements[char] ?? char;
  }
}

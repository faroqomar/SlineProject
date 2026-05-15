/// Unit tests for public display safety filtering.
///
/// These tests protect dashboard copy from trivial punctuation and diacritic
/// bypasses while keeping safe titles unchanged for display.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/utils/content_safety_filter.dart';

void main() {
  group('ContentSafetyFilter.displayTitle', () {
    test('keeps safe titles trimmed for display', () {
      expect(
        ContentSafetyFilter.displayTitle('  Outdoor photo session  '),
        'Outdoor photo session',
      );
    });

    test('blocks explicit phrases split by punctuation and diacritics', () {
      expect(
        ContentSafetyFilter.displayTitle('s.u.c.k my cöck'),
        ContentSafetyFilter.replacement,
      );
      expect(
        ContentSafetyFilter.displayTitle('f u c k   yóu'),
        ContentSafetyFilter.replacement,
      );
    });
  });
}

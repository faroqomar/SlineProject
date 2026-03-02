import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'T68 Booking request flow select slot book list/details reflect booking',
    (tester) async {
      const tag = 'T68';
      T61T70Preflight.log(
        tag,
        'Blocked by preflight: payment checkout has no automated completion path '
        'in current code (QiCard web flow only; demo mode stops before confirmation).',
      );
      await launchAppForIntegration(tester, tag: tag, resetAuth: true);
      throw TestFailure(
        '[$tag] Unexpected execution: this test should be skipped by preflight until '
        'a default-preserving checkout automation seam is added.',
      );
    },
    skip: T61T70Preflight.t68() != null,
  );
}

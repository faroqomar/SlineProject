import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'T67 Chat flow open conversation send message message visible',
    (tester) async {
      T61T70Preflight.log(
        'T67',
        'Preflight satisfied. Implement seeded conversation open/send/wait assertions.',
      );
      await launchAppForIntegration(tester, tag: 'T67');
      throw UnimplementedError(
        'T67 implementation requires seeded conversation contract.',
      );
    },
    skip: T61T70Preflight.t67() != null,
  );
}

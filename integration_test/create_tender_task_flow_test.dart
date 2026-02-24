import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'T66 Create tender task flow form submit appears in task/order surfaces',
    (tester) async {
      T61T70Preflight.log(
        'T66',
        'Preflight satisfied. Implement tender creation + two-surface visibility checks.',
      );
      await launchAppForIntegration(tester, tag: 'T66');
      throw UnimplementedError(
        'T66 implementation requires locked surfaces and seed inputs.',
      );
    },
    skip: T61T70Preflight.t66() != null,
  );
}

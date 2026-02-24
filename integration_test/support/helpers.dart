import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:sline_app/main.dart' as app;

import 'preflight.dart';

void ensureIntegrationBinding() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

Future<void> launchAppForIntegration(
  WidgetTester tester, {
  required String tag,
}) async {
  T61T70Preflight.log(tag, 'Launching app main()');
  app.main();
  await tester.pump();
}

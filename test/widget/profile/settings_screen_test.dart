/// Widget tests for the Amber Dusk settings route shell.
///
/// These checks protect the route-level background because settings is pushed
/// outside the bottom-tab shell and must paint its own Amber Dusk material.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/providers/theme_mode_provider.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/profile/view/settings_screen.dart';

import '../../test_support/pump_app.dart';

void main() {
  testWidgets('uses the Amber Dusk route background and atmospheric fades', (
    tester,
  ) async {
    await pumpApp(
      tester,
      ChangeNotifierProvider(
        create: (_) => ThemeModeProvider(),
        child: const SettingsScreen(),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);

    expect(scaffold.backgroundColor, AmberDuskColors.background);
    expect(find.byType(AmberDuskBackground), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('PREFERENCES'), findsOneWidget);
  });
}

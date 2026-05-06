import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/features/profile/services/profile_deep_link_handler.dart';

import '../../../test_support/pump_app.dart';

void main() {
  group('Profile deep links', () {
    testWidgets('profile entity selects visible Profile destination', (
      tester,
    ) async {
      final registry = DeepLinkRegistry();
      final navigationProvider = NavigationProvider();
      registerProfileDeepLinks(registry);

      await pumpApp(
        tester,
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  await registry.handle(context, 'profile', 'current-user');
                },
                child: const Text('Open profile link'),
              );
            },
          ),
        ),
      );

      navigationProvider.setCurrentIndex(MainNavDestinations.home);
      await tester.tap(find.text('Open profile link'));
      await tester.pump();

      expect(navigationProvider.currentIndex, MainNavDestinations.profile);
    });
  });
}

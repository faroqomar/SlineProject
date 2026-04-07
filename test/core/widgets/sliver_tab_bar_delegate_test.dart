import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/sliver_tab_bar_delegate.dart';

void main() {
  group('SliverTabBarDelegate', () {
    testWidgets('T-CW001 renders TabBar child inside CustomScrollView',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const DefaultTabController(
            length: 2,
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverTabBarDelegate(
                      TabBar(
                        tabs: [Tab(text: 'Tab A'), Tab(text: 'Tab B')],
                      ),
                    ),
                  ),
                  SliverFillRemaining(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
    });

    test('T-CW002 maxExtent and minExtent return TabBar preferred size', () {
      const tabBar = TabBar(
        tabs: [Tab(text: 'X'), Tab(text: 'Y')],
      );
      const delegate = SliverTabBarDelegate(tabBar);

      expect(delegate.maxExtent, equals(tabBar.preferredSize.height));
      expect(delegate.minExtent, equals(tabBar.preferredSize.height));
    });

    test('T-CW003 shouldRebuild returns false for same tabBar', () {
      const tabBar = TabBar(
        tabs: [Tab(text: 'A'), Tab(text: 'B')],
      );
      const delegate1 = SliverTabBarDelegate(tabBar);
      const delegate2 = SliverTabBarDelegate(tabBar);

      expect(delegate1.shouldRebuild(delegate2), isFalse);
    });

    testWidgets('T-CW004 applies custom backgroundColor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const DefaultTabController(
            length: 2,
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverTabBarDelegate(
                      TabBar(
                        tabs: [Tab(text: 'A'), Tab(text: 'B')],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ),
                  SliverFillRemaining(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // SliverTabBarDelegate wraps TabBar in a Container with BoxDecoration
      final containers = tester.widgetList<Container>(
        find.ancestor(
          of: find.byType(TabBar),
          matching: find.byType(Container),
        ),
      );
      final hasRedBg = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == Colors.red;
      });
      expect(hasRedBg, isTrue);
    });
  });
}

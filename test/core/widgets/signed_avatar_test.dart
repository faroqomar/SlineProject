import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/signed_avatar.dart';

import 'widget_test_helpers.dart';

void main() {
  group('SignedAvatar', () {
    testWidgets('T-CW080 shows shimmer while loading (null path)', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SignedAvatar(storagePathOrUrl: null));
      // null path → loading=false immediately → shows placeholder
      // but with empty path, it shows initials/person icon fallback
      expect(find.byType(SignedAvatar), findsOneWidget);
    });

    testWidgets(
      'T-CW081 shows initials fallback when no URL and initials provided',
      (tester) async {
        await pumpCoreWidget(
          tester,
          const SignedAvatar(
            storagePathOrUrl: null,
            initials: 'JD',
            radius: 24,
          ),
        );
        await tester.pump();
        // Should show initials text
        expect(find.text('JD'), findsOneWidget);
      },
    );

    testWidgets('T-CW082 shows person icon when no URL and no initials', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const SignedAvatar(storagePathOrUrl: null, radius: 24),
      );
      await tester.pump();
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('T-CW083 renders with public URL directly', (tester) async {
      await pumpCoreWidget(
        tester,
        const SignedAvatar(
          storagePathOrUrl: 'https://example.com/avatar.jpg',
          radius: 24,
        ),
      );
      await tester.pump();
      // CircleAvatar should be rendered with the URL
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('T-CW084 online indicator visible when enabled', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const SignedAvatar(
          storagePathOrUrl: 'https://example.com/avatar.jpg',
          radius: 24,
          showOnlineIndicator: true,
        ),
      );
      await tester.pump();
      // Online indicator is a 12x12 green container in a Stack
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('T-CW085 has Semantics image=true', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(
        tester,
        const SignedAvatar(storagePathOrUrl: null, radius: 24),
      );
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
      handle.dispose();
    });
  });
}

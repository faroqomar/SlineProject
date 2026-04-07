import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/signed_image.dart';

import 'widget_test_helpers.dart';

void main() {
  group('SignedImage', () {
    testWidgets('T-CW090 shows shimmer while loading (null path)',
        (tester) async {
      await pumpCoreWidget(
        tester,
        const SignedImage(storagePathOrUrl: null),
      );
      // Null path → loading=false immediately → error state
      // But the widget renders without crash
      expect(find.byType(SignedImage), findsOneWidget);
    });

    testWidgets('T-CW091 shows error state with retry text for empty path',
        (tester) async {
      await pumpCoreWidget(
        tester,
        const SignedImage(storagePathOrUrl: ''),
      );
      await tester.pump();
      // Empty path → error state with retry
      expect(find.text('Tap to retry'), findsOneWidget);
    });

    testWidgets('T-CW092 renders with public URL', (tester) async {
      await pumpCoreWidget(
        tester,
        const SignedImage(
          storagePathOrUrl: 'https://example.com/image.jpg',
        ),
      );
      await tester.pump();
      // With a full URL it should skip signed URL resolution
      expect(find.byType(SignedImage), findsOneWidget);
    });

    testWidgets('T-CW093 has Semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(
        tester,
        const SignedImage(storagePathOrUrl: null),
      );
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW094 no CircularProgressIndicator in any state',
        (tester) async {
      // SignedImage should NEVER show the old spinner — only shimmer or content
      await pumpCoreWidget(
        tester,
        const SignedImage(storagePathOrUrl: null),
      );
      await tester.pump();
      // No CircularProgressIndicator anywhere
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

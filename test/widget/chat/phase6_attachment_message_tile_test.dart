/// Verifies Phase 6 attachment privacy behavior so private storage paths stay
/// out of user-visible error text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/features/chat/attachments/widgets/attachment_message_tile.dart';

void main() {
  group('AttachmentMessageTile Phase 6 privacy', () {
    tearDown(SignedUrlCache.clear);

    testWidgets('does not expose private storage paths in error UI', (
      tester,
    ) async {
      const privatePath = 'chat-attachments/convos/private/file.jpg';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AttachmentMessageTile(
              isMine: false,
              storagePath: privatePath,
              time: '12:00',
              signedUrlResolver: (_) async {
                throw Exception('$privatePath signed-url failure');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Could not load attachment. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining(privatePath), findsNothing);
      expect(find.textContaining('signed-url'), findsNothing);
    });
  });
}

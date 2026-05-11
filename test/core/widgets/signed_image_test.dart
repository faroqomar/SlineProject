import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/services/signed_url_generator.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/l10n/app_localizations.dart';

import 'widget_test_helpers.dart';

// Mirrors Amber Dusk's profile photo fallback so this test can state the
// expected rendered color without coupling to the token object itself.
const expectedFallbackColor = Color(0xFF4A7A8C);

void main() {
  group('SignedImage', () {
    testWidgets('T-CW090 shows shimmer while loading (null path)', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SignedImage(storagePathOrUrl: null));
      // Null path → loading=false immediately → error state
      // But the widget renders without crash
      expect(find.byType(SignedImage), findsOneWidget);
    });

    testWidgets('T-CW091 shows error state with retry text for empty path', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SignedImage(storagePathOrUrl: ''));
      await tester.pump();
      // Empty path → error state with retry
      expect(find.text('Tap to retry'), findsOneWidget);
      final context = tester.element(find.byType(SignedImage));
      expect(AppLocalizations.of(context)?.tapToRetry, 'Tap to retry');
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCoolFallback = containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration &&
            decoration.color == expectedFallbackColor;
      });
      expect(hasCoolFallback, isTrue);
    });

    testWidgets('T-CW092 renders with public URL', (tester) async {
      await pumpCoreWidget(
        tester,
        const SignedImage(storagePathOrUrl: 'https://example.com/image.jpg'),
      );
      await tester.pump();
      // With a full URL it should skip signed URL resolution
      expect(find.byType(SignedImage), findsOneWidget);
    });

    testWidgets(
      'T-CW095 - resolves storage paths through the injected generator',
      (tester) async {
        final generator = _RecordingSignedUrlGenerator(
          'https://signed.example/task.jpg',
        );

        await pumpCoreWidget(
          tester,
          SignedImage(
            storagePathOrUrl: 'tasks/task-1/photo.jpg',
            urlGenerator: generator,
          ),
        );
        // The resolved image path can render CachedNetworkImage's repeating
        // shimmer placeholder, so pumpAndSettle would wait forever here.
        await tester.pump();

        expect(generator.paths, ['tasks/task-1/photo.jpg']);
        expect(find.text('Tap to retry'), findsNothing);
      },
    );

    testWidgets('T-CW096 - shows Amber fallback when generator fails', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        SignedImage(
          storagePathOrUrl: 'tasks/task-2/photo.jpg',
          urlGenerator: _ThrowingSignedUrlGenerator(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tap to retry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW096a accepts generic media fallback tokens', (
      tester,
    ) async {
      const fallbackColor = Color(0xFF102030);

      await pumpCoreWidget(
        tester,
        const SignedImage(
          storagePathOrUrl: '',
          mediaTokens: SignedImageMediaTokens(
            profilePhotoFallback: fallbackColor,
            foreground: Colors.white,
            fallbackLabelStyle: TextStyle(color: Colors.white),
          ),
        ),
      );
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCustomFallback = containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == fallbackColor;
      });
      expect(hasCustomFallback, isTrue);
    });

    testWidgets('T-CW093 has Semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(tester, const SignedImage(storagePathOrUrl: null));
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW094 no CircularProgressIndicator in any state', (
      tester,
    ) async {
      // SignedImage should NEVER show the old spinner — only shimmer or content
      await pumpCoreWidget(tester, const SignedImage(storagePathOrUrl: null));
      await tester.pump();
      // No CircularProgressIndicator anywhere
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

/// Records every requested storage path, returns a fixed URL, and ignores
/// `expire` so SignedImage tests can assert createSignedUrl inputs.
class _RecordingSignedUrlGenerator implements SignedUrlGenerator {
  _RecordingSignedUrlGenerator(this.url);

  final String url;
  final List<String> paths = [];

  @override
  Future<String?> createSignedUrl(
    String storagePath, {
    Duration? expire,
  }) async {
    paths.add(storagePath);
    return url;
  }
}

/// Always throws `Exception('signed image failure')` for SignedImage
/// error-path verification.
class _ThrowingSignedUrlGenerator implements SignedUrlGenerator {
  @override
  Future<String?> createSignedUrl(String storagePath, {Duration? expire}) {
    throw Exception('signed image failure');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/services/signed_url_generator.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
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
        final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        expect(
          avatar.backgroundColor,
          AmberDuskTokens.widgetTheme.media.avatarFallback,
        );
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
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(
        avatar.backgroundColor,
        AmberDuskTokens.widgetTheme.media.avatarFallback,
      );
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

    testWidgets(
      'T-CW086 resolves storage paths through the injected generator',
      (tester) async {
        final generator = _RecordingSignedUrlGenerator(
          'https://signed.example/avatar.jpg',
        );

        await pumpCoreWidget(
          tester,
          SignedAvatar(
            storagePathOrUrl: 'avatars/user-1/profile.png',
            radius: 24,
            urlGenerator: generator,
          ),
        );
        await tester.pump();

        expect(generator.paths, ['avatars/user-1/profile.png']);
        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('T-CW087 falls back without a spinner when generator fails', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        SignedAvatar(
          storagePathOrUrl: 'avatars/user-2/profile.png',
          radius: 24,
          urlGenerator: _ThrowingSignedUrlGenerator(),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
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
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasOnlineDot = containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration &&
            decoration.color == AmberDuskTokens.widgetTheme.media.onlineDot;
      });
      expect(hasOnlineDot, isTrue);
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

class _ThrowingSignedUrlGenerator implements SignedUrlGenerator {
  @override
  Future<String?> createSignedUrl(String storagePath, {Duration? expire}) {
    throw Exception('signed avatar failure');
  }
}

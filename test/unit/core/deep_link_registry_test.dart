import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';

void main() {
  late DeepLinkRegistry registry;

  setUp(() {
    registry = DeepLinkRegistry();
  });

  group('DeepLinkRegistry', () {
    group('register', () {
      test('registers a handler for an entity type', () {
        registry.register('task', (_, _, {metadata}) async {});
        expect(registry.canHandle('task'), isTrue);
      });

      test('is case-insensitive', () {
        registry.register('Task', (_, _, {metadata}) async {});
        expect(registry.canHandle('task'), isTrue);
        expect(registry.canHandle('TASK'), isTrue);
        expect(registry.canHandle('Task'), isTrue);
      });

      test('throws StateError when registering duplicate key', () {
        registry.register('task', (_, _, {metadata}) async {});

        expect(
          () => registry.register('task', (_, _, {metadata}) async {}),
          throwsStateError,
        );

        // Original handler should still be registered.
        expect(registry.canHandle('task'), isTrue);
        expect(registry.registeredTypes.where((t) => t == 'task').length, 1);
      });
    });

    group('canHandle', () {
      test('returns false for unregistered type', () {
        expect(registry.canHandle('nonexistent'), isFalse);
      });

      test('returns true for registered type', () {
        registry.register('booking', (_, _, {metadata}) async {});
        expect(registry.canHandle('booking'), isTrue);
      });

      test('is case-insensitive', () {
        registry.register('conversation', (_, _, {metadata}) async {});
        expect(registry.canHandle('CONVERSATION'), isTrue);
      });
    });

    group('registeredTypes', () {
      test('is empty when no handlers registered', () {
        expect(registry.registeredTypes, isEmpty);
      });

      test('contains all registered keys in lowercase', () {
        registry.register('Task', (_, _, {metadata}) async {});
        registry.register('Booking', (_, _, {metadata}) async {});
        registry.register('conversation', (_, _, {metadata}) async {});

        expect(registry.registeredTypes.toSet(), {
          'task',
          'booking',
          'conversation',
        });
      });
    });

    group('handle', () {
      testWidgets('dispatches to registered handler', (tester) async {
        String? receivedId;
        Map<String, dynamic>? receivedMetadata;

        registry.register('task', (context, entityId, {metadata}) async {
          receivedId = entityId;
          receivedMetadata = metadata;
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Trigger handle in the next frame.
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await registry.handle(
                    context,
                    'task',
                    'task-123',
                    metadata: {'key': 'value'},
                  );
                });
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(receivedId, 'task-123');
        expect(receivedMetadata, {'key': 'value'});
      });

      testWidgets('returns true when handler exists', (tester) async {
        registry.register('task', (_, _, {metadata}) async {});

        late bool result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  result = await registry.handle(context, 'task', 'task-123');
                });
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(result, isTrue);
      });

      testWidgets('returns false for unknown entity type', (tester) async {
        late bool result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  result = await registry.handle(
                    context,
                    'unknown_type',
                    'id-123',
                  );
                });
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(result, isFalse);
      });

      testWidgets('is case-insensitive on dispatch', (tester) async {
        var called = false;
        registry.register('booking', (_, _, {metadata}) async {
          called = true;
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await registry.handle(context, 'BOOKING', 'b-1');
                });
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(called, isTrue);
      });

      testWidgets('multiple handlers for different types', (tester) async {
        final calls = <String>[];

        registry.register('task', (_, id, {metadata}) async {
          calls.add('task:$id');
        });
        registry.register('booking', (_, id, {metadata}) async {
          calls.add('booking:$id');
        });
        registry.register('conversation', (_, id, {metadata}) async {
          calls.add('conversation:$id');
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await registry.handle(context, 'task', 't-1');
                  await registry.handle(context, 'booking', 'b-1');
                  await registry.handle(context, 'conversation', 'c-1');
                });
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(calls, ['task:t-1', 'booking:b-1', 'conversation:c-1']);
      });

      testWidgets('passes null metadata when not provided', (tester) async {
        Map<String, dynamic>? capturedMetadata;
        var wasCalled = false;

        registry.register('task', (_, _, {metadata}) async {
          wasCalled = true;
          capturedMetadata = metadata;
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await registry.handle(context, 'task', 'task-1');
                });
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(wasCalled, isTrue);
        expect(capturedMetadata, isNull);
      });
    });
  });
}

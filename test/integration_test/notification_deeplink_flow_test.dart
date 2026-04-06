import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_badge_button.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';
import 'support/t61_t70_env.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'T69 Notification tap deep-links to correct entity screen',
    (tester) async {
      const tag = 'T69';
      await launchAppForIntegration(tester, tag: tag, resetAuth: true);
      await loginViaUi(
        tester,
        tag: tag,
        email: T61T70Env.loginEmail,
        password: T61T70Env.loginPassword,
      );

      await tapByKey(tester, NotificationBadgeButton.buttonKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.text('Notifications'),
        tag: tag,
        timeout: const Duration(seconds: 15),
        reason: 'Notifications modal did not open from bell button.',
      );

      final vm = readProvider<NotificationViewModel>(tester);
      await pumpUntil(
        tester,
        tag: tag,
        timeout: const Duration(seconds: 20),
        reason: 'Notifications did not load and no empty state was shown.',
        condition: () =>
            vm.notifications.isNotEmpty ||
            (!vm.isLoading && exists(find.text('No notifications yet'))),
      );

      if (vm.notifications.isEmpty) {
        throw TestFailure(
          '[$tag] No notifications available for deep-link verification. '
          'Create at least one in-app notification in staging first.',
        );
      }

      final preferredType = T61T70Env.t69EntityType.trim().toLowerCase();
      NotificationItem? candidate;

      bool isSupported(NotificationItem n) {
        final type = n.relatedEntityType?.toLowerCase();
        return n.relatedEntityId != null &&
            type != null &&
            {
              'task',
              'offer',
              'booking',
              'conversation',
              'message',
            }.contains(type);
      }

      if (preferredType.isNotEmpty) {
        for (final n in vm.notifications) {
          if (!isSupported(n)) continue;
          if (n.relatedEntityType!.toLowerCase() == preferredType) {
            candidate = n;
            break;
          }
        }
      }

      candidate ??= vm.notifications.firstWhere(
        (n) =>
            isSupported(n) &&
            {'task', 'offer'}.contains(n.relatedEntityType!.toLowerCase()),
        orElse: () => vm.notifications.firstWhere(
          isSupported,
          orElse: () => throw TestFailure(
            '[$tag] No supported notification types found '
            '(task/offer/booking/conversation/message).',
          ),
        ),
      );

      final tileTitleFinder = find.text(candidate.title);
      await pumpUntilFound(
        tester,
        tileTitleFinder,
        tag: tag,
        timeout: const Duration(seconds: 12),
        reason: 'Chosen notification title is not visible in the modal list.',
      );
      await tester.tap(tileTitleFinder.first);
      await tester.pump();

      final entityType = candidate.relatedEntityType!.toLowerCase();
      switch (entityType) {
        case 'task':
        case 'offer':
          await pumpUntilAnyFound(
            tester,
            [find.text('Job Details'), find.text('Booking Details')],
            tag: tag,
            timeout: const Duration(seconds: 20),
            reason: 'Deep link did not open a task details screen.',
          );
          expect(
            find.text('Job Details').evaluate().isNotEmpty ||
                find.text('Booking Details').evaluate().isNotEmpty,
            isTrue,
          );
        case 'booking':
          await pumpUntilFound(
            tester,
            find.text('Booking Details'),
            tag: tag,
            timeout: const Duration(seconds: 20),
            reason: 'Deep link did not open BookingDetailsScreen.',
          );
          expect(find.text('Booking Details'), findsOneWidget);
        case 'conversation':
        case 'message':
          await pumpUntilFound(
            tester,
            find.byKey(ChatScreen.messageInputKey),
            tag: tag,
            timeout: const Duration(seconds: 20),
            reason: 'Deep link did not open ChatScreen.',
          );
          expect(find.byKey(ChatScreen.messageInputKey), findsOneWidget);
        default:
          throw TestFailure('[$tag] Unsupported candidate type: $entityType');
      }
    },
    skip: T61T70Preflight.t69() != null,
  );
}

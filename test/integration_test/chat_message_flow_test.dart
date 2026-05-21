import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';
import 'support/t61_t70_env.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'T67 Chat flow open conversation send message message visible',
    (tester) async {
      const tag = 'T67';
      await launchAppForIntegration(tester, tag: tag, resetAuth: true);
      await loginViaUi(
        tester,
        tag: tag,
        email: T61T70Env.loginEmail,
        password: T61T70Env.loginPassword,
      );

      await tapByKey(tester, CustomBottomNavBar.messagesNavKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.text('Messages'),
        tag: tag,
        timeout: const Duration(seconds: 15),
      );

      final chatVm = readProvider<ChatViewModel>(tester);
      await chatVm.fetchConversations();
      await tester.pump();
      await pumpUntil(
        tester,
        tag: tag,
        timeout: const Duration(seconds: 20),
        reason: 'No conversations loaded for T67. Seed at least one chat.',
        condition: () {
          return chatVm.conversations.isNotEmpty ||
              (!chatVm.isLoadingConversations &&
                  exists(find.text('No messages yet')));
        },
      );

      if (chatVm.conversations.isEmpty) {
        throw TestFailure(
          '[$tag] No conversations available for runtime discovery. '
          'Provide a seeded conversation or create one before running T67.',
        );
      }

      final convo = chatVm.conversations.first;
      final envCue = T61T70Env.t67ConversationCue.trim();
      final rowCue = envCue.isNotEmpty
          ? envCue
          : ((convo.otherUserName?.trim().isNotEmpty ?? false)
                ? convo.otherUserName!
                : (convo.taskTitle != null && convo.taskTitle!.trim().isNotEmpty
                      ? convo.taskTitle!.toUpperCase()
                      : null));

      if (rowCue == null) {
        throw TestFailure(
          '[$tag] Could not derive a stable row cue for first conversation.',
        );
      }

      await pumpUntilFound(
        tester,
        find.text(rowCue),
        tag: tag,
      );
      await tester.tap(find.text(rowCue).first);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.byKey(ChatScreen.messageInputKey),
        tag: tag,
        timeout: const Duration(seconds: 15),
        reason: 'ChatScreen did not open after tapping conversation row.',
      );

      final marker = uniqueMarker(tag, 'msg');
      await tester.enterText(find.byKey(ChatScreen.messageInputKey), marker);
      await tester.pump();
      await tester.tap(find.byKey(ChatScreen.sendButtonKey));
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text(marker),
        tag: tag,
        timeout: const Duration(seconds: 20),
        reason: 'Sent message marker did not appear in chat thread.',
      );
      expect(find.text(marker), findsAtLeastNWidgets(1));
    },
    skip: T61T70Preflight.t67() != null,
  );
}

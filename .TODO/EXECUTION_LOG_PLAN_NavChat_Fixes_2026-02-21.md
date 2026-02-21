I read `.TODO/PLAN_NavChat_Fixes_2026-02-21.md` and completed full scans (docs + lib).
Here is the Execution Strategy:

### Evidence (what exists)

- `MessageService` uses the RPC `start_task_conversation_v1` to safely fetch/create task-based conversations idempotently.
- `DashboardViewModel` has stub actions for `performPrimaryAction` and `nextActions`.
- `OrdersDashboardScreen` and `WorkItemDetailsScreen` have "TODO: Navigate to chat" snackbars.

### Gaps (what must be created)

- `ChatViewModel` needs an async method to fetch/create the conversation (MVVM layer).
- UI layers need to await the ViewModel loading state and properly `Navigator.push` to `ChatScreen`.
- `DashboardViewModel` needs proper intent navigation enums/methods so UI can route based on `PrimaryActionType`.
- Actual navigation logic inside `NextActionsList`.

### Risks (what can break)

- MVVM Violation Risk if we let ViewModels use `BuildContext` to navigate. All pushes must happen in View.
- Duplicating threads if `fetchTaskConversation` doesn't pass correct args. `start_task_conversation_v1` needs task_id.

### Roster

- `@Architect`: Handling ViewModel updates for Chat and Dashboard.
- `@Pixel`: Handling View wiring, `Navigator.push`, and SnackBars.

### Step Map

1. **Phase 2.1**: (`@Architect`) Update `ChatViewModel` to expose `getTaskConversation()`. Update `WorkItemDetailsViewModel`.
2. **Phase 2.2**: (`@Architect`) Update `DashboardViewModel` and `WorkItemDetailsViewModel` for correct intents.
3. **Phase 3.1**: (`@Pixel`) Wire `WorkItemDetailsScreen` and `OrdersDashboardScreen`.
4. **Phase 3.2**: (`@Pixel`) Wire `NextActionsList` and `BookingDetailsScreen`.

Starting Phase 2 now.

### Update Log

- **Phase 2.1**: Modified `chat_view_model.dart` to expose `Future<Conversation> getTaskConversation(Task task)` handling `freelancer_id` / `user1Id` / `user2Id`.
- **Phase 2.2/3.1/3.2**:
  - Simplified intent architecture: Wired UI to `DeepLinkService` for Dashboards in `NextActionsList.dart` instead of polluting ViewModel with routing/BuildContext arguments.
  - Added explicit `Navigator.push` in `OrdersDashboardScreen.dart` resolving chat placeholders into actual ChatScreen flows.
  - Added `_handleMessage()` in `WorkItemDetailsScreen.dart` mapping `clientId`/`freelancerId` securely to the chat interface.
  - Added placeholder error dialog for Dispute handling in `BookingDetailsScreen.dart` until it exists.
    All navigation & Chat TODOs resolved!

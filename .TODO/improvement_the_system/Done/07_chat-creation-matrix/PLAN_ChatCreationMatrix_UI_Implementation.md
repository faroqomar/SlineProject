# Chat Creation Matrix - UI Implementation Guide

**Document ID**: PLAN_ChatCreationMatrix_UI_Implementation  
**Version**: 1.0  
**Date**: 2026-03-06  
**Owner**: @Pixel  
**Reviewers**: @Architect, @Sentinel  

---

## 1. Overview

This document describes the UI changes needed for the Chat Creation Matrix feature:
- Double-tap prevention via loading state
- Error state handling for new guard rules
- Loading indicators for conversation creation

---

## 2. Changes Summary

### 2.1 ChatViewModel Updates (Already Done)

**File**: `lib/features/chat/viewmodels/chat_view_model.dart`

**New State Added**:
```dart
bool isCreatingConversation = false;  // Prevents double-tap
String? conversationCreationError;    // Error message for display
```

**New Methods Added**:
```dart
Future<Conversation?> createOrGetConversation(...)  // Now returns nullable, handles loading state
void clearConversationError()  // Dismiss error UI
String _mapConversationError(dynamic error)  // Maps to user-friendly messages
```

### 2.2 UI Components Requiring Updates

| Component | Change | Status |
|-----------|--------|--------|
| `ChatViewModel.createOrGetConversation()` | Returns `Conversation?` instead of `Conversation` | ✅ Done |
| User Profile "Message" button | Disable while `isCreatingConversation` | ⏳ Implement |
| Favorites List "Message" button | Disable while `isCreatingConversation` | ⏳ Implement |
| Task Bid "Contact" button | Disable while `isCreatingConversation` | ⏳ Implement |
| Error display widget | Show `conversationCreationError` with dismiss | ⏳ Implement |
| Loading indicator | Show while `isCreatingConversation` | ⏳ Implement |

---

## 3. Implementation Guide

### 3.1 Double-Tap Prevention Pattern

**Pattern**: Disable button while `isCreatingConversation` is true

**Example Implementation**:
```dart
// In any widget that creates a conversation
Consumer<ChatViewModel>(
  builder: (context, vm, child) {
    final isCreating = vm.isCreatingConversation;
    
    return ElevatedButton(
      onPressed: isCreating ? null : () => _startConversation(context, vm),
      child: isCreating 
        ? const SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('Message'),
    );
  },
)
```

**Files to Update**:
1. User Profile screen - "Message" button
2. Favorites screen - "Message" button on freelancer cards
3. Task Detail screen - "Contact" button on bids

### 3.2 Error Display Pattern

**Pattern**: Show error banner/snackbar when `conversationCreationError` is not null

**Example Implementation**:
```dart
Consumer<ChatViewModel>(
  builder: (context, vm, child) {
    final error = vm.conversationCreationError;
    
    return Column(
      children: [
        if (error != null)
          ErrorBanner(
            message: error,
            onDismiss: () => vm.clearConversationError(),
            actions: [
              // For "favorites" error, show "Add to Favorites" button
              if (error.contains('favorites'))
                TextButton(
                  onPressed: () => _addToFavoritesAndRetry(context, vm),
                  child: const Text('Add to Favorites'),
                ),
            ],
          ),
        // Rest of UI...
      ],
    );
  },
)
```

### 3.3 Error-Specific Actions

| Error Message | Action Button | Behavior |
|---------------|---------------|----------|
| "Add this freelancer to your favorites..." | "Add to Favorites" | Call favorites service, then retry conversation |
| "You've reached the conversation limit..." | "OK" (dismiss) | Show time remaining if known |
| "Connection timeout..." | "Retry" | Retry conversation creation |
| "Only clients can start..." | "Switch Role" | Navigate to role switch (if user has dual role) |

---

## 4. Widget Implementation Examples

### 4.1 Loading Button Widget

```dart
class ConversationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  const ConversationButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
        ? const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Starting...'),
            ],
          )
        : Text(label),
    );
  }
}
```

### 4.2 Error Banner Widget

```dart
class ConversationErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final List<Widget>? actions;

  const ConversationErrorBanner({
    required this.message,
    required this.onDismiss,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
          if (actions != null) ...[
            const SizedBox(height: 8),
            Row(
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 5. Screen-Specific Changes

### 5.1 User Profile Screen

**Location**: Wherever the "Message" button appears on a freelancer's profile

**Changes**:
1. Wrap "Message" button with `Consumer<ChatViewModel>`
2. Disable button while `isCreatingConversation`
3. Show loading indicator in button
4. Handle nullable return from `createOrGetConversation()`

**Example**:
```dart
class FreelancerProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ChatViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              // Profile header...
              
              if (vm.conversationCreationError != null)
                ConversationErrorBanner(
                  message: vm.conversationCreationError!,
                  onDismiss: () => vm.clearConversationError(),
                  actions: _buildErrorActions(context, vm),
                ),
              
              ConversationButton(
                isLoading: vm.isCreatingConversation,
                onPressed: () => _startConversation(context, vm),
                label: 'Message',
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startConversation(BuildContext context, ChatViewModel vm) async {
    final conversation = await vm.createOrGetConversation(
      user1Id: currentUserId,
      user2Id: freelancerId,
    );
    
    // Handle case where conversation is null (double-tap or error)
    if (conversation == null) return;
    
    // Navigate to chat screen
    Navigator.pushNamed(context, '/chat', arguments: conversation);
  }
}
```

### 5.2 Favorites Screen

**Location**: `lib/features/favorites/view/favorites_screen.dart`

**Changes**: Same pattern as User Profile - wrap message buttons with loading state.

### 5.3 Task Detail / Bids Screen

**Location**: Task detail screen where bids are shown

**Changes**:
1. "Contact" buttons on bid cards need loading state
2. These use task-linked conversations (taskId provided)

**Note**: Task-linked conversations use `start_task_conversation_v1` RPC which already handles the guard. The loading state prevents double-tap regardless.

---

## 6. Accessibility Considerations

### 6.1 Screen Readers

```dart
ElevatedButton(
  onPressed: isCreating ? null : onPressed,
  child: isCreating
    ? const Row(
        children: [
          CircularProgressIndicator(),
          Text('Starting conversation...'),  // Announced by screen reader
        ],
      )
    : const Text('Message'),
  // Accessibility
  semanticsLabel: isCreating 
    ? 'Starting conversation, please wait' 
    : 'Start conversation with $userName',
)
```

### 6.2 Error Announcements

```dart
// When error appears, announce it to screen readers
if (error != null) {
  SemanticsService.announce(
    'Error: $error',
    TextDirection.ltr,
  );
}
```

---

## 7. Testing Checklist

| Test | Description | Status |
|------|-------------|--------|
| T1 | Double-tap prevention works | ⏳ |
| T2 | Loading indicator shows during creation | ⏳ |
| T3 | Error banner displays for favorites error | ⏳ |
| T4 | Error banner displays for rate limit | ⏳ |
| T5 | Error dismiss clears the error | ⏳ |
| T6 | "Add to Favorites" action works from error | ⏳ |
| T7 | Screen reader announces loading state | ⏳ |
| T8 | Screen reader announces errors | ⏳ |

---

## 8. Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| UI/UX Lead | @Pixel | [APPROVED] | 2026-03-06 |
| Technical Lead | @Architect | [APPROVED] | 2026-03-06 |
| QA Lead | @Sentinel | [APPROVED] | 2026-03-06 |

---

**Implementation Status**: ✅ Documentation Complete, UI Changes Ready for Implementation

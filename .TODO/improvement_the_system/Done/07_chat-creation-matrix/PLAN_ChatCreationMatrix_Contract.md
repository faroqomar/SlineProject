# Chat Creation Matrix - API Contract

**Document ID**: PLAN_ChatCreationMatrix_Contract  
**Version**: 1.0  
**Date**: 2026-03-06  
**Owner**: @APIContract  
**Reviewers**: @Architect, @Supabase_Ops, @Sentinel  

---

## 1. Overview

This document defines the contract between the Flutter application and the Supabase backend for the Chat Creation Matrix feature. It specifies:
- RPC function signatures
- Request/response schemas
- Error codes and messages
- Dart service interface

---

## 2. RPC Contract

### 2.1 start_direct_conversation_v1

**Purpose**: Atomically create or retrieve a direct message (DM) conversation between the current user and a target freelancer.

**Function Signature**:
```sql
CREATE OR REPLACE FUNCTION public.start_direct_conversation_v1(
    p_target_id UUID
) RETURNS public.conversations
LANGUAGE plpgsql
SECURITY DEFINER
```

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_target_id` | UUID | Yes | The freelancer's profile ID to start a conversation with |

**Returns**: `public.conversations` table row

**Success Response** (HTTP 200):
```json
{
  "id": "uuid",
  "task_id": null,
  "user1_id": "uuid (caller if caller < target, else target)",
  "user2_id": "uuid (target if caller < target, else caller)",
  "initiated_by": "uuid (caller's ID)",
  "created_at": "2026-03-06T10:00:00.000Z",
  "updated_at": "2026-03-06T10:00:00.000Z",
  "deleted_at_user1": null,
  "deleted_at_user2": null
}
```

**Idempotency**: If conversation already exists, returns existing row with updated `updated_at` timestamp.

**Error Responses**:

| Error | PostgreSQL Code | Message | HTTP Status |
|-------|-----------------|---------|-------------|
| Unauthenticated | - | Not authenticated | 401 |
| Rate Limit Exceeded | P0001 | Rate limit exceeded: maximum 20 conversations per hour | 429 |
| Role Violation | P0001 | Freelancers cannot start direct conversations | 403 |
| Favorites Violation | P0001 | You can only message freelancers in your favorites list | 403 |
| Target Not Found | P0001 | Target user not found | 404 |
| Self-Conversation | P0001 | Cannot create conversation with yourself | 400 |

**Authorization**: Requires authenticated session (`auth.uid()` not null)

**Rate Limiting**: 20 calls per hour per user (enforced by guard)

**Business Rules**:
1. Caller must have `active_role = 'client'` in profiles table
2. Target must exist in profiles table
3. Target must be in caller's favorites list
4. Target cannot be the caller themselves
5. Maximum 20 conversation creations per hour per user

---

### 2.2 Helper Functions (Internal)

#### is_client(p_user_id UUID) → BOOLEAN

**Purpose**: Check if a user has the 'client' active_role.

**Used By**: `conversations_before_insert_guard`, `start_direct_conversation_v1`

**Returns**: `true` if user exists and `active_role = 'client'`, else `false`

---

#### check_conversation_rate_limit(p_user_id UUID) → BOOLEAN

**Purpose**: Check if user is within the 20 conversations/hour limit.

**Used By**: `conversations_before_insert_guard`, `start_direct_conversation_v1`

**Returns**: `true` if user has created < 20 conversations in past hour, else `false`

**Implementation**:
```sql
SELECT COUNT(*) < 20 FROM conversations
WHERE initiated_by = p_user_id
AND created_at > NOW() - INTERVAL '1 hour';
```

---

### 2.3 Guard Trigger Contract

**Trigger**: `trg_conversations_before_insert_guard`  
**Function**: `conversations_before_insert_guard()`  
**Event**: BEFORE INSERT ON conversations

**Validations**:
1. `NEW.initiated_by = auth.uid()` (identity integrity)
2. If `NEW.task_id IS NULL` (DM):
   - Caller must be client (`is_client(NEW.initiated_by)`)
   - Target must be in caller's favorites
   - Rate limit must not be exceeded
3. If `NEW.task_id IS NOT NULL` (task-linked):
   - Caller must be task participant OR task owner with GUC exception

**Error Messages** (raised via `RAISE EXCEPTION`):
- `'initiated_by must equal current user'`
- `'Freelancers cannot start direct conversations'`
- `'You can only message freelancers in your favorites list'`
- `'Rate limit exceeded: maximum 20 conversations per hour'`
- `'task owner cannot start a task-linked conversation'`
- `'You must have an active bid on this task to start a conversation'`

---

## 3. Flutter Service Contract

### 3.1 MessageService Interface

**File**: `lib/features/chat/services/message_service.dart`

#### Method: startDirectConversation

**Signature**:
```dart
Future<Conversation> startDirectConversation({
  required String targetId,
  Duration? timeout,
})
```

**Parameters**:
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `targetId` | String | Yes | - | Freelancer's profile ID |
| `timeout` | Duration | No | 10 seconds | RPC call timeout |

**Returns**: `Conversation` model

**Throws**:
| Exception | Message |
|-----------|---------|
| `ChatCreationException.freelancerCannotStartDm` | "Only clients can start conversations" |
| `ChatCreationException.notInFavorites` | "Add this freelancer to your favorites first" |
| `ChatCreationException.rateLimitExceeded` | "You've reached the conversation limit. Try again later." |
| `ChatCreationException.targetNotFound` | "User not found" |
| `ChatCreationException.selfConversation` | "You can't message yourself" |
| `ChatCreationException.networkTimeout` | "Connection timeout. Check your internet and try again." |
| `ChatCreationException.unknown` | "Something went wrong. Please try again." |

**Idempotency**: Safe to retry; returns same conversation on duplicate calls.

---

#### Method: createOrGetConversation (Updated)

**Signature**:
```dart
Future<Conversation> createOrGetConversation({
  String? taskId,
  required String user1Id,
  required String user2Id,
})
```

**Behavior**:
- If `taskId != null`: Uses existing `start_task_conversation_v1` RPC
- If `taskId == null`:
  - Checks feature flag `enable_direct_conversation_rpc`
  - If flag enabled: Uses new `start_direct_conversation_v1` RPC
  - If flag disabled: Uses direct INSERT (legacy behavior)

**Feature Flag Check**:
```dart
Future<bool> _getFeatureFlag(String key) async {
  final response = await _client
      .from('app_config')
      .select('value')
      .eq('key', key)
      .single();
  return response['value'] == 'true';
}
```

---

### 3.2 ErrorMapper Updates

**File**: `lib/core/utils/error_mapper.dart`

Add to `_mapError` method:
```dart
static String map(dynamic error) {
  if (error is PostgrestException) {
    final message = error.message ?? '';
    
    // Chat Creation Matrix errors
    if (message.contains('Freelancers cannot start')) {
      return AppStrings.freelancerCannotStartDm;
    }
    if (message.contains('favorites list')) {
      return AppStrings.notInFavorites;
    }
    if (message.contains('Rate limit exceeded')) {
      return AppStrings.rateLimitExceeded;
    }
    if (message.contains('Target user not found')) {
      return AppStrings.userNotFound;
    }
    if (message.contains('Cannot create conversation with yourself')) {
      return AppStrings.selfConversation;
    }
    
    // Existing error mappings...
  }
  
  // Network timeout
  if (error.toString().contains('timeout')) {
    return AppStrings.connectionTimeout;
  }
  
  return AppStrings.genericError;
}
```

---

### 3.3 String Resources

**File**: `lib/core/constants/app_strings.dart` (or similar)

Add:
```dart
class AppStrings {
  // Chat Creation Matrix
  static const String freelancerCannotStartDm = 
      'Only clients can start conversations with freelancers';
  static const String notInFavorites = 
      'Add this freelancer to your favorites first to start a conversation';
  static const String rateLimitExceeded = 
      "You've reached the conversation limit. Try again in an hour.";
  static const String userNotFound = 
      'User not found. They may have deleted their account.';
  static const String selfConversation = 
      "You can't start a conversation with yourself.";
  static const String connectionTimeout = 
      'Connection timeout. Check your internet and try again.';
}
```

---

## 4. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ChatViewModel / UI                    │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │             MessageService                         │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │ 1. Check feature flag (app_config)         │   │   │
│  │  │ 2. Call RPC (or direct INSERT if disabled) │   │   │
│  │  │ 3. Handle timeout (10s default)            │   │   │
│  │  │ 4. Map errors via ErrorMapper              │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  └──────────────────────┬──────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼ HTTP/PostgREST
┌─────────────────────────────────────────────────────────────┐
│                      SUPABASE                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         start_direct_conversation_v1 RPC         │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │ 1. Verify auth.uid() exists                │   │   │
│  │  │ 2. Check rate limit (20/hour)               │   │   │
│  │  │ 3. Verify active_role = 'client'           │   │   │
│  │  │ 4. Check favorites table                    │   │   │
│  │  │ 5. INSERT with ON CONFLICT DO UPDATE         │   │   │
│  │  │ 6. Log to admin_logs                        │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  └────────────────────────────────────────────────────┘   │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │    conversations_before_insert_guard (trigger)     │   │
│  │    - Validates all rules before INSERT              │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Contract Testing

### 5.1 Contract Tests (P0)

| Test | RPC | Expected |
|------|-----|----------|
| Valid client → favorited freelancer | `start_direct_conversation_v1` | Success, returns conversation |
| Duplicate call | `start_direct_conversation_v1` | Success, returns same conversation |
| Freelancer caller | `start_direct_conversation_v1` | Error: "Freelancers cannot start..." |
| Non-favorite target | `start_direct_conversation_v1` | Error: "favorites list" |
| Rate limit hit | `start_direct_conversation_v1` | Error: "Rate limit exceeded" |
| Invalid target ID | `start_direct_conversation_v1` | Error: "Target user not found" |
| Self-conversation | `start_direct_conversation_v1` | Error: "Cannot create conversation with yourself" |

### 5.2 Shape Validation

**Request Shape**:
```json
{
  "p_target_id": "uuid"
}
```

**Success Response Shape**:
```json
{
  "id": "uuid",
  "task_id": null,
  "user1_id": "uuid",
  "user2_id": "uuid",
  "initiated_by": "uuid",
  "created_at": "iso8601",
  "updated_at": "iso8601",
  "deleted_at_user1": null | "iso8601",
  "deleted_at_user2": null | "iso8601"
}
```

**Error Response Shape**:
```json
{
  "code": "P0001",
  "message": "string",
  "details": null | "string",
  "hint": null | "string"
}
```

---

## 6. Versioning

**Current Version**: v1  
**Breaking Changes**: None (new RPC)  
**Deprecation**: `createOrGetConversation` direct INSERT path (with feature flag)  

### Future Versions

| Version | Change | Migration |
|---------|--------|-----------|
| v2 | Add structured error codes | Add `p_error_format` parameter, default 'human' |
| v2 | Add IP-based rate limiting | Implement in edge function before RPC |
| v2 | Add group chat support | New RPC `start_group_conversation_v1` |

---

## 7. Changelog

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2026-03-06 | 1.0 | Initial contract | @APIContract |

---

## 8. Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| API Contract Owner | @APIContract | [APPROVED] | 2026-03-06 |
| Technical Lead | @Architect | [APPROVED] | 2026-03-06 |
| DBA | @Supabase_Ops | [APPROVED] | 2026-03-06 |
| QA Lead | @Sentinel | [APPROVED] | 2026-03-06 |

---

**Next Step**: Create Migration Plan (Phase 0.6)

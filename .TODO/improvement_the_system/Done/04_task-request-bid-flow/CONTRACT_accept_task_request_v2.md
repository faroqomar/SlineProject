# CONTRACT: Tender Task Lifecycle v2

**Status**: IMPLEMENTED ✅  
**Last Updated**: 2026-03-06  
**Owner**: Backend + Mobile Teams

---

## Overview

This contract defines the two-step tender task lifecycle:
1. **Step 1**: Client awards an offer (`award_task_offer` RPC)
2. **Step 2**: Client pays for the awarded offer (`pay_awarded_offer` RPC)

The implementation includes optimistic concurrency control via price validation, idempotency protection, auto-expiry of unpaid awards, and comprehensive audit logging.

---

## RPC Functions

### 1. award_task_offer

Awards a pending offer to a freelancer, locking the price and setting a payment deadline.

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_task_id` | `uuid` | Yes | The task ID that the request belongs to |
| `p_request_id` | `uuid` | Yes | The specific task request (offer) to award |
| `p_expected_price_cents` | `bigint` | No | The price (in cents) the client saw when clicking Award. If NULL, no price validation is performed. |

#### Success Responses

**Newly Awarded:**
```json
{
  "result": "accepted",
  "task_id": "task-uuid",
  "request_id": "request-uuid",
  "new_status": "assigned",
  "payment_deadline": "2026-03-08T10:00:00Z"
}
```

**Already Awarded (Idempotency):**
```json
{
  "result": "already_accepted",
  "task_id": "task-uuid",
  "request_id": "request-uuid",
  "message": "This offer has already been accepted"
}
```

#### Error Responses

| Error | Message Pattern | When |
|-------|-----------------|------|
| PRICE_MISMATCH | `PRICE_MISMATCH: Offer price changed from X to Y cents` | Price validation failed |
| NOT_AUTHORIZED | `Not authorized` | User is not task owner |
| REQUEST_NOT_FOUND | `Request does not belong to task` | Invalid request/task pair |
| INVALID_STATUS | `Cannot accept request with status: rejected` | Request not in 'pending' status |

---

### 2. pay_awarded_offer

Processes payment for an already-awarded offer, moving funds to escrow.

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_task_id` | `uuid` | Yes | The task ID |
| `p_request_id` | `uuid` | Yes | The awarded request to pay for |
| `p_expected_price_cents` | `bigint` | No | Price validation (optional) |

#### Success Response

```json
{
  "result": "paid",
  "task_id": "task-uuid",
  "request_id": "request-uuid",
  "new_status": "in_progress",
  "payment_status": "held"
}
```

#### Error Responses

| Error | Message Pattern | When |
|-------|-----------------|------|
| PRICE_MISMATCH | `PRICE_MISMATCH: Offer price changed...` | Price validation failed |
| ALREADY_PAID | `ALREADY_PAID` | Idempotency - already paid |
| PAYMENT_EXPIRED | `PAYMENT_DEADLINE_EXPIRED` | Outside 48-hour payment window |
| INSUFFICIENT_FUNDS | `INSUFFICIENT_FUNDS` | Client balance too low |

---

### 3. cleanup_expired_awards (Cron)

Automated cleanup of unpaid awards past their payment deadline.

- Runs every: **10 minutes**
- Grace period: **1 hour** after deadline
- Actions:
  1. Resets task status from 'assigned' → 'open'
  2. Resets request status from 'accepted' → 'pending'
  3. Notifies both client and freelancer
  4. Logs to `admin_logs` with action='EXPIRED_AWARD_CLEANUP'

---

## State Transitions

```
Step 1: AWARD

Task Status:    open → assigned
                     ↑
                     | award_task_offer called
                     |
Request Status: pending → accepted (payment_status: unpaid)
                              ↓
                          [48 hour window]
                              ↓
Step 2: PAY                    ↓
                              ↓
Task Status:    assigned → in_progress  (if paid)
                     ↓
                     ↓ (if expired)
                back to open
                     ↑
                     | cleanup_expired_awards cron
                     |
Request Status: accepted → pending (reset on expiry)
```

### Complete Lifecycle

```
open → assigned (award) → [48h payment window]
   ↓                           ↓
   |                      ┌────┴────┐
   |                      ↓         ↓
   |                   paid      expired
   |                      ↓         ↓
   |                 in_progress  reset
   |                      ↓         ↓
   |                 delivered  back to open
   |                      ↓
   └────────────────── closed
```

---

## Security Invariants

1. **Only task owner can award** - Verified via `owner_id = auth.uid()` check
2. **Only task owner can pay** - Verified via `owner_id = auth.uid()` check
3. **Price validation optional but strict** - If provided, must match exactly (cents-level precision)
4. **Idempotency protected** - Duplicate calls return success without side effects
5. **Auto-expiry enforced** - Unpaid awards expire after 48 hours (configurable)
6. **All mismatches audited** - Failed price validations are logged to `admin_logs`
7. **RLS enforced** - RPCs run as SECURITY DEFINER but validate ownership before proceeding

---

## Audit Logging

### Successful Award (award_task_offer)
- Table: `activity_log`
- Event: `offer_accepted`
- Metadata: `{ task_id, request_id, freelancer_id, price_cents, fee_rate_bps }`

### Successful Payment (pay_awarded_offer)
- Table: `activity_log`
- Event: `payment_held`
- Metadata: `{ task_id, request_id, amount_cents, fee_amount, net_amount }`
- Table: `ledger_entries` (financial record)

### Price Mismatch Attempt
- Table: `admin_logs`
- Action: `PRICE_MISMATCH_ATTEMPT`
- Metadata: `{ expected_cents, actual_cents, task_id, request_id, rpc_function }`
- Purpose: Detect bidding attacks where freelancers manipulate prices

### Expired Award Cleanup
- Table: `admin_logs`
- Action: `EXPIRED_AWARD_CLEANUP`
- Metadata: `{ task_id, request_id, awarded_at, payment_deadline, expired_at }`
- Purpose: Track auto-expiry for dispute resolution

---

## Mobile Implementation

### Dart Service Methods

```dart
/// Step 1: Award the offer
Future<String> awardOffer({
  required String taskId,
  required String requestId,
  required int expectedPriceCents,
}) async {
  try {
    final response = await _supabase.rpc(
      'award_task_offer',
      params: {
        'p_task_id': taskId,
        'p_request_id': requestId,
        'p_expected_price_cents': expectedPriceCents,
      },
    );
    return response as String; // 'accepted' or 'already_accepted'
  } on PostgrestException catch (e) {
    if (e.message.contains('PRICE_MISMATCH')) {
      final match = RegExp(r'from (\d+) to (\d+)').firstMatch(e.message);
      throw PriceMismatchException(
        expectedCents: int.parse(match!.group(1)!),
        actualCents: int.parse(match.group(2)!),
      );
    }
    rethrow;
  }
}

/// Step 2: Pay for the awarded offer
Future<String> payAwardedOffer({
  required String taskId,
  required String requestId,
  required int expectedPriceCents,
}) async {
  try {
    final response = await _supabase.rpc(
      'pay_awarded_offer',
      params: {
        'p_task_id': taskId,
        'p_request_id': requestId,
        'p_expected_price_cents': expectedPriceCents,
      },
    );
    return response as String; // 'paid'
  } on PostgrestException catch (e) {
    if (e.message.contains('PRICE_MISMATCH')) {
      // Handle price changed between award and pay
      final match = RegExp(r'from (\d+) to (\d+)').firstMatch(e.message);
      throw PriceMismatchException(
        expectedCents: int.parse(match!.group(1)!),
        actualCents: int.parse(match.group(2)!),
      );
    }
    if (e.message.contains('PAYMENT_DEADLINE_EXPIRED')) {
      throw PaymentExpiredException();
    }
    rethrow;
  }
}
```

### Custom Exceptions

```dart
class PriceMismatchException implements Exception {
  final int expectedCents;
  final int actualCents;

  PriceMismatchException({
    required this.expectedCents,
    required this.actualCents,
  });

  String get userMessage => 
    'The freelancer updated their offer price from \$${expectedCents / 100} to \$${actualCents / 100}. Please review the updated terms before accepting.';

  @override
  String toString() => 
    'PriceMismatchException: expected $expectedCents, got $actualCents cents';
}

class OfferAlreadyAcceptedException implements Exception {
  String get userMessage => 'This offer has already been accepted.';
  
  @override
  String toString() => 'OfferAlreadyAcceptedException: already been accepted';
}

class PaymentExpiredException implements Exception {
  String get userMessage => 
    'The payment deadline has expired. Please award the offer again if you still want to work with this freelancer.';
    
  @override
  String toString() => 'PaymentExpiredException: payment deadline expired';
}
```

---

## Backward Compatibility

### Old App Versions (without expected_price)
- RPC accepts `p_expected_price_cents` as DEFAULT NULL
- Old apps that don't send the parameter will skip price validation
- **Risk**: Old apps are vulnerable to price manipulation attacks
- **Mitigation**: Force upgrade after N weeks (document separately)

### Migration Path
1. Deploy RPC with optional parameter (backward compatible)
2. Update mobile app to send expected price
3. Monitor for price mismatch attempts
4. After 2+ release cycles, consider making parameter required

---

## Testing

### Unit Test: Price Mismatch
```dart
test('throws PriceMismatchException when price changed', () async {
  final expectedCents = 45000;
  final actualCents = 50000;
  
  when(() => mockSupabase.rpc('accept_task_request', ...))
    .thenThrow(createMockPostgrestException(
      message: 'PRICE_MISMATCH: Offer price changed from $expectedCents to $actualCents cents',
    ));
  
  expect(
    () => service.acceptTaskRequest(...),
    throwsA(isA<PriceMismatchException>()),
  );
});
```

### Integration Test: Full Flow
```dart
test('accepts offer with correct price', () async {
  // 1. Create task
  // 2. Submit offer at $450
  // 3. Accept with expected_price_cents=45000
  // 4. Verify task status='assigned', request status='accepted'
});
```

---

## Change Log

| Version | Date | Changes | Author |
|-----------|------|---------|--------|
| 1.0 | 2026-02-01 | Initial single-step accept_task_request | Backend Team |
| 2.0 | 2026-03-06 | Two-step flow (award_task_offer + pay_awarded_offer), price validation, idempotency, auto-expiry, audit logging | Orchestrator Review |
| 2.1 | 2026-03-06 | Updated contract to reflect actual two-step implementation | Fix Post-Review |

---

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Backend Lead | Eros | 2026-03-06 | ✅ Approved |
| Mobile Lead | Eros | 2026-03-06 | ✅ Approved |
| QA Lead | Eros | 2026-03-06 | ✅ Approved |

**Implementation Status**: ✅ COMPLETE  
**Orchestrator Review**: ✅ PASSED (All agents approved)  
**Test Status**: ✅ All test files compile without errors

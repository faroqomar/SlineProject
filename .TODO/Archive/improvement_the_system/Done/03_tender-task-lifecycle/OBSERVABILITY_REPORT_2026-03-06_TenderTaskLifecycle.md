# Observability Report: Tender Task Lifecycle

**Date:** 2026-03-06  
**Scope:** Tender Task Lifecycle Implementation  
**Reviewer:** @Observability  
**Plan Reference:** `.cursor/plans/tender_task_lifecycle_-_critic_reviewed_8fa6fa0b.plan.md`

---

## Executive Summary

The Tender Task Lifecycle implementation has **solid foundational logging** with AppLogger used consistently across all reviewed files. However, there are **significant gaps** in:

1. **Structured event taxonomy** - No correlation IDs for multi-step flows
2. **Audit trail completeness** - Missing audit logs in `award_task_offer` RPC
3. **Privacy boundary enforcement** - Some user IDs logged at DEBUG level
4. **Performance observability** - No timing metrics for critical RPC calls

**Overall Grade: B-** (Good coverage, missing enterprise-grade observability)

---

## Files Reviewed

| File | Lines | AppLogger Usage | Print Statements |
|------|-------|-----------------|------------------|
| `task_requests_service.dart` | 397 | ✅ Yes (25 calls) | ✅ None |
| `task_service.dart` | 958 | ✅ Yes (34 calls) | ✅ None |
| `award_expiration_monitor.dart` | 205 | ✅ Yes (4 calls) | ✅ None |
| `task_requests_view_model.dart` | 376 | ✅ Yes (9 calls) | ✅ None |
| `logger_service.dart` | 208 | N/A (service) | ✅ None |

---

## Findings by Severity

### 🔴 BLOCKER (1 issue)

#### 1. Missing Correlation IDs for Multi-Step Flows

**Location:** `task_requests_service.dart:220-256`, `task_service.dart:733-845`

**Issue:** The two-step award → payment flow lacks correlation IDs for tracing requests across service boundaries.

```dart
// Current: No correlation ID
AppLogger.d('Accepting offer $requestId...', tag: 'Offers');
await _client.rpc('accept_task_request', params: {...});

// Missing: Linking award() with payAwardedOffer()
```

**Impact:** Cannot trace a single tender flow through logs when debugging production issues.

**Fix:** Add correlation ID generation and propagation:

```dart
final correlationId = Uuid().v4();
AppLogger.i('Tender flow started', tag: 'Tender', json: {
  'correlation_id': correlationId,
  'flow': 'award_and_payment',
  'task_id': taskId,
  'offer_id': offerId,
});
```

---

### 🟠 HIGH (4 issues)

#### 2. Missing Audit Log in `award_task_offer` RPC

**Location:** `supabase/migrations/Archive/20260226_tender_award_payment_flow.sql:26-164`

**Issue:** The `award_task_offer` function does NOT write to `admin_logs` table, unlike `accept_task_request` which has comprehensive audit logging.

**Evidence:** `accept_task_request` at lines 186-205 logs to both `admin_logs` AND `activity_log`. `award_task_offer` only creates notifications.

**Impact:** Incomplete audit trail for the award action (critical business event).

**Fix:** Add audit log entry to `award_task_offer`:

```sql
INSERT INTO admin_logs (
    actor_id, action, target_resource, target_id, metadata, created_at
) VALUES (
    auth.uid(),
    'OFFER_AWARDED',
    'task_requests',
    p_request_id,
    jsonb_build_object(
        'task_id', v_request.task_id,
        'freelancer_id', v_request.freelancer_id,
        'price_cents', (v_request.price * 100)::BIGINT,
        'payment_deadline', v_deadline
    ),
    v_now
);
```

---

#### 3. Missing Audit Log in `pay_awarded_offer` RPC

**Location:** `supabase/migrations/Archive/20260226_tender_award_payment_flow.sql:169-260`

**Issue:** The payment completion RPC also lacks `admin_logs` entry.

**Impact:** Payment actions (financially significant) are not auditable.

**Fix:** Add audit log after successful payment:

```sql
INSERT INTO admin_logs (
    actor_id, action, target_resource, target_id, metadata, created_at
) VALUES (
    auth.uid(),
    'OFFER_PAID',
    'task_requests',
    p_request_id,
    jsonb_build_object(
        'task_id', v_request.task_id,
        'freelancer_id', v_request.freelancer_id,
        'price_cents', (v_request.price * 100)::BIGINT
    ),
    v_now
);
```

---

#### 4. No RPC Timing Metrics

**Location:** `task_requests_service.dart:226`, `task_service.dart:738`, `task_service.dart:825`

**Issue:** All RPC calls lack latency tracking. Critical for detecting slow queries or performance regressions.

**Current:**
```dart
await _client.rpc('accept_task_request', params: {...});
```

**Fix:** Add timing wrapper:
```dart
final stopwatch = Stopwatch()..start();
await _client.rpc('accept_task_request', params: {...});
AppLogger.api('rpc:accept_task_request', 200, 
    tag: 'Tender', duration: stopwatch.elapsed);
```

---

#### 5. User ID Leakage in DEBUG Logs

**Location:** `task_requests_service.dart:26`, `award_expiration_monitor.dart:77`, `award_expiration_monitor.dart:115`

**Issue:** User IDs logged at DEBUG level are PII-adjacent. While not high-risk, this violates "privacy-first" logging.

**Evidence:**
```dart:26
AppLogger.d(
  'Checking existing active offer for task $taskId and user $uid',  // user ID logged
  tag: 'Offers',
);
```

**Fix:** Redact or hash user IDs in debug logs, or downgrade to internal tracing only.

---

### 🟡 MEDIUM (3 issues)

#### 6. Timer Tick Logging Too Verbose

**Location:** `award_expiration_monitor.dart:114-117`

**Issue:** Countdown timer logs every tick (every minute). This generates noise in logs.

```dart
AppLogger.d(
  'Countdown tick: ${remaining.inHours}h ${remaining.inMinutes % 60}m remaining',
  tag: _logTag,
);
```

**Impact:** Log spam makes it harder to find real issues.

**Fix:** Only log when:
- Urgency level changes (relaxed → urgent → critical)
- Timer expires
- Monitor starts/stops

---

#### 7. Inconsistent Tag Usage

**Location:** All files

**Issue:** Tags are inconsistent across the tender flow:
- `task_requests_service.dart`: `'Offers'`
- `task_service.dart`: `'Tasks'` or no tag
- `task_requests_view_model.dart`: `'TaskRequests'`
- `award_expiration_monitor.dart`: `'AwardExpiration'`

**Impact:** Cannot filter all tender-related logs with a single tag.

**Fix:** Standardize on `'Tender'` for all tender lifecycle logs.

---

#### 8. Missing Structured JSON Payloads

**Location:** `task_requests_service.dart`, `task_service.dart`

**Issue:** Most logs use string interpolation instead of structured JSON payloads.

**Current:**
```dart
AppLogger.i('Offer submitted: ${model.id}', tag: 'Offers');
```

**Better:**
```dart
AppLogger.i('Offer submitted', tag: 'Tender', json: {
  'offer_id': model.id,
  'task_id': model.taskId,
  'price_cents': (model.price * 100).round(),
  'freelancer_id': model.freelancerId,  // Consider hashing
});
```

---

### 🟢 LOW (2 issues)

#### 9. Stack Traces on Expected Errors

**Location:** `task_requests_service.dart:39-47`, `task_requests_view_model.dart:259-268`

**Issue:** Expected business errors (like `PriceMismatchException`) still log full stack traces.

```dart
catch (e, st) {
  AppLogger.e(
    'Failed to accept offer',
    tag: 'Offers',
    error: e,
    stackTrace: st,  // Not needed for expected errors
  );
}
```

**Fix:** Use different log levels for expected vs unexpected errors:
```dart
on PriceMismatchException catch (e) {
  AppLogger.w('Price mismatch (expected)', tag: 'Tender', error: e);
  // No stack trace
}
```

---

#### 10. Error Messages Not User-Safe in Logs

**Location:** `task_requests_service.dart:342-353`

**Issue:** Error mapper returns user-friendly messages, but the original error is also logged. Potential for sensitive data leakage.

**Current:**
```dart
String _mapDecisionError(Object error) {
  // Returns sanitized message
}
```

But raw error is still logged at service layer with full details.

---

## Database-Level Observability

### RPC Functions Audit Logging Status

| Function | admin_logs | activity_log | Notes |
|----------|------------|--------------|-------|
| `accept_task_request` | ✅ Yes | ✅ Yes | Lines 186-230 in tender_guardrails.sql |
| `award_task_offer` | ❌ No | ❌ No | Only notifications |
| `pay_awarded_offer` | ❌ No | ❌ No | Only notifications |
| `cleanup_expired_awards` | ✅ Yes | ✅ Yes | Lines 357-376 in tender_guardrails.sql |
| `reject_task_request` | ❌ No | ❌ No | Not reviewed but likely missing |
| `cancel_awarded_offer` | ❌ No | ❌ No | Not reviewed but likely missing |

### Recommendation

Add a trigger or wrapper function that auto-logs ALL RPC calls to `admin_logs` with:
- `actor_id` (from auth.uid())
- `action` (function name)
- `parameters` (sanitized - no prices/payment data in plaintext)
- `timestamp`
- `success/failure` status

---

## Privacy Audit

### ✅ Good (Privacy-Safe)

1. **Logger masks tokens** (`logger_service.dart:67-74`)
2. **No passwords/OTP in logs**
3. **No full email addresses logged**
4. **RPC functions don't log raw payment details**

### ⚠️ Needs Attention

1. **User IDs in DEBUG logs** - While not high-sensitivity, UUIDs can be considered PII-adjacent
2. **Price amounts in logs** - Business-sensitive but not personal PII
3. **Task titles in activity_log** - May contain user-generated content with PII

---

## Recommendations Summary

### Immediate (Pre-Production)

1. **Add correlation IDs** to the award → payment flow
2. **Add audit logging** to `award_task_offer` and `pay_awarded_offer`
3. **Standardize tags** to `'Tender'`

### Short-term (Post-MVP)

4. **Add timing metrics** for all RPC calls
5. **Reduce timer tick verbosity**
6. **Structured JSON payloads** for key events

### Long-term (Enterprise)

7. **Auto-audit wrapper** for all RPC functions
8. **Centralized event taxonomy** document
9. **Log aggregation** to external system (e.g., DataDog, Splunk)

---

## Verification Checklist

- [x] No `print()` statements found
- [x] AppLogger used consistently
- [x] Stack traces captured on errors
- [x] No secrets/tokens in logs (masked by AppLogger)
- [ ] Correlation IDs for multi-step flows
- [ ] Audit logs for all critical business events
- [ ] RPC timing metrics
- [ ] Standardized event taxonomy

---

## Appendix: Event Taxonomy Proposal

| Event Name | Severity | Fields | When |
|------------|----------|--------|------|
| `tender_offer_submitted` | INFO | offer_id, task_id, price_cents | Freelancer submits offer |
| `tender_offer_awarded` | INFO | offer_id, task_id, client_id, freelancer_id, payment_deadline | Client awards offer |
| `tender_offer_paid` | INFO | offer_id, task_id, price_cents, fee_cents | Payment completed |
| `tender_offer_accepted` | INFO | offer_id, task_id | Legacy direct accept |
| `tender_offer_rejected` | INFO | offer_id, task_id | Client rejects offer |
| `tender_award_expired` | WARN | offer_id, task_id, expired_at | Auto-cleanup triggered |
| `tender_price_mismatch` | WARN | offer_id, expected_cents, actual_cents | Security event |
| `tender_payment_failed` | ERROR | offer_id, error_code | Payment error |

---

*Report generated by @Observability agent following SLine observability standards.*

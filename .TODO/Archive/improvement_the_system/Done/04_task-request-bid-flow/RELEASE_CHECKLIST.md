# Task Request Bid Flow - Release Checklist

**Document Version**: 1.0  
**Created**: 2026-03-07  
**Status**: Phase 4.5 Complete  
**Feature**: Task Request (Bid/Offer) Lifecycle Management  

This document defines the complete release checklist, rollback procedures, and monitoring requirements for the Task Request Bid Flow feature.

---

## Table of Contents

1. [Pre-Release Verification](#pre-release-verification)
2. [Deployment Order](#deployment-order)
3. [Rollback Procedures](#rollback-procedures)
4. [Monitoring Metrics](#monitoring-metrics)
5. [Rollback Triggers](#rollback-triggers)
6. [Post-Release Verification](#post-release-verification)
7. [AppLogger Monitoring Patterns](#applogger-monitoring-patterns)
8. [Emergency Contacts](#emergency-contacts)

---

## Pre-Release Verification

### Automated Testing

| Check | Command | Expected Result | Status |
|-------|---------|-----------------|--------|
| Unit Tests | `flutter test test/unit/tender/` | >50 tests pass | ⬜ |
| Integration Tests | `flutter test test/integration/` | All pass | ⬜ |
| RLS Security Tests | `flutter test test/security/task_requests_rls_test.dart` | All pass | ⬜ |
| Chat Creation Tests | `flutter test test/rls/chat_creation_security_test.dart` | All pass | ⬜ |
| Widget Tests | `flutter test test/widget/tasks/` | All pass | ⬜ |
| Code Analysis | `flutter analyze` | 0 errors, 0 warnings | ⬜ |
| Code Format | `flutter format --set-exit-if-changed .` | Clean exit | ⬜ |

**Minimum Test Thresholds**:
- Total test count: >50 unit tests
- Code coverage: >80% for tender-related code
- RLS test coverage: 100% of policies verified

### Manual E2E Scenarios

Complete the [SMOKE_TEST_TENDER.md](../../../SMOKE_TEST_TENDER.md):

| Scenario | Steps | Expected Result | Status |
|----------|-------|-----------------|--------|
| Submit Offer | Freelancer submits bid on open task | Success, notification sent to client | ⬜ |
| View Offers | Client sees bid list with prices | All bids visible with correct prices | ⬜ |
| Price Change Race | Freelancer updates while client views | PRICE_MISMATCH dialog shown | ⬜ |
| Accept Offer | Client accepts valid bid | Task assigned, countdown starts | ⬜ |
| Reject Offer | Client rejects bid | Freelancer notified, conversation created | ⬜ |
| Replace Offer | Freelancer replaces existing bid | Old bid withdrawn, new bid active | ⬜ |
| Payment Flow | Client pays for awarded bid | Payment held, task moves to in_progress | ⬜ |
| Countdown Display | Timer visible after award | Countdown updates every minute | ⬜ |
| Auto-Expiry | Award expires after 48h | Task reverts to open, freelancer notified | ⬜ |

### Documentation Verification

| Document | Status | Notes |
|----------|--------|-------|
| [THREAT_MODEL.md](THREAT_MODEL.md) | ⬜ Updated | Security scenarios documented |
| [API_CONTRACT.md](API_CONTRACT.md) | ⬜ Updated | All RPCs documented |
| [RLS_CHECK_MATRIX.md](RLS_CHECK_MATRIX.md) | ⬜ Updated | All 6 policies verified |
| [Sline_everything/DEVELOPER_GUIDE.md](../../../../Sline_everything/DEVELOPER_GUIDE.md) | ⬜ Updated | Feature section added |
| [Sline_everything/SUPABASE_SETUP.md](../../../../Sline_everything/SUPABASE_SETUP.md) | ⬜ Updated | Migration applied |
| Code comments | ⬜ Reviewed | Complex logic documented |

### Database Verification

| Check | Query/Command | Expected Result | Status |
|-------|---------------|-----------------|--------|
| RPC Functions Exist | `\df public.accept_task_request` | Function exists | ⬜ |
| RLS Policies Active | `\dp public.task_requests` | 6 policies shown | ⬜ |
| Constraints Active | `\d public.task_requests` | idx_one_accepted_per_task shown | ⬜ |
| Cron Job Active | `SELECT * FROM cron.job;` | cleanup_expired_awards listed | ⬜ |
| RPC Grants | `\df+ accept_task_request` | EXECUTE granted to authenticated | ⬜ |

---

## Deployment Order

### Phase 1: Database Preparation (0 downtime)

```sql
-- Verify all RPCs exist and are granted
SELECT proname, proargnames, prosecdef 
FROM pg_proc 
WHERE proname IN (
    'accept_task_request',
    'reject_task_request', 
    'replace_task_request',
    'submit_task_bid',
    'cleanup_expired_awards',
    'award_task_offer',
    'pay_awarded_offer'
);

-- Verify grants
SELECT grantee, privilege_type 
FROM information_schema.role_routine_grants 
WHERE routine_name = 'accept_task_request';
```

| Step | Action | Verification | Status |
|------|--------|--------------|--------|
| 1.1 | Verify RPC functions deployed | All 7 functions exist | ⬜ |
| 1.2 | Verify RLS policies active | 6 policies on task_requests | ⬜ |
| 1.3 | Verify constraints active | Unique indexes in place | ⬜ |
| 1.4 | Verify cron job running | cleanup_expired_awards scheduled | ⬜ |
| 1.5 | Verify RPC grants | authenticated role has EXECUTE | ⬜ |

### Phase 2: App Deployment (if native changes)

| Step | Action | Verification | Status |
|------|--------|--------------|--------|
| 2.1 | Build release APK/IPA | `flutter build apk --release` | ⬜ |
| 2.2 | Upload to Play/App Store | Version number incremented | ⬜ |
| 2.3 | Staged rollout (5%) | Monitor for 2 hours | ⬜ |
| 2.4 | Full rollout | Monitor for 24 hours | ⬜ |

**Note**: If only backend changes (RPCs/RLS), app deployment may be skipped. The feature will work for existing app versions if they already use the tender flow.

### Phase 3: Post-Deployment Verification

| Step | Action | Verification | Status |
|------|--------|--------------|--------|
| 3.1 | Run smoke test | [SMOKE_TEST_TENDER.md](../../../SMOKE_TEST_TENDER.md) passes | ⬜ |
| 3.2 | Check Supabase logs | No errors in RPC calls | ⬜ |
| 3.3 | Verify realtime subscriptions | Subscriptions active | ⬜ |
| 3.4 | Check error rates | <2% error rate | ⬜ |

---

## Rollback Procedures

### Emergency Rollback (Critical Issue)

**Trigger**: App crash, data corruption, security breach

| Step | Action | Command/Method | ETA |
|------|--------|----------------|-----|
| 1 | Disable "View Offers" button | Hotfix PR: Hide `DashboardOfferCard` CTA | 15 min |
| 2 | Disable bid submission via RLS | Emergency SQL (see below) | 5 min |
| 3 | Revert app (if deployed) | Rollback Play/App Store release | 30 min |
| 4 | Notify users | In-app banner + push notification | 10 min |
| 5 | Post-mortem | Schedule within 24 hours | - |

**Emergency RLS Disable**:
```sql
-- Disable all bid submission (emergency only)
DROP POLICY IF EXISTS task_requests_insert_freelancer_jwt ON public.task_requests;
DROP POLICY IF EXISTS tr_insert ON public.task_requests;

-- Or revoke RPC execution (preferred - keeps data safe)
REVOKE EXECUTE ON FUNCTION submit_task_bid FROM authenticated;
REVOKE EXECUTE ON FUNCTION replace_task_request FROM authenticated;
```

**Restore After Fix**:
```sql
-- Re-run migration to restore policies
\i supabase/migrations/20260306_tender_guardrails.sql
```

### Payment Issue Rollback

**Trigger**: Payment gateway errors, escrow failures, duplicate charges

| Step | Action | Responsible | ETA |
|------|--------|-------------|-----|
| 1 | Disable QiCard integration | Backend: Disable payment provider | 5 min |
| 2 | Enable manual escrow fallback | Support team process | 10 min |
| 3 | Identify affected users | Query: `payment_status = 'failed'` | 15 min |
| 4 | Contact affected users | Email/push notification | 30 min |
| 5 | Manual reconciliation | Support + Finance team | 2 hours |
| 6 | Fix and re-enable | Deploy fix, re-enable QiCard | 4 hours |

**Affected User Query**:
```sql
-- Find users with payment issues in last 24h
SELECT 
    tr.id as request_id,
    tr.client_id,
    tr.freelancer_id,
    tr.payment_status,
    tr.updated_at,
    t.title as task_title
FROM task_requests tr
JOIN tasks t ON t.id = tr.task_id
WHERE tr.payment_status IN ('failed', 'error')
  AND tr.updated_at > NOW() - INTERVAL '24 hours';
```

### Data Issue Rollback

**Trigger**: Incorrect bid statuses, missing notifications, corrupted awards

| Step | Action | Command/Method | ETA |
|------|--------|----------------|-----|
| 1 | Identify affected records | SQL query (see below) | 15 min |
| 2 | Stop cron job | `SELECT cron.unschedule('cleanup-expired-awards');` | 2 min |
| 3 | Manual status corrections | Supabase dashboard or SQL | 30 min |
| 4 | Re-send notifications | Manual notification insert | 20 min |
| 5 | Notify affected users | Bulk email/push | 30 min |
| 6 | Re-enable cron | `SELECT cron.schedule(...);` | 2 min |

**Data Audit Query**:
```sql
-- Find inconsistent states
SELECT 
    tr.id,
    tr.status as request_status,
    tr.payment_status,
    t.status as task_status,
    CASE 
        WHEN tr.status = 'accepted' AND t.status != 'assigned' THEN 'INCONSISTENT'
        WHEN tr.payment_status = 'held' AND t.status != 'in_progress' THEN 'INCONSISTENT'
        ELSE 'OK'
    END as state_check
FROM task_requests tr
JOIN tasks t ON t.id = tr.task_id
WHERE tr.status IN ('accepted', 'paid', 'completed');
```

**Manual Correction Example**:
```sql
-- Fix task status for accepted but unassigned
UPDATE tasks 
SET status = 'assigned',
    assigned_freelancer_id = tr.freelancer_id
FROM task_requests tr
WHERE tasks.id = tr.task_id
  AND tr.status = 'accepted'
  AND tasks.status != 'assigned';
```

---

## Monitoring Metrics

### Primary KPIs (Dashboard Required)

| Metric | Target | Warning | Critical | Data Source |
|--------|--------|---------|----------|-------------|
| Bid submission success rate | >95% | <90% | <85% | App logs + Supabase |
| Award acceptance rate | >70% | <60% | <50% | task_requests table |
| Payment completion rate | >90% | <85% | <80% | task_requests.payment_status |
| Error rate (overall) | <2% | >5% | >10% | AppLogger + Crashlytics |

### Real-time Health Checks

| Check | Query/Method | Frequency | Alert Threshold |
|-------|--------------|-----------|-----------------|
| RPC error rate | Supabase logs filter: `status >= 400` | 5 minutes | >5% errors |
| Stuck awards | `SELECT count(*) FROM task_requests WHERE status='accepted' AND awarded_at < NOW() - INTERVAL '47 hours'` | 10 minutes | >10 stuck |
| Failed payments | `SELECT count(*) FROM task_requests WHERE payment_status='failed' AND updated_at > NOW() - INTERVAL '1 hour'` | 15 minutes | >3 failures/hour |
| Notification queue | Check notifications table for backlog | 5 minutes | >100 pending |

### AppLogger Expected Log Patterns

Use these patterns to monitor feature health via logs:

```dart
// Bid submission success
AppLogger.i('Bid submitted successfully', 
    tag: 'TENDER', 
    json: {'request_id': requestId, 'task_id': taskId});

// Award acceptance
AppLogger.i('Offer accepted', 
    tag: 'TENDER', 
    json: {'request_id': requestId, 'price': price});

// Payment completion
AppLogger.i('Payment completed - escrow funded', 
    tag: 'TENDER', 
    json: {'request_id': requestId, 'amount': amount});

// Errors (monitored automatically via CrashReportingService)
AppLogger.e('Bid submission failed', 
    tag: 'TENDER', 
    error: exception);

// Price mismatch (expected edge case)
AppLogger.w('Price mismatch detected - showing retry dialog', 
    tag: 'TENDER', 
    json: {'expected': expectedPrice, 'actual': actualPrice});

// Award expiration (handled by cron)
AppLogger.i('Award expired - task reopened', 
    tag: 'TENDER', 
    json: {'request_id': requestId, 'hours_expired': 48});
```

**Log-based Alerts**:

| Pattern | Log Level | Alert Type | Action |
|---------|-----------|------------|--------|
| `Bid submission failed` | ERROR | PagerDuty | Check RPC health |
| `Payment failed` | ERROR | PagerDuty | Check QiCard integration |
| `Race condition detected` | WARNING | Slack #alerts | Monitor for abuse |
| `Unauthorized access attempt` | ERROR | PagerDuty + Security | Investigate immediately |

### Realtime Subscription Health

| Metric | Target | Check Method |
|--------|--------|--------------|
| Connection uptime | >99% | Supabase realtime dashboard |
| Message latency | <500ms | Ping/pong measurement |
| Reconnection rate | <5/hour | Connection event logs |
| Subscription errors | 0 | Error log monitoring |

---

## Rollback Triggers

### Automatic Triggers (Immediate Rollback)

| Trigger | Threshold | Action | Owner |
|---------|-----------|--------|-------|
| Bid submission error rate | >5% for 10 minutes | Disable bid submission | Auto + On-call |
| Payment failure rate | >10% for 15 minutes | Disable QiCard integration | Auto + On-call |
| App crash rate | >1% for any tender flow | Emergency app rollback | On-call engineer |
| Data inconsistency detected | Any confirmed case | Stop all state changes | Auto + DBA |
| Security breach suspected | Any unauthorized access | Full emergency rollback | Security team |

### Manual Triggers (Human Decision)

| Trigger | Evidence Required | Decision Maker | Action |
|---------|-------------------|----------------|--------|
| User complaint spike | >10 complaints in 1 hour | Product manager | Partial rollback |
| Performance degradation | >3s API response time | Engineering lead | Optimize or rollback |
| Feature confusion | Usability test failures | UX lead | UI rollback |
| Compliance issue | Legal/audit flag | CTO | Full rollback |

### Trigger Response Flowchart

```
ALERT FIRED
    │
    ▼
┌─────────────────┐
│ Automatic?      │
│ + Security?     │
└────────┬────────┘
         │
    YES ▼                NO ▼
┌─────────────┐      ┌─────────────┐
│ IMMEDIATE   │      │ Page on-call│
│ ROLLBACK    │      │ engineer    │
│ + Notify    │      │             │
└──────┬──────┘      └──────┬──────┘
       │                    │
       ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│ Assess impact   │  │ Assess severity │
│ within 15 min   │  │ within 30 min   │
└────────┬────────┘  └────────┬────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│ Decide:         │  │ Decide:         │
│ Full / Partial  │  │ Rollback / Fix  │
│ / Monitor       │  │ / Monitor       │
└─────────────────┘  └─────────────────┘
```

---

## Post-Release Verification

### 24-Hour Checklist

| Check | Method | Expected Result | Status |
|-------|--------|-----------------|--------|
| Metrics dashboard reviewed | Supabase + Crashlytics | All KPIs green | ⬜ |
| No critical errors | Error log review | 0 P0/P1 errors | ⬜ |
| No user complaints | Support ticket review | <5 tender-related tickets | ⬜ |
| Performance acceptable | API latency check | p95 < 500ms | ⬜ |
| All test users successful | Smoke test re-run | 5/5 tests pass | ⬜ |
| Rollback plan documented | This document | All sections complete | ⬜ |

### 7-Day Review

| Metric | Target | Review Date | Status |
|--------|--------|-------------|--------|
| Bid submission volume | >100/day | +7 days | ⬜ |
| Award acceptance rate | >70% | +7 days | ⬜ |
| Payment completion rate | >90% | +7 days | ⬜ |
| Support tickets | <2% of interactions | +7 days | ⬜ |
| NPS score | No significant drop | +7 days | ⬜ |

### Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Lead | | | |
| Engineering Lead | | | |
| Product Manager | | | |
| Security Review | | | |

---

## AppLogger Monitoring Patterns

### Standard Log Tags for Filtering

```dart
// Use these tags consistently for easy filtering:
const String TAG_TENDER = 'TENDER';
const String TAG_BID = 'TENDER_BID';
const String TAG_PAYMENT = 'TENDER_PAYMENT';
const String TAG_AWARD = 'TENDER_AWARD';
const String TAG_RLS = 'TENDER_RLS';
```

### Expected Log Volume (Normal Operation)

| Operation | Expected Frequency | Log Level |
|-----------|-------------------|-----------|
| Bid submitted | 100-500/day | INFO |
| Offer accepted | 20-100/day | INFO |
| Payment completed | 15-80/day | INFO |
| Price mismatch | 5-20/day | WARNING |
| Award expired | 2-10/day | INFO |
| RPC errors | 0-5/day | ERROR |
| RLS violations | 0/day | ERROR |

### Abnormal Patterns (Investigate)

| Pattern | Possible Cause | Action |
|---------|---------------|--------|
| Spike in price mismatches | UI caching issue | Check client-side state |
| High award expiry rate | Payment UX friction | Review payment flow |
| Bid submission errors | RPC/RLS issue | Check Supabase health |
| Payment failures | QiCard integration | Contact payment provider |
| RLS violations | Attack or bug | Security investigation |

---

## Emergency Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| On-call Engineer | PagerDuty | Auto-escalates after 15 min |
| Engineering Lead | Slack: #eng-leads | Page if on-call unresponsive |
| Database Admin | Slack: @dba-oncall | For data corruption issues |
| Security Team | security@sline.app | For suspected breaches |
| Product Manager | Slack: @pm-oncall | For feature decisions |
| QiCard Support | support@qicard.com | For payment issues |
| Supabase Support | dashboard + Slack | For infrastructure issues |

---

## References

- [THREAT_MODEL.md](THREAT_MODEL.md) - Security threat scenarios and mitigations
- [RLS_CHECK_MATRIX.md](RLS_CHECK_MATRIX.md) - Complete RLS policy verification
- [API_CONTRACT.md](API_CONTRACT.md) - RPC function specifications
- [SMOKE_TEST_TENDER.md](../../../SMOKE_TEST_TENDER.md) - Quick E2E verification script
- [LIVE_DB_VERIFICATION.md](LIVE_DB_VERIFICATION.md) - Database verification steps
- `supabase/migrations/20260306_tender_guardrails.sql` - Database migration

---

**Document End**

*Verification: All release checklist items, rollback procedures, and monitoring requirements documented.*

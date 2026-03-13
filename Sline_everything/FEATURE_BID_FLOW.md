# Task Request (Bid) Flow - Quick Reference Guide

**Version**: 1.0  
**Created**: 2026-03-06  
**Status**: Phase 4.4 Complete

A quick reference guide for developers working with the Task Request (Bid/Offer) lifecycle.

---

## Quick Links

- **Full Documentation**: [DEVELOPER_GUIDE.md#task-request-bid-flow](DEVELOPER_GUIDE.md#task-request-bid-flow)
- **API Contract**: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/API_CONTRACT.md`
- **Threat Model**: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/THREAT_MODEL.md`

---

## File Reference

### Core Implementation Files

| File | Purpose | Lines |
|------|---------|-------|
| `lib/features/tasks/models/task_request_model.dart` | TaskRequest entity | ~265 |
| `lib/features/tasks/services/task_requests_service.dart` | Service layer | ~823 |
| `lib/features/tasks/viewmodels/task_requests_view_model.dart` | ViewModel | ~836 |
| `lib/features/tasks/viewmodels/award_expiration_monitor.dart` | Countdown timer | ~180 |
| `lib/features/tasks/exceptions/offer_exceptions.dart` | Custom exceptions | ~50 |

### UI Files

| File | Purpose |
|------|---------|
| `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Owner view: accept/reject offers |
| `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | Freelancer view: submit/replace offer |
| `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Individual offer display |
| `lib/features/tasks/view/widgets/expiration_countdown.dart` | Payment deadline countdown |
| `lib/features/tasks/view/widgets/payment_status_badge.dart` | Payment state indicator |
| `lib/features/tasks/view/widgets/dashboard_offer_card.dart` | Dashboard card with countdown |

### Test Files

| File | Purpose |
|------|---------|
| `test/unit/tender/task_requests_service_test.dart` | Service layer tests |
| `test/unit/tender/task_requests_view_model_test.dart` | ViewModel tests |
| `test/unit/tender/award_expiration_monitor_test.dart` | Timer tests |
| `test/rls/task_requests_rls_test.dart` | RLS policy tests |
| `test/fixtures/tender_tasks.dart` | Test fixtures |
| `test/fixtures/task_request_factory.dart` | Factory methods |

---

## Common Tasks

### 1. Submit a New Bid (Freelancer)

```dart
// In ViewModel
final success = await viewModel.submitOfferUI(
  taskId: taskId,
  price: 150.00,  // Dollars
  days: 7,
  note: 'I can complete this within a week',
);

if (success) {
  // Offer submitted successfully
} else {
  // Check viewModel.errorMessage for details
}
```

### 2. Replace Existing Bid (Freelancer)

```dart
// Check if bid is replaceable first
final result = await viewModel.checkBidReplaceability();
if (result.isReplaceable && result.existingBid != null) {
  // Show "Update Offer" button
}

// Replace the offer
final offer = await service.replaceOffer(
  taskId: taskId,
  price: 175.00,
  days: 5,
  note: 'Updated my estimate',
);
```

### 3. Accept/Offer Award (Client - Step 1)

```dart
try {
  final priceCents = (request.price * 100).round();
  final success = await viewModel.acceptOffer(
    request,
    expectedPriceCents: priceCents,
  );
  if (success) {
    // Show payment deadline countdown
    // Navigate to payment screen or show countdown
  }
} on PriceMismatchException catch (e) {
  // Show price mismatch dialog
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Price Updated'),
      content: Text(e.userMessage),
      actions: [
        TextButton(
          onPressed: () => refreshOffers(),
          child: Text('Refresh'),
        ),
      ],
    ),
  );
}
```

### 4. Complete Payment (Client - Step 2)

```dart
final result = await viewModel.payForAwardedOffer(requestId);
if (result != null) {
  // Payment successful, work is now active
  // Navigate to work details or chat
}
```

### 5. Reject Offer (Client)

```dart
await viewModel.reject(requestId);
// Rejection automatically creates conversation for follow-up
```

### 6. Cancel Awarded Offer (Client)

```dart
final success = await viewModel.cancelAwardedOffer(requestId);
if (success) {
  // Offer cancelled, task reverted to 'open'
}
```

---

## Code Snippets

### Bid Replaceability Check

```dart
// In SubmitRequestSheet
Future<void> _checkExistingBid() async {
  final result = await viewModel.checkBidReplaceability();
  setState(() {
    _existingBid = result.existingBid;
    _isReplaceable = result.isReplaceable;
    if (_existingBid != null) {
      _priceController.text = _existingBid!.price.toString();
      _daysController.text = _existingBid!.days.toString();
      _noteController.text = _existingBid!.note ?? '';
    }
  });
}
```

### Countdown Timer Integration

```dart
// In RequestTile or DashboardOfferCard
Consumer<AwardExpirationMonitor>(
  builder: (context, monitor, child) {
    final urgency = monitor.getUrgencyLevel(deadline);
    return ExpirationCountdown(
      deadline: deadline,
      urgency: urgency,
      onExpired: () => refreshOffers(),
    );
  },
)
```

### Error Mapping in UI

```dart
String getErrorMessage(dynamic error) {
  if (error is PriceMismatchException) {
    return error.userMessage;
  }
  if (error is OfferAlreadyAcceptedException) {
    return 'This offer has already been accepted.';
  }
  if (error is String) {
    return error;
  }
  return 'An error occurred. Please try again.';
}
```

---

## Database Reference

### task_requests Table (Key Columns)

```sql
SELECT 
  id,
  task_id,
  freelancer_id,      -- Canonical bidder column
  bidder_id,          -- Legacy column (mirrored)
  price,              -- NUMERIC
  days,               -- INTEGER
  note,
  status,             -- pending, accepted, rejected, withdrawn
  payment_status,     -- unpaid, held, released, refunded
  awarded_at,         -- TIMESTAMPTZ (set on accept)
  payment_deadline,   -- TIMESTAMPTZ (48h from award)
  awarded_by,         -- UUID (who accepted)
  fee_rate_applied_bps, -- Platform fee at award time
  fee_amount,         -- Calculated fee in cents
  net_amount          -- Freelancer payout in cents
FROM task_requests;
```

### RPC Function Signatures

```sql
-- Award offer (Step 1)
accept_task_request(
  p_task_id UUID,
  p_request_id UUID,
  p_expected_price_cents BIGINT DEFAULT NULL
) RETURNS TEXT;  -- 'accepted' or 'already_accepted'

-- Reject offer
reject_task_request(
  p_task_id UUID,
  p_request_id UUID
) RETURNS UUID;  -- conversation_id

-- Replace own offer
replace_task_request(
  p_task_id UUID,
  p_freelancer_id UUID,
  p_message TEXT,
  p_price NUMERIC,
  p_days INTEGER
) RETURNS VOID;

-- Cron: Expire unpaid awards
cleanup_expired_awards() RETURNS VOID;
```

---

## Configuration

### system_config Keys

```sql
-- Payment window duration (default: 48 hours)
INSERT INTO system_config (key, value, description)
VALUES (
  'tender_payment_timeout_hours',
  '{"timeout_hours": 48}',
  'Hours client has to pay after accepting offer'
);

-- Platform fee rate (default: 10% = 1000 bps)
INSERT INTO system_config (key, value, description)
VALUES (
  'platform_fee_bps',
  '{"default_rate_bps": 1000}',
  'Platform fee in basis points (100 bps = 1%)'
);
```

---

## Testing

### Run Unit Tests

```bash
flutter test test/unit/tender/
```

### Run RLS Tests

```bash
flutter test test/rls/task_requests_rls_test.dart
```

### Manual Smoke Test

See `.TODO/SMOKE_TEST_TENDER.md` for 5-minute verification checklist.

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `PRICE_MISMATCH` error | Freelancer updated offer during award | Refresh list and try again |
| `already_accepted` response | Double-click or retry | No action needed, already accepted |
| `deadline expired` error | Payment window closed | Cancel and re-award |
| `42501` RLS error | Permission denied | Check user role and task ownership |
| Rate limiting (2s) | Too rapid submissions | Wait 2 seconds between actions |
| Offer not appearing | Cache stale | Pull-to-refresh or reload screen |

---

## Security Checklist

Before modifying bid flow code:

- [ ] All database writes go through RPC (SECURITY DEFINER)
- [ ] No direct UPDATE on `task_requests.status` from client
- [ ] Price validation on award (optimistic concurrency)
- [ ] Idempotency check prevents double acceptance
- [ ] Rate limiting on submit (2-second debounce)
- [ ] Proper error mapping (no raw SQL errors to UI)
- [ ] Test RLS policies still pass after changes

---

## Migration Files

| File | Purpose |
|------|---------|
| `supabase/migrations/20260306_tender_guardrails.sql` | Indexes, accept_task_request, cleanup_expired_awards |
| `20260305*_reject_task_request_conversation_initiator.sql` | reject_task_request with conversation creation |
| `20260322000002`–`20260322000005` (replace_task_request sequence) | replace_task_request: single overload, no role gate, **update-in-place** (final: `20260322000005_replace_task_request_update_in_place.sql`) |

---

**End of Quick Reference Guide**

*For detailed documentation, see [DEVELOPER_GUIDE.md#task-request-bid-flow](DEVELOPER_GUIDE.md#task-request-bid-flow)*

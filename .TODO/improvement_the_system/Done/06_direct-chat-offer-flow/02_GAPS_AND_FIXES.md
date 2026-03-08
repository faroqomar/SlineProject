# 02_GAPS_AND_FIXES

## 1. Naming & Status Mismatch

**Gap:** Visual diagram uses `pending` for the initial state. The database uses `sent`.
**Fix:** Rename `pending` to `sent` in the state machine diagram to match `SUPABASE_SETUP.md` line 684 and `DirectOffersService.dart`.

## 2. Incomplete State Representation (payment_status vs status)

**Gap:** Direct offers rely heavily on `payment_status` (`unpaid`, `held`, `released`, `refunded`) to ensure safety and financial integrity. The diagram implies `active` equals paid, but does not show the ledger coupling explicitly.
**Fix:** Introduce composite states in the new diagram where `status` + `payment_status` are coupled to map exactly to reality:

- `[sent, unpaid]`
- `[accepted, unpaid]`
- `[active, held]`
- `[delivered, held]`
- `[completed, released]`
- `[canceled, unpaid/refunded]`

## 3. The Cancellation Black Hole

**Gap:** The diagram clearly shows an `active --> canceled` transition that triggers a refund. However, `DirectOffersService.dart` has absolutely no method to cancel an active (paid/held) offer. Both `cancelAcceptedOffer` (client) and `cancelOffer` (freelancer) strictly check that the offer has not been paid (i.e. is `accepted`/`unpaid` or `sent`). There is no user-facing way to cancel/refund an active direct offer.
**Fix:** A protocol for resolving a dispute on a direct offer must be added (or noted as missing). If the system expects support intervention to trigger a refund ledger entry, that admin/support path must be explicit.

## 4. Unmapped Rejection Path

**Gap:** The diagram shows `pending --> rejected`. `DirectOffersService.dart` (`rejectOffer`) implements this. That matches safely. However, a freelancer cancelling their own sent offer should lead to `canceled`, not `rejected`. The diagram needs to show the freelancer's right to withdraw before acceptance.
**Fix:** Add `sent --> canceled (freelancer withdraws)` transition.

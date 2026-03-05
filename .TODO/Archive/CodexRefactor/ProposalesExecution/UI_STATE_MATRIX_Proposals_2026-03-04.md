# UI State Matrix: Proposals 2026-03-04

**Purpose**: One visible behavior per state; one test target per state.

| State | Description | Visible behavior | Test target |
|-------|-------------|------------------|-------------|
| **loading** | List or screen loading | Skeleton or progress indicator | find.byType(SkeletonOfferCard) or CircularProgressIndicator |
| **empty** | No proposals yet | "No offers yet" (or equivalent) | find.text('No offers yet') |
| **pending submit** | User can submit; sheet open | Submit proposal sheet visible | Key('submit_proposal_sheet') |
| **pending replace** | User has existing proposal; replace confirm | Replace confirmation dialog | Dialog with "Replace your existing offer?" |
| **rejected** | Proposal rejected | Status "Rejected"; no accept/reject actions | Status label; no primary CTA |
| **awarded-waiting-payment** | Owner awarded; client must pay | Pay CTA in Requests/Inbox/Work/Next Actions/Work Details | Key('proposal_payment_screen') or pay CTA keys |
| **missing resume record** | Awarded but no resume payload | Graceful message or hide pay CTA | No crash; optional "Unable to load" |
| **payment failed/retry** | Finalize failed; user can retry | Error message + retry or "Pay" again | Error text; Pay button still available |
| **forbidden/role mismatch** | Wrong role (e.g. client submits without role) | Explicit error message; no silent role switch | SnackBar or dialog with role requirement |
| **unavailable launcher** | No payment method or task unavailable | Disabled or "Unavailable" state | _buildTenderUnavailableBanner or disabled button |

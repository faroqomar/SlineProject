# State Matrix: Proposals 2026-03-04

**Purpose**: Transition rules for proposal lifecycle.

## States

- **pending**: Proposal submitted; owner can reject or award; freelancer can replace.
- **rejected**: Owner rejected; terminal for that proposal.
- **accepted** (awarded): Owner awarded; client must pay within deadline; client can cancel award.
- **paid**: Payment finalized; moves to work/delivery (out of proposal scope for this matrix).

## Transitions

| From | Event | To | Actor |
|------|--------|-----|-------|
| pending | submit | pending (replace) or new row | freelancer |
| pending | replace | pending | freelancer |
| pending | reject | rejected | owner |
| pending | award | accepted | owner |
| accepted | pay / finalize | paid | client |
| accepted | cancel_awarded_offer | pending (task open again) | owner |

## Resume

- **Resume**: Client or freelancer opens "resume payment" from Requests/Inbox/Work/Next Actions/Work Details; same ProposalPaymentSummary and route helper; no new state, just navigation to payment screen.

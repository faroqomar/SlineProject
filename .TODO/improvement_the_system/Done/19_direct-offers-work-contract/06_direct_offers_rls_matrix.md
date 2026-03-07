# Direct Offers RLS Matrix

**Plan:** PLAN_DirectChatOfferFlow_2026-03-07_CRITIC (Phase 2)  
**Date:** 2026-03-07

| Actor | Action | Expected |
|-------|--------|----------|
| Client (owner) | SELECT own offer (client_id = auth.uid()) | Allow |
| Client (owner) | UPDATE own offer status to 'canceled' when accepted + unpaid | Allow |
| Client (owner) | UPDATE own offer status to 'rejected' when sent | Allow |
| Freelancer (owner) | SELECT own offer (freelancer_id = auth.uid()) | Allow |
| Freelancer (owner) | UPDATE own offer status to 'canceled' when sent | Allow |
| Other user | SELECT offer where client_id != uid AND freelancer_id != uid | Deny |
| Other user | UPDATE any direct_offers row not owned (client/freelancer) | Deny |
| Unauthenticated | SELECT/UPDATE direct_offers | Deny |

**Run:** Use Supabase MCP execute_sql as second user (or RLS test harness) to verify negative cases.

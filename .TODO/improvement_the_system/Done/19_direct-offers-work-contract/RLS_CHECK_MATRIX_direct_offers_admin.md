# RLS / Access Matrix: direct_offers & Admin Objects

**Plan 19: Direct Offers Work Contract**

## public.direct_offers

| Operation | Who | Condition | Negative test |
|-----------|-----|-----------|---------------|
| SELECT | Client | client_id = auth.uid() | Other user cannot SELECT |
| SELECT | Freelancer | freelancer_id = auth.uid() | Other user cannot SELECT |
| INSERT | Freelancer | freelancer_id = auth.uid() AND conversation participant | Self-offer (client_id = freelancer_id) rejected by trg_direct_offer_guard_insert |
| UPDATE | Client or Freelancer | client_id = auth.uid() OR freelancer_id = auth.uid() | Other user cannot UPDATE |
| DELETE | No one | RLS denies | N/A |

## admin.vw_direct_offer_money_story

| Operation | Who | Condition | Negative test |
|-----------|-----|-----------|---------------|
| SELECT | service_role only | No GRANT to anon/authenticated | anon/authenticated cannot SELECT |

## admin.vw_direct_offer_stuck_funds

| Operation | Who | Condition | Negative test |
|-----------|-----|-----------|---------------|
| SELECT | service_role only | No GRANT to anon/authenticated | anon/authenticated cannot SELECT |

## public.admin_refund_direct_offer

| Operation | Who | Condition | Negative test |
|-----------|-----|-----------|---------------|
| EXECUTE | Admin (auth.uid() IN admin_users) | RPC body checks admin_users | Non-admin gets 'only admin can refund direct_offer' |
| EXECUTE | anon | REVOKE EXECUTE FROM anon | anon cannot call |
| EXECUTE | authenticated (non-admin) | RPC body raises | Regular user gets exception |

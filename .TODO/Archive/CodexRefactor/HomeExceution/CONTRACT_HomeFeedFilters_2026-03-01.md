# Home Feed Contracts

## Seller Level Contract
- DB type: `public.seller_level_enum`
- Canonical values:
  - `new_seller`
  - `level_1`
  - `level_2`
  - `top_rated`
- UI label mapping:
  - `New Seller` -> `new_seller`
  - `Level 1` -> `level_1`
  - `Level 2` -> `level_2`
  - `Top Rated Seller` -> `top_rated`

## Profile Summary RPC Contract
- Function: `public.rpc_get_profile_summaries(p_ids uuid[])`
- Caller: authenticated only
- Returned fields:
  - `id`
  - `full_name`
  - `avatar_url`
  - `bio`
  - `active_role`
  - `skills`
  - `created_at`
  - `seller_level`
- Forbidden fields:
  - `email`
  - `metadata`
  - `roles`
  - `is_wallet_frozen`

## Feed Cursor Contract
- Query order: `created_at DESC, id DESC`
- Cursor fields:
  - `cursorCreatedAtIso`
  - `cursorId`
- Next-page filter:
  - rows with earlier `created_at`
  - or same `created_at` and smaller `id`

## Delivery Bucket Contract
- Source order:
  - booking task minimum numeric `packages[*].delivery`
  - otherwise `deadline - now`
  - otherwise `Anytime`
- Buckets:
  - `Up to 24h` => `> 0 && <= 24h`
  - `Up to 3 days` => `> 24h && <= 72h`
  - `Up to 7 days` => `> 72h && <= 168h`
  - `Anytime` => missing estimate or `> 168h`
- Expired deadlines do not match the first three buckets.

## Seller-Level Filter Contract
- Match against `Task.authorSellerLevel`.
- If any seller-level filter is active, all tender tasks are excluded.
- Filtering is client-side over the loaded discovery window in this pass.

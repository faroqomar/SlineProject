# Gaps and Fixes for Role Switching

## Gaps Identified

1. **No Cache/Stream Teardown Mechanism Documented:** The diagram implies a simple DB update. Realistically, local Flutter state (e.g. ViewModels, Supabase realtime streams) must be reset to avoid persona data leakage.
2. **Missing Security Enforcement Layer:** A malicious actor could send an API request to act as a freelancer while their `active_role` is client.
3. **Race Conditions:** User submits a proposal request while simultaneously switching role to client on another device.
4. **Lack of JWT Custom Claims:** Database joins on `profiles` inside RLS policies are slow and expensive. Role should ideally be a custom JWT claim OR cached effectively.

## Proposed Fixes

1. Introduce a strict "State Teardown" sequence in the app upon role switch.
2. Ensure RLS policies explicitly check `active_role` for action matrices.
3. Update the diagram to represent a Sequence rather than a simple State, showing the UI reacting, cache clearing, and RPC/DB updating safely.

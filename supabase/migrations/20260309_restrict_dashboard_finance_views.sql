-- Restrict dashboard finance views to service_role only.
-- Standard dashboard runtime must not read platform-wide financial metrics.
-- See .TODO/CONTRACT_Dashboard_Finance_Boundary_2026-03-01.md

REVOKE SELECT ON public.vw_financial_metrics_realtime FROM authenticated;
REVOKE SELECT ON public.vw_financial_metrics_period FROM authenticated;

-- service_role retains SELECT (already granted in 20260225_create_wallet_views.sql)
-- Admin reporting must use service_role or a dedicated admin RPC.

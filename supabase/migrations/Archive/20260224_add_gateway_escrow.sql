-- Phase 1.1 (QiService): additive enum extension for external card escrow.
-- Safe rollback posture: keep additive enum value in place.

ALTER TYPE public.payment_event_type_enum
ADD VALUE IF NOT EXISTS 'gateway_escrow';

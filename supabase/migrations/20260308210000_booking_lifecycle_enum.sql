-- Booking Lifecycle (Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic)
-- Add disputed and no_show to booking_status_enum (additive only).

ALTER TYPE public.booking_status_enum ADD VALUE IF NOT EXISTS 'disputed';
ALTER TYPE public.booking_status_enum ADD VALUE IF NOT EXISTS 'no_show';

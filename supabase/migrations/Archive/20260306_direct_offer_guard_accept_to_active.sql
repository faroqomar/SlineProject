-- Allow direct_offer status transition: accepted -> active when payment_status = held.
-- Required for QiCard flow: offer is accepted+unpaid, then process_gateway_escrow_direct_offer
-- sets payment_status = held and status = active.

CREATE OR REPLACE FUNCTION public.fn_direct_offer_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only allow status/payment_status changes that respect lifecycle
    IF OLD.status IS DISTINCT FROM NEW.status OR OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
        -- sent -> accepted (no payment yet): payment_status stays unpaid
        IF OLD.status = 'sent' AND NEW.status = 'accepted' AND NEW.payment_status = 'unpaid' THEN
            RETURN NEW;
        END IF;
        -- sent -> accepted/active with payment: must have payment_status = held (set by RPC after escrow_hold)
        IF OLD.status = 'sent' AND NEW.status IN ('accepted', 'active') THEN
            IF NEW.payment_status != 'held' THEN
                RAISE EXCEPTION 'direct_offer: status cannot become active without payment_status = held';
            END IF;
            RETURN NEW;
        END IF;
        -- accepted -> active: gateway escrow (QiCard) sets held + active after payment success
        IF OLD.status = 'accepted' AND NEW.status = 'active' AND NEW.payment_status = 'held' THEN
            RETURN NEW;
        END IF;
        -- active -> delivered: freelancer only
        IF OLD.status = 'active' AND NEW.status = 'delivered' THEN
            IF auth.uid() != OLD.freelancer_id THEN
                RAISE EXCEPTION 'direct_offer: only freelancer can mark delivered';
            END IF;
            RETURN NEW;
        END IF;
        -- delivered -> completed: must have payment_status = released (set by RPC after release_with_fee)
        IF OLD.status = 'delivered' AND NEW.status = 'completed' THEN
            IF NEW.payment_status != 'released' THEN
                RAISE EXCEPTION 'direct_offer: status cannot become completed without payment_status = released';
            END IF;
            RETURN NEW;
        END IF;
        -- sent -> rejected, canceled; any -> refunded/canceled (when refund)
        IF NEW.status IN ('rejected', 'canceled', 'refunded') THEN
            RETURN NEW;
        END IF;
        -- Disallow any other transition from guard (RPC may set status+payment together)
        IF OLD.status != NEW.status THEN
            RAISE EXCEPTION 'direct_offer: invalid status transition from % to %', OLD.status, NEW.status;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.fn_direct_offer_guard IS 'Enforces direct_offer status/payment_status lifecycle. Allows accepted->active when payment_status=held (QiCard gateway escrow).';

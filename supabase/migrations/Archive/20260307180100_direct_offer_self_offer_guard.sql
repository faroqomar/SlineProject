-- Reject direct_offer INSERT when client_id = freelancer_id (self-offer). Plan 19.

CREATE OR REPLACE FUNCTION public.fn_direct_offer_guard_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.client_id = NEW.freelancer_id THEN
        RAISE EXCEPTION 'direct_offer: client and freelancer cannot be the same';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_direct_offer_guard_insert ON public.direct_offers;
CREATE TRIGGER trg_direct_offer_guard_insert
    BEFORE INSERT ON public.direct_offers
    FOR EACH ROW
    EXECUTE PROCEDURE public.fn_direct_offer_guard_insert();

COMMENT ON FUNCTION public.fn_direct_offer_guard_insert IS 'Rejects INSERT when client_id = freelancer_id (self-offer).';

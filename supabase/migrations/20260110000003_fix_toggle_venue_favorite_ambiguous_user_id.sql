-- Fix ambiguous `user_id` reference inside toggle_venue_favorite RPC.
--
-- Error:
--   {"code":"42702","message":"column reference \"user_id\" is ambiguous"}
--
-- Root cause:
--   In PL/pgSQL, identifiers like `user_id` can resolve ambiguously between
--   function parameters/variables and table columns (particularly in contexts
--   like ON CONFLICT targets).
--
-- Fix:
--   Drop + recreate the function using positional arguments ($1/$2) and
--   avoid ON CONFLICT column targets that mention `user_id`.

DROP FUNCTION IF EXISTS public.toggle_venue_favorite(uuid, uuid);

CREATE OR REPLACE FUNCTION public.toggle_venue_favorite(
  venue_id uuid,
  user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF $2 <> auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.venue_favorites vf
    WHERE vf.venue_id = $1
      AND vf.user_id = $2
  ) THEN
    DELETE FROM public.venue_favorites vf
    WHERE vf.venue_id = $1
      AND vf.user_id = $2;
  ELSE
    -- Insert without ON CONFLICT targets to avoid `user_id` ambiguity.
    -- Relies on the unique(user_id, venue_id) constraint at the table level.
    INSERT INTO public.venue_favorites
    SELECT gen_random_uuid(), $2, $1, now()
    WHERE NOT EXISTS (
      SELECT 1
      FROM public.venue_favorites vf
      WHERE vf.venue_id = $1
        AND vf.user_id = $2
    );
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_venue_favorite(uuid, uuid) TO authenticated;

-- Optional overload: safer client contract (no user_id passed from client).
DROP FUNCTION IF EXISTS public.toggle_venue_favorite(uuid);

CREATE OR REPLACE FUNCTION public.toggle_venue_favorite(
  venue_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  PERFORM public.toggle_venue_favorite($1, auth.uid());
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_venue_favorite(uuid) TO authenticated;

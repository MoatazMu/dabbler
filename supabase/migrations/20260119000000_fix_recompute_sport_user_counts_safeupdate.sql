-- Fix for environments with safe-update enforcement (e.g. pg_safeupdate)
-- Any UPDATE without a WHERE clause will error with "UPDATE requires a WHERE clause".
-- This function is invoked by triggers on public.profiles.

create or replace function public.recompute_sport_user_counts()
  returns void
  language plpgsql
as $function$
BEGIN
  -- reset
  UPDATE public.sports
  SET
    primary_user_count = 0,
    interested_user_count = 0
  WHERE true;

  -- primary sport count (profiles table)
  UPDATE public.sports s
  SET primary_user_count = sub.cnt
  FROM (
    SELECT
      lower(trim(primary_sport)) AS sport_key,
      COUNT(*) AS cnt
    FROM public.profiles
    WHERE primary_sport IS NOT NULL
      AND is_active = true
    GROUP BY lower(trim(primary_sport))
  ) sub
  WHERE s.sport_key = sub.sport_key;

  -- interested sport count (sport_profiles table)
  UPDATE public.sports s
  SET interested_user_count = sub.cnt
  FROM (
    SELECT
      sp.sport_id,
      COUNT(DISTINCT sp.profile_id) AS cnt
    FROM public.sport_profiles sp
    JOIN public.profiles p ON p.id = sp.profile_id
    WHERE p.is_active = true
    GROUP BY sp.sport_id
  ) sub
  WHERE s.id = sub.sport_id;
END;
$function$;

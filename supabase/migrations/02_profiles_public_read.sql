BEGIN;

-- Ensure anonymous/public roles can select from profiles when allowed by RLS
GRANT SELECT ON public.profiles TO anon;

-- Public read policy: allow viewing active, non-deleted profiles
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_select_public'
    ) THEN
        CREATE POLICY profiles_select_public
            ON public.profiles
            FOR SELECT
            USING (is_active = true AND deleted_at IS NULL);
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_select_public'
    ) THEN
        EXECUTE $$COMMENT ON POLICY profiles_select_public ON public.profiles IS 'mig:02_profiles_public_read | allow viewing public active profiles'$$;
    END IF;
END;
$$;

COMMIT;

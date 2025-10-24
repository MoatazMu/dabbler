BEGIN;

-- Ensure pgcrypto extension is available for UUID generation helpers
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Helper function to retrieve the authenticated user's UUID from JWT claims
CREATE OR REPLACE FUNCTION public.auth_uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid,
        NULLIF((current_setting('request.jwt.claims', true)::jsonb)->>'sub', '')::uuid
    );
$$;
COMMENT ON FUNCTION public.auth_uid() IS 'mig:01_auth_profiles_init | resolve authenticated user id from JWT claims';

-- Helper function to determine if the requester has administrative privileges
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    claim_role text := current_setting('request.jwt.claim.role', true);
    claim_is_admin text := current_setting('request.jwt.claim.is_admin', true);
    claims jsonb := COALESCE(current_setting('request.jwt.claims', true)::jsonb, '{}'::jsonb);
BEGIN
    IF claim_role = 'service_role' THEN
        RETURN true;
    END IF;

    IF COALESCE(claim_is_admin, claims->>'is_admin') = 'true' THEN
        RETURN true;
    END IF;

    RETURN false;
END;
$$;
COMMENT ON FUNCTION public.is_admin() IS 'mig:01_auth_profiles_init | determine elevated access for admin or service role';

-- Trigger helper to update timestamp columns
CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
COMMENT ON FUNCTION public.tg_set_updated_at() IS 'mig:01_auth_profiles_init | maintain updated_at timestamps via trigger';

-- Profiles table definition
CREATE TABLE IF NOT EXISTS public.profiles (
    user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name text NOT NULL,
    username citext,
    avatar_url text,
    profile_type text NOT NULL DEFAULT 'player',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz NULL
);
COMMENT ON TABLE public.profiles IS 'mig:01_auth_profiles_init | user profile records linked to auth users';

-- Ensure unique username constraint exists and is documented
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_username_key'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_username_key UNIQUE (username);
    END IF;
END;
$$;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_username_key'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        EXECUTE $$COMMENT ON CONSTRAINT profiles_username_key ON public.profiles IS 'mig:01_auth_profiles_init | enforce unique usernames (case-insensitive)'$$;
    END IF;
END;
$$;

-- Document primary key and foreign key constraints
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_pkey'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        EXECUTE $$COMMENT ON CONSTRAINT profiles_pkey ON public.profiles IS 'mig:01_auth_profiles_init | primary key for profiles via user_id'$$;
    END IF;
END;
$$;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_user_id_fkey'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        EXECUTE $$COMMENT ON CONSTRAINT profiles_user_id_fkey ON public.profiles IS 'mig:01_auth_profiles_init | reference auth.users for ownership cascade'$$;
    END IF;
END;
$$;

-- Attach trigger to keep updated_at in sync
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'profiles_set_updated_at'
          AND tgrelid = 'public.profiles'::regclass
          AND NOT tgisinternal
    ) THEN
        CREATE TRIGGER profiles_set_updated_at
        BEFORE UPDATE ON public.profiles
        FOR EACH ROW
        EXECUTE FUNCTION public.tg_set_updated_at();
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'profiles_set_updated_at'
          AND tgrelid = 'public.profiles'::regclass
          AND NOT tgisinternal
    ) THEN
        EXECUTE $$COMMENT ON TRIGGER profiles_set_updated_at ON public.profiles IS 'mig:01_auth_profiles_init | auto-update timestamp on profile changes'$$;
    END IF;
END;
$$;

-- Enable row level security and configure privileges
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT ALL PRIVILEGES ON public.profiles TO service_role;

-- Owner select policy (exclude soft-deleted rows)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_owner_select'
    ) THEN
        CREATE POLICY profiles_owner_select
            ON public.profiles
            FOR SELECT
            USING (user_id = public.auth_uid() AND deleted_at IS NULL);
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_owner_select'
    ) THEN
        EXECUTE $$COMMENT ON POLICY profiles_owner_select ON public.profiles IS 'mig:01_auth_profiles_init | allow owners to view their active profile'$$;
    END IF;
END;
$$;

-- Owner insert policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_owner_insert'
    ) THEN
        CREATE POLICY profiles_owner_insert
            ON public.profiles
            FOR INSERT
            WITH CHECK (user_id = public.auth_uid());
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_owner_insert'
    ) THEN
        EXECUTE $$COMMENT ON POLICY profiles_owner_insert ON public.profiles IS 'mig:01_auth_profiles_init | restrict profile creation to authenticated owner'$$;
    END IF;
END;
$$;

-- Owner update policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_owner_update'
    ) THEN
        CREATE POLICY profiles_owner_update
            ON public.profiles
            FOR UPDATE
            USING (user_id = public.auth_uid())
            WITH CHECK (user_id = public.auth_uid());
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_owner_update'
    ) THEN
        EXECUTE $$COMMENT ON POLICY profiles_owner_update ON public.profiles IS 'mig:01_auth_profiles_init | allow owners to modify their profile'$$;
    END IF;
END;
$$;

-- Admin override policy (covers all commands)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_admin_all'
    ) THEN
        CREATE POLICY profiles_admin_all
            ON public.profiles
            USING (public.is_admin())
            WITH CHECK (public.is_admin());
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'profiles_admin_all'
    ) THEN
        EXECUTE $$COMMENT ON POLICY profiles_admin_all ON public.profiles IS 'mig:01_auth_profiles_init | grant admins full access to profiles'$$;
    END IF;
END;
$$;

COMMIT;

-- Verification queries
-- Objects tagged to this migration
WITH tag AS (SELECT 'mig:01_auth_profiles_init' AS t)
SELECT 'tables' AS kind, n.nspname AS schema, c.relname, obj_description(c.oid,'pg_class') AS comment
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace, tag
WHERE c.relkind='r' AND obj_description(c.oid,'pg_class') LIKE (tag.t || '%')
UNION ALL
SELECT 'functions', n.nspname, p.proname, obj_description(p.oid,'pg_proc')
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace, tag
WHERE obj_description(p.oid,'pg_proc') LIKE (tag.t || '%')
UNION ALL
SELECT 'triggers', n.nspname, t.tgname, d.description
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_description d ON d.objoid = t.oid, tag
WHERE obj_description(c.oid,'pg_class') LIKE (tag.t || '%')
ORDER BY kind, schema;

-- RLS flag
SELECT relname, relrowsecurity AS rls_enabled
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND relname IN ('profiles');

-- Policies on profiles
SELECT * FROM pg_policies WHERE schemaname='public' AND tablename='profiles';

-- Grants on profiles
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema='public' AND table_name='profiles'
ORDER BY grantee, privilege_type;

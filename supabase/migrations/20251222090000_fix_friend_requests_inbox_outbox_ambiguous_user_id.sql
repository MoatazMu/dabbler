-- Fix ambiguous column references in friend request RPCs.
--
-- In PL/pgSQL functions using RETURNS TABLE, output column names become
-- variables in scope. Unqualified references like `user_id` can become
-- ambiguous (variable vs table column). Qualify column references.

CREATE OR REPLACE FUNCTION rpc_friend_requests_inbox()
RETURNS TABLE (
  user_id UUID,
  peer_user_id UUID,
  requested_by UUID,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  peer_profile JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_my_profile_id UUID;
BEGIN
  -- Get current user's profile ID
  SELECT p.user_id INTO v_my_profile_id
  FROM profiles p
  WHERE p.user_id = auth.uid()
  LIMIT 1;

  IF v_my_profile_id IS NULL THEN
    RAISE EXCEPTION 'Profile not found for current user';
  END IF;

  RETURN QUERY
  SELECT
    f.user_id,
    f.peer_user_id,
    f.requested_by,
    f.status,
    f.created_at,
    f.updated_at,
    jsonb_build_object(
      'user_id', p.user_id,
      'display_name', p.display_name,
      'avatar_url', p.avatar_url,
      'username', p.username
    ) AS peer_profile
  FROM friendships f
  LEFT JOIN profiles p ON p.user_id = f.user_id
  WHERE f.peer_user_id = v_my_profile_id
    AND f.status = 'pending'
    AND f.requested_by != v_my_profile_id
  ORDER BY f.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION rpc_friend_requests_outbox()
RETURNS TABLE (
  user_id UUID,
  peer_user_id UUID,
  requested_by UUID,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  peer_profile JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_my_profile_id UUID;
BEGIN
  -- Get current user's profile ID
  SELECT p.user_id INTO v_my_profile_id
  FROM profiles p
  WHERE p.user_id = auth.uid()
  LIMIT 1;

  IF v_my_profile_id IS NULL THEN
    RAISE EXCEPTION 'Profile not found for current user';
  END IF;

  RETURN QUERY
  SELECT
    f.user_id,
    f.peer_user_id,
    f.requested_by,
    f.status,
    f.created_at,
    f.updated_at,
    jsonb_build_object(
      'user_id', p.user_id,
      'display_name', p.display_name,
      'avatar_url', p.avatar_url,
      'username', p.username
    ) AS peer_profile
  FROM friendships f
  LEFT JOIN profiles p ON p.user_id = f.peer_user_id
  WHERE f.user_id = v_my_profile_id
    AND f.status = 'pending'
    AND f.requested_by = v_my_profile_id
  ORDER BY f.created_at DESC;
END;
$$;

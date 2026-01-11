-- Fix incorrect parameter references in friend request RPCs.
--
-- Symptoms:
-- - Calling rpc_friend_request_send(p_peer_profile_id := ...) fails with:
--   "column \"p_peer\" does not exist"
--
-- Root cause:
-- - The function body referenced `p_peer` (non-existent identifier) instead of
--   the actual parameter name `p_peer_profile_id`.

CREATE OR REPLACE FUNCTION rpc_friend_request_send(p_peer_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_my_profile_id UUID;
  v_user_id UUID;
  v_peer_user_id UUID;
BEGIN
  -- Get current user's profile ID
  SELECT user_id INTO v_my_profile_id
  FROM profiles
  WHERE user_id = auth.uid()
  LIMIT 1;

  IF v_my_profile_id IS NULL THEN
    RAISE EXCEPTION 'Profile not found for current user';
  END IF;

  -- Ensure correct ordering: user_id < peer_user_id to satisfy check constraint
  IF v_my_profile_id < p_peer_profile_id THEN
    v_user_id := v_my_profile_id;
    v_peer_user_id := p_peer_profile_id;
  ELSE
    v_user_id := p_peer_profile_id;
    v_peer_user_id := v_my_profile_id;
  END IF;

  -- Insert friendship request between profiles with correct ordering
  INSERT INTO friendships (user_id, peer_user_id, requested_by, status, created_at, updated_at)
  VALUES (v_user_id, v_peer_user_id, v_my_profile_id, 'pending', NOW(), NOW())
  ON CONFLICT (user_id, peer_user_id) DO UPDATE
  SET status = 'pending', requested_by = v_my_profile_id, updated_at = NOW();

  -- Create notification for the receiver
  INSERT INTO notifications (to_user_id, kind_key, title, body, context, created_at)
  VALUES (
    p_peer_profile_id,
    'social.friend_request',
    'New Friend Request',
    'Someone sent you a friend request',
    jsonb_build_object('from_user_id', v_my_profile_id),
    NOW()
  );
END;
$$;

CREATE OR REPLACE FUNCTION rpc_friend_request_reject(p_peer_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_my_profile_id UUID;
  v_user_id UUID;
  v_peer_user_id UUID;
BEGIN
  -- Get current user's profile ID
  SELECT user_id INTO v_my_profile_id
  FROM profiles
  WHERE user_id = auth.uid()
  LIMIT 1;

  IF v_my_profile_id IS NULL THEN
    RAISE EXCEPTION 'Profile not found for current user';
  END IF;

  -- Determine correct ordering
  IF v_my_profile_id < p_peer_profile_id THEN
    v_user_id := v_my_profile_id;
    v_peer_user_id := p_peer_profile_id;
  ELSE
    v_user_id := p_peer_profile_id;
    v_peer_user_id := v_my_profile_id;
  END IF;

  -- Delete friendship
  DELETE FROM friendships
  WHERE user_id = v_user_id AND peer_user_id = v_peer_user_id;
END;
$$;

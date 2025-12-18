-- Create RPC functions for friend requests

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS rpc_friend_request_send(UUID);
DROP FUNCTION IF EXISTS rpc_friend_request_accept(UUID);
DROP FUNCTION IF EXISTS rpc_friend_request_reject(UUID);
DROP FUNCTION IF EXISTS rpc_friend_remove(UUID);
DROP FUNCTION IF EXISTS rpc_friend_unfriend(UUID);
DROP FUNCTION IF EXISTS rpc_friend_requests_inbox();
DROP FUNCTION IF EXISTS rpc_friend_requests_outbox();
DROP FUNCTION IF EXISTS rpc_block_user(UUID);
DROP FUNCTION IF EXISTS rpc_unblock_user(UUID);

-- Function to send friend request
-- p_peer_profile_id is the peer profile ID (not user ID)
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
    p_peer,
    'social.friend_request',
    'New Friend Request',
    'Someone sent you a friend request',
    jsonb_build_object('from_user_id', v_my_profile_id),
    NOW()
  );
END;
$$;

-- Function to accept friend request
-- p_peer_profile_id is the peer profile ID
CREATE OR REPLACE FUNCTION rpc_friend_request_accept(p_peer_profile_id UUID)
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
  
  -- Update friendship status to accepted
  UPDATE friendships
  SET status = 'accepted', updated_at = NOW()
  WHERE user_id = v_user_id AND peer_user_id = v_peer_user_id;
  
  -- Create notification for the requester (the person who sent the friend request)
  -- The requester is whoever is NOT the current user
  INSERT INTO notifications (to_user_id, kind_key, title, body, context, created_at)
  VALUES (
    p_peer_profile_id,
    'social.friend_accepted',
    'Friend Request Accepted',
    'Your friend request was accepted',
    jsonb_build_object('from_user_id', v_my_profile_id),
    NOW()
  );
END;
$$;

-- Function to reject friend request
-- p_peer_profile_id is the peer profile ID
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
  IF v_my_profile_id < p_peer THEN
    v_user_id := v_my_profile_id;
    v_peer_user_id := p_peer;
  ELSE
    v_user_id := p_peer;
    v_peer_user_id := v_my_profile_id;
  END IF;
  
  -- Delete friendship
  DELETE FROM friendships
  WHERE user_id = v_user_id AND peer_user_id = v_peer_user_id;
END;
$$;

-- Function to remove friend (unfriend)
-- p_peer_profile_id is the peer profile ID
CREATE OR REPLACE FUNCTION rpc_friend_remove(p_peer_profile_id UUID)
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

-- Alternative function name for compatibility
-- p_peer is the peer profile ID
CREATE OR REPLACE FUNCTION rpc_friend_unfriend(p_peer UUID)
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
  IF v_my_profile_id < p_peer THEN
    v_user_id := v_my_profile_id;
    v_peer_user_id := p_peer;
  ELSE
    v_user_id := p_peer;
    v_peer_user_id := v_my_profile_id;
  END IF;
  
  -- Delete friendship
  DELETE FROM friendships
  WHERE user_id = v_user_id AND peer_user_id = v_peer_user_id;
END;
$$;

-- Function to get inbox (incoming friend requests)
-- Returns friend requests sent TO current user's profile
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
  SELECT user_id INTO v_my_profile_id
  FROM profiles
  WHERE user_id = auth.uid()
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
  WHERE f.peer_user_id = v_my_profile_id AND f.status = 'pending' AND f.requested_by != v_my_profile_id
  ORDER BY f.created_at DESC;
END;
$$;

-- Function to get outbox (outgoing friend requests)
-- Returns friend requests sent FROM current user's profile
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
  SELECT user_id INTO v_my_profile_id
  FROM profiles
  WHERE user_id = auth.uid()
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
  WHERE f.user_id = v_my_profile_id AND f.status = 'pending' AND f.requested_by = v_my_profile_id
  ORDER BY f.created_at DESC;
END;
$$;

-- Function to block user
-- p_peer is the peer profile ID to block
CREATE OR REPLACE FUNCTION rpc_block_user(p_peer UUID)
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
  
  -- Insert into blocks table (assuming it exists)
  INSERT INTO blocks (blocker_id, blocked_id, created_at)
  VALUES (v_my_profile_id, p_peer, NOW())
  ON CONFLICT (blocker_id, blocked_id) DO NOTHING;
  
  -- Determine correct ordering
  IF v_my_profile_id < p_peer THEN
    v_user_id := v_my_profile_id;
    v_peer_user_id := p_peer;
  ELSE
    v_user_id := p_peer;
    v_peer_user_id := v_my_profile_id;
  END IF;
  
  -- Remove any existing friendship
  DELETE FROM friendships
  WHERE user_id = v_user_id AND peer_user_id = v_peer_user_id;
END;
$$;

-- Function to unblock user
-- p_peer is the peer profile ID to unblock
CREATE OR REPLACE FUNCTION rpc_unblock_user(p_peer UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_my_profile_id UUID;
BEGIN
  -- Get current user's profile ID
  SELECT user_id INTO v_my_profile_id
  FROM profiles
  WHERE user_id = auth.uid()
  LIMIT 1;
  
  IF v_my_profile_id IS NULL THEN
    RAISE EXCEPTION 'Profile not found for current user';
  END IF;
  
  -- Remove from blocks table
  DELETE FROM blocks
  WHERE blocker_id = v_my_profile_id AND blocked_id = p_peer;
END;
$$;

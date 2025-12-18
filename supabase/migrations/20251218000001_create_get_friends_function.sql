-- Create function to get friends list with profile information
-- Returns accepted friendships with joined profile data

CREATE OR REPLACE FUNCTION public.rpc_get_friends(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
  user_id UUID,
  display_name TEXT,
  avatar_url TEXT,
  username TEXT,
  verified BOOLEAN,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Use provided user_id or current authenticated user
  v_user_id := COALESCE(p_user_id, auth.uid());
  
  -- Check if user is authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Get all accepted friendships where the user is involved
  -- and join with profiles to get friend information
  RETURN QUERY
  SELECT 
    p.user_id,
    p.display_name,
    p.avatar_url,
    p.username,
    COALESCE(p.verified, false) as verified,
    f.created_at
  FROM friendships f
  INNER JOIN profiles p ON (
    CASE 
      WHEN f.user_id = v_user_id THEN p.user_id = f.peer_user_id
      WHEN f.peer_user_id = v_user_id THEN p.user_id = f.user_id
      ELSE FALSE
    END
  )
  WHERE 
    (f.user_id = v_user_id OR f.peer_user_id = v_user_id)
    AND f.status = 'accepted'
  ORDER BY f.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.rpc_get_friends(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.rpc_get_friends IS 
'Returns list of accepted friends with profile information for the authenticated user or specified user';

-- Function to get friend suggestions based on mutual friends
CREATE OR REPLACE FUNCTION rpc_get_friend_suggestions(
  p_user_id UUID DEFAULT auth.uid(),
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  username TEXT,
  avatar_url TEXT,
  bio TEXT,
  mutual_friends_count INTEGER,
  mutual_friend_ids UUID[]
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH user_friends AS (
    -- Get all friends of the current user
    SELECT 
      CASE 
        WHEN f.user_id = p_user_id THEN f.peer_user_id
        ELSE f.user_id
      END AS friend_id
    FROM friendships f
    WHERE (f.user_id = p_user_id OR f.peer_user_id = p_user_id)
      AND f.status = 'accepted'
  ),
  potential_friends AS (
    -- Get friends of friends who are not already friends
    SELECT 
      CASE 
        WHEN f.user_id = uf.friend_id THEN f.peer_user_id
        ELSE f.user_id
      END AS suggested_user_id,
      uf.friend_id AS mutual_friend_id
    FROM friendships f
    INNER JOIN user_friends uf ON (f.user_id = uf.friend_id OR f.peer_user_id = uf.friend_id)
    WHERE f.status = 'accepted'
      AND CASE 
        WHEN f.user_id = uf.friend_id THEN f.peer_user_id
        ELSE f.user_id
      END != p_user_id  -- Not the current user
      AND CASE 
        WHEN f.user_id = uf.friend_id THEN f.peer_user_id
        ELSE f.user_id
      END NOT IN (SELECT friend_id FROM user_friends)  -- Not already a friend
  ),
  suggestion_counts AS (
    SELECT 
      pf.suggested_user_id,
      COUNT(DISTINCT pf.mutual_friend_id) AS mutual_count,
      ARRAY_AGG(DISTINCT pf.mutual_friend_id) AS mutual_ids
    FROM potential_friends pf
    WHERE NOT EXISTS (
      -- Exclude if there's any pending request in either direction
      SELECT 1 FROM friendships f2
      WHERE ((f2.user_id = p_user_id AND f2.peer_user_id = pf.suggested_user_id)
         OR (f2.user_id = pf.suggested_user_id AND f2.peer_user_id = p_user_id))
        AND f2.status IN ('pending', 'blocked')
    )
    GROUP BY pf.suggested_user_id
  )
  SELECT 
    p.id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.bio,
    sc.mutual_count::INTEGER,
    sc.mutual_ids
  FROM suggestion_counts sc
  INNER JOIN profiles p ON p.id = sc.suggested_user_id
  ORDER BY sc.mutual_count DESC, p.full_name ASC
  LIMIT p_limit;
END;
$$;

-- Function to search users (for friend search)
CREATE OR REPLACE FUNCTION rpc_search_users(
  p_query TEXT,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  username TEXT,
  avatar_url TEXT,
  bio TEXT,
  is_friend BOOLEAN,
  has_pending_request BOOLEAN
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_current_user_id UUID := auth.uid();
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.bio,
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE ((f.user_id = v_current_user_id AND f.peer_user_id = p.id)
         OR (f.user_id = p.id AND f.peer_user_id = v_current_user_id))
        AND f.status = 'accepted'
    ) AS is_friend,
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE ((f.user_id = v_current_user_id AND f.peer_user_id = p.id)
         OR (f.user_id = p.id AND f.peer_user_id = v_current_user_id))
        AND f.status = 'pending'
    ) AS has_pending_request
  FROM profiles p
  WHERE p.id != v_current_user_id
    AND (
      p.full_name ILIKE '%' || p_query || '%'
      OR p.username ILIKE '%' || p_query || '%'
    )
  ORDER BY 
    -- Prioritize exact username matches
    CASE WHEN p.username ILIKE p_query THEN 0 ELSE 1 END,
    -- Then by name similarity
    p.full_name ASC
  LIMIT p_limit;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION rpc_get_friend_suggestions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION rpc_search_users(TEXT, INTEGER) TO authenticated;

-- Fix friend suggestions + user search functions to match current profiles schema.
-- profiles has `display_name` (NOT `full_name`).

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
      END != p_user_id
      AND CASE
        WHEN f.user_id = uf.friend_id THEN f.peer_user_id
        ELSE f.user_id
      END NOT IN (SELECT friend_id FROM user_friends)
  ),
  suggestion_counts AS (
    SELECT
      pf.suggested_user_id,
      COUNT(DISTINCT pf.mutual_friend_id) AS mutual_count,
      ARRAY_AGG(DISTINCT pf.mutual_friend_id) AS mutual_ids
    FROM potential_friends pf
    WHERE NOT EXISTS (
      SELECT 1 FROM friendships f2
      WHERE ((f2.user_id = p_user_id AND f2.peer_user_id = pf.suggested_user_id)
         OR (f2.user_id = pf.suggested_user_id AND f2.peer_user_id = p_user_id))
        AND f2.status IN ('pending', 'blocked')
    )
    GROUP BY pf.suggested_user_id
  )
  SELECT
    p.id,
    -- Backward-compatible output column name.
    p.display_name,
    p.username,
    p.avatar_url,
    p.bio,
    sc.mutual_count::INTEGER,
    sc.mutual_ids
  FROM suggestion_counts sc
  INNER JOIN profiles p ON p.id = sc.suggested_user_id
  ORDER BY sc.mutual_count DESC, p.display_name ASC
  LIMIT p_limit;
END;
$$;

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
    -- Backward-compatible output column name.
    p.display_name,
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
      p.display_name ILIKE '%' || p_query || '%'
      OR p.username ILIKE '%' || p_query || '%'
    )
  ORDER BY
    CASE WHEN p.username ILIKE p_query THEN 0 ELSE 1 END,
    p.display_name ASC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION rpc_get_friend_suggestions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION rpc_search_users(TEXT, INTEGER) TO authenticated;

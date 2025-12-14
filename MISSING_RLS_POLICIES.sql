-- ============================================================================
-- RLS Policies for Posts, Comments, and Related Tables
-- ============================================================================
-- Apply these manually to your Supabase database
-- This script will drop existing policies and recreate them
-- Check existing policies first with:
-- SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public';

-- ============================================================================
-- DROP EXISTING POLICIES (if any)
-- ============================================================================

-- Posts policies
DROP POLICY IF EXISTS "posts_select_public" ON public.posts;
DROP POLICY IF EXISTS "posts_select_own" ON public.posts;
DROP POLICY IF EXISTS "posts_select_circle" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_own" ON public.posts;
DROP POLICY IF EXISTS "posts_update_own" ON public.posts;
DROP POLICY IF EXISTS "posts_delete_own" ON public.posts;

-- Comments policies
DROP POLICY IF EXISTS "comments_select_visible_posts" ON public.post_comments;
DROP POLICY IF EXISTS "comments_insert_on_visible_posts" ON public.post_comments;
DROP POLICY IF EXISTS "comments_update_own" ON public.post_comments;
DROP POLICY IF EXISTS "comments_delete_own" ON public.post_comments;

-- Likes policies
DROP POLICY IF EXISTS "post_likes_select_visible" ON public.post_likes;
DROP POLICY IF EXISTS "post_likes_insert_own" ON public.post_likes;
DROP POLICY IF EXISTS "post_likes_delete_own" ON public.post_likes;
DROP POLICY IF EXISTS "comment_likes_select_visible" ON public.comment_likes;
DROP POLICY IF EXISTS "comment_likes_insert_own" ON public.comment_likes;
DROP POLICY IF EXISTS "comment_likes_delete_own" ON public.comment_likes;

-- Vibes and reactions policies
DROP POLICY IF EXISTS "post_vibes_select_all" ON public.post_vibes;
DROP POLICY IF EXISTS "post_vibes_insert_author" ON public.post_vibes;
DROP POLICY IF EXISTS "post_vibes_delete_author" ON public.post_vibes;
DROP POLICY IF EXISTS "post_reactions_select_visible" ON public.post_reactions;
DROP POLICY IF EXISTS "post_reactions_insert_own" ON public.post_reactions;
DROP POLICY IF EXISTS "post_reactions_delete_own" ON public.post_reactions;

-- Mentions policies
DROP POLICY IF EXISTS "post_mentions_select_all" ON public.post_mentions;
DROP POLICY IF EXISTS "post_mentions_insert_author" ON public.post_mentions;
DROP POLICY IF EXISTS "comment_mentions_select_all" ON public.comment_mentions;
DROP POLICY IF EXISTS "comment_mentions_insert_author" ON public.comment_mentions;

-- Hides policies
DROP POLICY IF EXISTS "post_hides_select_own" ON public.post_hides;
DROP POLICY IF EXISTS "post_hides_insert_own" ON public.post_hides;
DROP POLICY IF EXISTS "post_hides_delete_own" ON public.post_hides;

-- Reference data policies
DROP POLICY IF EXISTS "vibes_select_all" ON public.vibes;
DROP POLICY IF EXISTS "location_tags_select_all" ON public.location_tags;

-- ============================================================================
-- POSTS TABLE
-- ============================================================================

-- Allow public read access for public posts
CREATE POLICY "posts_select_public" ON public.posts
FOR SELECT
USING (
  visibility = 'public' 
  AND is_deleted = false 
  AND is_hidden_admin = false
);

-- Allow users to see their own posts
CREATE POLICY "posts_select_own" ON public.posts
FOR SELECT
USING (auth.uid() = author_user_id);

-- Allow users to see circle posts from friends
CREATE POLICY "posts_select_circle" ON public.posts
FOR SELECT
USING (
  visibility = 'circle'
  AND is_deleted = false
  AND is_hidden_admin = false
  AND EXISTS (
    SELECT 1 FROM friendships
    WHERE (
      (user_id = auth.uid() AND peer_user_id = author_user_id)
      OR (peer_user_id = auth.uid() AND user_id = author_user_id)
    )
    AND status = 'accepted'
  )
);

-- Allow users to create posts
CREATE POLICY "posts_insert_own" ON public.posts
FOR INSERT
WITH CHECK (auth.uid() = author_user_id);

-- Allow users to update their own posts
CREATE POLICY "posts_update_own" ON public.posts
FOR UPDATE
USING (auth.uid() = author_user_id)
WITH CHECK (auth.uid() = author_user_id);

-- Allow users to delete their own posts
CREATE POLICY "posts_delete_own" ON public.posts
FOR DELETE
USING (auth.uid() = author_user_id);

-- ============================================================================
-- POST_COMMENTS TABLE
-- ============================================================================

-- Allow read access to comments on visible posts
CREATE POLICY "comments_select_visible_posts" ON public.post_comments
FOR SELECT
USING (
  is_deleted = false 
  AND is_hidden_admin = false
  AND EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_comments.post_id
    AND (
      posts.visibility = 'public'
      OR posts.author_user_id = auth.uid()
      OR (
        posts.visibility = 'circle'
        AND EXISTS (
          SELECT 1 FROM friendships
          WHERE (
            (user_id = auth.uid() AND peer_user_id = posts.author_user_id)
            OR (peer_user_id = auth.uid() AND user_id = posts.author_user_id)
          )
          AND status = 'accepted'
        )
      )
    )
  )
);

-- Allow users to create comments on visible posts
CREATE POLICY "comments_insert_on_visible_posts" ON public.post_comments
FOR INSERT
WITH CHECK (
  auth.uid() = author_user_id
  AND EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_comments.post_id
    AND (
      posts.visibility = 'public'
      OR posts.author_user_id = auth.uid()
      OR (
        posts.visibility = 'circle'
        AND EXISTS (
          SELECT 1 FROM friendships
          WHERE (
            (user_id = auth.uid() AND peer_user_id = posts.author_user_id)
            OR (peer_user_id = auth.uid() AND user_id = posts.author_user_id)
          )
          AND status = 'accepted'
        )
      )
    )
  )
);

-- Allow users to update their own comments
CREATE POLICY "comments_update_own" ON public.post_comments
FOR UPDATE
USING (auth.uid() = author_user_id)
WITH CHECK (auth.uid() = author_user_id);

-- Allow users to delete their own comments
CREATE POLICY "comments_delete_own" ON public.post_comments
FOR DELETE
USING (auth.uid() = author_user_id);

-- ============================================================================
-- POST_LIKES TABLE
-- ============================================================================

-- Allow users to see likes on visible posts
CREATE POLICY "post_likes_select_visible" ON public.post_likes
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_likes.post_id
    AND (
      posts.visibility = 'public'
      OR posts.author_user_id = auth.uid()
      OR (
        posts.visibility = 'circle'
        AND EXISTS (
          SELECT 1 FROM friendships
          WHERE (
            (user_id = auth.uid() AND peer_user_id = posts.author_user_id)
            OR (peer_user_id = auth.uid() AND user_id = posts.author_user_id)
          )
          AND status = 'accepted'
        )
      )
    )
  )
);

-- Allow users to like visible posts
CREATE POLICY "post_likes_insert_own" ON public.post_likes
FOR INSERT
WITH CHECK (
  auth.uid() = user_id
  AND EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_likes.post_id
    AND (
      posts.visibility = 'public'
      OR (
        posts.visibility = 'circle'
        AND EXISTS (
          SELECT 1 FROM friendships
          WHERE (
            (user_id = auth.uid() AND peer_user_id = posts.author_user_id)
            OR (peer_user_id = auth.uid() AND user_id = posts.author_user_id)
          )
          AND status = 'accepted'
        )
      )
    )
  )
);

-- Allow users to remove their own likes
CREATE POLICY "post_likes_delete_own" ON public.post_likes
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- COMMENT_LIKES TABLE
-- ============================================================================

-- Allow users to see likes on comments they can see
CREATE POLICY "comment_likes_select_visible" ON public.comment_likes
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM post_comments
    WHERE post_comments.id = comment_likes.comment_id
    AND post_comments.is_deleted = false
    AND EXISTS (
      SELECT 1 FROM posts
      WHERE posts.id = post_comments.post_id
      AND (
        posts.visibility = 'public'
        OR posts.author_user_id = auth.uid()
      )
    )
  )
);

-- Allow users to like comments
CREATE POLICY "comment_likes_insert_own" ON public.comment_likes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow users to remove their own likes
CREATE POLICY "comment_likes_delete_own" ON public.comment_likes
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- POST_VIBES TABLE
-- ============================================================================

-- Allow public read access
CREATE POLICY "post_vibes_select_all" ON public.post_vibes
FOR SELECT
USING (true);

-- Allow post authors to manage vibes
CREATE POLICY "post_vibes_insert_author" ON public.post_vibes
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_vibes.post_id
    AND posts.author_user_id = auth.uid()
  )
);

CREATE POLICY "post_vibes_delete_author" ON public.post_vibes
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_vibes.post_id
    AND posts.author_user_id = auth.uid()
  )
);

-- ============================================================================
-- POST_REACTIONS TABLE
-- ============================================================================

-- Allow users to see reactions on visible posts
CREATE POLICY "post_reactions_select_visible" ON public.post_reactions
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_reactions.post_id
    AND (posts.visibility = 'public' OR posts.author_user_id = auth.uid())
  )
);

-- Allow users to add reactions
CREATE POLICY "post_reactions_insert_own" ON public.post_reactions
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = post_reactions.actor_profile_id
    AND profiles.user_id = auth.uid()
  )
);

-- Allow users to remove their own reactions
CREATE POLICY "post_reactions_delete_own" ON public.post_reactions
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = post_reactions.actor_profile_id
    AND profiles.user_id = auth.uid()
  )
);

-- ============================================================================
-- POST_MENTIONS TABLE
-- ============================================================================

-- Allow public read access
CREATE POLICY "post_mentions_select_all" ON public.post_mentions
FOR SELECT
USING (true);

-- Allow post authors to mention users
CREATE POLICY "post_mentions_insert_author" ON public.post_mentions
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM posts
    WHERE posts.id = post_mentions.post_id
    AND posts.author_user_id = auth.uid()
  )
);

-- ============================================================================
-- COMMENT_MENTIONS TABLE
-- ============================================================================

-- Allow public read access
CREATE POLICY "comment_mentions_select_all" ON public.comment_mentions
FOR SELECT
USING (true);

-- Allow comment authors to mention users
CREATE POLICY "comment_mentions_insert_author" ON public.comment_mentions
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM post_comments
    WHERE post_comments.id = comment_mentions.comment_id
    AND post_comments.author_user_id = auth.uid()
  )
);

-- ============================================================================
-- POST_HIDES TABLE
-- ============================================================================

-- Allow users to see their own hidden posts
CREATE POLICY "post_hides_select_own" ON public.post_hides
FOR SELECT
USING (auth.uid() = owner_user_id);

-- Allow users to hide posts
CREATE POLICY "post_hides_insert_own" ON public.post_hides
FOR INSERT
WITH CHECK (auth.uid() = owner_user_id);

-- Allow users to unhide posts
CREATE POLICY "post_hides_delete_own" ON public.post_hides
FOR DELETE
USING (auth.uid() = owner_user_id);

-- ============================================================================
-- VIBES TABLE (read-only reference data)
-- ============================================================================

CREATE POLICY "vibes_select_all" ON public.vibes
FOR SELECT
USING (is_active = true);

-- ============================================================================
-- LOCATION_TAGS TABLE (read-only reference data)
-- ============================================================================

CREATE POLICY "location_tags_select_all" ON public.location_tags
FOR SELECT
USING (true);

-- ============================================================================
-- Enable RLS on all tables
-- ============================================================================

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_vibes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_mentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_mentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_hides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vibes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_tags ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- NOTES:
-- ============================================================================
-- 1. These policies assume you have a 'friendships' table with:
--    - requester_user_id, target_user_id columns
--    - status column with 'accepted' value for confirmed friendships
--
-- 2. Adjust the circle/friends visibility logic if your app uses a different
--    friends/circle model
--
-- 3. Test each policy after applying to ensure it works as expected
--
-- 4. For production, consider more granular policies (e.g., separate policies
--    for link-sharing visibility)
-- ============================================================================

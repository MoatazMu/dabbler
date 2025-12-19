-- Add notification support for post likes

-- Insert notification kind for post likes
INSERT INTO notification_kinds (key, label_en, label_ar)
VALUES ('social.post_liked', 'Post Liked', 'إعجاب بالمنشور')
ON CONFLICT (key) DO NOTHING;

-- Function to create notification when someone likes a post
CREATE OR REPLACE FUNCTION notify_post_like()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_post_author_id UUID;
  v_liker_profile profiles;
BEGIN
  -- Get the post author's user_id
  SELECT author_user_id INTO v_post_author_id
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Don't notify if user likes their own post
  IF v_post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Get liker's profile info for notification body
  SELECT * INTO v_liker_profile
  FROM profiles
  WHERE user_id = NEW.user_id
  LIMIT 1;
  
  -- Upsert notification: update existing or create new
  -- If same user likes the same post again, refresh notification (mark unread, update timestamp)
  INSERT INTO notifications (
    to_user_id,
    kind_key,
    title,
    body,
    context,
    action_route,
    created_at,
    is_read
  )
  VALUES (
    v_post_author_id,
    'social.post_liked',
    'New Like',
    COALESCE(v_liker_profile.display_name, 'Someone') || ' liked your post',
    jsonb_build_object(
      'liker_user_id', NEW.user_id,
      'post_id', NEW.post_id,
      'liker_profile_id', NEW.profile_id
    ),
    '/social-post-detail/' || NEW.post_id,
    NOW(),
    false
  )
  ON CONFLICT (to_user_id, kind_key, (context->>'liker_user_id'), (context->>'post_id'))
  DO UPDATE SET
    created_at = NOW(),
    is_read = false,
    body = COALESCE((SELECT display_name FROM profiles WHERE user_id = NEW.user_id LIMIT 1), 'Someone') || ' liked your post';
  
  RETURN NEW;
END;
$$;

-- Create trigger on post_likes INSERT
DROP TRIGGER IF EXISTS trigger_notify_post_like ON post_likes;
CREATE TRIGGER trigger_notify_post_like
  AFTER INSERT ON post_likes
  FOR EACH ROW
  EXECUTE FUNCTION notify_post_like();

-- Update existing notifications with old route format
UPDATE notifications
SET action_route = REPLACE(action_route, '/post/', '/social-post-detail/')
WHERE kind_key = 'social.post_liked'
  AND action_route LIKE '/post/%';

-- Add unique constraint on post_likes to enable upsert in app code
-- This prevents duplicate likes from same user on same post
DO $$
BEGIN
  -- Check if constraint already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'post_likes_post_id_user_id_key'
  ) THEN
    -- Remove any duplicate likes first
    DELETE FROM post_likes
    WHERE (post_id, user_id, created_at) IN (
      SELECT post_id, user_id, created_at
      FROM (
        SELECT 
          post_id,
          user_id,
          created_at,
          ROW_NUMBER() OVER (PARTITION BY post_id, user_id ORDER BY created_at DESC) as rn
        FROM post_likes
      ) t
      WHERE rn > 1
    );
    
    -- Add unique constraint
    ALTER TABLE post_likes ADD CONSTRAINT post_likes_post_id_user_id_key UNIQUE (post_id, user_id);
  END IF;
END $$;

-- Remove duplicate notifications, keeping only the most recent one per liker+post combination
DELETE FROM notifications
WHERE id IN (
  SELECT id
  FROM (
    SELECT 
      id,
      ROW_NUMBER() OVER (
        PARTITION BY to_user_id, kind_key, (context->>'liker_user_id'), (context->>'post_id')
        ORDER BY created_at DESC
      ) as rn
    FROM notifications
    WHERE kind_key = 'social.post_liked'
  ) t
  WHERE rn > 1
);

-- Create unique constraint to prevent duplicate notifications for same liker+post
-- This allows UPSERT to work properly
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_post_like_unique
ON notifications (
  to_user_id,
  kind_key,
  (context->>'liker_user_id'),
  (context->>'post_id')
)
WHERE kind_key = 'social.post_liked';

-- Enable realtime for notifications table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  END IF;
END $$;

-- Add comment for documentation
COMMENT ON FUNCTION notify_post_like() IS 'Creates a notification when someone likes a post (except self-likes)';
COMMENT ON TRIGGER trigger_notify_post_like ON post_likes IS 'Triggers notification creation when a post is liked';

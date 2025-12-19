-- Add notification support for comments and comment likes

-- Insert notification kinds
INSERT INTO notification_kinds (key, label_en, label_ar)
VALUES 
  ('social.post_commented', 'New Comment', 'تعليق جديد'),
  ('social.comment_liked', 'Comment Liked', 'إعجاب بالتعليق')
ON CONFLICT (key) DO NOTHING;

-- Function to create notification when someone comments on a post
CREATE OR REPLACE FUNCTION notify_post_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_post_author_id UUID;
  v_commenter_profile profiles;
BEGIN
  -- Get the post author's user_id
  SELECT author_user_id INTO v_post_author_id
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Don't notify if user comments on their own post
  IF v_post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Get commenter's profile info
  SELECT * INTO v_commenter_profile
  FROM profiles
  WHERE user_id = NEW.user_id
  LIMIT 1;
  
  -- Delete existing notification for this commenter+post combination (refresh if they comment again)
  DELETE FROM notifications
  WHERE to_user_id = v_post_author_id
    AND kind_key = 'social.post_commented'
    AND (context->>'commenter_user_id') = NEW.user_id::text
    AND (context->>'post_id') = NEW.post_id::text;
  
  -- Insert fresh notification
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
    'social.post_commented',
    'New Comment',
    COALESCE(v_commenter_profile.display_name, 'Someone') || ' commented on your post',
    jsonb_build_object(
      'commenter_user_id', NEW.user_id,
      'post_id', NEW.post_id,
      'comment_id', NEW.id,
      'commenter_profile_id', NEW.profile_id
    ),
    '/social-post-detail/' || NEW.post_id,
    NOW(),
    false
  );
  
  RETURN NEW;
END;
$$;

-- Function to create notification when someone likes a comment
CREATE OR REPLACE FUNCTION notify_comment_like()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_comment_author_id UUID;
  v_liker_profile profiles;
  v_comment_post_id UUID;
BEGIN
  -- Get the comment author's user_id and post_id
  SELECT user_id, post_id INTO v_comment_author_id, v_comment_post_id
  FROM post_comments
  WHERE id = NEW.comment_id;
  
  -- Don't notify if user likes their own comment
  IF v_comment_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Get liker's profile info
  SELECT * INTO v_liker_profile
  FROM profiles
  WHERE user_id = NEW.user_id
  LIMIT 1;
  
  -- Delete existing notification for this liker+comment combination
  DELETE FROM notifications
  WHERE to_user_id = v_comment_author_id
    AND kind_key = 'social.comment_liked'
    AND (context->>'liker_user_id') = NEW.user_id::text
    AND (context->>'comment_id') = NEW.comment_id::text;
  
  -- Insert fresh notification
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
    v_comment_author_id,
    'social.comment_liked',
    'Comment Liked',
    COALESCE(v_liker_profile.display_name, 'Someone') || ' liked your comment',
    jsonb_build_object(
      'liker_user_id', NEW.user_id,
      'comment_id', NEW.comment_id,
      'post_id', v_comment_post_id,
      'liker_profile_id', NEW.profile_id
    ),
    '/social-post-detail/' || v_comment_post_id,
    NOW(),
    false
  );
  
  RETURN NEW;
END;
$$;

-- Update the post like notification function to use delete-then-insert
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
  
  -- Delete existing notification for this liker+post combination
  DELETE FROM notifications
  WHERE to_user_id = v_post_author_id
    AND kind_key = 'social.post_liked'
    AND (context->>'liker_user_id') = NEW.user_id::text
    AND (context->>'post_id') = NEW.post_id::text;
  
  -- Insert fresh notification
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
  );
  
  RETURN NEW;
END;
$$;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_notify_post_comment ON post_comments;
CREATE TRIGGER trigger_notify_post_comment
  AFTER INSERT ON post_comments
  FOR EACH ROW
  EXECUTE FUNCTION notify_post_comment();

DROP TRIGGER IF EXISTS trigger_notify_comment_like ON comment_likes;
CREATE TRIGGER trigger_notify_comment_like
  AFTER INSERT ON comment_likes
  FOR EACH ROW
  EXECUTE FUNCTION notify_comment_like();

-- Add comments for documentation
COMMENT ON FUNCTION notify_post_comment() IS 'Creates a notification when someone comments on a post (except self-comments)';
COMMENT ON FUNCTION notify_comment_like() IS 'Creates a notification when someone likes a comment (except self-likes)';
COMMENT ON TRIGGER trigger_notify_post_comment ON post_comments IS 'Triggers notification creation when a post is commented';
COMMENT ON TRIGGER trigger_notify_comment_like ON comment_likes IS 'Triggers notification creation when a comment is liked';

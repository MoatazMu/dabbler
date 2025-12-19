-- Function to increment comment_count on posts table
CREATE OR REPLACE FUNCTION increment_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts
  SET comment_count = COALESCE(comment_count, 0) + 1
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement comment_count on posts table
CREATE OR REPLACE FUNCTION decrement_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts
  SET comment_count = GREATEST(COALESCE(comment_count, 0) - 1, 0)
  WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to increment comment_count when a comment is added
DROP TRIGGER IF EXISTS increment_post_comment_count_trigger ON post_comments;
CREATE TRIGGER increment_post_comment_count_trigger
AFTER INSERT ON post_comments
FOR EACH ROW
EXECUTE FUNCTION increment_post_comment_count();

-- Trigger to decrement comment_count when a comment is deleted
DROP TRIGGER IF EXISTS decrement_post_comment_count_trigger ON post_comments;
CREATE TRIGGER decrement_post_comment_count_trigger
AFTER DELETE ON post_comments
FOR EACH ROW
EXECUTE FUNCTION decrement_post_comment_count();

-- Repair existing comment_count values to match actual comment counts
UPDATE posts
SET comment_count = (
  SELECT COUNT(*)
  FROM post_comments
  WHERE post_comments.post_id = posts.id
);

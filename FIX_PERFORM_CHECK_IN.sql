-- =====================================================
-- FIX: Correct perform_check_in Function
-- This fixes the ambiguous column reference error
-- Run this in Supabase SQL Editor
-- =====================================================

CREATE OR REPLACE FUNCTION perform_check_in(
  p_user_id UUID,
  p_device_info JSONB DEFAULT NULL
)
RETURNS TABLE (
  total_days_completed INT,
  streak_count INT,
  is_completed BOOLEAN,
  is_first_check_in_today BOOLEAN
) AS $$
DECLARE
  v_existing_record RECORD;
  v_is_first_today BOOLEAN;
  v_new_total INT;
  v_new_streak INT;
  v_last_check DATE;
  v_today DATE := CURRENT_DATE;
BEGIN
  -- Get existing check-in record
  SELECT 
    uc.user_id,
    uc.total_days_completed,
    uc.streak_count,
    uc.last_check_in
  INTO v_existing_record
  FROM user_check_ins uc
  WHERE uc.user_id = p_user_id;

  -- Check if already checked in today
  IF v_existing_record.last_check_in IS NOT NULL 
     AND DATE(v_existing_record.last_check_in) = v_today THEN
    -- Already checked in today, return current status
    v_is_first_today := FALSE;
    v_new_total := v_existing_record.total_days_completed;
    v_new_streak := v_existing_record.streak_count;
  ELSE
    -- First check-in today
    v_is_first_today := TRUE;
    
    IF v_existing_record.user_id IS NULL THEN
      -- New user, first ever check-in
      v_new_total := 1;
      v_new_streak := 1;
      
      INSERT INTO user_check_ins (
        user_id,
        total_days_completed,
        streak_count,
        last_check_in
      ) VALUES (
        p_user_id,
        v_new_total,
        v_new_streak,
        NOW()
      );
      
      RAISE NOTICE 'First check-in created for user %', p_user_id;
    ELSE
      -- Existing user
      v_last_check := DATE(v_existing_record.last_check_in);
      
      -- Check if streak continues (checked in yesterday)
      IF v_today - v_last_check = 1 THEN
        v_new_streak := v_existing_record.streak_count + 1;
      ELSE
        -- Streak broken, reset to 1
        v_new_streak := 1;
      END IF;
      
      v_new_total := v_existing_record.total_days_completed + 1;
      
      -- Update with explicit column names to avoid ambiguity
      UPDATE user_check_ins uc
      SET 
        total_days_completed = v_new_total,
        streak_count = v_new_streak,
        last_check_in = NOW()
      WHERE uc.user_id = p_user_id;
      
      RAISE NOTICE 'Check-in updated for user %, new total: %, new streak: %', p_user_id, v_new_total, v_new_streak;
    END IF;
    
    -- Log the check-in
    INSERT INTO check_in_logs (
      user_id,
      check_in_date,
      device_info
    ) VALUES (
      p_user_id,
      v_today,
      p_device_info
    );
    
    RAISE NOTICE 'Check-in log created for user % on date %', p_user_id, v_today;
  END IF;

  -- Return result
  RETURN QUERY
  SELECT 
    v_new_total AS total_days_completed,
    v_new_streak AS streak_count,
    (v_new_total >= 14)::BOOLEAN AS is_completed,
    v_is_first_today AS is_first_check_in_today;
    
  RAISE NOTICE 'Returning: total=%, streak=%, completed=%, first_today=%', v_new_total, v_new_streak, (v_new_total >= 14), v_is_first_today;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test it immediately
SELECT 'Testing perform_check_in function...' as test;
SELECT * FROM perform_check_in(auth.uid(), NULL);

-- Check the results
SELECT 'Check-in record:' as label;
SELECT * FROM user_check_ins WHERE user_id = auth.uid();

SELECT 'Check-in logs:' as label;
SELECT * FROM check_in_logs WHERE user_id = auth.uid() ORDER BY check_in_date DESC LIMIT 5;

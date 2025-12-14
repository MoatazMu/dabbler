-- =====================================================
-- CHECK-IN SYSTEM - VERIFICATION AND CREATION SCRIPT
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. VERIFY TABLES EXIST
-- =====================================================
SELECT 'Checking if tables exist...' as step;

SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_check_ins') 
    THEN '✅ user_check_ins table exists'
    ELSE '❌ user_check_ins table MISSING'
  END as user_check_ins_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'check_in_logs') 
    THEN '✅ check_in_logs table exists'
    ELSE '❌ check_in_logs table MISSING'
  END as check_in_logs_status;

-- 2. VERIFY FUNCTIONS EXIST
-- =====================================================
SELECT 'Checking if functions exist...' as step;

SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'perform_check_in') 
    THEN '✅ perform_check_in function exists'
    ELSE '❌ perform_check_in function MISSING'
  END as perform_check_in_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_check_in_status') 
    THEN '✅ get_check_in_status function exists'
    ELSE '❌ get_check_in_status function MISSING'
  END as get_check_in_status_status;

-- 3. CREATE perform_check_in FUNCTION IF NOT EXISTS
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
  SELECT * INTO v_existing_record
  FROM user_check_ins
  WHERE user_id = p_user_id;

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
      
      UPDATE user_check_ins
      SET 
        total_days_completed = v_new_total,
        streak_count = v_new_streak,
        last_check_in = NOW()
      WHERE user_id = p_user_id;
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
  END IF;

  -- Return result
  RETURN QUERY
  SELECT 
    v_new_total,
    v_new_streak,
    (v_new_total >= 14)::BOOLEAN,
    v_is_first_today;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. CREATE get_check_in_status FUNCTION IF NOT EXISTS
-- =====================================================
CREATE OR REPLACE FUNCTION get_check_in_status(p_user_id UUID)
RETURNS TABLE (
  streak_count INT,
  total_days_completed INT,
  is_completed BOOLEAN,
  last_check_in TIMESTAMPTZ,
  checked_in_today BOOLEAN,
  days_remaining INT
) AS $$
DECLARE
  v_record RECORD;
  v_today DATE := CURRENT_DATE;
BEGIN
  SELECT * INTO v_record
  FROM user_check_ins
  WHERE user_id = p_user_id;

  IF v_record.user_id IS NULL THEN
    -- User has never checked in
    RETURN QUERY
    SELECT 
      0::INT,
      0::INT,
      FALSE::BOOLEAN,
      NULL::TIMESTAMPTZ,
      FALSE::BOOLEAN,
      14::INT;
  ELSE
    -- Return user's status
    RETURN QUERY
    SELECT 
      v_record.streak_count,
      v_record.total_days_completed,
      (v_record.total_days_completed >= 14)::BOOLEAN,
      v_record.last_check_in,
      (DATE(v_record.last_check_in) = v_today)::BOOLEAN,
      GREATEST(0, 14 - v_record.total_days_completed)::INT;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. VERIFY RLS POLICIES
-- =====================================================
SELECT 'Checking RLS policies...' as step;

SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('user_check_ins', 'check_in_logs')
ORDER BY tablename, policyname;

-- 6. TEST THE FUNCTIONS
-- =====================================================
SELECT 'Testing functions with current user...' as step;

-- Test get_check_in_status
SELECT 'Current check-in status:' as test;
SELECT * FROM get_check_in_status(auth.uid());

-- To test perform_check_in, uncomment the line below:
-- SELECT * FROM perform_check_in(auth.uid(), NULL);

-- 7. VIEW CURRENT DATA
-- =====================================================
SELECT 'Current check-in records:' as step;
SELECT * FROM user_check_ins WHERE user_id = auth.uid();

SELECT 'Check-in logs:' as step;
SELECT * FROM check_in_logs WHERE user_id = auth.uid() ORDER BY check_in_date DESC LIMIT 5;

-- =====================================================
-- VERIFICATION COMPLETE
-- =====================================================
SELECT '✅ Verification and setup complete!' as status;

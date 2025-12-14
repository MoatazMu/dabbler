# Check-In System Debug Guide

## Expected Behavior When User Clicks "Check In Now"

### Step-by-Step Flow:

1. **User clicks "Check In Now" button** in the modal
   - Location: `EarlyBirdCheckInModal` widget
   - Triggers: `onCheckIn` callback

2. **Controller's performCheckIn() is called**
   - Location: `CheckInController.performCheckIn()`
   - Sets state to loading
   - Calls repository method

3. **Repository makes RPC call to Supabase**
   - Location: `CheckInRepositoryImpl.performCheckIn()`
   - Calls Supabase function: `perform_check_in`
   - Passes parameters: `p_user_id` (from auth), `p_device_info` (optional)

4. **Supabase Function Executes** (Server-side)
   - Inserts/Updates record in `user_check_ins` table
   - Inserts log entry in `check_in_logs` table
   - Returns response with:
     - `total_days_completed`: number
     - `streak_count`: number
     - `is_completed`: boolean (true if >= 14 days)
     - `is_first_check_in_today`: boolean

5. **Response is Processed**
   - Controller updates state with new status
   - UI shows success message
   - Modal closes

## Debug Checklist

### 1. Verify Supabase Functions Exist

Run this query in Supabase SQL Editor:

```sql
-- Check if perform_check_in function exists
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines
WHERE routine_name = 'perform_check_in'
  AND routine_schema = 'public';

-- Check if get_check_in_status function exists
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines
WHERE routine_name = 'get_check_in_status'
  AND routine_schema = 'public';
```

### 2. Verify Tables Exist

```sql
-- Check tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('user_check_ins', 'check_in_logs');

-- Check table structure
\d user_check_ins
\d check_in_logs
```

### 3. Test RPC Call Directly

In Supabase SQL Editor, test the function manually:

```sql
-- Replace with your actual user ID
SELECT * FROM perform_check_in(
  p_user_id := 'your-user-id-here',
  p_device_info := null
);
```

### 4. Check RLS Policies

```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('user_check_ins', 'check_in_logs');

-- Check policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('user_check_ins', 'check_in_logs');
```

### 5. Check Flutter Debug Logs

Look for these log messages in your Flutter console:

```
MainNavigationScreen: shouldShow=true
MainNavigationScreen: status=...
CheckInController: Performing check-in
CheckInRepository: Performing check-in for user [USER_ID]
CheckInRepository: perform_check_in response=[RESPONSE]
CheckInRepository: Parsed response data={...}
CheckInController: Check-in successful: [RESPONSE]
MainNavigationScreen: wasFirstToday=true
```

## Common Issues & Solutions

### Issue 1: "Function not found" Error
**Symptom**: Error message about `perform_check_in` not existing
**Solution**: Run the SQL migration to create the functions

### Issue 2: No Response from RPC Call
**Symptom**: `response is List && response.isNotEmpty` fails
**Solution**: Check function returns proper JSON format

### Issue 3: RLS Blocking Insert
**Symptom**: Function executes but no records appear
**Solution**: Ensure RLS policies allow authenticated users to insert

### Issue 4: User ID is NULL
**Symptom**: "Not signed in" error
**Solution**: Verify user is authenticated with Supabase

## Manual Test in Supabase Dashboard

1. Go to Supabase Dashboard > SQL Editor
2. Run this to manually insert a check-in:

```sql
-- Manual test insert
INSERT INTO user_check_ins (user_id, total_days_completed, streak_count, last_check_in)
VALUES (
  auth.uid(), -- or your user ID
  1,
  1,
  NOW()
)
ON CONFLICT (user_id) 
DO UPDATE SET
  total_days_completed = user_check_ins.total_days_completed + 1,
  streak_count = user_check_ins.streak_count + 1,
  last_check_in = NOW();

-- Check if it worked
SELECT * FROM user_check_ins WHERE user_id = auth.uid();
SELECT * FROM check_in_logs WHERE user_id = auth.uid();
```

## Expected Database State After Check-In

### In `user_check_ins` table:
```
user_id | total_days_completed | streak_count | last_check_in | created_at
--------|---------------------|--------------|---------------|------------
[UUID]  | 1                   | 1            | [TIMESTAMP]   | [TIMESTAMP]
```

### In `check_in_logs` table:
```
id   | user_id | check_in_date | device_info | created_at
-----|---------|---------------|-------------|------------
[ID] | [UUID]  | [DATE]        | null        | [TIMESTAMP]
```

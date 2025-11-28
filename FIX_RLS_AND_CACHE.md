# Complete Fix for Upload & RLS Issues

## Problem 1: Still Uploading as `.jpg` (Cached Code)
Your browser is serving **old JavaScript** from cache.

## Problem 2: `403 Unauthorized` (Missing RLS Policies)
The `posts` table has no RLS policies allowing authenticated users to insert.

---

## Fix Part 1: Apply RLS Policies (DO THIS FIRST)

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project: `wtncuzcskpigqpmnxwws`
3. Click **SQL Editor** in the left sidebar

### Step 2: Run the Migration
Copy and paste this SQL into a new query:

```sql
-- Enable RLS on posts table
ALTER TABLE IF EXISTS public.posts ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read public posts
CREATE POLICY posts_select_public
    ON public.posts
    FOR SELECT
    TO authenticated
    USING (
        visibility = 'public'
        OR author_user_id = auth.uid()
    );

-- Allow authenticated users to insert their own posts
CREATE POLICY posts_insert_own
    ON public.posts
    FOR INSERT
    TO authenticated
    WITH CHECK (
        author_user_id = auth.uid()
    );

-- Allow users to update their own posts
CREATE POLICY posts_update_own
    ON public.posts
    FOR UPDATE
    TO authenticated
    USING (author_user_id = auth.uid())
    WITH CHECK (author_user_id = auth.uid());

-- Allow users to delete their own posts
CREATE POLICY posts_delete_own
    ON public.posts
    FOR DELETE
    TO authenticated
    USING (author_user_id = auth.uid());

-- Enable RLS on post_vibes table
ALTER TABLE IF EXISTS public.post_vibes ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read vibes for posts they can see
CREATE POLICY post_vibes_select_public
    ON public.post_vibes
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_vibes.post_id
            AND (posts.visibility = 'public' OR posts.author_user_id = auth.uid())
        )
    );

-- Allow users to manage vibes for their own posts
CREATE POLICY post_vibes_insert_own
    ON public.post_vibes
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_vibes.post_id
            AND posts.author_user_id = auth.uid()
        )
    );

CREATE POLICY post_vibes_delete_own
    ON public.post_vibes
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_vibes.post_id
            AND posts.author_user_id = auth.uid()
        )
    );

-- Enable RLS on post_mentions table
ALTER TABLE IF EXISTS public.post_mentions ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read mentions for posts they can see
CREATE POLICY post_mentions_select_public
    ON public.post_mentions
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_mentions.post_id
            AND (posts.visibility = 'public' OR posts.author_user_id = auth.uid())
        )
    );

-- Allow users to create mentions in their own posts
CREATE POLICY post_mentions_insert_own
    ON public.post_mentions
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_mentions.post_id
            AND posts.author_user_id = auth.uid()
        )
    );

-- Enable RLS on post_comments table
ALTER TABLE IF EXISTS public.post_comments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read comments on posts they can see
CREATE POLICY post_comments_select_public
    ON public.post_comments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_comments.post_id
            AND (posts.visibility = 'public' OR posts.author_user_id = auth.uid())
        )
    );

-- Allow authenticated users to insert comments
CREATE POLICY post_comments_insert_auth
    ON public.post_comments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        author_user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_comments.post_id
            AND (posts.visibility = 'public' OR posts.author_user_id = auth.uid())
        )
    );

-- Allow users to update their own comments
CREATE POLICY post_comments_update_own
    ON public.post_comments
    FOR UPDATE
    TO authenticated
    USING (author_user_id = auth.uid())
    WITH CHECK (author_user_id = auth.uid());

-- Allow users to delete their own comments
CREATE POLICY post_comments_delete_own
    ON public.post_comments
    FOR DELETE
    TO authenticated
    USING (author_user_id = auth.uid());
```

### Step 3: Click **RUN** 
Wait for "Success. No rows returned"

### Step 4: Verify Policies Were Created
Run this check query:

```sql
SELECT 
    schemaname, 
    tablename, 
    policyname
FROM pg_policies 
WHERE tablename IN ('posts', 'post_vibes', 'post_mentions', 'post_comments')
ORDER BY tablename, policyname;
```

You should see:
- `posts_select_public`
- `posts_insert_own`
- `posts_update_own`
- `posts_delete_own`
- (and similar for other tables)

---

## Fix Part 2: Clear Browser Cache & Rebuild

### Option A: Hard Clear Browser Cache (RECOMMENDED)

1. **Close the Flutter app completely** (stop the terminal running `flutter run`)

2. **In Chrome:**
   - Open DevTools (F12)
   - Right-click the **Refresh** button
   - Select **"Empty Cache and Hard Reload"**
   
   OR
   
   - `Cmd+Shift+Delete` (Mac) / `Ctrl+Shift+Delete` (Win/Linux)
   - Select:
     - ✅ Cached images and files
     - ✅ Time range: **All time**
   - Click **Clear data**

3. **Close Chrome completely**

4. **Rebuild and run:**
   ```bash
   cd /Users/moatazmustapha/Desktop/dabbler
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

### Option B: Use Incognito Mode (FASTEST TEST)

1. Stop the current app
2. Run:
   ```bash
   flutter run -d chrome
   ```
3. When the app opens, press `Cmd+Shift+N` (Mac) or `Ctrl+Shift+N` (Windows/Linux) to open **Incognito**
4. Navigate to `http://localhost:<port>` in the incognito window
5. Test media upload

---

## Verification

### 1. Test Upload

1. Open the app
2. Click the floating post composer
3. Attach a **PNG** image
4. Add text and select a vibe
5. Click **Post**

### 2. Check Network Tab

In Chrome DevTools → Network tab, look for the storage upload request:

**✅ SUCCESS** should look like:
```
POST https://.../storage/v1/object/post-media/posts/<uuid>.png
Content-Type: image/png
Body: starts with \u0089PNG
```

**❌ FAILURE** (old cached code) looks like:
```
POST https://.../storage/v1/object/post-media/posts/<uuid>.jpg
Content-Type: image/jpeg
Body: starts with \u0089PNG  ← WRONG!
```

### 3. Check Response

**Before RLS fix:** `403 Unauthorized` or `{"error": "new row violates row-level security policy"}`

**After RLS fix:** `200 OK` or `201 Created`

### 4. Check Database

Run in Supabase SQL Editor:

```sql
SELECT 
    id,
    author_user_id,
    kind,
    visibility,
    body,
    media,
    created_at
FROM posts
WHERE author_user_id = '<your-user-id>'
ORDER BY created_at DESC
LIMIT 5;
```

Expected `media` field:
```json
{
  "bucket": "post-media",
  "path": "posts/<uuid>.png",
  "kind": "image",
  "mime_type": "image/png"
}
```

### 5. Check Storage

Go to Supabase Dashboard → Storage → `post-media` bucket → `posts/` folder

Files should have correct extensions (e.g., `.png` for PNG files)

---

## Still Not Working?

### If you still see `.jpg` uploads after cache clear:

1. **Check for service workers:**
   - Chrome DevTools → Application tab → Service Workers
   - Click **Unregister** for localhost

2. **Disable cache in DevTools:**
   - Chrome DevTools (F12) → Network tab
   - ✅ Check **"Disable cache"**
   - Keep DevTools open while testing

3. **Nuclear option:**
   ```bash
   # Delete ALL browser data for localhost
   # Chrome → Settings → Privacy and security → Site settings
   # → View permissions and data stored across sites
   # → Search for "localhost" → Delete
   ```

### If you get a different error after RLS fix:

**Error:** `"Profile not found for current user"`
- Your `profiles` table doesn't have a row for your `user_id`
- Run:
  ```sql
  SELECT id, user_id, display_name FROM profiles WHERE user_id = '<your-user-id>';
  ```
- If empty, you need to create a profile first

**Error:** `"Failed to load vibes"`
- Your `vibes` table is empty or vibes don't have `contexts` with `'moment'`
- Check:
  ```sql
  SELECT id, key, label, contexts FROM vibes WHERE 'moment' = ANY(contexts);
  ```

---

## Summary

1. ✅ **RLS policies created** → Users can now insert posts
2. ✅ **Cache cleared** → Browser will load new code with correct upload logic
3. ✅ **Legacy upload code disabled** → Can't be called accidentally
4. ✅ **SocialRepository is the only upload path** → Guaranteed correct MIME/extension

Once both fixes are applied, PNG files will upload as `.png` with `image/png` MIME, and posts will save successfully to the database.

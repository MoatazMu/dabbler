# Media Upload Fix Applied

## Problem
PNG files were being uploaded with `.jpg` extension and `image/jpeg` MIME type due to legacy upload code.

## Root Cause
- Old `uploadImages` method in `SocialService` hard-coded `.jpg` extension and `image/jpeg` MIME type
- Old `MediaService` was a duplicate of functionality now in `SocialRepository`
- Flutter web build cache was serving stale compiled JavaScript

## Changes Applied

### 1. Disabled Legacy Upload Code
**File:** `lib/features/social/services/social_service.dart`
- Marked `uploadImages()` as `@Deprecated`
- Replaced implementation with `throw UnimplementedError()` and clear migration message
- Removed unused `dart:io` import

**File:** `lib/services/media_service.dart`
- Marked entire `MediaService` class as `@Deprecated`
- Replaced implementation with `throw UnimplementedError()` and clear migration message
- Added library-level deprecation notice

### 2. Cleaned Build Cache
- Ran `flutter clean` to remove all compiled artifacts
- Ran `flutter pub get` to refresh dependencies
- Ran `dart run build_runner build --delete-conflicting-outputs` to regenerate Freezed models

## Correct Upload Flow (Already Implemented)

All media uploads now go through:

```dart
// 1. User selects media in InlinePostComposer
final file = await ImagePicker().pickImage(source: ImageSource.gallery);

// 2. Upload via SocialRepository
final repo = ref.read(socialRepositoryProvider);
final mediaJson = await repo.uploadPostMedia(file); // XFile

// 3. Create post/comment with media
await repo.createPost(
  kind: 'moment',
  visibility: PostVisibility.public,
  body: 'Text content',
  media: mediaJson, // { bucket, path, kind, mime_type }
  primaryVibeId: selectedVibeId,
);
```

### How `uploadPostMedia` Works Correctly

```dart
// From SocialRepository.uploadPostMedia():
Future<Map<String, dynamic>> uploadPostMedia(XFile file) async {
  final bytes = await file.readAsBytes();
  
  // ✅ Correctly extracts extension from file path
  final path = file.path;
  String ext = path.split('.').last.toLowerCase(); // e.g., 'png'
  if (ext.isEmpty) ext = 'jpg';
  
  // ✅ Uses package:mime to detect MIME type from file bytes
  final mimeType = lookupMimeType(path, headerBytes: bytes) ?? 'image/jpeg';
  // For PNG: returns 'image/png'
  
  // ✅ Generates correct path with proper extension
  final id = const Uuid().v4();
  final storagePath = 'posts/$id.$ext'; // e.g., 'posts/<uuid>.png'
  
  // ✅ Uploads to correct bucket
  await _client.storage
      .from('post-media')
      .uploadBinary(storagePath, Uint8List.fromList(bytes));
  
  return {
    'bucket': 'post-media',
    'path': storagePath,
    'kind': 'image',
    'mime_type': mimeType,
  };
}
```

## Verification Steps

### 1. Stop the Current Dev Server
```bash
# Press Ctrl+C in the terminal running the Flutter app
```

### 2. Rebuild for Web
```bash
cd /Users/moatazmustapha/Desktop/dabbler
flutter run -d chrome
```

### 3. Test Media Upload
1. Open the app in Chrome
2. Click the floating post composer (bottom right)
3. Click the image attachment button
4. Select a **PNG** file
5. Add text and select a vibe
6. Click "Post"

### 4. Verify in Browser DevTools
1. Open Chrome DevTools (F12)
2. Go to Network tab
3. Filter by "post-media"
4. Look at the upload request:
   - **URL should end with `.png`** (not `.jpg`)
   - **Content-Type should be `image/png`** (not `image/jpeg`)
   - Body should start with `\u0089PNG` (PNG magic bytes)

### 5. Verify in Supabase Storage
1. Go to Supabase dashboard → Storage → `post-media` bucket
2. Navigate to `posts/` folder
3. Check the uploaded file:
   - File extension matches the original (e.g., `.png`)
   - File opens correctly when previewed

### 6. Verify in Database
```sql
-- Check the posts.media field
SELECT id, body, media
FROM posts
WHERE media IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;
```

Expected `media` value:
```json
{
  "bucket": "post-media",
  "path": "posts/<uuid>.png",
  "kind": "image",
  "mime_type": "image/png"
}
```

## What If It Still Fails?

If you still see `.jpg` uploads after these changes:

1. **Clear browser cache completely:**
   ```
   Chrome → Settings → Privacy and security → Clear browsing data
   - Cached images and files
   - Last 24 hours
   ```

2. **Hard reload in browser:**
   ```
   Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)
   ```

3. **Check for other upload code paths:**
   ```bash
   cd /Users/moatazmustapha/Desktop/dabbler
   grep -r "uploadBinary\|upload(" lib/ --include="*.dart"
   ```
   
   Any match outside of:
   - `lib/data/social/social_repository.dart`
   - Profile avatar upload code
   
   ...should be investigated.

## Migration Status

### ✅ Migrated to SocialRepository
- `InlinePostComposer` (home screen floating composer)
- New post creation flow
- Comment creation with media

### ❌ NOT Migrated (But Don't Use Media)
- `add_post_screen.dart` - text-only posts, passes empty `mediaUrls: []`
- `social_feed_controller.createPost()` - mock/stub implementation, not actually used

### 🚫 Deprecated (Will Error If Called)
- `SocialService.uploadImages()` → throws `UnimplementedError`
- `MediaService.uploadPostMedia()` → throws `UnimplementedError`

## Success Criteria

✅ PNG files upload with `.png` extension  
✅ PNG files upload with `image/png` MIME type  
✅ JPEG files upload with `.jpg` extension  
✅ JPEG files upload with `image/jpeg` MIME type  
✅ `posts.media` contains correct bucket, path, kind, mime_type  
✅ Images render correctly in feed cards  
✅ No console errors or upload failures  

## Contact
If you still encounter issues after following these steps, capture:
1. Full Network request (copy as cURL from DevTools)
2. Console errors (if any)
3. The file extension you're trying to upload
4. Screenshot of the Supabase Storage entry

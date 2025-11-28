# Dabbler Social Model — Source of Truth

This document describes how social content (posts, vibes, media, locations, etc.) works in Dabbler.  
It is intended for humans **and** AI copilots (Cursor, MCP, etc.) as the canonical reference.

---

## 0. Core Principles

- There are **three post kinds**, enforced as a Postgres enum:  
  `public.post_kind = 'moment' | 'dab' | 'kickin'`.
- All social actions are **profile-first**: authors, likers, hiders, and mentions are `public.profiles` rows, not `auth.users`.
- Media files live in **Supabase Storage**, not in the DB; the DB only stores pointers + metadata.
- Vibes are a **catalog** that can be filtered by post kind via `vibes.contexts`.
- Locations are **free-text tags** with weighting (Instagram-style), optionally linked to real venues.

---

## 1. Post Types & Semantics

Enum: `public.post_kind` with values:

- `moment`
  - Pre-game or post-game interaction.
  - Often has media and a vibe.
  - Can be linked to an upcoming or past game and/or a location.
- `dab`
  - Generic thought, reflection, or ask (for a game, team, or player).
  - Usually text-first. May have vibes. Typically no location/media, but allowed.
- `kickin`
  - “Last call” / reminder / change of time / “game is starting now.”
  - Strongly associated with a game and often a location.

**Code rule:**  
When creating posts, always set `kind` to one of `'moment' | 'dab' | 'kickin'`. Never invent other values.

---

## 2. Key Tables (public schema)

### 2.1 `profiles` (identity for social)

The **author identity** for all social content.

Relevant columns:

- `id uuid pk`
- `user_id uuid -> auth.users.id`
- `username text / citext`
- `display_name text`
- `profile_type text` — e.g. `player`, `organiser`, etc.

**Rule:**  
When writing new social code, always use `profiles.id` as the actor (author, liker, mention target), not `auth.users.id`.

---

### 2.2 `posts`

Core social content.

Important columns:

- `id uuid pk`
- `kind public.post_kind not null` — `'moment' | 'dab' | 'kickin'`
- `visibility text` — check in `('public', 'circle', 'link', 'private')`
- `author_profile_id uuid not null -> profiles.id`
- `author_user_id uuid -> auth.users.id` (legacy, avoid using in new code)
- `body text`
- `media jsonb null` — **single-file metadata object**, see §4
- `primary_vibe_id uuid null -> vibes.id`
- `game_id uuid null -> games.id`
- `location_tag_id uuid null -> location_tags.id`
- `like_count integer`
- `comment_count integer`
- `is_deleted boolean`
- `is_hidden_admin boolean`
- `created_at timestamptz`
- `updated_at timestamptz`

Indexes (relevant):

- `idx_posts_kind_created` on `(kind, created_at desc)`
- Optional feed-style indexes may exist (e.g. `(kind, visibility, created_at)` with filters).

**Typical feed filter:**

```sql
select *
from public.posts
where kind = 'kickin'
  and visibility = 'public'
  and not is_deleted
  and not is_hidden_admin
order by created_at desc
limit 50;



⸻

2.3 vibes

Catalog of vibes (feelings/actions).

Important columns:
	•	id uuid pk
	•	key text unique — machine key, e.g. supportive, frustrated
	•	emoji text
	•	contexts text[] — used for mapping vibes to post kinds:
	•	May contain 'moment', 'dab', 'kickin'
	•	theme text — optional group/theme
	•	label_en text
	•	label_ar text
	•	type text — e.g. feeling, action
	•	is_active boolean
	•	created_at, updated_at timestamps

Usage for UI:

To load vibes for a given post kind:
select *
from public.vibes
where is_active = true
  and '<KIND>' = any(contexts);  -- 'moment' | 'dab' | 'kickin'


⸻

2.4 post_vibes

Many-to-many relationship between posts and vibes.
	•	post_id uuid not null -> posts.id
	•	vibe_id uuid not null -> vibes.id
	•	assigned_at timestamptz default now()
	•	PK: (post_id, vibe_id)

Typical pattern:
	•	posts.primary_vibe_id stores the “main” vibe.
	•	post_vibes stores all vibes applied to the post.

⸻

2.5 post_reactions (if present)

Per-user vibe-style reactions to posts.
	•	post_id uuid not null -> posts.id
	•	actor_profile_id uuid not null -> profiles.id
	•	vibe_id uuid not null -> vibes.id
	•	created_at timestamptz
	•	PK: (post_id, actor_profile_id, vibe_id)

This can eventually be used to replace a simple “like” with richer reactions.

⸻

2.6 post_comments

Comments on posts, including threaded replies.
	•	id uuid pk
	•	post_id uuid -> posts.id
	•	author_profile_id uuid -> profiles.id
	•	author_user_id uuid -> auth.users.id (legacy)
	•	parent_comment_id uuid null -> post_comments.id (threading)
	•	body text
	•	like_count integer
	•	is_deleted boolean
	•	created_at timestamptz

⸻

2.7 Likes & Hides

post_likes
	•	post_id uuid not null -> posts.id
	•	profile_id uuid not null -> profiles.id
	•	created_at timestamptz
	•	PK: (post_id, profile_id)

comment_likes
	•	comment_id uuid not null -> post_comments.id
	•	profile_id uuid not null -> profiles.id
	•	created_at timestamptz
	•	PK: (comment_id, profile_id)

post_hides
	•	post_id uuid not null -> posts.id
	•	owner_profile_id uuid not null -> profiles.id
	•	created_at timestamptz
	•	PK: (post_id, owner_profile_id)

⸻

2.8 Mentions

Used to track @username mentions in posts/comments.

post_mentions
	•	post_id uuid not null -> posts.id
	•	mentioned_profile_id uuid not null -> profiles.id
	•	created_at timestamptz
	•	PK: (post_id, mentioned_profile_id)

comment_mentions
	•	comment_id uuid not null -> post_comments.id
	•	mentioned_profile_id uuid not null -> profiles.id
	•	created_at timestamptz
	•	PK: (comment_id, mentioned_profile_id)

Typical UX pipeline:
	1.	User types @username in the composer.
	2.	App parses mentions and resolves username -> profiles.id.
	3.	After creating the post/comment row, app inserts rows into post_mentions / comment_mentions.
	4.	Backend/notifications can use these rows to send mention notifications.

⸻

2.9 Locations — location_tags

Instagram-style free-text locations, with frequency weighting.
	•	id uuid pk
	•	label text — what user sees, e.g. "Burj Khalifa"
	•	slug text unique — normalized, e.g. "burj-khalifa"
	•	country_code text null
	•	city text null
	•	neighbourhood text null
	•	venue_id uuid null -> venues.id (optional link to structured venue)
	•	use_count integer not null default 0
	•	last_used_at timestamptz not null default now()
	•	created_at timestamptz not null default now()

Indexes:
	•	Unique index on slug
	•	Trigram index on label (for autocomplete)

Helper function: upsert_location_tag

select *
from public.upsert_location_tag(_label text, _venue_id uuid default null)
  returns public.location_tags;

  Behaviour:
	•	Normalizes the label into a slug.
	•	If a location tag with the same slug + venue_id exists:
	•	increments use_count, updates last_used_at.
	•	Else:
	•	inserts a new row.
	•	Returns the full location_tags row.

Usage in app:
	•	For autocomplete: ilike search on label or slug.
	•	When user confirms a free-typed location:
	•	Call upsert_location_tag(label, venueId?).
	•	Store the returned id in posts.location_tag_id.

⸻

3. Media Storage Model

3.1 Supabase Storage

Media is stored in Supabase Storage. The DB only stores references.
	•	Bucket name: post-media
	•	Visibility:
	•	During development: can be public.
	•	Later: recommended to switch to private and use signed URLs.
	•	Object path pattern (single file per post for now):

    posts/<uuid>.<ext>

    Example:
	•	posts/3f7c0d3e-c3c3-4f87-9b68-433b2db7b5d1.jpg

3.2 posts.media JSON shape

public.posts.media is a jsonb column. For now we assume one file per post.

Recommended shape:

{
  "bucket": "post-media",
  "path": "posts/<uuid>.<ext>",
  "kind": "image",
  "mime_type": "image/jpeg"
}

Additional fields (optional):
	•	width — integer
	•	height — integer
	•	duration_ms — for video

3.3 Upload flow (client-side)

Pattern A (preferred):
    1. User picks a file in Flutter (XFile).
    2. App generates a random UUID for this media (or post).
    3. App computes path: posts/<uuid>.<ext>.
    4. App uploads bytes:
    await supabase.storage
    .from('post-media')
    .uploadBinary(path, bytes);

    5. App builds the media JSON object and passes it to createPost:
    final mediaJson = {
     'bucket': 'post-media',
     'path': 'posts/<uuid>.<ext>',
      'kind': 'image',
      'mime_type': mimeType,
    };

    6. PostService.createPost inserts this JSON into posts.media.

3.4 Rendering media in the feed

To render media in feed:
	1.	Fetch posts.media from DB.
	2.	From the JSON, derive a URL:
    final publicUrl = supabase
    .storage
    .from(media['bucket'] as String)
    .getPublicUrl(media['path'] as String)
    .data;

    	3.	Pass this URL into your PostCard / media widget.

If bucket becomes private in future, replace getPublicUrl with signed URL generation.

⸻

4. Behaviour Rules for Code & Copilots

These rules are for both humans and AI assistants (Cursor, MCP, etc.).

4.1 Identity
	•	Always use profiles.id for:
	•	posts.author_profile_id
	•	post_comments.author_profile_id
	•	post_likes.profile_id
	•	comment_likes.profile_id
	•	post_hides.owner_profile_id
	•	post_mentions.mentioned_profile_id
	•	comment_mentions.mentioned_profile_id
	•	Do not add new logic that depends on author_user_id for feeds or display.

To get the current profile id from auth.uid():

select id
from public.profiles
where user_id = auth.uid();

4.2 Post Creation per Kind

When writing or generating code for post creation:
	•	Common required fields:
	•	kind ('moment' | 'dab' | 'kickin')
	•	visibility ('public' | 'circle' | 'link' | 'private')
	•	author_profile_id
	•	body (may be empty for pure-media posts)
	•	moment:
	•	May set: media, primary_vibe_id, post_vibes, game_id, location_tag_id, mentions.
	•	dab:
	•	Usually text only; can have vibes; usually no media/location.
	•	kickin:
	•	Usually sets game_id and optionally location_tag_id, with optional media and vibes.

4.3 Vibes
	•	Use vibes.contexts to filter appropriate vibes:

    select *
from public.vibes
where is_active = true
  and '<KIND>' = any(contexts);  -- 'moment' | 'dab' | 'kickin'

  	•	When setting primary_vibe_id:
	•	It should point to an existing, active vibe.
	•	post_vibes can include multiple vibes per post.

4.4 Locations
	•	For search/autocomplete:
	•	Use case-insensitive match on location_tags.label or slug.
	•	For creating/reusing a tag:
	•	Call upsert_location_tag(label, venue_id) and use the returned id as posts.location_tag_id.

4.5 Media
	•	For now, the app should enforce at most one media file per post.
	•	Store a single JSON object in posts.media, not an array.
	•	All file uploads should go to the post-media bucket under posts/<uuid>.<ext>.

4.6 Mentions
	•	Parse mentions from body on the client:
	•	Detect @username.
	•	Resolve usernames to profiles.id.
	•	After inserting the post/comment, insert rows into post_mentions / comment_mentions.

⸻

5. Helpful Views (if present)

There are some views built on top of posts:
	•	v_post_detail — post + author + vibes, used for detail screens.
	•	v_post_discovery — similar, used for discovery/feed.
	•	v_trending_vibes — calculates trending vibes based on recent posts and p.kind.

Codegen should treat these as read-only helpers. New writes should always go to the base tables (posts, post_vibes, post_reactions, etc.).

⸻

6. Summary for AI Assistants

When generating code for Dabbler:
	1.	Read this file first to understand the social schema and behaviour.
	2.	Use public.profiles as the main identity in social features.
	3.	Use public.post_kind for post types (moment, dab, kickin).
	4.	Store media in Supabase Storage (post-media bucket), not directly in the DB.
	5.	In the DB, store media as a small JSON pointer in posts.media.
	6.	Filter vibes by vibes.contexts and the current kind.
	7.	Use upsert_location_tag and location_tags for locations.
	8.	Wire mentions through post_mentions / comment_mentions after content is saved.




Media storage:

- Supabase Storage bucket name: `post-media`.
- Path pattern: `posts/<uuid>.<ext>`.
- Column: `public.posts.media` (jsonb) stores:
  {
    "bucket": "post-media",
    "path": "posts/<uuid>.<ext>",
    "kind": "image",
    "mime_type": "image/jpeg"
  }
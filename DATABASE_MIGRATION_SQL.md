# Database Migration SQL Statements

Run these SQL statements in Supabase SQL Editor to synchronize the database schema with the game creation flow.

## 1. Games Table Schema Updates

```sql
-- Ensure game_type has default and is not null
ALTER TABLE games
  ALTER COLUMN game_type SET DEFAULT 'pickup',
  ALTER COLUMN game_type SET NOT NULL;

-- Ensure rules has default empty JSON object
ALTER TABLE games
  ALTER COLUMN rules SET DEFAULT '{}'::jsonb;

-- Ensure listing_visibility has default
ALTER TABLE games
  ALTER COLUMN listing_visibility SET DEFAULT 'public';

-- Ensure join_policy has default
ALTER TABLE games
  ALTER COLUMN join_policy SET DEFAULT 'open';

-- Fix listing_visibility constraint to allow 'public' and 'private'
-- First, check what values exist and update invalid ones
DO $$
BEGIN
  -- Update any NULL values to 'public' (default)
  UPDATE games
  SET listing_visibility = 'public'
  WHERE listing_visibility IS NULL;
  
  -- Update any invalid values to 'public' (you can change this to 'private' if preferred)
  -- Common invalid values might be: 'invite', 'link', 'hidden', etc.
  UPDATE games
  SET listing_visibility = 'public'
  WHERE listing_visibility NOT IN ('public', 'private');
  
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'games_listing_visibility_check'
    AND conrelid = 'games'::regclass
  ) THEN
    ALTER TABLE games DROP CONSTRAINT games_listing_visibility_check;
  END IF;
  
  -- Add new constraint allowing both 'public' and 'private'
  ALTER TABLE games
    ADD CONSTRAINT games_listing_visibility_check
    CHECK (listing_visibility IN ('public', 'private'));
END $$;

-- Add check constraint for game_type values (only if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'games_game_type_check'
    AND conrelid = 'games'::regclass
  ) THEN
    ALTER TABLE games
      ADD CONSTRAINT games_game_type_check 
      CHECK (game_type IN ('pickup', 'training', 'league'));
  END IF;
END $$;

-- Add indices for games table performance
CREATE INDEX IF NOT EXISTS idx_games_sport ON games (sport);
CREATE INDEX IF NOT EXISTS idx_games_start_at ON games (start_at);
CREATE INDEX IF NOT EXISTS idx_games_visibility ON games (listing_visibility);
CREATE INDEX IF NOT EXISTS idx_games_is_cancelled ON games (is_cancelled);
CREATE INDEX IF NOT EXISTS idx_games_game_type ON games (game_type);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_games_sport_visibility_start
  ON games (sport, listing_visibility, start_at);
```

## 2. Venues Table Enhancements for Filtering

```sql
-- Add fields to venues table for detailed filters
ALTER TABLE venues
  ADD COLUMN IF NOT EXISTS area text,
  ADD COLUMN IF NOT EXISTS lat double precision,
  ADD COLUMN IF NOT EXISTS lng double precision,
  ADD COLUMN IF NOT EXISTS is_indoor boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS surface_type text,
  ADD COLUMN IF NOT EXISTS min_price_per_hour numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_price_per_hour numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS rating numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS rating_count integer DEFAULT 0;

-- Ensure amenities is text[] if not already
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'venues' AND column_name = 'amenities'
  ) THEN
    ALTER TABLE venues ADD COLUMN amenities text[];
  END IF;
END $$;

-- Add indices for venues table
CREATE INDEX IF NOT EXISTS idx_venues_city ON venues (city);
CREATE INDEX IF NOT EXISTS idx_venues_is_active ON venues (is_active);
CREATE INDEX IF NOT EXISTS idx_venues_location ON venues (lat, lng);
CREATE INDEX IF NOT EXISTS idx_venues_is_indoor ON venues (is_indoor);
CREATE INDEX IF NOT EXISTS idx_venues_surface_type ON venues (surface_type);
CREATE INDEX IF NOT EXISTS idx_venues_price_range ON venues (min_price_per_hour, max_price_per_hour);
```

## 3. Venue Spaces Table Updates

```sql
-- Add fields to venue_spaces table
ALTER TABLE venue_spaces
  ADD COLUMN IF NOT EXISTS sport text,
  ADD COLUMN IF NOT EXISTS format_hint text;

-- Add indices for venue_spaces
CREATE INDEX IF NOT EXISTS idx_venue_spaces_sport ON venue_spaces (sport);
CREATE INDEX IF NOT EXISTS idx_venue_spaces_venue_id ON venue_spaces (venue_id);
CREATE INDEX IF NOT EXISTS idx_venue_spaces_is_active ON venue_spaces (is_active);
```

## 4. Profiles Table Updates for Player Filtering

```sql
-- Extend profiles table for player-only filtering
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_player boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS primary_sport text,
  ADD COLUMN IF NOT EXISTS skill_level integer;

-- Create index for player filtering
CREATE INDEX IF NOT EXISTS idx_profiles_is_player
  ON profiles (is_player) WHERE is_player = true;

-- Create index for primary_sport filtering
CREATE INDEX IF NOT EXISTS idx_profiles_primary_sport
  ON profiles (primary_sport) WHERE primary_sport IS NOT NULL;
```

## 5. Optional: RPC Function for Venue Search with Filters

```sql
-- Create RPC function for searching venues with filters
CREATE OR REPLACE FUNCTION search_venues_with_filters(
  p_lat double precision DEFAULT NULL,
  p_lng double precision DEFAULT NULL,
  p_radius_km double precision DEFAULT 10,
  p_sport text DEFAULT NULL,
  p_price_min numeric DEFAULT NULL,
  p_price_max numeric DEFAULT NULL,
  p_is_indoor boolean DEFAULT NULL,
  p_surface_type text DEFAULT NULL,
  p_min_rating numeric DEFAULT NULL,
  p_amenities text[] DEFAULT NULL,
  p_city text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  name_en text,
  address_line1 text,
  city text,
  lat double precision,
  lng double precision,
  is_indoor boolean,
  surface_type text,
  min_price_per_hour numeric,
  max_price_per_hour numeric,
  rating numeric,
  rating_count integer,
  amenities text[],
  distance_km double precision
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.id,
    v.name_en,
    v.address_line1,
    v.city,
    v.lat,
    v.lng,
    v.is_indoor,
    v.surface_type,
    v.min_price_per_hour,
    v.max_price_per_hour,
    v.rating,
    v.rating_count,
    v.amenities,
    CASE 
      WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
        -- Haversine distance calculation (approximate)
        6371 * acos(
          cos(radians(p_lat)) * 
          cos(radians(v.lat)) * 
          cos(radians(v.lng) - radians(p_lng)) + 
          sin(radians(p_lat)) * 
          sin(radians(v.lat))
        )
      ELSE NULL
    END AS distance_km
  FROM venues v
  LEFT JOIN venue_spaces vs ON vs.venue_id = v.id
  WHERE 
    v.is_active = true
    AND (p_sport IS NULL OR vs.sport = p_sport)
    AND (p_city IS NULL OR v.city = p_city)
    AND (p_price_min IS NULL OR v.max_price_per_hour >= p_price_min)
    AND (p_price_max IS NULL OR v.min_price_per_hour <= p_price_max)
    AND (p_is_indoor IS NULL OR v.is_indoor = p_is_indoor)
    AND (p_surface_type IS NULL OR v.surface_type = p_surface_type)
    AND (p_min_rating IS NULL OR v.rating >= p_min_rating)
    AND (p_amenities IS NULL OR v.amenities && p_amenities)
    AND (
      p_lat IS NULL OR 
      p_lng IS NULL OR
      -- Distance filter (using bounding box approximation)
      v.lat BETWEEN p_lat - (p_radius_km / 111.0) AND p_lat + (p_radius_km / 111.0)
      AND v.lng BETWEEN p_lng - (p_radius_km / (111.0 * cos(radians(p_lat)))) 
                     AND p_lng + (p_radius_km / (111.0 * cos(radians(p_lat))))
    )
  GROUP BY v.id, v.name_en, v.address_line1, v.city, v.lat, v.lng, 
           v.is_indoor, v.surface_type, v.min_price_per_hour, v.max_price_per_hour,
           v.rating, v.rating_count, v.amenities
  ORDER BY distance_km NULLS LAST, v.rating DESC;
END;
$$;
```

## Notes

- Run these migrations in order
- Test each migration before proceeding to the next
- The RPC function is optional but recommended for better performance
- Update existing data as needed after adding new columns


-- Migration: Create FCM Tokens Table for Push Notifications
-- Purpose: Store Firebase Cloud Messaging tokens for each user/device
-- Run this in Supabase SQL Editor

-- Create fcm_tokens table
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'iOS', 'macOS', 'web', 'linux', 'windows', 'fuchsia')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Unique constraint: one token per user per platform
    CONSTRAINT unique_user_platform UNIQUE (user_id, platform)
);

-- Add index for faster lookups by user_id
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON public.fcm_tokens(user_id);

-- Add index for faster lookups by token (useful for cleanup of expired tokens)
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON public.fcm_tokens(token);

-- Enable Row Level Security
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-runs)
DROP POLICY IF EXISTS "Users can view their own FCM tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "Users can insert their own FCM tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "Users can update their own FCM tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "Users can delete their own FCM tokens" ON public.fcm_tokens;

-- RLS Policy: Users can read their own tokens
CREATE POLICY "Users can view their own FCM tokens"
    ON public.fcm_tokens
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own tokens
CREATE POLICY "Users can insert their own FCM tokens"
    ON public.fcm_tokens
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own tokens
CREATE POLICY "Users can update their own FCM tokens"
    ON public.fcm_tokens
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own tokens
CREATE POLICY "Users can delete their own FCM tokens"
    ON public.fcm_tokens
    FOR DELETE
    USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists (for re-runs)
DROP TRIGGER IF EXISTS update_fcm_tokens_timestamp ON public.fcm_tokens;

-- Trigger to update updated_at on row update
CREATE TRIGGER update_fcm_tokens_timestamp
    BEFORE UPDATE ON public.fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.update_fcm_tokens_updated_at();

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fcm_tokens TO authenticated;

-- Optional: Create a function to get all tokens for a specific user (useful for sending notifications)
CREATE OR REPLACE FUNCTION public.get_user_fcm_tokens(target_user_id UUID)
RETURNS TABLE (
    token TEXT,
    platform TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT fcm_tokens.token, fcm_tokens.platform
    FROM public.fcm_tokens
    WHERE fcm_tokens.user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

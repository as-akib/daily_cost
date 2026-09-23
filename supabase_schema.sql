-- ==============================================================================
-- DailyCost - Migration & Database Setup (Handles Existing & New Tables)
-- Run this in Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Create or Update PROFILES Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    photo_url TEXT,
    monthly_income NUMERIC NOT NULL DEFAULT 0,
    savings_goal NUMERIC NOT NULL DEFAULT 0,
    fixed_costs JSONB NOT NULL DEFAULT '[]'::jsonb,
    base_currency TEXT NOT NULL DEFAULT 'BDT',
    currency_symbol TEXT NOT NULL DEFAULT '৳',
    cycle_start_day INTEGER NOT NULL DEFAULT 1,
    is_onboarded BOOLEAN NOT NULL DEFAULT false,
    is_anonymous BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ensure all columns exist even if profiles table was created earlier
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS monthly_income NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS savings_goal NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fixed_costs JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS base_currency TEXT NOT NULL DEFAULT 'BDT';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS currency_symbol TEXT NOT NULL DEFAULT '৳';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS cycle_start_day INTEGER NOT NULL DEFAULT 1;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_onboarded BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- 2. Create or Update EXPENSES Table
CREATE TABLE IF NOT EXISTS public.expenses (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    category TEXT NOT NULL,
    note TEXT NOT NULL DEFAULT '',
    date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS note TEXT NOT NULL DEFAULT '';
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- 3. Create or Update CATEGORIES Table
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    icon_code_point INTEGER NOT NULL,
    color_value BIGINT NOT NULL,
    is_custom BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_custom BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses (user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories (user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_anonymous ON public.profiles (is_anonymous, created_at);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Reset and re-apply permissive policies for anon & authenticated users
DROP POLICY IF EXISTS "Allow all for profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow all for expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow all for categories" ON public.categories;

CREATE POLICY "Allow all for profiles" ON public.profiles
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all for expenses" ON public.expenses
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all for categories" ON public.categories
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- 5. Auto Cleanup Function for Guest Accounts (7-day cleanup)
CREATE OR REPLACE FUNCTION public.cleanup_old_guest_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete guest expenses
    DELETE FROM public.expenses
    WHERE user_id IN (
        SELECT id FROM public.profiles 
        WHERE is_anonymous = true 
        AND created_at < NOW() - INTERVAL '7 days'
    )
    OR (
        user_id LIKE 'guest_%' 
        AND created_at < NOW() - INTERVAL '7 days'
    );

    -- Delete guest custom categories
    DELETE FROM public.categories
    WHERE user_id IN (
        SELECT id FROM public.profiles 
        WHERE is_anonymous = true 
        AND created_at < NOW() - INTERVAL '7 days'
    )
    OR user_id LIKE 'guest_%';

    -- Delete guest profiles
    DELETE FROM public.profiles
    WHERE is_anonymous = true
    AND created_at < NOW() - INTERVAL '7 days';
END;
$$;

GRANT EXECUTE ON FUNCTION public.cleanup_old_guest_data() TO anon, authenticated;

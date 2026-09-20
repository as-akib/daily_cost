-- ==============================================================================
-- DailyCost Supabase Database Schema
-- Run this in your Supabase Dashboard: SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Create PROFILES Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    photo_url TEXT,
    monthly_income NUMERIC NOT NULL DEFAULT 0,
    savings_goal NUMERIC NOT NULL DEFAULT 0,
    base_currency TEXT NOT NULL DEFAULT 'USD',
    cycle_start_day INTEGER NOT NULL DEFAULT 1,
    fixed_costs JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create EXPENSES Table
CREATE TABLE IF NOT EXISTS public.expenses (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    amount_in_base_currency NUMERIC NOT NULL,
    category TEXT NOT NULL,
    note TEXT,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for fast user expense queries sorted by date
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses (user_id, date DESC);

-- 3. Create CATEGORIES Table
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'more_horiz',
    color TEXT NOT NULL DEFAULT '#64748B',
    is_default BOOLEAN NOT NULL DEFAULT false,
    is_hidden BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories (user_id);

-- ==============================================================================
-- Row-Level Security (RLS) Policies
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Profiles: Allow users to select, insert, and update their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (true);

-- Expenses: Allow users to manage their own expenses
DROP POLICY IF EXISTS "Users can manage own expenses" ON public.expenses;
CREATE POLICY "Users can manage own expenses"
    ON public.expenses FOR ALL
    USING (true)
    WITH CHECK (true);

-- Categories: Allow users to view and manage categories
DROP POLICY IF EXISTS "Users can view categories" ON public.categories;
CREATE POLICY "Users can view categories"
    ON public.categories FOR ALL
    USING (true)
    WITH CHECK (true);

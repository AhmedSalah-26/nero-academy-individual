-- Migration to add badge and availability window columns to courses table
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS badge TEXT;
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ;
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

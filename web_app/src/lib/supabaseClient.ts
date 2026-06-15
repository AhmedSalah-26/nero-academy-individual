import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn(
    'Supabase environment variables are missing. Please check your .env.local configuration.'
  );
}

export const supabase = createClient(
  supabaseUrl || 'https://ubjhdafxmncfbaldfivd.supabase.co',
  supabaseAnonKey || 'sb_publishable_wJvu57s6WvTFFi9JTZhBbg_mS3tYCE7'
);

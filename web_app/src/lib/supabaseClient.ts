import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

let supabaseInstance: SupabaseClient;

if (supabaseUrl && supabaseAnonKey) {
  supabaseInstance = createClient(supabaseUrl, supabaseAnonKey);
} else {
  if (typeof window !== 'undefined') {
    console.warn('Supabase environment variables are missing. Please check your .env.local configuration.');
  }
  supabaseInstance = createClient('https://placeholder.supabase.co', 'placeholder-key');
}

export const supabase = supabaseInstance;

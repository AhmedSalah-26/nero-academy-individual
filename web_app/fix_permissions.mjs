/**
 * Fix: permission denied for function current_profile_sensitive_state
 * Run: node database_scripts/fix_permissions.mjs
 */
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL     = 'https://ubjhdafxmncfbaldfivd.supabase.co';
const SERVICE_ROLE_KEY = 'PASTE_YOUR_SERVICE_ROLE_KEY_HERE'; // ← ضع مفتاح service_role

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

const sql = `
GRANT EXECUTE ON FUNCTION public.current_profile_sensitive_state() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_instructor() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_enrolled(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_course(UUID) TO authenticated;
`;

const { error } = await supabase.rpc('exec_sql', { sql }).catch(() => ({ error: 'rpc not available' }));

if (error) {
  console.log('⚠️  Use Supabase Dashboard → SQL Editor and run:');
  console.log('─'.repeat(60));
  console.log(sql);
  console.log('─'.repeat(60));
} else {
  console.log('✅ Permissions granted!');
}

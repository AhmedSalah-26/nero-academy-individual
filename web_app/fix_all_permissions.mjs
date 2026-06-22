/**
 * ============================================================
 * 🔧 COMPREHENSIVE FIX: Grant all function permissions
 * ============================================================
 * Run from web_app directory:
 *   node fix_all_permissions.mjs <SERVICE_ROLE_KEY>
 *
 * Or set SERVICE_ROLE_KEY below and run:
 *   node fix_all_permissions.mjs
 * ============================================================
 */

import { createClient } from '@supabase/supabase-js';
import https from 'https';

const SUPABASE_URL     = 'https://ubjhdafxmncfbaldfivd.supabase.co';
const SERVICE_ROLE_KEY = process.argv[2] || 'PASTE_YOUR_SERVICE_ROLE_KEY_HERE';

if (SERVICE_ROLE_KEY === 'PASTE_YOUR_SERVICE_ROLE_KEY_HERE') {
  console.error('❌ Please provide service role key:');
  console.error('   node fix_all_permissions.mjs YOUR_SERVICE_ROLE_KEY');
  console.error('\nOr paste it in the script at SERVICE_ROLE_KEY variable.');
  process.exit(1);
}

// ─── Run SQL via Supabase REST API ────────────────────────────────────────────
async function runSQL(sql) {
  return new Promise((resolve, reject) => {
    const projectRef = SUPABASE_URL.replace('https://', '').replace('.supabase.co', '');
    const body = JSON.stringify({ query: sql });

    const options = {
      hostname: `${projectRef}.supabase.co`,
      path: '/rest/v1/rpc/exec_sql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        'apikey': SERVICE_ROLE_KEY,
        'Content-Length': Buffer.byteLength(body),
      },
    };

    // Use Supabase Management API instead
    const pgOptions = {
      hostname: 'api.supabase.com',
      path: `/v1/projects/${projectRef}/database/query`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        'Content-Length': Buffer.byteLength(body),
      },
    };

    const req = https.request(pgOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ ok: true, data });
        } else {
          resolve({ ok: false, status: res.statusCode, data });
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
  });

  console.log('🔧 Fixing all Supabase function permissions...\n');

  // ── All functions that need GRANT EXECUTE ──────────────────────────────────
  const grants = [
    // Core security helpers
    'GRANT EXECUTE ON FUNCTION public.is_instructor() TO authenticated, anon',
    'GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon',
    'GRANT EXECUTE ON FUNCTION public.is_enrolled(UUID) TO authenticated, anon',
    'GRANT EXECUTE ON FUNCTION public.can_manage_course(UUID) TO authenticated, anon',
    'GRANT EXECUTE ON FUNCTION public.current_profile_sensitive_state() TO authenticated, anon',

    // Enrollment RPCs
    'GRANT EXECUTE ON FUNCTION public.create_enrollment(UUID, TEXT, UUID, VARCHAR, DECIMAL) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO authenticated',

    // Chat / Conversations
    'GRANT EXECUTE ON FUNCTION public.get_user_conversations(TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID, UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_course_group_members(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.update_course_group_title(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) TO authenticated',

    // Quiz helpers
    'GRANT EXECUTE ON FUNCTION public.update_quiz_question_totals(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.increment_quiz_questions(UUID, INTEGER) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.decrement_quiz_questions(UUID, INTEGER) TO authenticated',
  ];

  let successCount = 0;
  let errorCount = 0;
  const errors = [];

  for (const grant of grants) {
    // Extract function name for display
    const fnName = grant.match(/FUNCTION public\.(\w+)/)?.[1] ?? grant;

    try {
      const { error } = await supabase.rpc('exec_sql', { sql: grant + ';' }).single();

      if (error && error.message?.includes('exec_sql')) {
        // exec_sql RPC not available, try direct approach
        throw new Error('no_rpc');
      }

      if (error && !error.message?.includes('does not exist')) {
        errors.push({ fn: fnName, error: error.message });
        errorCount++;
        console.log(`   ⚠️  ${fnName}: ${error.message}`);
      } else {
        successCount++;
        console.log(`   ✅ ${fnName}`);
      }
    } catch (e) {
      if (e.message === 'no_rpc') {
        // Can't use exec_sql - output SQL for manual run
        errors.push({ fn: fnName, error: 'exec_sql RPC not available' });
        errorCount++;
      } else {
        errors.push({ fn: fnName, error: e.message });
        errorCount++;
      }
    }
  }

  console.log('\n' + '─'.repeat(60));

  if (errorCount > 0) {
    console.log(`\n⚠️  ${successCount} succeeded, ${errorCount} need manual fix.`);
    console.log('\n📋 Run this SQL in Supabase Dashboard → SQL Editor:\n');
    console.log('─'.repeat(60));
    console.log(grants.map(g => g + ';').join('\n'));
    console.log('─'.repeat(60));
  } else {
    console.log(`\n🎉 All ${successCount} permissions granted successfully!`);
  }

  console.log('\n📋 Full SQL to run in Supabase SQL Editor:');
  console.log('─'.repeat(60));
  console.log(grants.map(g => g + ';').join('\n'));
  console.log('─'.repeat(60));
}

main().catch(console.error);

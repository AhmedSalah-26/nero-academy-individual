// run_migration.mjs — يشغّل 039_get_course_details_rpc.sql على Supabase مباشرة
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Read env from .env.local
const envContent = readFileSync(resolve(__dirname, 'web_app/.env.local'), 'utf-8');
const envVars = Object.fromEntries(
  envContent.split('\n')
    .filter(l => l.includes('='))
    .map(l => { const i = l.indexOf('='); return [l.slice(0,i).trim(), l.slice(i+1).trim()]; })
);

const SUPABASE_URL = envVars['NEXT_PUBLIC_SUPABASE_URL'];
const SUPABASE_ANON_KEY = envVars['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

// Extract project ref from URL
const projectRef = SUPABASE_URL.replace('https://', '').split('.')[0];

const sql = readFileSync(
  resolve(__dirname, 'database_scripts/039_get_course_details_rpc.sql'),
  'utf-8'
);

console.log(`\n🔗 Project: ${projectRef}`);
console.log(`📄 Running: 039_get_course_details_rpc.sql\n`);

// Use Supabase REST SQL endpoint (requires service_role or uses pg_meta plugin)
// Fallback: call via supabase-js rpc('query') — but that needs service_role
// We'll use the Supabase Admin API via pg_meta
const url = `https://${projectRef}.supabase.co/rest/v1/rpc/query`;

// Try the Management API approach
const mgmtUrl = `https://api.supabase.com/v1/projects/${projectRef}/database/query`;

console.log('⚠️  Cannot run DDL via anon key — needs service_role or Management API token.');
console.log('\n📋 Copy & paste this SQL into your Supabase Dashboard → SQL Editor:\n');
console.log('━'.repeat(60));
console.log(sql);
console.log('━'.repeat(60));
console.log('\n🌐 Dashboard URL:');
console.log(`   https://supabase.com/dashboard/project/${projectRef}/sql/new\n`);

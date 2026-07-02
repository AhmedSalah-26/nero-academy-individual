/**
 * 🧪 Create Test Accounts for Huawei AppGallery Review
 *
 * Creates:
 *   - Test Instructor: instructor.test@shehabtech.app / Test@2025
 *   - Test Student:    student.test@shehabtech.app   / Test@2025
 *
 * HOW TO RUN:
 *   node create_test_accounts.mjs
 */

import { createClient } from '@supabase/supabase-js';

// ─── CONFIG ───────────────────────────────────────────────────────────────────
const SUPABASE_URL = 'https://ubjhdafxmncfbaldfivd.supabase.co';
const SERVICE_ROLE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViamhkYWZ4bW5jZmJhbGRmaXZkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTM2Nzk5MiwiZXhwIjoyMDk0OTQzOTkyfQ.VakrusnA5wwWR2UFOViuifAlCDs8ofyqVX8YHmglqlA';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ─── Account definitions ───────────────────────────────────────────────────────
const ACCOUNTS = [
  {
    email: 'instructor.test@shehabtech.app',
    password: 'Test@2025',
    name: 'Test Instructor',
    role: 'instructor',
    is_verified_instructor: true,
    headline_ar: 'مدرس تجريبي',
    headline_en: 'Test Instructor',
    bio_ar: 'حساب تجريبي لمراجعة التطبيق',
    bio_en: 'Test account for app review',
  },
  {
    email: 'student.test@shehabtech.app',
    password: 'Test@2025',
    name: 'Test Student',
    role: 'student',
    is_verified_instructor: false,
    headline_ar: null,
    headline_en: null,
    bio_ar: null,
    bio_en: null,
  },
];

async function createOrUpdateAccount(account) {
  console.log(`\n👤 Processing: ${account.email} (${account.role})`);

  // Check if already exists
  const { data: existing } = await supabase
    .from('profiles')
    .select('id')
    .eq('email', account.email)
    .maybeSingle();

  let userId;

  if (existing) {
    console.log('   ℹ️  Already exists, updating password & profile...');
    userId = existing.id;

    // Update password
    const { error: pwError } = await supabase.auth.admin.updateUserById(userId, {
      password: account.password,
      email_confirm: true,
    });
    if (pwError) console.warn('   ⚠️  Password update:', pwError.message);
  } else {
    // Create new auth user
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: account.email,
      password: account.password,
      email_confirm: true,
    });

    if (authError) {
      console.error('   ❌ Failed to create auth user:', authError.message);
      return null;
    }

    userId = authUser.user.id;
    console.log(`   ✅ Auth user created: ${userId}`);
  }

  // Upsert profile
  const profileData = {
    id: userId,
    email: account.email,
    name: account.name,
    role: account.role,
    is_active: true,
    updated_at: new Date().toISOString(),
  };

  if (account.is_verified_instructor) profileData.is_verified_instructor = true;
  if (account.headline_ar) profileData.headline_ar = account.headline_ar;
  if (account.headline_en) profileData.headline_en = account.headline_en;
  if (account.bio_ar) profileData.bio_ar = account.bio_ar;
  if (account.bio_en) profileData.bio_en = account.bio_en;

  const { error: profileError } = await supabase.from('profiles').upsert(profileData);
  if (profileError) {
    console.warn('   ⚠️  Profile note:', profileError.message);
  } else {
    console.log('   ✅ Profile upserted successfully');
  }

  return userId;
}

async function main() {
  console.log('🧪 Creating Test Accounts for AppGallery Review\n');
  console.log('═'.repeat(50));

  const results = [];
  for (const account of ACCOUNTS) {
    const userId = await createOrUpdateAccount(account);
    if (userId) results.push({ ...account, userId });
  }

  console.log('\n' + '═'.repeat(50));
  console.log('🎉 Done! Test Account Credentials:\n');

  for (const r of results) {
    console.log(`📋 ${r.role.toUpperCase()} Account:`);
    console.log(`   Email   : ${r.email}`);
    console.log(`   Password: ${r.password}`);
    console.log(`   User ID : ${r.userId}`);
    console.log();
  }

  console.log('═'.repeat(50));
  console.log('\n📝 For Huawei AppGallery "For Reviewer" section, use:');
  console.log('   Instructor → instructor.test@shehabtech.app / Test@2025');
  console.log('   Student    → student.test@shehabtech.app   / Test@2025');
}

main().catch(console.error);

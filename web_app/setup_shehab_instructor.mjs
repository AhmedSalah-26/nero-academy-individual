/**
 * 🚀 Supabase Setup Script - Create Shehab Instructor + Clean Old Data
 * 
 * HOW TO RUN:
 *   1. Add your SUPABASE_SERVICE_ROLE_KEY below (from Supabase Dashboard → Settings → API)
 *   2. Run: node database_scripts/setup_shehab_instructor.mjs
 */

import { createClient } from '@supabase/supabase-js';

// ─── CONFIG ───────────────────────────────────────────────────────────────────
const SUPABASE_URL = 'https://ubjhdafxmncfbaldfivd.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViamhkYWZ4bW5jZmJhbGRmaXZkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTM2Nzk5MiwiZXhwIjoyMDk0OTQzOTkyfQ.VakrusnA5wwWR2UFOViuifAlCDs8ofyqVX8YHmglqlA';  // ← ضع مفتاح service_role هنا

// ─── Instructor Credentials ───────────────────────────────────────────────────
const INSTRUCTOR_EMAIL = 'shehab@neroacademy.com';
const INSTRUCTOR_PASSWORD = 'Shehab@2025';
const INSTRUCTOR_NAME = 'شهاب';

// ─── Init Supabase Admin Client ───────────────────────────────────────────────
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

// ─── MAIN ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('🧹 Starting cleanup and setup...\n');

  // ── Step 1: Delete all Chat data ────────────────────────────────────────────
  console.log('🗑️  Deleting all chat/conversation data...');
  await supabase.from('message_reactions').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('messages').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('conversation_participants').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('conversations').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  console.log('   ✅ Chat data deleted');

  // ── Step 2: Delete all Courses data ─────────────────────────────────────────
  console.log('🗑️  Deleting all courses and related data...');
  await supabase.from('qa_answer_upvotes').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('qa_answers').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('qa_questions').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('quiz_attempts').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('quiz_questions').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('quizzes').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('lesson_progress').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('lesson_attachments').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('lessons').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('sections').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('announcements').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('coupon_courses').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('certificates').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('enrollments').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('parent_enrollments').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('cart_items').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('wishlist').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('course_reviews').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('courses').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  console.log('   ✅ All courses & related data deleted');

  // ── Step 3: Delete old instructor profiles ───────────────────────────────────
  console.log('🗑️  Deleting old instructor profiles...');
  const { data: oldInstructors } = await supabase
    .from('profiles')
    .select('id, email')
    .eq('role', 'instructor');

  if (oldInstructors && oldInstructors.length > 0) {
    for (const inst of oldInstructors) {
      console.log(`   Deleting instructor: ${inst.email}`);
      await supabase.auth.admin.deleteUser(inst.id);
    }
    console.log(`   ✅ Deleted ${oldInstructors.length} old instructor(s)`);
  } else {
    console.log('   ℹ️  No old instructors found');
  }

  // ── Step 4: Create Shehab instructor account ─────────────────────────────────
  console.log(`\n👤 Creating instructor account: ${INSTRUCTOR_EMAIL}`);

  // Check if already exists
  const { data: existing } = await supabase
    .from('profiles')
    .select('id')
    .eq('email', INSTRUCTOR_EMAIL)
    .single();

  let userId;

  if (existing) {
    console.log('   ℹ️  User already exists, updating...');
    userId = existing.id;
  } else {
    // Create new auth user
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: INSTRUCTOR_EMAIL,
      password: INSTRUCTOR_PASSWORD,
      email_confirm: true,
    });

    if (authError) {
      console.error('   ❌ Failed to create auth user:', authError.message);
      process.exit(1);
    }

    userId = authUser.user.id;
    console.log(`   ✅ Auth user created: ${userId}`);

    // Insert into profiles (trigger may do this automatically)
    const { error: insertError } = await supabase.from('profiles').upsert({
      id: userId,
      email: INSTRUCTOR_EMAIL,
      name: INSTRUCTOR_NAME,
      role: 'instructor',
    });

    if (insertError) {
      console.log('   ℹ️  Profile insert note:', insertError.message, '(trigger may have already inserted it)');
    }
  }

  // Update profile with full instructor info
  const { error: updateError } = await supabase
    .from('profiles')
    .update({
      name: INSTRUCTOR_NAME,
      role: 'instructor',
      is_verified_instructor: true,
      is_active: true,
      headline_ar: 'مدرس البرمجة',
      headline_en: 'Programming Instructor',
      bio_ar: 'مدرس برمجة متخصص في تعليم المبتدئين من الصفر خطوة بخطوة',
      bio_en: 'Programming instructor specializing in teaching beginners from scratch, step by step',
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId);

  if (updateError) {
    console.error('   ❌ Failed to update profile:', updateError.message);
  } else {
    console.log('   ✅ Profile updated successfully');
  }

  // ── Done ─────────────────────────────────────────────────────────────────────
  console.log('\n' + '─'.repeat(50));
  console.log('🎉 Setup complete!\n');
  console.log('📋 Instructor Credentials:');
  console.log(`   Email   : ${INSTRUCTOR_EMAIL}`);
  console.log(`   Password: ${INSTRUCTOR_PASSWORD}`);
  console.log(`   User ID : ${userId}`);
  console.log('─'.repeat(50));
}

main().catch(console.error);

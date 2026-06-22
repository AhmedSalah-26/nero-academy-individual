-- ============================================================
-- 🧹 Script: Create Shehab Instructor + Clean Old Data
-- Version: 1.0 | June 2026
-- ⚠️  Run this in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- STEP 1: Delete all chat/conversation data
-- (CASCADE handles messages & participants automatically)
-- ────────────────────────────────────────────────────────────
DELETE FROM message_reactions;
DELETE FROM messages;
DELETE FROM conversation_participants;
DELETE FROM conversations;

-- ────────────────────────────────────────────────────────────
-- STEP 2: Delete all course-related data
-- (CASCADE handles most child tables, but we'll be explicit)
-- ────────────────────────────────────────────────────────────
DELETE FROM qa_answer_upvotes;
DELETE FROM qa_answers;
DELETE FROM qa_questions;
DELETE FROM quiz_attempts;
DELETE FROM quiz_questions;
DELETE FROM quizzes;
DELETE FROM lesson_progress;
DELETE FROM lesson_attachments;
DELETE FROM lessons;
DELETE FROM sections;
DELETE FROM announcements;
DELETE FROM coupon_courses;
DELETE FROM certificates;
DELETE FROM enrollments;
DELETE FROM parent_enrollments;
DELETE FROM cart_items;
DELETE FROM wishlist;
DELETE FROM course_reviews;
DELETE FROM courses;

-- ────────────────────────────────────────────────────────────
-- STEP 3: (Optional) Delete old student profiles too
-- Comment out if you want to keep students
-- ────────────────────────────────────────────────────────────
-- DELETE FROM profiles WHERE role = 'student';

-- ────────────────────────────────────────────────────────────
-- STEP 4: Create Shehab instructor account in auth.users
-- then insert into profiles
--
-- ⚠️  IMPORTANT: Replace the email & password below
--    Email:    shehab@neroacademy.com
--    Password: Shehab@2025
--
-- After running this, Supabase will create the auth user
-- and the trigger will auto-insert into profiles.
-- We then update the profile to set role = 'instructor'.
-- ────────────────────────────────────────────────────────────

-- Create auth user via Supabase admin function
SELECT supabase_admin.create_user(
  '{"email": "shehab@neroacademy.com", "password": "Shehab@2025", "email_confirm": true}'::jsonb
);

-- ⚠️  If the above gives an error, use the Supabase Dashboard instead:
--     Authentication → Users → Add User → enter email & password → confirm email

-- ────────────────────────────────────────────────────────────
-- STEP 5: Update profile to instructor role
-- (Run this AFTER creating the auth user above)
-- ────────────────────────────────────────────────────────────
UPDATE profiles
SET
  name                  = 'شهاب',
  role                  = 'instructor',
  is_verified_instructor = TRUE,
  is_active             = TRUE,
  headline_ar           = 'مدرس البرمجة',
  headline_en           = 'Programming Instructor',
  bio_ar                = 'مدرس برمجة متخصص في تعليم المبتدئين من الصفر',
  bio_en                = 'Programming instructor specializing in teaching beginners from scratch',
  updated_at            = NOW()
WHERE email = 'shehab@neroacademy.com';

-- ────────────────────────────────────────────────────────────
-- ✅ Verify everything worked
-- ────────────────────────────────────────────────────────────
SELECT id, email, name, role, is_verified_instructor, created_at
FROM profiles
WHERE email = 'shehab@neroacademy.com';

SELECT COUNT(*) AS remaining_courses FROM courses;
SELECT COUNT(*) AS remaining_conversations FROM conversations;

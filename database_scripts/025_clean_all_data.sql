-- ============================================================
-- 025_clean_all_data.sql
-- تنظيف كامل لبيانات قاعدة البيانات مع الحفاظ على الهيكل
-- ⚠️ تحذير: هذا الأمر يحذف جميع البيانات بشكل نهائي
-- ============================================================

-- تعطيل الـ triggers مؤقتاً لتجنب مشاكل الـ foreign keys
SET session_replication_role = 'replica';

-- ============================================================
-- 1. بيانات التعلم والتقدم
-- ============================================================
TRUNCATE TABLE public.lesson_progress              RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.quiz_attempts                RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.certificates                 RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.assignment_submissions       RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.submission_rubric_scores     RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.bookmarks                    RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.notes                        RESTART IDENTITY CASCADE;

-- ============================================================
-- 2. التقييمات والأسئلة
-- ============================================================
TRUNCATE TABLE public.review_reports               RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.course_reviews               RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.qa_answer_upvotes            RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.qa_answers                   RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.qa_questions                 RESTART IDENTITY CASCADE;

-- ============================================================
-- 3. المنتدى والرسائل
-- ============================================================
TRUNCATE TABLE public.course_forum_reactions       RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.course_forum_read_receipts   RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.course_forum_pinned_messages RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.course_forum_messages        RESTART IDENTITY CASCADE;

-- ============================================================
-- 4. الطلبات والاشتراكات
-- ============================================================
TRUNCATE TABLE public.coupon_usages                RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.cart_items                   RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.payout_items                 RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.instructor_payouts           RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.instructor_earnings          RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.enrollments                  RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.parent_enrollments           RESTART IDENTITY CASCADE;

-- ============================================================
-- 5. الاشعارات والاجهزة
-- ============================================================
TRUNCATE TABLE public.announcement_reads           RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.device_tokens                RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.notifications                RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.notification_preferences     RESTART IDENTITY CASCADE;

-- ============================================================
-- 6. السلة والمفضلة والتقارير
-- ============================================================
TRUNCATE TABLE public.wishlist                     RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.course_reports               RESTART IDENTITY CASCADE;

-- ============================================================
-- 7. محتوى الكورسات
-- (عَلّق الأسطر دي لو عايز تحتفظ بالكورسات)
-- ============================================================
TRUNCATE TABLE public.assignment_rubrics           RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.assignments                  RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.quiz_questions               RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.quizzes                      RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.lesson_attachments           RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.course_attachments           RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.lessons                      RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.sections                     RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.courses                      RESTART IDENTITY CASCADE;

-- ============================================================
-- 8. الكوبونات والبانرات والاعلانات
-- ============================================================
TRUNCATE TABLE public.coupon_categories            RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.coupon_courses               RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.coupons                      RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.banners                      RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.announcements                RESTART IDENTITY CASCADE;

-- ============================================================
-- 9. بيانات المستخدمين
-- ⚠️ ألغِ التعليق لو عايز تحذف بيانات المستخدمين أيضاً
-- ============================================================
-- TRUNCATE TABLE public.parent_student_links RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE public.instructor_profiles  RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE public.profiles             RESTART IDENTITY CASCADE;

-- ============================================================
-- إعادة تفعيل الـ triggers
-- ============================================================
SET session_replication_role = 'origin';

-- تحقق من النتيجة - كم صف تبقى في كل جدول
SELECT 
  tablename AS "الجدول",
  n_live_tup AS "عدد الصفوف المتبقية"
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

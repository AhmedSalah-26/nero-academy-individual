-- ============================================================
-- Nasaq full database bootstrap
-- Run this once on a NEW EMPTY Supabase project from SQL Editor.
-- Includes base schema, Ahmed/Shehab updates, triggers, RPCs, and Nasaq flow.
-- Excludes destructive/old seed scripts: 012_create_shehab_instructor.sql, 025_clean_all_data.sql.
-- ============================================================


-- ============================================================
-- 001_individual_lms_schema.sql
-- ============================================================
-- ============================================================
-- ðŸŽ“ LMS (Learning Management System) - Individual/Single-Instructor LMS Database Schema
-- Ù…Ø®Ø·Ø· Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ù„Ù†Ø³Ø®Ø© Ø§Ù„Ù…Ø¯Ø±Ø³ Ø§Ù„ÙˆØ§Ø­Ø¯ (Ù…Ø¯Ø±Ø³ ÙˆØ§Ø­Ø¯ + Ø·Ù„Ø§Ø¨)
-- Version: 2.0 | May 2026
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop old tables if they exist to start fresh
-- (Add CASCADE to ensure everything is cleaned up properly)
DROP TABLE IF EXISTS message_reactions CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversation_participants CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS review_reports CASCADE;
DROP TABLE IF EXISTS course_reports CASCADE;
DROP TABLE IF EXISTS coupon_usages CASCADE;
DROP TABLE IF EXISTS coupon_courses CASCADE;
DROP TABLE IF EXISTS coupon_categories CASCADE;
DROP TABLE IF EXISTS coupons CASCADE;
DROP TABLE IF EXISTS announcement_reads CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS quiz_attempts CASCADE;
DROP TABLE IF EXISTS quiz_questions CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS qa_answer_upvotes CASCADE;
DROP TABLE IF EXISTS qa_answers CASCADE;
DROP TABLE IF EXISTS qa_questions CASCADE;
DROP TABLE IF EXISTS bookmarks CASCADE;
DROP TABLE IF EXISTS notes CASCADE;
DROP TABLE IF EXISTS course_reviews CASCADE;
DROP TABLE IF EXISTS certificates CASCADE;
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS parent_enrollments CASCADE;
DROP TABLE IF EXISTS wishlist CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS lesson_attachments CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS levels CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS banners CASCADE;

-- Also drop old multi-instructor tables if they exist
DROP TABLE IF EXISTS instructor_profiles CASCADE;
DROP TABLE IF EXISTS instructor_earnings CASCADE;
DROP TABLE IF EXISTS instructor_payouts CASCADE;
DROP TABLE IF EXISTS payout_items CASCADE;
DROP TABLE IF EXISTS instructor_applications CASCADE;
DROP TABLE IF EXISTS instructor_balances CASCADE;
DROP TABLE IF EXISTS instructor_withdrawals CASCADE;
DROP TABLE IF EXISTS instructor_balance CASCADE;
DROP TABLE IF EXISTS earnings_transactions CASCADE;

-- ============================================================
-- PART 1: CORE TABLES
-- ============================================================

-- 1.1 PROFILES TABLE (extends Supabase Auth)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'instructor')),
  avatar_url TEXT,
  -- Instructor specific fields
  headline_ar TEXT,
  headline_en TEXT,
  bio_ar TEXT,
  bio_en TEXT,
  expertise TEXT[] DEFAULT '{}',
  social_links JSONB DEFAULT '{}',
  is_verified_instructor BOOLEAN DEFAULT FALSE,
  -- Student specific fields
  interests TEXT[] DEFAULT '{}',
  -- Common fields
  is_active BOOLEAN DEFAULT TRUE,
  is_banned BOOLEAN DEFAULT FALSE,
  banned_until TIMESTAMPTZ,
  ban_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_active ON profiles(is_active) WHERE is_active = TRUE;

-- 1.2 CATEGORIES TABLE (Course Categories)
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  name_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  image_url TEXT,
  icon_name TEXT,
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  courses_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_active ON categories(is_active);
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_sort ON categories(sort_order);

-- 1.3 LEVELS TABLE (Dynamic levels)
CREATE TABLE levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description_ar TEXT,
  description_en TEXT,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_levels_active ON levels(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_levels_order ON levels(display_order);

-- 1.4 COURSES TABLE (Main courses table)
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  level_id UUID REFERENCES levels(id) ON DELETE SET NULL,
  -- Basic Info
  title_ar TEXT NOT NULL,
  title_en TEXT,
  subtitle_ar TEXT,
  subtitle_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  -- Media
  thumbnail_url TEXT,
  preview_video_url TEXT,
  -- Pricing
  price DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  discount_price DECIMAL(10,2) CHECK (discount_price >= 0),
  pricing_options JSONB NOT NULL DEFAULT '[]',
  is_free BOOLEAN DEFAULT FALSE,
  currency TEXT DEFAULT 'EGP',
  level TEXT DEFAULT 'beginner', -- Backward compatibility
  language TEXT DEFAULT 'ar',
  -- Content Stats (auto-calculated)
  total_duration INTEGER DEFAULT 0, -- in minutes
  total_lessons INTEGER DEFAULT 0,
  total_sections INTEGER DEFAULT 0,
  -- Enrollment Stats
  enrolled_count INTEGER DEFAULT 0,
  max_students INTEGER, -- NULL = unlimited
  -- Rating (auto-calculated)
  rating DECIMAL(3,2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  rating_count INTEGER DEFAULT 0,
  -- Course Content
  requirements JSONB DEFAULT '[]',
  objectives JSONB DEFAULT '[]',
  target_audience JSONB DEFAULT '[]',
  group_links JSONB DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  -- Certificate
  has_certificate BOOLEAN DEFAULT TRUE,
  certificate_template_id UUID,
  -- Status
  is_published BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  is_suspended BOOLEAN DEFAULT FALSE,
  suspension_reason TEXT,
  -- Flash Sale / Limited Offer
  is_flash_sale BOOLEAN DEFAULT FALSE,
  flash_sale_price DECIMAL(10,2),
  flash_sale_start TIMESTAMPTZ,
  flash_sale_end TIMESTAMPTZ,
  -- Timestamps
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_courses_instructor ON courses(teacher_id);
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE INDEX idx_courses_level_id ON courses(level_id);
CREATE INDEX idx_courses_published ON courses(is_published) WHERE is_published = TRUE;
CREATE INDEX idx_courses_active ON courses(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_courses_featured ON courses(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_courses_created ON courses(created_at DESC);

-- 1.5 SECTIONS TABLE (Course Sections)
CREATE TABLE sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  sort_order INTEGER DEFAULT 0,
  total_duration INTEGER DEFAULT 0, -- in minutes
  total_lessons INTEGER DEFAULT 0,
  is_published BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sections_course ON sections(course_id);
CREATE INDEX idx_sections_sort ON sections(course_id, sort_order);

-- 1.6 LESSONS TABLE (Individual Lessons with file uploads)
CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Basic Info
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  -- Content Type
  type TEXT DEFAULT 'video' CHECK (type IN ('video', 'article', 'quiz', 'assignment', 'resource', 'live', 'document', 'file')),
  -- Video Content
  video_url TEXT,
  video_provider TEXT DEFAULT 'supabase', -- supabase, youtube, vimeo, bunny
  video_duration INTEGER DEFAULT 0, -- in seconds
  -- Article Content
  article_content_ar TEXT,
  article_content_en TEXT,
  -- File Upload columns
  file_url TEXT,
  file_name TEXT,
  file_size INTEGER,
  file_type TEXT,
  -- Settings
  sort_order INTEGER DEFAULT 0,
  is_preview BOOLEAN DEFAULT FALSE,
  is_published BOOLEAN DEFAULT TRUE,
  is_mandatory BOOLEAN DEFAULT TRUE,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lessons_section ON lessons(section_id);
CREATE INDEX idx_lessons_course ON lessons(course_id);
CREATE INDEX idx_lessons_sort ON lessons(section_id, sort_order);

-- 1.7 LESSON_ATTACHMENTS TABLE (Downloadable resources)
CREATE TABLE lesson_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_name_ar TEXT,
  file_url TEXT NOT NULL,
  file_type TEXT,
  file_size INTEGER,
  download_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_attachments_lesson ON lesson_attachments(lesson_id);

-- ============================================================
-- PART 2: ENROLLMENT & PROGRESS TABLES
-- ============================================================

-- 2.1 CART_ITEMS TABLE (Shopping Cart)
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  price_at_add DECIMAL(10,2),
  pricing_option JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_cart_items_user ON cart_items(user_id);

-- 2.2 WISHLIST TABLE (Saved courses)
CREATE TABLE wishlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_wishlist_user ON wishlist(user_id);

-- 2.3 PARENT_ENROLLMENTS TABLE (Checkout Session grouping)
CREATE TABLE parent_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  coupon_id UUID, -- FK set later
  coupon_code VARCHAR(50),
  coupon_discount DECIMAL(10,2) DEFAULT 0,
  payment_method TEXT DEFAULT 'card',
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_transaction_id TEXT,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_parent_enrollments_user ON parent_enrollments(user_id);
CREATE INDEX idx_parent_enrollments_status ON parent_enrollments(payment_status);

-- 2.4 ENROLLMENTS TABLE (Course enrollments)
CREATE TABLE enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES profiles(id),
  parent_enrollment_id UUID REFERENCES parent_enrollments(id) ON DELETE SET NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  pricing_option JSONB,
  discount DECIMAL(10,2) DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('pending', 'active', 'completed', 'expired', 'refunded')),
  progress_percentage DECIMAL(5,2) DEFAULT 0,
  completed_lessons INTEGER DEFAULT 0,
  total_watch_time INTEGER DEFAULT 0,
  last_accessed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  certificate_id UUID,
  access_expires_at TIMESTAMPTZ,
  refund_requested_at TIMESTAMPTZ,
  refund_reason TEXT,
  refunded_at TIMESTAMPTZ,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_enrollments_user ON enrollments(user_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);
CREATE INDEX idx_enrollments_created ON enrollments(created_at DESC);

-- 2.5 LESSON_PROGRESS TABLE (Track lesson completion)
CREATE TABLE lesson_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE CASCADE,
  is_completed BOOLEAN DEFAULT FALSE,
  watch_time INTEGER DEFAULT 0,
  last_position INTEGER DEFAULT 0,
  completion_percentage DECIMAL(5,2) DEFAULT 0,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  last_watched_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

CREATE INDEX idx_lesson_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_lesson_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_lesson_progress_completed ON lesson_progress(is_completed) WHERE is_completed = TRUE;

-- 2.6 CERTIFICATES TABLE
CREATE TABLE certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE SET NULL,
  certificate_number TEXT UNIQUE NOT NULL,
  certificate_url TEXT,
  student_name TEXT NOT NULL,
  course_title TEXT NOT NULL,
  instructor_name TEXT NOT NULL,
  completion_date DATE NOT NULL,
  verification_code TEXT UNIQUE,
  is_valid BOOLEAN DEFAULT TRUE,
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_certificates_user ON certificates(user_id);
CREATE INDEX idx_certificates_number ON certificates(certificate_number);

-- ============================================================
-- PART 3: REVIEWS & INTERACTION TABLES
-- ============================================================

-- 3.1 COURSE_REVIEWS TABLE
CREATE TABLE course_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  is_visible BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, user_id)
);

CREATE INDEX idx_reviews_course ON course_reviews(course_id);
CREATE INDEX idx_reviews_user ON course_reviews(user_id);

-- 3.2 NOTES TABLE (Student notes on lessons)
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  timestamp_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notes_user_course ON notes(user_id, course_id);

-- 3.3 BOOKMARKS TABLE (Bookmarked lessons)
CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

-- 3.4 Q&A QUESTIONS TABLE
CREATE TABLE qa_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_answered BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_visible BOOLEAN DEFAULT TRUE,
  views_count INTEGER DEFAULT 0,
  answers_count INTEGER DEFAULT 0,
  upvotes_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_questions_course ON qa_questions(course_id);

-- 3.5 Q&A ANSWERS TABLE
CREATE TABLE qa_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES qa_questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_accepted BOOLEAN DEFAULT FALSE,
  is_instructor_answer BOOLEAN DEFAULT FALSE,
  is_visible BOOLEAN DEFAULT TRUE,
  upvotes_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_answers_question ON qa_answers(question_id);

-- 3.6 Q&A ANSWER UPVOTES TABLE
CREATE TABLE qa_answer_upvotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id UUID NOT NULL REFERENCES qa_answers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(answer_id, user_id)
);

CREATE INDEX idx_answer_upvotes_answer ON qa_answer_upvotes(answer_id);
CREATE INDEX idx_answer_upvotes_user ON qa_answer_upvotes(user_id);

-- ============================================================
-- PART 4: QUIZZES & ASSESSMENTS
-- ============================================================

-- 4.1 QUIZZES TABLE
CREATE TABLE quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  passing_score INTEGER DEFAULT 70,
  time_limit INTEGER,
  max_attempts INTEGER,
  shuffle_questions BOOLEAN DEFAULT FALSE,
  shuffle_answers BOOLEAN DEFAULT FALSE,
  show_correct_answers BOOLEAN DEFAULT TRUE,
  total_questions INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  attempts_count INTEGER DEFAULT 0,
  average_score DECIMAL(5,2) DEFAULT 0,
  is_published BOOLEAN DEFAULT TRUE,
  is_mandatory BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quizzes_lesson ON quizzes(lesson_id);
CREATE INDEX idx_quizzes_course ON quizzes(course_id);

-- 4.2 QUIZ_QUESTIONS TABLE
CREATE TABLE quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  question_ar TEXT NOT NULL,
  question_en TEXT,
  question_type TEXT DEFAULT 'single' CHECK (question_type IN ('single', 'multiple', 'true_false', 'text')),
  options JSONB DEFAULT '[]', -- [{id, text_ar, text_en, is_correct}]
  correct_answer TEXT,
  points INTEGER DEFAULT 1,
  explanation_ar TEXT,
  explanation_en TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quiz_questions_quiz ON quiz_questions(quiz_id);

-- 4.3 QUIZ_ATTEMPTS TABLE
CREATE TABLE quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE SET NULL,
  score INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  percentage DECIMAL(5,2) DEFAULT 0,
  passed BOOLEAN DEFAULT FALSE,
  answers JSONB DEFAULT '[]',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  time_spent INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quiz_attempts_quiz ON quiz_attempts(quiz_id);
CREATE INDEX idx_quiz_attempts_user ON quiz_attempts(user_id);

-- ============================================================
-- PART 5: ANNOUNCEMENTS & NOTIFICATIONS
-- ============================================================

-- 5.1 ANNOUNCEMENTS TABLE
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  content_ar TEXT NOT NULL,
  content_en TEXT,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_published BOOLEAN DEFAULT TRUE,
  send_email BOOLEAN DEFAULT FALSE,
  views_count INTEGER DEFAULT 0,
  published_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_announcements_course ON announcements(course_id);

-- 5.2 ANNOUNCEMENT_READS TABLE
CREATE TABLE announcement_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(announcement_id, user_id)
);

-- ============================================================
-- PART 6: COUPONS SYSTEM (Simplified)
-- ============================================================

-- 6.1 COUPONS TABLE
CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) NOT NULL UNIQUE,
  name_ar VARCHAR(255) NOT NULL,
  name_en VARCHAR(255),
  description_ar TEXT,
  description_en TEXT,
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
  max_discount_amount DECIMAL(10,2),
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  usage_limit INTEGER,
  usage_count INTEGER DEFAULT 0,
  usage_limit_per_user INTEGER DEFAULT 1,
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  scope VARCHAR(20) DEFAULT 'all' CHECK (scope IN ('all', 'categories', 'courses')),
  teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT TRUE,
  is_suspended BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_active ON coupons(is_active, start_date, end_date);

-- Add foreign key to parent_enrollments now that coupons is created
ALTER TABLE parent_enrollments 
ADD CONSTRAINT fk_parent_enrollments_coupon 
FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE SET NULL;

-- 6.2 COUPON_CATEGORIES TABLE
CREATE TABLE coupon_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coupon_id, category_id)
);

-- 6.3 COUPON_COURSES TABLE
CREATE TABLE coupon_courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coupon_id, course_id)
);

-- 6.4 COUPON_USAGES TABLE
CREATE TABLE coupon_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES parent_enrollments(id) ON DELETE SET NULL,
  discount_amount DECIMAL(10,2) NOT NULL,
  used_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PART 7: REPORTS SYSTEM
-- ============================================================

-- 7.1 COURSE_REPORTS TABLE
CREATE TABLE course_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'rejected')),
  admin_response TEXT,
  admin_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- 7.2 REVIEW_REPORTS TABLE
CREATE TABLE review_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID REFERENCES course_reviews(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  cached_reviewer_id UUID,
  cached_review_comment TEXT,
  cached_review_rating INTEGER,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'rejected')),
  admin_response TEXT,
  admin_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- ============================================================
-- PART 8: BANNERS & MARKETING (Simplified target)
-- ============================================================

-- 8.1 BANNERS TABLE
CREATE TABLE banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar TEXT NOT NULL,
  title_en TEXT,
  subtitle_ar TEXT,
  subtitle_en TEXT,
  image_url TEXT NOT NULL,
  link_type TEXT DEFAULT 'none' CHECK (link_type IN ('none', 'course', 'category', 'url')),
  link_value TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  clicks_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_banners_active ON banners(is_active, sort_order);

-- ============================================================
-- PART 9: CHAT & FORUM (Unified Conversations)
-- ============================================================

-- 9.1 conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(10) NOT NULL CHECK (type IN ('single', 'multi')),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    title TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.2 conversation_participants
CREATE TABLE conversation_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- 9.3 messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message_text TEXT,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
    media_url TEXT,
    file_name TEXT,
    file_size BIGINT,
    reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.4 message_reactions
CREATE TABLE message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

CREATE INDEX idx_conversations_course ON conversations(course_id);
CREATE INDEX idx_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);

-- ============================================================
-- PART 10: NOTIFICATIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  body_ar TEXT NOT NULL,
  body_en TEXT,
  type TEXT NOT NULL, -- enrollment, announcement, system, reply
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);


-- ============================================================
-- PART 11: CORE HELPER FUNCTIONS & TRIGGERS
-- ============================================================

-- 11.1 Check if user is instructor
CREATE OR REPLACE FUNCTION is_instructor()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'instructor'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 11.2 Check if user is admin (merged into instructor for single-instructor lms)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'instructor'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 11.3 Check if user is enrolled in course
CREATE OR REPLACE FUNCTION is_enrolled(p_course_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM enrollments 
    WHERE user_id = auth.uid() 
    AND course_id = p_course_id 
    AND status IN ('active', 'completed')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 11.4 Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 11.5 Update course rating on review changes
CREATE OR REPLACE FUNCTION update_course_rating()
RETURNS TRIGGER AS $$
DECLARE
  avg_rating DECIMAL(3,2);
  review_count INTEGER;
  target_course_id UUID;
BEGIN
  target_course_id := COALESCE(NEW.course_id, OLD.course_id);
  
  SELECT COALESCE(AVG(rating), 0), COUNT(*) 
  INTO avg_rating, review_count
  FROM course_reviews
  WHERE course_id = target_course_id AND is_visible = TRUE;
  
  UPDATE courses 
  SET rating = avg_rating, rating_count = review_count 
  WHERE id = target_course_id;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_course_rating ON course_reviews;
CREATE TRIGGER trigger_update_course_rating
  AFTER INSERT OR UPDATE OR DELETE ON course_reviews
  FOR EACH ROW EXECUTE FUNCTION update_course_rating();

-- 11.6 Update course stats (sections, lessons, duration)
CREATE OR REPLACE FUNCTION update_course_stats()
RETURNS TRIGGER AS $$
DECLARE
  v_course_id UUID;
  v_section_id UUID;
BEGIN
  IF TG_TABLE_NAME = 'sections' THEN
    v_course_id := COALESCE(NEW.course_id, OLD.course_id);
  ELSIF TG_TABLE_NAME = 'lessons' THEN
    v_course_id := COALESCE(NEW.course_id, OLD.course_id);
    v_section_id := COALESCE(NEW.section_id, OLD.section_id);
    
    IF v_section_id IS NOT NULL THEN
      UPDATE sections SET
        total_lessons = (SELECT COUNT(*) FROM lessons WHERE section_id = v_section_id AND is_published = TRUE),
        total_duration = (SELECT COALESCE(SUM(video_duration), 0) / 60 FROM lessons WHERE section_id = v_section_id AND is_published = TRUE)
      WHERE id = v_section_id;
    END IF;
  END IF;
  
  IF v_course_id IS NOT NULL THEN
    UPDATE courses SET
      total_sections = (SELECT COUNT(*) FROM sections WHERE course_id = v_course_id AND is_published = TRUE),
      total_lessons = (SELECT COUNT(*) FROM lessons WHERE course_id = v_course_id AND is_published = TRUE),
      total_duration = (SELECT COALESCE(SUM(video_duration), 0) / 60 FROM lessons WHERE course_id = v_course_id AND is_published = TRUE)
    WHERE id = v_course_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_course_stats_sections ON sections;
CREATE TRIGGER trigger_update_course_stats_sections
  AFTER INSERT OR UPDATE OR DELETE ON sections
  FOR EACH ROW EXECUTE FUNCTION update_course_stats();

DROP TRIGGER IF EXISTS trigger_update_course_stats_lessons ON lessons;
CREATE TRIGGER trigger_update_course_stats_lessons
  AFTER INSERT OR UPDATE OR DELETE ON lessons
  FOR EACH ROW EXECUTE FUNCTION update_course_stats();

-- 11.7 Update enrollment progress
CREATE OR REPLACE FUNCTION update_enrollment_progress()
RETURNS TRIGGER AS $$
DECLARE
  v_enrollment_id UUID;
  v_course_id UUID;
  v_total_lessons INTEGER;
  v_completed_lessons INTEGER;
  v_progress DECIMAL(5,2);
BEGIN
  v_course_id := COALESCE(NEW.course_id, OLD.course_id);
  
  SELECT id INTO v_enrollment_id
  FROM enrollments
  WHERE user_id = COALESCE(NEW.user_id, OLD.user_id) AND course_id = v_course_id;
  
  IF v_enrollment_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_total_lessons
    FROM lessons
    WHERE course_id = v_course_id AND is_published = TRUE AND is_mandatory = TRUE;
    
    SELECT COUNT(*) INTO v_completed_lessons
    FROM lesson_progress
    WHERE enrollment_id = v_enrollment_id AND is_completed = TRUE
    AND lesson_id IN (SELECT id FROM lessons WHERE course_id = v_course_id AND is_mandatory = TRUE);
    
    IF v_total_lessons > 0 THEN
      v_progress := (v_completed_lessons::DECIMAL / v_total_lessons) * 100;
    ELSE
      v_progress := 0;
    END IF;
    
    UPDATE enrollments SET
      progress_percentage = v_progress,
      completed_lessons = v_completed_lessons,
      total_watch_time = (SELECT COALESCE(SUM(watch_time), 0) FROM lesson_progress WHERE enrollment_id = v_enrollment_id),
      last_accessed_at = NOW(),
      completed_at = CASE WHEN v_progress >= 100 THEN NOW() ELSE NULL END,
      status = CASE WHEN v_progress >= 100 THEN 'completed' ELSE status END
    WHERE id = v_enrollment_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_enrollment_progress ON lesson_progress;
CREATE TRIGGER trigger_update_enrollment_progress
  AFTER INSERT OR UPDATE ON lesson_progress
  FOR EACH ROW EXECUTE FUNCTION update_enrollment_progress();

-- 11.8 Update course enrolled count on enrollment state change
CREATE OR REPLACE FUNCTION update_instructor_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE courses SET
    enrolled_count = (SELECT COUNT(*) FROM enrollments WHERE course_id = COALESCE(NEW.course_id, OLD.course_id) AND status IN ('active', 'completed'))
  WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_instructor_stats ON enrollments;
CREATE TRIGGER trigger_update_instructor_stats
  AFTER INSERT OR UPDATE OR DELETE ON enrollments
  FOR EACH ROW EXECUTE FUNCTION update_instructor_stats();

-- 11.9 Update answer upvotes count
CREATE OR REPLACE FUNCTION update_qa_answer_upvotes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE qa_answers
    SET upvotes_count = upvotes_count + 1
    WHERE id = NEW.answer_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE qa_answers
    SET upvotes_count = GREATEST(0, upvotes_count - 1)
    WHERE id = OLD.answer_id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_qa_answer_upvotes_count ON qa_answer_upvotes;
CREATE TRIGGER trigger_update_qa_answer_upvotes_count
  AFTER INSERT OR DELETE ON qa_answer_upvotes
  FOR EACH ROW EXECUTE FUNCTION update_qa_answer_upvotes_count();


-- ============================================================
-- PART 12: USER FACING FUNCTIONS
-- ============================================================

-- 12.1 Create Enrollment Function
CREATE OR REPLACE FUNCTION create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_total_subtotal DECIMAL := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM cart_items WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;
  
  SELECT COALESCE(SUM(
    CASE 
      WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
      ELSE COALESCE(c.discount_price, c.price)
    END
  ), 0) INTO v_total_subtotal
  FROM cart_items ci
  JOIN courses c ON c.id = ci.course_id
  WHERE ci.user_id = p_user_id;
  
  INSERT INTO parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    p_user_id,
    v_total_subtotal - COALESCE(p_coupon_discount, 0),
    v_total_subtotal,
    COALESCE(p_coupon_discount, 0),
    p_coupon_id, p_coupon_code, COALESCE(p_coupon_discount, 0),
    p_payment_method,
    CASE WHEN v_total_subtotal - COALESCE(p_coupon_discount, 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;
  
  FOR v_course IN 
    SELECT 
      c.id as course_id,
      c.teacher_id,
      CASE 
        WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
        ELSE COALESCE(c.discount_price, c.price)
      END as final_price
    FROM cart_items ci
    JOIN courses c ON c.id = ci.course_id
    WHERE ci.user_id = p_user_id
  LOOP
    INSERT INTO enrollments (
      user_id, course_id, teacher_id, parent_enrollment_id,
      price, status, enrolled_at
    )
    VALUES (
      p_user_id, v_course.course_id, v_course.teacher_id, v_parent_enrollment_id,
      v_course.final_price,
      CASE WHEN v_course.final_price = 0 OR (v_total_subtotal - COALESCE(p_coupon_discount, 0) = 0) THEN 'active' ELSE 'pending' END,
      NOW()
    )
    RETURNING id INTO v_enrollment_id;
  END LOOP;
  
  IF p_coupon_id IS NOT NULL THEN
    INSERT INTO coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (p_coupon_id, p_user_id, v_parent_enrollment_id, COALESCE(p_coupon_discount, 0));
    
    UPDATE coupons SET usage_count = usage_count + 1 WHERE id = p_coupon_id;
  END IF;
  
  DELETE FROM cart_items WHERE user_id = p_user_id;
  
  RETURN v_parent_enrollment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12.2 Confirm Payment Function
CREATE OR REPLACE FUNCTION confirm_enrollment_payment(
  p_parent_enrollment_id UUID,
  p_transaction_id TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE parent_enrollments SET
    payment_status = 'paid',
    payment_transaction_id = p_transaction_id,
    paid_at = NOW()
  WHERE id = p_parent_enrollment_id;
  
  UPDATE enrollments SET
    status = 'active'
  WHERE parent_enrollment_id = p_parent_enrollment_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12.3 Update Lesson Progress Function
CREATE OR REPLACE FUNCTION update_lesson_progress(
  p_lesson_id UUID,
  p_watch_time INTEGER DEFAULT 0,
  p_last_position INTEGER DEFAULT 0,
  p_is_completed BOOLEAN DEFAULT FALSE
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_course_id UUID;
  v_enrollment_id UUID;
  v_progress_id UUID;
  v_result JSON;
BEGIN
  SELECT course_id INTO v_course_id FROM lessons WHERE id = p_lesson_id;
  
  SELECT id INTO v_enrollment_id
  FROM enrollments
  WHERE user_id = v_user_id AND course_id = v_course_id AND status = 'active';
  
  IF v_enrollment_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not enrolled in this course');
  END IF;
  
  INSERT INTO lesson_progress (
    user_id, lesson_id, course_id, enrollment_id,
    watch_time, last_position, is_completed, completed_at
  )
  VALUES (
    v_user_id, p_lesson_id, v_course_id, v_enrollment_id,
    p_watch_time, p_last_position, p_is_completed,
    CASE WHEN p_is_completed THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id, lesson_id) DO UPDATE SET
    watch_time = GREATEST(lesson_progress.watch_time, EXCLUDED.watch_time),
    last_position = EXCLUDED.last_position,
    is_completed = lesson_progress.is_completed OR EXCLUDED.is_completed,
    completed_at = COALESCE(lesson_progress.completed_at, EXCLUDED.completed_at),
    last_watched_at = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_progress_id;
  
  SELECT json_build_object(
    'success', true,
    'progress_id', v_progress_id,
    'course_progress', progress_percentage,
    'completed_lessons', completed_lessons
  ) INTO v_result
  FROM enrollments WHERE id = v_enrollment_id;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12.4 Issue Certificate Function
CREATE OR REPLACE FUNCTION issue_certificate(p_course_id UUID)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_enrollment RECORD;
  v_course RECORD;
  v_instructor RECORD;
  v_user RECORD;
  v_certificate_id UUID;
  v_certificate_number TEXT;
  v_verification_code TEXT;
BEGIN
  SELECT * INTO v_enrollment
  FROM enrollments
  WHERE user_id = v_user_id AND course_id = p_course_id AND status = 'completed';
  
  IF v_enrollment IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Course not completed');
  END IF;
  
  IF v_enrollment.certificate_id IS NOT NULL THEN
    RETURN json_build_object('success', true, 'certificate_id', v_enrollment.certificate_id, 'already_issued', true);
  END IF;
  
  SELECT * INTO v_course FROM courses WHERE id = p_course_id;
  
  IF NOT v_course.has_certificate THEN
    RETURN json_build_object('success', false, 'error', 'Course does not offer certificates');
  END IF;
  
  SELECT name INTO v_instructor FROM profiles WHERE id = v_course.teacher_id;
  SELECT name INTO v_user FROM profiles WHERE id = v_user_id;
  
  v_certificate_number := 'CERT-' || UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 8));
  v_verification_code := UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 12));
  
  INSERT INTO certificates (
    user_id, course_id, enrollment_id,
    certificate_number, verification_code,
    student_name, course_title, instructor_name,
    completion_date
  )
  VALUES (
    v_user_id, p_course_id, v_enrollment.id,
    v_certificate_number, v_verification_code,
    COALESCE(v_user.name, 'Student'),
    COALESCE(v_course.title_ar, v_course.title_en),
    COALESCE(v_instructor.name, 'Instructor'),
    CURRENT_DATE
  )
  RETURNING id INTO v_certificate_id;
  
  UPDATE enrollments SET certificate_id = v_certificate_id WHERE id = v_enrollment.id;
  
  RETURN json_build_object(
    'success', true,
    'certificate_id', v_certificate_id,
    'certificate_number', v_certificate_number,
    'verification_code', v_verification_code
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12.5 Validate Coupon Function
CREATE OR REPLACE FUNCTION validate_coupon(
  p_coupon_code VARCHAR,
  p_user_id UUID,
  p_cart_total DECIMAL,
  p_course_ids UUID[] DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_coupon RECORD;
  v_user_usage_count INTEGER;
  v_discount_amount DECIMAL;
BEGIN
  SELECT * INTO v_coupon FROM coupons 
  WHERE code = UPPER(p_coupon_code) AND is_active = TRUE AND is_suspended = FALSE;
  
  IF v_coupon IS NULL THEN
    RETURN json_build_object('valid', false, 'error_ar', 'ÙƒÙˆØ¯ Ø§Ù„Ø®ØµÙ… ØºÙŠØ± ØµØ­ÙŠØ­', 'error_en', 'Invalid coupon code');
  END IF;
  
  IF v_coupon.start_date > NOW() THEN
    RETURN json_build_object('valid', false, 'error_ar', 'ÙƒÙˆØ¯ Ø§Ù„Ø®ØµÙ… Ù„Ù… ÙŠØ¨Ø¯Ø£ Ø¨Ø¹Ø¯', 'error_en', 'Coupon not started yet');
  END IF;
  
  IF v_coupon.end_date IS NOT NULL AND v_coupon.end_date < NOW() THEN
    RETURN json_build_object('valid', false, 'error_ar', 'ÙƒÙˆØ¯ Ø§Ù„Ø®ØµÙ… Ù…Ù†ØªÙ‡ÙŠ', 'error_en', 'Coupon expired');
  END IF;
  
  IF v_coupon.usage_limit IS NOT NULL AND v_coupon.usage_count >= v_coupon.usage_limit THEN
    RETURN json_build_object('valid', false, 'error_ar', 'ØªÙ… Ø§Ø³ØªÙ†ÙØ§Ø¯ Ø§Ù„ÙƒÙˆØ¨ÙˆÙ†', 'error_en', 'Coupon exhausted');
  END IF;
  
  SELECT COUNT(*) INTO v_user_usage_count FROM coupon_usages WHERE coupon_id = v_coupon.id AND user_id = p_user_id;
  IF v_user_usage_count >= v_coupon.usage_limit_per_user THEN
    RETURN json_build_object('valid', false, 'error_ar', 'Ù„Ù‚Ø¯ Ø§Ø³ØªØ®Ø¯Ù…Øª Ù‡Ø°Ø§ Ø§Ù„ÙƒÙˆØ¨ÙˆÙ† Ù…Ù† Ù‚Ø¨Ù„', 'error_en', 'Already used this coupon');
  END IF;
  
  IF p_cart_total < v_coupon.min_order_amount THEN
    RETURN json_build_object('valid', false, 'error_ar', 'Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ø¯Ù†Ù‰ Ù„Ù„Ø·Ù„Ø¨ ' || v_coupon.min_order_amount, 'error_en', 'Minimum order is ' || v_coupon.min_order_amount);
  END IF;
  
  IF v_coupon.discount_type = 'percentage' THEN
    v_discount_amount := p_cart_total * (v_coupon.discount_value / 100);
    IF v_coupon.max_discount_amount IS NOT NULL AND v_discount_amount > v_coupon.max_discount_amount THEN
      v_discount_amount := v_coupon.max_discount_amount;
    END IF;
  ELSE
    v_discount_amount := LEAST(v_coupon.discount_value, p_cart_total);
  END IF;
  
  RETURN json_build_object(
    'valid', true,
    'coupon_id', v_coupon.id,
    'code', v_coupon.code,
    'name_ar', v_coupon.name_ar,
    'name_en', v_coupon.name_en,
    'discount_type', v_coupon.discount_type,
    'discount_value', v_coupon.discount_value,
    'discount_amount', ROUND(v_discount_amount, 2),
    'final_amount', ROUND(p_cart_total - v_discount_amount, 2)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- PART 13: CHAT HELPER FUNCTIONS
-- ============================================================

-- 13.1 Helper to avoid recursive RLS checks on conversation_participants
CREATE OR REPLACE FUNCTION is_conversation_participant(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM conversation_participants cp
        WHERE cp.conversation_id = p_conversation_id
        AND cp.user_id = p_user_id
    );
$$;

-- 13.2 Create or get course forum conversation
CREATE OR REPLACE FUNCTION get_or_create_course_conversation(p_course_id UUID, p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_teacher_id UUID;
BEGIN
    SELECT id INTO v_conversation_id
    FROM conversations
    WHERE course_id = p_course_id AND type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        SELECT teacher_id INTO v_teacher_id
        FROM courses WHERE id = p_course_id;

        INSERT INTO conversations (type, course_id, title, created_by)
        SELECT 'multi', p_course_id, COALESCE(c.title_ar, c.title_en, 'Course Forum'), COALESCE(v_teacher_id, p_user_id)
        FROM courses c WHERE c.id = p_course_id
        RETURNING id INTO v_conversation_id;

        IF v_teacher_id IS NOT NULL THEN
            INSERT INTO conversation_participants (conversation_id, user_id, role)
            VALUES (v_conversation_id, v_teacher_id, 'admin')
            ON CONFLICT (conversation_id, user_id) DO NOTHING;
        END IF;
    END IF;

    INSERT INTO conversation_participants (conversation_id, user_id, role)
    VALUES (v_conversation_id, p_user_id, 'member')
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13.3 Get or create single conversation
CREATE OR REPLACE FUNCTION get_or_create_single_conversation(p_user1_id UUID, p_user2_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    SELECT c.id INTO v_conversation_id
    FROM conversations c
    JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = p_user1_id
    JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = p_user2_id
    WHERE c.type = 'single'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        INSERT INTO conversations (type, created_by)
        VALUES ('single', p_user1_id)
        RETURNING id INTO v_conversation_id;

        INSERT INTO conversation_participants (conversation_id, user_id, role)
        VALUES
            (v_conversation_id, p_user1_id, 'member'),
            (v_conversation_id, p_user2_id, 'member');
    END IF;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13.4 Get user conversations list
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID, p_type TEXT DEFAULT NULL)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM conversation_participants cp_other
            JOIN profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id != p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM conversation_participants cp_other
            JOIN profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id != p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM conversations c
    JOIN conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- PART 14: INSTRUCTOR DASHBOARD STATS & REVENUE CHART (No Payout Table dependency)
-- ============================================================

-- 14.1 Get Instructor Dashboard Stats (Directly from enrollments)
CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_teacher_id UUID := auth.uid();
    v_stats JSON;
    v_total_courses INT;
    v_published_courses INT;
    v_total_students INT;
    v_total_enrollments INT;
    v_monthly_enrollments INT;
    v_total_earnings NUMERIC;
    v_available_balance NUMERIC;
    v_pending_balance NUMERIC;
    v_average_rating NUMERIC;
    v_total_reviews INT;
    v_unanswered_questions INT;
BEGIN
    -- Get course counts
    SELECT COUNT(*), COUNT(CASE WHEN is_published THEN 1 END)
    INTO v_total_courses, v_published_courses
    FROM courses WHERE teacher_id = v_teacher_id;
    
    -- Get student/enrollment counts
    SELECT 
        COUNT(DISTINCT e.user_id),
        COUNT(*),
        COUNT(CASE WHEN e.enrolled_at >= DATE_TRUNC('month', NOW()) THEN 1 END)
    INTO v_total_students, v_total_enrollments, v_monthly_enrollments
    FROM enrollments e 
    JOIN courses c ON c.id = e.course_id 
    WHERE c.teacher_id = v_teacher_id;
    
    -- Get earnings directly from enrollments (price paid)
    SELECT 
        COALESCE(SUM(e.price), 0)
    INTO v_total_earnings
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.teacher_id = v_teacher_id AND e.status IN ('active', 'completed');
    
    -- Available balance is equal to total earnings in single instructor setup
    v_available_balance := v_total_earnings;
    
    -- Pending balance represents courses that are pending payment
    SELECT 
        COALESCE(SUM(e.price), 0)
    INTO v_pending_balance
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.teacher_id = v_teacher_id AND e.status = 'pending';
    
    -- Get ratings
    SELECT COALESCE(AVG(cr.rating), 0), COUNT(*)
    INTO v_average_rating, v_total_reviews
    FROM course_reviews cr 
    JOIN courses c ON c.id = cr.course_id 
    WHERE c.teacher_id = v_teacher_id;
    
    -- Get unanswered questions
    SELECT COUNT(*)
    INTO v_unanswered_questions
    FROM qa_questions q 
    JOIN courses c ON c.id = q.course_id 
    WHERE c.teacher_id = v_teacher_id AND q.is_answered = false;
    
    -- Build result JSON
    v_stats := json_build_object(
        'total_courses', COALESCE(v_total_courses, 0),
        'published_courses', COALESCE(v_published_courses, 0),
        'total_students', COALESCE(v_total_students, 0),
        'total_enrollments', COALESCE(v_total_enrollments, 0),
        'monthly_enrollments', COALESCE(v_monthly_enrollments, 0),
        'total_earnings', COALESCE(v_total_earnings, 0),
        'available_balance', COALESCE(v_available_balance, 0),
        'pending_balance', COALESCE(v_pending_balance, 0),
        'average_rating', ROUND(COALESCE(v_average_rating, 0)::numeric, 1),
        'total_reviews', COALESCE(v_total_reviews, 0),
        'unanswered_questions', COALESCE(v_unanswered_questions, 0)
    );

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14.2 Get Instructor Revenue Chart
CREATE OR REPLACE FUNCTION get_instructor_revenue_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_teacher_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
        COALESCE(SUM(e.price), 0)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN enrollments e ON 
        DATE_TRUNC('day', e.enrolled_at) = dates.date
        AND e.teacher_id = v_teacher_id
        AND e.status IN ('active', 'completed')
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14.3 Get Instructor Enrollments Chart
CREATE OR REPLACE FUNCTION get_instructor_enrollments_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_teacher_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
        COUNT(e.id)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN enrollments e ON 
        DATE_TRUNC('day', e.enrolled_at) = dates.date
        AND e.teacher_id = v_teacher_id
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14.4 Process Refund
CREATE OR REPLACE FUNCTION public.process_refund(
  p_enrollment_id UUID,
  p_reason TEXT
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.enrollments
  SET status = 'refunded',
      refunded_at = NOW(),
      refund_reason = p_reason
  WHERE id = p_enrollment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- PART 15: ROW LEVEL SECURITY POLICIES (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE qa_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE qa_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE qa_answer_upvotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- 15.1 profiles Policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- 15.2 categories Policies
CREATE POLICY "Anyone can view categories" ON categories FOR SELECT USING (is_active = true);
CREATE POLICY "Instructor can manage categories" ON categories FOR ALL USING (is_admin());

-- 15.3 levels Policies
CREATE POLICY "Anyone can view active levels" ON levels FOR SELECT USING (is_active = true);
CREATE POLICY "Instructor can manage levels" ON levels FOR ALL USING (is_admin());

-- 15.4 courses Policies
CREATE POLICY "Anyone can view published courses" ON courses FOR SELECT USING (is_published = true AND is_active = true);
CREATE POLICY "Instructor can do everything on courses" ON courses FOR ALL USING (teacher_id = auth.uid() OR is_admin());

-- 15.5 sections Policies
CREATE POLICY "Anyone can view sections of published courses" ON sections FOR SELECT 
  USING (EXISTS (SELECT 1 FROM courses WHERE id = sections.course_id AND is_published = true) OR is_admin() OR is_enrolled(sections.course_id));
CREATE POLICY "Instructor can manage sections" ON sections FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses WHERE id = sections.course_id AND (teacher_id = auth.uid() OR is_admin())));

-- 15.6 lessons Policies
CREATE POLICY "View lessons if enrolled or preview" ON lessons FOR SELECT 
  USING (is_preview = true OR is_enrolled(lessons.course_id) OR is_admin());
CREATE POLICY "Instructor can manage lessons" ON lessons FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses WHERE id = lessons.course_id AND (teacher_id = auth.uid() OR is_admin())));

-- 15.7 lesson_attachments Policies
CREATE POLICY "View attachments if enrolled" ON lesson_attachments FOR SELECT 
  USING (is_enrolled((SELECT course_id FROM lessons WHERE id = lesson_attachments.lesson_id)) OR is_admin());
CREATE POLICY "Instructor can manage attachments" ON lesson_attachments FOR ALL 
  USING (is_admin());

-- 15.8 cart_items Policies
CREATE POLICY "Users can manage their own cart" ON cart_items FOR ALL USING (user_id = auth.uid());

-- 15.9 wishlist Policies
CREATE POLICY "Users can manage their own wishlist" ON wishlist FOR ALL USING (user_id = auth.uid());

-- 15.10 parent_enrollments & enrollments Policies
CREATE POLICY "Users can view their own enrollments" ON parent_enrollments FOR SELECT USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "Users can view their individual enrollments" ON enrollments FOR SELECT USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "Instructor can view enrollments" ON enrollments FOR SELECT USING (is_admin());

-- 15.11 lesson_progress Policies
CREATE POLICY "Users can manage their own progress" ON lesson_progress FOR ALL USING (user_id = auth.uid() OR is_admin());

-- 15.12 certificates Policies
CREATE POLICY "Anyone can view certificates" ON certificates FOR SELECT USING (true);
CREATE POLICY "Users can insert certificates" ON certificates FOR INSERT WITH CHECK (user_id = auth.uid());

-- 15.13 course_reviews Policies
CREATE POLICY "Anyone can view reviews" ON course_reviews FOR SELECT USING (is_visible = true);
CREATE POLICY "Enrolled users can manage reviews" ON course_reviews FOR ALL USING (user_id = auth.uid());

-- 15.14 notes & bookmarks Policies
CREATE POLICY "Users can manage their own notes" ON notes FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Users can manage their own bookmarks" ON bookmarks FOR ALL USING (user_id = auth.uid());

-- 15.15 Q&A Policies
CREATE POLICY "Anyone can view visible QA" ON qa_questions FOR SELECT USING (is_visible = true);
CREATE POLICY "Authenticated can ask QA" ON qa_questions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users or instructor can update QA" ON qa_questions FOR UPDATE USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Anyone can view visible answers" ON qa_answers FOR SELECT USING (is_visible = true);
CREATE POLICY "Authenticated can answer QA" ON qa_answers FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users or instructor can update answers" ON qa_answers FOR UPDATE USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Anyone can view answer upvotes" ON qa_answer_upvotes FOR SELECT USING (true);
CREATE POLICY "Authenticated can upvote answers" ON qa_answer_upvotes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove their answer upvotes" ON qa_answer_upvotes FOR DELETE USING (auth.uid() = user_id);

-- 15.16 Quizzes Policies
CREATE POLICY "Enrolled can view quizzes" ON quizzes FOR SELECT USING (is_enrolled(course_id) OR is_admin());
CREATE POLICY "Instructor can manage quizzes" ON quizzes FOR ALL USING (is_admin());

CREATE POLICY "Enrolled can view quiz questions" ON quiz_questions FOR SELECT USING (is_enrolled((SELECT course_id FROM quizzes WHERE id = quiz_questions.quiz_id)) OR is_admin());
CREATE POLICY "Instructor can manage quiz questions" ON quiz_questions FOR ALL USING (is_admin());

CREATE POLICY "Users can manage quiz attempts" ON quiz_attempts FOR ALL USING (user_id = auth.uid() OR is_admin());

-- 15.17 Announcements Policies
CREATE POLICY "Enrolled can view announcements" ON announcements FOR SELECT USING (is_enrolled(course_id) OR is_admin());
CREATE POLICY "Instructor can manage announcements" ON announcements FOR ALL USING (is_admin());

-- 15.18 Coupons Policies
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT USING (is_active = true);
CREATE POLICY "Instructor can manage coupons" ON coupons FOR ALL USING (is_admin());

-- 15.19 Banners Policies
CREATE POLICY "Anyone can view active banners" ON banners FOR SELECT USING (is_active = true);
CREATE POLICY "Instructor can manage banners" ON banners FOR ALL USING (is_admin());

-- 15.20 Conversations Policies
CREATE POLICY "Participants can view conversations" ON conversations FOR SELECT USING (is_conversation_participant(id, auth.uid()) OR is_admin());
CREATE POLICY "Authenticated users can create conversations" ON conversations FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Participants can view members" ON conversation_participants FOR SELECT USING (is_conversation_participant(conversation_id, auth.uid()) OR is_admin());
CREATE POLICY "Participants can manage members" ON conversation_participants FOR ALL USING (is_conversation_participant(conversation_id, auth.uid()) OR is_admin());

CREATE POLICY "Participants can view messages" ON messages FOR SELECT USING (is_conversation_participant(conversation_id, auth.uid()) OR is_admin());
CREATE POLICY "Participants can send messages" ON messages FOR INSERT WITH CHECK (user_id = auth.uid() AND (is_conversation_participant(conversation_id, auth.uid()) OR is_admin()));
CREATE POLICY "Users can manage messages" ON messages FOR ALL USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "Participants can view reactions" ON message_reactions FOR SELECT USING (EXISTS (SELECT 1 FROM messages m WHERE m.id = message_reactions.message_id AND (is_conversation_participant(m.conversation_id, auth.uid()) OR is_admin())));
CREATE POLICY "Participants can manage reactions" ON message_reactions FOR ALL USING (user_id = auth.uid());


-- ============================================================
-- PART 16: REALTIME SUBSCRIPTIONS
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;


-- ============================================================
-- PART 17: STORAGE BUCKETS AND STORAGE POLICIES
-- ============================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('courses', 'courses', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('categories', 'categories', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('banners', 'banners', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('videos', 'videos', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('certificates', 'certificates', true) ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public SELECT courses" ON storage.objects FOR SELECT USING (bucket_id = 'courses');
CREATE POLICY "Instructor manage courses" ON storage.objects FOR ALL USING (bucket_id = 'courses' AND is_instructor());

CREATE POLICY "Public SELECT categories" ON storage.objects FOR SELECT USING (bucket_id = 'categories');
CREATE POLICY "Instructor manage categories" ON storage.objects FOR ALL USING (bucket_id = 'categories' AND is_admin());

CREATE POLICY "Public SELECT avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Authenticated manage avatars" ON storage.objects FOR ALL USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "Public SELECT banners" ON storage.objects FOR SELECT USING (bucket_id = 'banners');
CREATE POLICY "Instructor manage banners" ON storage.objects FOR ALL USING (bucket_id = 'banners' AND is_admin());

CREATE POLICY "View videos if enrolled" ON storage.objects FOR SELECT USING (bucket_id = 'videos' AND auth.role() = 'authenticated');
CREATE POLICY "Instructor manage videos" ON storage.objects FOR ALL USING (bucket_id = 'videos' AND is_instructor());

CREATE POLICY "View attachments if enrolled" ON storage.objects FOR SELECT USING (bucket_id = 'attachments' AND auth.role() = 'authenticated');
CREATE POLICY "Instructor manage attachments" ON storage.objects FOR ALL USING (bucket_id = 'attachments' AND is_instructor());

CREATE POLICY "Public SELECT certificates" ON storage.objects FOR SELECT USING (bucket_id = 'certificates');
CREATE POLICY "System write certificates" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'certificates' AND auth.role() = 'authenticated');


-- ============================================================
-- PART 18: GRANTS
-- ============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON public.categories TO anon;
GRANT SELECT ON public.courses TO anon;
GRANT SELECT ON public.levels TO anon;
GRANT SELECT ON public.banners TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;


-- ============================================================
-- PART 19: SEED DATA (Default levels & categories)
-- ============================================================

-- Insert Default Levels
INSERT INTO levels (name_ar, name_en, slug, description_ar, description_en, display_order, is_active)
VALUES
  ('Ù…Ø¨ØªØ¯Ø¦', 'Beginner', 'beginner', 'Ù…Ù†Ø§Ø³Ø¨ Ù„Ù„Ù…Ø¨ØªØ¯Ø¦ÙŠÙ† Ø¨Ø¯ÙˆÙ† Ø®Ø¨Ø±Ø© Ø³Ø§Ø¨Ù‚Ø©', 'Suitable for beginners with no prior experience', 1, true),
  ('Ù…ØªÙˆØ³Ø·', 'Intermediate', 'intermediate', 'ÙŠØªØ·Ù„Ø¨ Ù…Ø¹Ø±ÙØ© Ø£Ø³Ø§Ø³ÙŠØ© Ø¨Ø§Ù„Ù…ÙˆØ¶ÙˆØ¹', 'Requires basic knowledge of the subject', 2, true),
  ('Ù…ØªÙ‚Ø¯Ù…', 'Advanced', 'advanced', 'Ù„Ù„Ù…ØªÙ‚Ø¯Ù…ÙŠÙ† Ø°ÙˆÙŠ Ø§Ù„Ø®Ø¨Ø±Ø©', 'For advanced learners with experience', 3, true),
  ('Ø¬Ù…ÙŠØ¹ Ø§Ù„Ù…Ø³ØªÙˆÙŠØ§Øª', 'All Levels', 'all_levels', 'Ù…Ù†Ø§Ø³Ø¨ Ù„Ø¬Ù…ÙŠØ¹ Ø§Ù„Ù…Ø³ØªÙˆÙŠØ§Øª', 'Suitable for all levels', 4, true)
ON CONFLICT (slug) DO NOTHING;

-- Insert default categories
INSERT INTO categories (id, name_ar, name_en, description_ar, description_en, icon_name, image_url, sort_order, is_active) VALUES
('c1000000-0000-4000-a000-000000000001', 'Ø§Ù„Ø¨Ø±Ù…Ø¬Ø© ÙˆØ§Ù„ØªØ·ÙˆÙŠØ±', 'Development', 'ØªØ¹Ù„Ù… Ø§Ù„Ø¨Ø±Ù…Ø¬Ø© ÙˆØªØ·ÙˆÙŠØ± Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª', 'Learn programming and app development', 'code', 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400', 1, true),
('c1000000-0000-4000-a000-000000000002', 'Ø§Ù„ØªØµÙ…ÙŠÙ…', 'Design', 'ØªØµÙ…ÙŠÙ… Ø§Ù„Ø¬Ø±Ø§ÙÙŠÙƒ ÙˆÙˆØ§Ø¬Ù‡Ø§Øª Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù…', 'Graphic design and UI/UX', 'palette', 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400', 2, true),
('c1000000-0000-4000-a000-000000000003', 'Ø§Ù„Ø±ÙŠØ§Ø¶ÙŠØ§Øª ÙˆØ§Ù„Ø¹Ù„ÙˆÙ…', 'Math & Science', 'Ø´Ø±Ø­ Ù…Ù†Ø§Ù‡Ø¬ Ø§Ù„Ø±ÙŠØ§Ø¶ÙŠØ§Øª ÙˆØ§Ù„Ø¹Ù„ÙˆÙ…', 'Mathematics and Science curricula', 'functions', 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400', 3, true)
ON CONFLICT (id) DO NOTHING;



-- ============================================================
-- 002_new_app_updates.sql
-- ============================================================
-- ============================================================
-- 1. Create Missing Tables (Not in 001 Schema)
-- ============================================================

-- Fix: Make quizzes.lesson_id nullable to support course-level quizzes
ALTER TABLE IF EXISTS quizzes ALTER COLUMN lesson_id DROP NOT NULL;

-- Fix: Add image_url column to quiz_questions (for question images)
ALTER TABLE IF EXISTS quiz_questions ADD COLUMN IF NOT EXISTS image_url TEXT;


-- A. Instructor Earnings Table
CREATE TABLE IF NOT EXISTS instructor_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES enrollments(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Amounts
  gross_amount DECIMAL(10,2) NOT NULL, -- total paid by student
  platform_fee DECIMAL(10,2) NOT NULL, -- platform's share
  net_amount DECIMAL(10,2) NOT NULL, -- instructor's share
  revenue_share DECIMAL(5,2) DEFAULT 70.00, -- percentage at time of sale
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'available', 'paid', 'refunded')),
  available_at TIMESTAMPTZ, -- when it becomes available for payout
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_earnings_instructor ON instructor_earnings(teacher_id);
CREATE INDEX IF NOT EXISTS idx_earnings_course ON instructor_earnings(course_id);
CREATE INDEX IF NOT EXISTS idx_earnings_status ON instructor_earnings(status);

-- B. Direct Messages Table
CREATE TABLE IF NOT EXISTS direct_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dm_sender ON direct_messages (sender_id, created_at);
CREATE INDEX IF NOT EXISTS idx_dm_receiver ON direct_messages (receiver_id, created_at);

-- ============================================================
-- 2. App Fixes & Updates (Missing Columns and Triggers)
-- ============================================================

-- Add course statistics columns
ALTER TABLE IF EXISTS courses ADD COLUMN IF NOT EXISTS lesson_count INT DEFAULT 0;
ALTER TABLE IF EXISTS courses ADD COLUMN IF NOT EXISTS section_count INT DEFAULT 0;
ALTER TABLE IF EXISTS courses ADD COLUMN IF NOT EXISTS total_revenue DECIMAL(10,2) DEFAULT 0;

-- Function to update course stats
CREATE OR REPLACE FUNCTION update_course_stats(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_section_count INT;
    v_lesson_count INT;
    v_total_revenue DECIMAL(10,2);
BEGIN
    -- Count sections
    SELECT COUNT(*) INTO v_section_count
    FROM sections
    WHERE course_id = p_course_id;
    
    -- Count lessons
    SELECT COUNT(*) INTO v_lesson_count
    FROM lessons
    WHERE course_id = p_course_id;
    
    -- Sum revenue from instructor_earnings
    SELECT COALESCE(SUM(net_amount), 0) INTO v_total_revenue
    FROM instructor_earnings
    WHERE course_id = p_course_id AND status IN ('available', 'paid', 'pending');
    
    -- Update course
    UPDATE courses
    SET section_count = v_section_count,
        lesson_count = v_lesson_count,
        total_revenue = v_total_revenue
    WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for sections
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_section()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for lessons
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_lesson()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for earnings
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_earning()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS section_stats_trigger ON sections;
DROP TRIGGER IF EXISTS lesson_stats_trigger ON lessons;
DROP TRIGGER IF EXISTS earning_stats_trigger ON instructor_earnings;

-- Create triggers
CREATE TRIGGER section_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON sections
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_section();

CREATE TRIGGER lesson_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON lessons
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_lesson();

CREATE TRIGGER earning_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON instructor_earnings
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_earning();

-- Update all existing courses stats immediately
DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        PERFORM update_course_stats(course_record.id);
    END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION update_course_stats(UUID) TO authenticated;

-- ============================================================
-- 3. Quiz Statistics Additions
-- ============================================================

-- Add columns to quizzes table
ALTER TABLE IF EXISTS quizzes ADD COLUMN IF NOT EXISTS attempts_count INT DEFAULT 0;
ALTER TABLE IF EXISTS quizzes ADD COLUMN IF NOT EXISTS average_score DECIMAL(5,2) DEFAULT 0;

-- Function to update quiz stats
CREATE OR REPLACE FUNCTION update_quiz_stats(p_quiz_id UUID)
RETURNS VOID AS $$
DECLARE
    v_attempts_count INT;
    v_average_score DECIMAL(5,2);
BEGIN
    SELECT 
        COUNT(*)::INT,
        COALESCE(AVG(percentage), 0)::DECIMAL(5,2)
    INTO v_attempts_count, v_average_score
    FROM quiz_attempts
    WHERE quiz_id = p_quiz_id
      AND completed_at IS NOT NULL;
    
    UPDATE quizzes
    SET attempts_count = v_attempts_count,
        average_score = v_average_score
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update stats
CREATE OR REPLACE FUNCTION trigger_update_quiz_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.completed_at IS NOT NULL AND (OLD.completed_at IS NULL OR OLD.completed_at != NEW.completed_at) THEN
        PERFORM update_quiz_stats(NEW.quiz_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS quiz_attempt_stats_trigger ON quiz_attempts;

CREATE TRIGGER quiz_attempt_stats_trigger
AFTER INSERT OR UPDATE ON quiz_attempts
FOR EACH ROW
EXECUTE FUNCTION trigger_update_quiz_stats();

-- Update all existing quizzes
DO $$
DECLARE
    quiz_record RECORD;
BEGIN
    FOR quiz_record IN SELECT id FROM quizzes LOOP
        PERFORM update_quiz_stats(quiz_record.id);
    END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION update_quiz_stats(UUID) TO authenticated;

-- ============================================================
-- 4. Direct Messages RLS Policies
-- ============================================================

ALTER TABLE IF EXISTS direct_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own DMs" ON direct_messages;
CREATE POLICY "Users can read own DMs" ON direct_messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send DMs" ON direct_messages;
CREATE POLICY "Users can send DMs" ON direct_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

SELECT 'All missing tables, columns, and triggers successfully added to 001 schema!' as status;
-- ============================================================
-- 5. Course Attachments Table
-- ============================================================

CREATE TABLE IF NOT EXISTS course_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_name_ar TEXT,
  file_url TEXT NOT NULL,
  file_type TEXT, -- pdf, zip, doc, jpg, png, etc.
  file_size INTEGER, -- in bytes
  download_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_course_attachments_course ON course_attachments(course_id);
CREATE INDEX IF NOT EXISTS idx_course_attachments_sort ON course_attachments(course_id, sort_order);

-- Enable RLS
ALTER TABLE course_attachments ENABLE ROW LEVEL SECURITY;

-- Policy: Instructors can manage their course attachments
DROP POLICY IF EXISTS "Instructors can manage their course attachments" ON course_attachments;
CREATE POLICY "Instructors can manage their course attachments" ON course_attachments
FOR ALL
USING (
  course_id IN (
    SELECT id FROM courses WHERE teacher_id = auth.uid()
  )
);

-- Policy: Enrolled students can view course attachments
DROP POLICY IF EXISTS "Enrolled students can view course attachments" ON course_attachments;
CREATE POLICY "Enrolled students can view course attachments" ON course_attachments
FOR SELECT
USING (
  course_id IN (
    SELECT course_id FROM enrollments 
    WHERE user_id = auth.uid() AND status = 'active'
  )
);

-- Policy: Admins can manage all attachments
DROP POLICY IF EXISTS "Admins can manage all attachments" ON course_attachments;
CREATE POLICY "Admins can manage all attachments" ON course_attachments
FOR ALL
USING (is_admin());

SELECT 'course_attachments table added successfully!' as status;

-- ============================================================
-- 6. Quiz Submit Function
-- ============================================================

DROP FUNCTION IF EXISTS submit_quiz_attempt(UUID, JSONB, INT);

CREATE OR REPLACE FUNCTION submit_quiz_attempt(
  p_attempt_id UUID,
  p_answers JSONB,
  p_time_spent INT DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_attempt RECORD;
  v_quiz RECORD;
  v_score INT := 0;
  v_total_points INT := 0;
  v_percentage DECIMAL;
  v_passed BOOLEAN;
  v_question RECORD;
  v_user_answer JSONB;
  v_correct_option_ids JSONB;
  v_is_correct BOOLEAN;
  v_debug_info JSONB := '[]'::jsonb;
BEGIN
  -- Get attempt
  SELECT * INTO v_attempt
  FROM quiz_attempts
  WHERE id = p_attempt_id AND user_id = v_user_id;

  IF v_attempt IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt not found or unauthorized');
  END IF;

  -- Check if already completed
  IF v_attempt.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt already completed');
  END IF;

  -- Get quiz
  SELECT * INTO v_quiz FROM quizzes WHERE id = v_attempt.quiz_id;

  IF v_quiz IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Quiz not found');
  END IF;

  -- Calculate score
  FOR v_question IN
    SELECT id, points, options
    FROM quiz_questions
    WHERE quiz_id = v_attempt.quiz_id
  LOOP
    v_total_points := v_total_points + v_question.points;

    -- Get user's answer for this question (array of option IDs)
    v_user_answer := p_answers->v_question.id::text;

    -- Get correct option IDs from the question options
    SELECT jsonb_agg(opt->>'id') INTO v_correct_option_ids
    FROM jsonb_array_elements(v_question.options) AS opt
    WHERE (opt->>'is_correct')::boolean = true;

    IF v_correct_option_ids IS NULL THEN
      v_correct_option_ids := '[]'::jsonb;
    END IF;

    -- Check if answer is correct
    IF v_user_answer IS NOT NULL AND jsonb_array_length(v_user_answer) > 0 THEN
      v_is_correct := (
        SELECT
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_user_answer) x) =
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_correct_option_ids) x)
      );
      IF v_is_correct THEN
        v_score := v_score + v_question.points;
      END IF;
    ELSE
      v_is_correct := false;
    END IF;

    v_debug_info := v_debug_info || jsonb_build_object(
      'question_id', v_question.id,
      'user_answer', v_user_answer,
      'correct_options', v_correct_option_ids,
      'is_correct', v_is_correct
    );
  END LOOP;

  -- Calculate percentage
  v_percentage := CASE
    WHEN v_total_points > 0 THEN (v_score::DECIMAL / v_total_points) * 100
    ELSE 0
  END;

  v_passed := v_percentage >= v_quiz.passing_score;

  -- Update attempt
  UPDATE quiz_attempts SET
    completed_at = NOW(),
    score        = v_score,
    total_points = v_total_points,
    percentage   = v_percentage,
    passed       = v_passed,
    time_spent   = p_time_spent,
    answers      = p_answers
  WHERE id = p_attempt_id;

  RETURN json_build_object(
    'success',       true,
    'attempt_id',    p_attempt_id,
    'score',         v_score,
    'total_points',  v_total_points,
    'percentage',    ROUND(v_percentage, 2),
    'passed',        v_passed,
    'passing_score', v_quiz.passing_score,
    'debug',         v_debug_info
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION submit_quiz_attempt(UUID, JSONB, INT) TO authenticated;

SELECT 'submit_quiz_attempt function added successfully!' as status;



-- ============================================================
-- 004_course_group_management.sql
-- ============================================================
-- 004_course_group_management.sql
-- Contains functions for managing course group (forum) members and settings.

-- 1. get_course_group_members
CREATE OR REPLACE FUNCTION public.get_course_group_members(p_course_id UUID)
RETURNS TABLE (
    user_id UUID,
    user_name TEXT,
    user_avatar TEXT,
    role TEXT,
    is_banned BOOLEAN,
    banned_reason TEXT,
    conversation_title TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conversation_id UUID;
    v_conversation_title TEXT;
BEGIN
    -- Get the course forum conversation id
    SELECT id, title INTO v_conversation_id, v_conversation_title
    FROM conversations
    WHERE course_id = p_course_id AND type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        cp.user_id,
        p.name AS user_name,
        p.avatar_url AS user_avatar,
        cp.role::text,
        cp.is_banned,
        cp.ban_reason AS banned_reason,
        v_conversation_title AS conversation_title
    FROM conversation_participants cp
    JOIN profiles p ON p.id = cp.user_id
    WHERE cp.conversation_id = v_conversation_id
    ORDER BY cp.role ASC, p.name ASC;
END;
$$;

-- 2. update_course_group_title
CREATE OR REPLACE FUNCTION public.update_course_group_title(p_course_id UUID, p_title TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Check if user is instructor or admin of the course
    -- (Omitted complex auth checks for brevity, assuming UI only shows this to admins/instructors)

    SELECT id INTO v_conversation_id
    FROM conversations
    WHERE course_id = p_course_id AND type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NOT NULL THEN
        UPDATE conversations
        SET title = p_title, updated_at = NOW()
        WHERE id = v_conversation_id;
    END IF;
END;
$$;

-- 3. manage_course_group_member
CREATE OR REPLACE FUNCTION public.manage_course_group_member(
    p_course_id UUID,
    p_target_user_id UUID,
    p_action TEXT,
    p_reason TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    SELECT id INTO v_conversation_id
    FROM conversations
    WHERE course_id = p_course_id AND type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        RAISE EXCEPTION 'Course group not found';
    END IF;

    IF p_action = 'remove' THEN
        DELETE FROM conversation_participants
        WHERE conversation_id = v_conversation_id AND user_id = p_target_user_id;

    ELSIF p_action = 'ban' THEN
        UPDATE conversation_participants
        SET is_banned = TRUE, ban_reason = p_reason, banned_at = NOW(), banned_by = auth.uid()
        WHERE conversation_id = v_conversation_id AND user_id = p_target_user_id;

    ELSIF p_action = 'unban' THEN
        UPDATE conversation_participants
        SET is_banned = FALSE, ban_reason = NULL, banned_at = NULL, banned_by = NULL
        WHERE conversation_id = v_conversation_id AND user_id = p_target_user_id;

    ELSIF p_action = 'admin' THEN
        UPDATE conversation_participants
        SET role = 'admin'
        WHERE conversation_id = v_conversation_id AND user_id = p_target_user_id;

    ELSIF p_action = 'member' THEN
        UPDATE conversation_participants
        SET role = 'member'
        WHERE conversation_id = v_conversation_id AND user_id = p_target_user_id;

    ELSE
        RAISE EXCEPTION 'Invalid action: %', p_action;
    END IF;
END;
$$;

-- 4. get_instructor_courses (Optional, if missing, but usually this is needed to list groups)
CREATE OR REPLACE FUNCTION public.get_instructor_courses(p_teacher_id UUID)
RETURNS TABLE (
    course_id UUID,
    title_ar TEXT,
    title_en TEXT,
    has_group BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS course_id,
        c.title_ar,
        c.title_en,
        EXISTS(
            SELECT 1 FROM conversations conv 
            WHERE conv.course_id = c.id AND conv.type = 'course_forum'
        ) AS has_group
    FROM courses c
    WHERE c.teacher_id = p_teacher_id
    ORDER BY c.created_at DESC;
END;
$$;



-- ============================================================
-- 005_qa_answer_upvotes.sql
-- ============================================================
-- =====================================================
-- Q&A Answer Upvotes
-- Apply this to existing Supabase projects that already
-- have qa_questions and qa_answers.
-- =====================================================

CREATE TABLE IF NOT EXISTS qa_answer_upvotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id UUID NOT NULL REFERENCES qa_answers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(answer_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_answer_upvotes_answer
  ON qa_answer_upvotes(answer_id);

CREATE INDEX IF NOT EXISTS idx_answer_upvotes_user
  ON qa_answer_upvotes(user_id);

ALTER TABLE qa_answer_upvotes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view answer upvotes" ON qa_answer_upvotes;
CREATE POLICY "Anyone can view answer upvotes"
  ON qa_answer_upvotes
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated can upvote answers" ON qa_answer_upvotes;
CREATE POLICY "Authenticated can upvote answers"
  ON qa_answer_upvotes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove their answer upvotes" ON qa_answer_upvotes;
CREATE POLICY "Users can remove their answer upvotes"
  ON qa_answer_upvotes
  FOR DELETE
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION update_qa_answer_upvotes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE qa_answers
    SET upvotes_count = upvotes_count + 1
    WHERE id = NEW.answer_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE qa_answers
    SET upvotes_count = GREATEST(0, upvotes_count - 1)
    WHERE id = OLD.answer_id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_qa_answer_upvotes_count ON qa_answer_upvotes;
CREATE TRIGGER trigger_update_qa_answer_upvotes_count
  AFTER INSERT OR DELETE ON qa_answer_upvotes
  FOR EACH ROW
  EXECUTE FUNCTION update_qa_answer_upvotes_count();

UPDATE qa_answers a
SET upvotes_count = (
  SELECT COUNT(*)
  FROM qa_answer_upvotes u
  WHERE u.answer_id = a.id
);

GRANT SELECT, INSERT, DELETE ON qa_answer_upvotes TO authenticated;



-- ============================================================
-- 006_security_rls_hardening.sql
-- ============================================================
-- 006_security_rls_hardening.sql
-- Security hardening based on SECURITY_RLS_REVIEW_AR.md.
-- Run on staging first, then verify the RPC and RLS test cases before production.

-- ============================================================
-- 1. Harden helper functions and profile creation
-- ============================================================

ALTER TABLE IF EXISTS public.conversation_participants
  ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS ban_reason TEXT,
  ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS banned_by UUID REFERENCES public.profiles(id);

CREATE OR REPLACE FUNCTION public.is_instructor()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'instructor'
      AND is_active = TRUE
      AND is_banned = FALSE
  );
$$;

-- This project currently uses the single-instructor model. Keep the existing
-- behavior, but make the check explicit and active-user only.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT public.is_instructor();
$$;

CREATE OR REPLACE FUNCTION public.is_enrolled(p_course_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.enrollments
    WHERE user_id = auth.uid()
      AND course_id = p_course_id
      AND status IN ('active', 'completed')
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_course(p_course_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.courses c
    JOIN public.profiles p ON p.id = auth.uid()
    WHERE c.id = p_course_id
      AND p.role = 'instructor'
      AND p.is_active = TRUE
      AND p.is_banned = FALSE
      AND (c.teacher_id = public.current_teacher_id() OR public.is_admin())
  );
$$;

CREATE OR REPLACE FUNCTION public.current_profile_sensitive_state()
RETURNS TABLE (
  role TEXT,
  is_active BOOLEAN,
  is_banned BOOLEAN,
  banned_until TIMESTAMPTZ,
  ban_reason TEXT,
  is_verified_instructor BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT
    p.role,
    p.is_active,
    p.is_banned,
    p.banned_until,
    p.ban_reason,
    p.is_verified_instructor
  FROM public.profiles p
  WHERE p.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    'student',
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$;

-- ============================================================
-- 2. Lock profile self-updates to non-sensitive fields
-- ============================================================

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update safe profile fields" ON public.profiles;

CREATE POLICY "Users can update safe profile fields"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND role IS NOT DISTINCT FROM (
    SELECT s.role FROM public.current_profile_sensitive_state() s
  )
  AND is_active IS NOT DISTINCT FROM (
    SELECT s.is_active FROM public.current_profile_sensitive_state() s
  )
  AND is_banned IS NOT DISTINCT FROM (
    SELECT s.is_banned FROM public.current_profile_sensitive_state() s
  )
  AND banned_until IS NOT DISTINCT FROM (
    SELECT s.banned_until FROM public.current_profile_sensitive_state() s
  )
  AND ban_reason IS NOT DISTINCT FROM (
    SELECT s.ban_reason FROM public.current_profile_sensitive_state() s
  )
  AND is_verified_instructor IS NOT DISTINCT FROM (
    SELECT s.is_verified_instructor FROM public.current_profile_sensitive_state() s
  )
);

-- ============================================================
-- 3. Enable missing RLS and add policies for sensitive tables
-- ============================================================

ALTER TABLE IF EXISTS public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.instructor_earnings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can manage members" ON public.conversation_participants;
DROP POLICY IF EXISTS "Course managers can manage conversation members" ON public.conversation_participants;
CREATE POLICY "Course managers can manage conversation members"
ON public.conversation_participants
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM public.conversations c
    WHERE c.id = conversation_id
      AND c.course_id IS NOT NULL
      AND public.can_manage_course(c.course_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.conversations c
    WHERE c.id = conversation_id
      AND c.course_id IS NOT NULL
      AND public.can_manage_course(c.course_id)
  )
);

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
ON public.notifications
FOR SELECT
USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Users can mark own notifications read" ON public.notifications;
CREATE POLICY "Users can mark own notifications read"
ON public.notifications
FOR UPDATE
USING (user_id = auth.uid() OR public.is_admin())
WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Instructors can view own earnings" ON public.instructor_earnings;
CREATE POLICY "Instructors can view own earnings"
ON public.instructor_earnings
FOR SELECT
USING (teacher_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Admins can manage earnings" ON public.instructor_earnings;
CREATE POLICY "Admins can manage earnings"
ON public.instructor_earnings
FOR ALL
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ============================================================
-- 4. Harden enrollment, payment, refund, and chat RPCs
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_coupon RECORD;
  v_total_subtotal DECIMAL := 0;
  v_coupon_discount DECIMAL := 0;
  v_user_usage_count INTEGER := 0;
BEGIN
  SELECT NULL::UUID AS id, NULL::VARCHAR AS code INTO v_coupon;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Cannot create enrollment for another user';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.cart_items WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  SELECT COALESCE(SUM(
    CASE
      WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
      ELSE COALESCE(c.discount_price, c.price)
    END
  ), 0)
  INTO v_total_subtotal
  FROM public.cart_items ci
  JOIN public.courses c ON c.id = ci.course_id
  WHERE ci.user_id = v_user_id;

  IF p_coupon_id IS NOT NULL OR p_coupon_code IS NOT NULL THEN
    SELECT *
    INTO v_coupon
    FROM public.coupons
    WHERE (id = p_coupon_id OR code = UPPER(p_coupon_code))
      AND is_active = TRUE
      AND is_suspended = FALSE
      AND start_date <= NOW()
      AND (end_date IS NULL OR end_date >= NOW())
      AND (usage_limit IS NULL OR usage_count < usage_limit)
      AND min_order_amount <= v_total_subtotal
    LIMIT 1;

    IF v_coupon.id IS NULL THEN
      RAISE EXCEPTION 'Invalid coupon';
    END IF;

    SELECT COUNT(*)
    INTO v_user_usage_count
    FROM public.coupon_usages
    WHERE coupon_id = v_coupon.id
      AND user_id = v_user_id;

    IF v_user_usage_count >= v_coupon.usage_limit_per_user THEN
      RAISE EXCEPTION 'Coupon usage limit exceeded';
    END IF;

    IF v_coupon.discount_type = 'percentage' THEN
      v_coupon_discount := v_total_subtotal * (v_coupon.discount_value / 100);
      IF v_coupon.max_discount_amount IS NOT NULL THEN
        v_coupon_discount := LEAST(v_coupon_discount, v_coupon.max_discount_amount);
      END IF;
    ELSE
      v_coupon_discount := LEAST(v_coupon.discount_value, v_total_subtotal);
    END IF;
  END IF;

  INSERT INTO public.parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    v_user_id,
    GREATEST(v_total_subtotal - v_coupon_discount, 0),
    v_total_subtotal,
    v_coupon_discount,
    v_coupon.id,
    v_coupon.code,
    v_coupon_discount,
    p_payment_method,
    CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;

  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.teacher_id,
      CASE
        WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
        ELSE COALESCE(c.discount_price, c.price)
      END AS final_price
    FROM public.cart_items ci
    JOIN public.courses c ON c.id = ci.course_id
    WHERE ci.user_id = v_user_id
  LOOP
    INSERT INTO public.enrollments (
      user_id, course_id, teacher_id, parent_enrollment_id,
      price, discount, status, enrolled_at
    )
    VALUES (
      v_user_id,
      v_course.course_id,
      v_course.teacher_id,
      v_parent_enrollment_id,
      v_course.final_price,
      CASE
        WHEN v_total_subtotal > 0 THEN ROUND(v_coupon_discount * (v_course.final_price / v_total_subtotal), 2)
        ELSE 0
      END,
      CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'active' ELSE 'pending' END,
      NOW()
    )
    RETURNING id INTO v_enrollment_id;
  END LOOP;

  IF v_coupon.id IS NOT NULL THEN
    INSERT INTO public.coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (v_coupon.id, v_user_id, v_parent_enrollment_id, v_coupon_discount);

    UPDATE public.coupons
    SET usage_count = usage_count + 1
    WHERE id = v_coupon.id;
  END IF;

  DELETE FROM public.cart_items WHERE user_id = v_user_id;

  RETURN v_parent_enrollment_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.confirm_enrollment_payment(
  p_parent_enrollment_id UUID,
  p_transaction_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.parent_enrollments
  SET payment_status = 'paid',
      payment_transaction_id = p_transaction_id,
      paid_at = NOW(),
      updated_at = NOW()
  WHERE id = p_parent_enrollment_id
    AND payment_status <> 'paid';

  UPDATE public.enrollments
  SET status = 'active',
      updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id
    AND status = 'pending';

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.process_refund(
  p_enrollment_id UUID,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_course_id UUID;
BEGIN
  SELECT course_id
  INTO v_course_id
  FROM public.enrollments
  WHERE id = p_enrollment_id;

  IF v_course_id IS NULL THEN
    RAISE EXCEPTION 'Enrollment not found';
  END IF;

  IF NOT public.can_manage_course(v_course_id) THEN
    RAISE EXCEPTION 'Not authorized to refund this enrollment';
  END IF;

  UPDATE public.enrollments
  SET status = 'refunded',
      refunded_at = NOW(),
      refund_reason = p_reason,
      updated_at = NOW()
  WHERE id = p_enrollment_id;

  UPDATE public.parent_enrollments pe
  SET payment_status = 'refunded',
      updated_at = NOW()
  WHERE pe.id = (
    SELECT e.parent_enrollment_id
    FROM public.enrollments e
    WHERE e.id = p_enrollment_id
  )
  AND NOT EXISTS (
    SELECT 1
    FROM public.enrollments e2
    WHERE e2.parent_enrollment_id = pe.id
      AND e2.status <> 'refunded'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_course_conversation(p_course_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_conversation_id UUID;
  v_teacher_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT (public.is_enrolled(p_course_id) OR public.can_manage_course(p_course_id)) THEN
    RAISE EXCEPTION 'Not authorized to join this course conversation';
  END IF;

  SELECT id
  INTO v_conversation_id
  FROM public.conversations
  WHERE course_id = p_course_id
    AND type = 'multi'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    SELECT teacher_id
    INTO v_teacher_id
    FROM public.courses
    WHERE id = p_course_id;

    INSERT INTO public.conversations (type, course_id, title, created_by)
    SELECT 'multi', p_course_id, COALESCE(c.title_ar, c.title_en, 'Course Forum'), COALESCE(v_teacher_id, v_user_id)
    FROM public.courses c
    WHERE c.id = p_course_id
    RETURNING id INTO v_conversation_id;

    IF v_teacher_id IS NOT NULL THEN
      INSERT INTO public.conversation_participants (conversation_id, user_id, role)
      VALUES (v_conversation_id, v_teacher_id, 'admin')
      ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;
  END IF;

  INSERT INTO public.conversation_participants (conversation_id, user_id, role)
  VALUES (v_conversation_id, v_user_id, CASE WHEN public.can_manage_course(p_course_id) THEN 'admin' ELSE 'member' END)
  ON CONFLICT (conversation_id, user_id) DO NOTHING;

  RETURN v_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_course_conversation(p_course_id UUID, p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot create conversation for another user';
  END IF;

  RETURN public.get_or_create_course_conversation(p_course_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_single_conversation(p_user1_id UUID, p_user2_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_conversation_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user1_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Cannot create conversation for another user';
  END IF;

  IF p_user1_id = p_user2_id THEN
    RAISE EXCEPTION 'Cannot create self conversation';
  END IF;

  SELECT c.id
  INTO v_conversation_id
  FROM public.conversations c
  JOIN public.conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = p_user1_id
  JOIN public.conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = p_user2_id
  WHERE c.type = 'single'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    INSERT INTO public.conversations (type, created_by)
    VALUES ('single', p_user1_id)
    RETURNING id INTO v_conversation_id;

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    VALUES
      (v_conversation_id, p_user1_id, 'member'),
      (v_conversation_id, p_user2_id, 'member')
    ON CONFLICT (conversation_id, user_id) DO NOTHING;
  END IF;

  RETURN v_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_type TEXT DEFAULT NULL)
RETURNS TABLE (
  conversation_id UUID,
  conversation_type VARCHAR(10),
  conversation_title TEXT,
  course_id UUID,
  created_at TIMESTAMPTZ,
  last_message_id UUID,
  last_message_text TEXT,
  last_message_user_id UUID,
  last_message_user_name TEXT,
  last_message_created_at TIMESTAMPTZ,
  participants_count BIGINT,
  other_user_name TEXT,
  other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  RETURN QUERY
  SELECT
    c.id AS conversation_id,
    c.type AS conversation_type,
    c.title AS conversation_title,
    c.course_id,
    c.created_at,
    lm.id AS last_message_id,
    lm.message_text AS last_message_text,
    lm.user_id AS last_message_user_id,
    p_sender.name AS last_message_user_name,
    lm.created_at AS last_message_created_at,
    (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
    CASE WHEN c.type = 'single' THEN (
      SELECT p_other.name
      FROM public.conversation_participants cp_other
      JOIN public.profiles p_other ON p_other.id = cp_other.user_id
      WHERE cp_other.conversation_id = c.id
        AND cp_other.user_id <> v_user_id
      LIMIT 1
    ) ELSE NULL END AS other_user_name,
    CASE WHEN c.type = 'single' THEN (
      SELECT p_other.avatar_url
      FROM public.conversation_participants cp_other
      JOIN public.profiles p_other ON p_other.id = cp_other.user_id
      WHERE cp_other.conversation_id = c.id
        AND cp_other.user_id <> v_user_id
      LIMIT 1
    ) ELSE NULL END AS other_user_avatar
  FROM public.conversations c
  JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = v_user_id
  LEFT JOIN LATERAL (
    SELECT m.id, m.message_text, m.user_id, m.created_at
    FROM public.messages m
    WHERE m.conversation_id = c.id
      AND m.is_deleted = FALSE
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON TRUE
  LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
  WHERE (p_type IS NULL OR c.type = p_type)
  ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id UUID, p_type TEXT DEFAULT NULL)
RETURNS TABLE (
  conversation_id UUID,
  conversation_type VARCHAR(10),
  conversation_title TEXT,
  course_id UUID,
  created_at TIMESTAMPTZ,
  last_message_id UUID,
  last_message_text TEXT,
  last_message_user_id UUID,
  last_message_user_name TEXT,
  last_message_created_at TIMESTAMPTZ,
  participants_count BIGINT,
  other_user_name TEXT,
  other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Cannot read conversations for another user';
  END IF;

  RETURN QUERY
  SELECT * FROM public.get_user_conversations(p_type);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_course_group_members(p_course_id UUID)
RETURNS TABLE (
  user_id UUID,
  user_name TEXT,
  user_avatar TEXT,
  role TEXT,
  is_banned BOOLEAN,
  banned_reason TEXT,
  conversation_title TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_conversation_id UUID;
  v_conversation_title TEXT;
BEGIN
  IF NOT public.can_manage_course(p_course_id) THEN
    RAISE EXCEPTION 'Not authorized to manage this course group';
  END IF;

  SELECT id, title
  INTO v_conversation_id, v_conversation_title
  FROM public.conversations
  WHERE course_id = p_course_id
    AND type = 'multi'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    cp.user_id,
    p.name AS user_name,
    p.avatar_url AS user_avatar,
    cp.role::text,
    COALESCE(cp.is_banned, FALSE) AS is_banned,
    cp.ban_reason AS banned_reason,
    v_conversation_title AS conversation_title
  FROM public.conversation_participants cp
  JOIN public.profiles p ON p.id = cp.user_id
  WHERE cp.conversation_id = v_conversation_id
  ORDER BY cp.role ASC, p.name ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_course_group_title(p_course_id UUID, p_title TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.can_manage_course(p_course_id) THEN
    RAISE EXCEPTION 'Not authorized to manage this course group';
  END IF;

  UPDATE public.conversations
  SET title = NULLIF(BTRIM(p_title), ''),
      updated_at = NOW()
  WHERE course_id = p_course_id
    AND type = 'multi';
END;
$$;

CREATE OR REPLACE FUNCTION public.manage_course_group_member(
  p_course_id UUID,
  p_target_user_id UUID,
  p_action TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_conversation_id UUID;
BEGIN
  IF NOT public.can_manage_course(p_course_id) THEN
    RAISE EXCEPTION 'Not authorized to manage this course group';
  END IF;

  SELECT id
  INTO v_conversation_id
  FROM public.conversations
  WHERE course_id = p_course_id
    AND type = 'multi'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    RAISE EXCEPTION 'Course group not found';
  END IF;

  IF p_action = 'remove' THEN
    DELETE FROM public.conversation_participants
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'ban' THEN
    UPDATE public.conversation_participants
    SET is_banned = TRUE,
        ban_reason = p_reason,
        banned_at = NOW(),
        banned_by = auth.uid()
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'unban' THEN
    UPDATE public.conversation_participants
    SET is_banned = FALSE,
        ban_reason = NULL,
        banned_at = NULL,
        banned_by = NULL
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'admin' THEN
    UPDATE public.conversation_participants
    SET role = 'admin'
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'member' THEN
    UPDATE public.conversation_participants
    SET role = 'member'
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSE
    RAISE EXCEPTION 'Invalid action: %', p_action;
  END IF;
END;
$$;

-- ============================================================
-- 5. Storage policy tightening for clearly-owned buckets
-- ============================================================

DROP POLICY IF EXISTS "Authenticated manage avatars" ON storage.objects;
DROP POLICY IF EXISTS "System write certificates" ON storage.objects;
DROP POLICY IF EXISTS "Users manage own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Admins write certificates" ON storage.objects;

CREATE POLICY "Users manage own avatars"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
)
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

CREATE POLICY "Admins write certificates"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'certificates' AND public.is_admin());

-- ============================================================
-- 6. Function execution grants
-- ============================================================

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM authenticated;

-- Helpers used inside RLS policies need execute permission for table reads.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'is_instructor',
        'is_admin',
        'is_enrolled',
        'is_conversation_participant',
        'can_manage_course',
        'current_profile_sensitive_state'
      )
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO anon, authenticated', r.oid::regprocedure);
  END LOOP;
END;
$$;

-- App-facing RPCs. Each function below must still enforce its own auth checks.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'add_phone_to_auth_user',
        'create_profile_for_phone_auth',
        'create_enrollment',
        'validate_coupon',
        'update_lesson_progress',
        'issue_certificate',
        'get_or_create_single_conversation',
        'get_or_create_course_conversation',
        'get_user_conversations',
        'get_course_group_members',
        'update_course_group_title',
        'manage_course_group_member',
        'get_instructor_forum_courses',
        'set_course_group_enabled',
        'process_refund',
        'get_instructor_dashboard_stats',
        'get_instructor_revenue_chart',
        'get_instructor_enrollments_chart',
        'submit_withdraw_request',
        'toggle_section_published',
        'schedule_section_publish',
        'toggle_lesson_published',
        'schedule_lesson_publish',
        'increment_enrolled_count',
        'decrement_enrolled_count',
        'increment_quiz_questions',
        'decrement_quiz_questions',
        'submit_quiz_attempt',
        'get_unread_notifications_count',
        'mark_all_notifications_read'
      )
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.oid::regprocedure);
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO service_role;



-- ============================================================
-- 007_fix_enrollment_unique_constraint.sql
-- ============================================================
-- 007_fix_enrollment_unique_constraint.sql
-- Run this script in your Supabase SQL Editor to update the create_enrollment function.
-- This prevents "duplicate key value violates unique constraint" crashes.

CREATE OR REPLACE FUNCTION public.create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_coupon RECORD;
  v_total_subtotal DECIMAL := 0;
  v_coupon_discount DECIMAL := 0;
  v_user_usage_count INTEGER := 0;
BEGIN
  SELECT NULL::UUID AS id, NULL::VARCHAR AS code INTO v_coupon;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Cannot create enrollment for another user';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.cart_items WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  -- 1. Check if the user is already active or completed in any of the courses in their cart
  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.title_ar,
      c.title_en
    FROM public.cart_items ci
    JOIN public.courses c ON c.id = ci.course_id
    WHERE ci.user_id = v_user_id
  LOOP
    IF EXISTS (
      SELECT 1 FROM public.enrollments
      WHERE user_id = v_user_id
        AND course_id = v_course.course_id
        AND status IN ('active', 'completed')
    ) THEN
      RAISE EXCEPTION 'You are already enrolled in course: %', COALESCE(v_course.title_ar, v_course.title_en);
    END IF;
  END LOOP;

  -- 2. Calculate subtotal
  SELECT COALESCE(SUM(
    CASE
      WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
      ELSE COALESCE(c.discount_price, c.price)
    END
  ), 0)
  INTO v_total_subtotal
  FROM public.cart_items ci
  JOIN public.courses c ON c.id = ci.course_id
  WHERE ci.user_id = v_user_id;

  -- 3. Apply Coupon if applicable
  IF p_coupon_id IS NOT NULL OR p_coupon_code IS NOT NULL THEN
    SELECT *
    INTO v_coupon
    FROM public.coupons
    WHERE (id = p_coupon_id OR code = UPPER(p_coupon_code))
      AND is_active = TRUE
      AND is_suspended = FALSE
      AND start_date <= NOW()
      AND (end_date IS NULL OR end_date >= NOW())
      AND (usage_limit IS NULL OR usage_count < usage_limit)
      AND min_order_amount <= v_total_subtotal
    LIMIT 1;

    IF v_coupon.id IS NULL THEN
      RAISE EXCEPTION 'Invalid coupon';
    END IF;

    SELECT COUNT(*)
    INTO v_user_usage_count
    FROM public.coupon_usages
    WHERE coupon_id = v_coupon.id
      AND user_id = v_user_id;

    IF v_user_usage_count >= v_coupon.usage_limit_per_user THEN
      RAISE EXCEPTION 'Coupon usage limit exceeded';
    END IF;

    IF v_coupon.discount_type = 'percentage' THEN
      v_coupon_discount := v_total_subtotal * (v_coupon.discount_value / 100);
      IF v_coupon.max_discount_amount IS NOT NULL THEN
        v_coupon_discount := LEAST(v_coupon_discount, v_coupon.max_discount_amount);
      END IF;
    ELSE
      v_coupon_discount := LEAST(v_coupon.discount_value, v_total_subtotal);
    END IF;
  END IF;

  -- 4. Create parent enrollment
  INSERT INTO public.parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    v_user_id,
    GREATEST(v_total_subtotal - v_coupon_discount, 0),
    v_total_subtotal,
    v_coupon_discount,
    v_coupon.id,
    v_coupon.code,
    v_coupon_discount,
    p_payment_method,
    CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;

  -- 5. Insert or update course enrollments (Handling unique constraint conflict)
  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.teacher_id,
      CASE
        WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
        ELSE COALESCE(c.discount_price, c.price)
      END AS final_price
    FROM public.cart_items ci
    JOIN public.courses c ON c.id = ci.course_id
    WHERE ci.user_id = v_user_id
  LOOP
    INSERT INTO public.enrollments (
      user_id, course_id, teacher_id, parent_enrollment_id,
      price, discount, status, enrolled_at
    )
    VALUES (
      v_user_id,
      v_course.course_id,
      v_course.teacher_id,
      v_parent_enrollment_id,
      v_course.final_price,
      CASE
        WHEN v_total_subtotal > 0 THEN ROUND(v_coupon_discount * (v_course.final_price / v_total_subtotal), 2)
        ELSE 0
      END,
      CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'active' ELSE 'pending' END,
      NOW()
    )
    ON CONFLICT (user_id, course_id)
    DO UPDATE SET
      teacher_id = EXCLUDED.teacher_id,
      parent_enrollment_id = EXCLUDED.parent_enrollment_id,
      price = EXCLUDED.price,
      discount = EXCLUDED.discount,
      status = EXCLUDED.status,
      enrolled_at = EXCLUDED.enrolled_at,
      updated_at = NOW()
    RETURNING id INTO v_enrollment_id;
  END LOOP;

  -- 6. Record coupon usage if coupon was applied
  IF v_coupon.id IS NOT NULL THEN
    INSERT INTO public.coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (v_coupon.id, v_user_id, v_parent_enrollment_id, v_coupon_discount);

    UPDATE public.coupons
    SET usage_count = usage_count + 1
    WHERE id = v_coupon.id;
  END IF;

  -- 7. Clear cart items
  DELETE FROM public.cart_items WHERE user_id = v_user_id;

  RETURN v_parent_enrollment_id;
END;
$$;



-- ============================================================
-- 008_quiz_question_totals.sql
-- ============================================================
-- Keep quiz total_questions and total_points in sync with quiz_questions.
-- Also restores compatibility for older clients that call the legacy
-- increment/decrement RPC names after adding or deleting questions.

CREATE OR REPLACE FUNCTION public.update_quiz_question_totals(p_quiz_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.quizzes
  SET
    total_questions = (
      SELECT COUNT(*)::INT
      FROM public.quiz_questions
      WHERE quiz_id = p_quiz_id
    ),
    total_points = (
      SELECT COALESCE(SUM(points), 0)::INT
      FROM public.quiz_questions
      WHERE quiz_id = p_quiz_id
    ),
    updated_at = NOW()
  WHERE id = p_quiz_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_update_quiz_question_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.update_quiz_question_totals(OLD.quiz_id);
    RETURN OLD;
  END IF;

  PERFORM public.update_quiz_question_totals(NEW.quiz_id);

  IF TG_OP = 'UPDATE' AND OLD.quiz_id IS DISTINCT FROM NEW.quiz_id THEN
    PERFORM public.update_quiz_question_totals(OLD.quiz_id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS quiz_question_totals_trigger ON public.quiz_questions;

CREATE TRIGGER quiz_question_totals_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.quiz_questions
FOR EACH ROW
EXECUTE FUNCTION public.trigger_update_quiz_question_totals();

CREATE OR REPLACE FUNCTION public.increment_quiz_questions(
  p_quiz_id UUID,
  p_points INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.update_quiz_question_totals(p_quiz_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_quiz_questions(
  p_quiz_id UUID,
  p_points INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.update_quiz_question_totals(p_quiz_id);
END;
$$;

DO $$
DECLARE
  quiz_record RECORD;
BEGIN
  FOR quiz_record IN SELECT id FROM public.quizzes LOOP
    PERFORM public.update_quiz_question_totals(quiz_record.id);
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_quiz_question_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_quiz_questions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_quiz_questions(UUID, INTEGER) TO authenticated;



-- ============================================================
-- 009_supabase_linter_security_hardening.sql
-- ============================================================
-- 009_supabase_linter_security_hardening.sql
-- Run this script in Supabase SQL Editor after 006, 007, and 008.
-- Safe mode: addresses the main Supabase linter warnings that can be fixed
-- without breaking the current app RPC flows:
--   1. function_search_path_mutable
--   2. anon_security_definer_function_executable
--   3. public_bucket_allows_listing
--
-- Note:
-- SECURITY DEFINER functions that are intentionally called by signed-in users
-- will still be callable by authenticated after this script. Supabase may keep
-- warning about those until they are redesigned as SECURITY INVOKER functions
-- or moved out of the exposed public API schema. See 010 for strict lockdown.

BEGIN;

-- ============================================================
-- 1. Pin search_path for all public functions
-- ============================================================

DO $$
DECLARE
  v_function TEXT;
BEGIN
  FOR v_function IN
    SELECT FORMAT(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
  LOOP
    EXECUTE FORMAT(
      'ALTER FUNCTION %s SET search_path = public, pg_temp',
      v_function
    );
  END LOOP;
END;
$$;

-- ============================================================
-- 2. Revoke broad RPC execution, especially from anon
-- ============================================================

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM authenticated;

-- Service role/admin operations should keep full function access.
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Re-grant only functions that are intentionally used by the app or RLS
-- policies for signed-in users. This keeps anon blocked while avoiding app
-- breakage for authenticated flows.
DO $$
DECLARE
  v_function TEXT;
  v_allowed_names TEXT[] := ARRAY[
    -- RLS/helper checks used by policies and screens
    'is_instructor',
    'is_admin',
    'is_enrolled',
    'can_manage_course',
    'current_profile_sensitive_state',
    'is_conversation_participant',

    -- Auth/profile helpers
    'add_phone_to_auth_user',
    'create_profile_for_phone_auth',

    -- Course details and learning
    'get_course_details',
    'get_recommended_courses',
    'update_lesson_progress',

    -- Enrollment/payment/coupon flows
    'create_enrollment',
    'confirm_enrollment_payment',
    'validate_coupon',

    -- Quiz flows
    'submit_quiz_attempt',
    'issue_certificate',

    -- Instructor dashboard and management
    'get_instructor_dashboard_stats',
    'get_instructor_revenue_chart',
    'get_instructor_enrollments_chart',
    'get_instructor_forum_courses',
    'process_refund',
    'increment_enrolled_count',
    'decrement_enrolled_count',
    'submit_withdraw_request',
    'toggle_section_published',
    'schedule_section_publish',
    'toggle_lesson_published',
    'schedule_lesson_publish',

    -- Course forum/chat flows
    'get_course_group_members',
    'update_course_group_title',
    'manage_course_group_member',
    'set_course_group_enabled',
    'get_user_conversations',
    'get_or_create_course_conversation',
    'get_or_create_single_conversation',

    -- Notifications
    'get_unread_notifications_count',
    'mark_all_notifications_read'
  ];
BEGIN
  FOR v_function IN
    SELECT FORMAT(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.proname = ANY (v_allowed_names)
  LOOP
    EXECUTE FORMAT('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_function);
  END LOOP;
END;
$$;

-- Explicitly keep internal trigger/helper functions non-callable from clients.
-- Triggers can still execute trigger functions without client EXECUTE grants.
DO $$
DECLARE
  v_function TEXT;
  v_internal_names TEXT[] := ARRAY[
    'handle_new_user',
    'update_course_rating',
    'update_course_stats',
    'update_enrollment_progress',
    'update_instructor_stats',
    'update_qa_answer_upvotes_count',
    'trigger_update_course_stats_on_section',
    'trigger_update_course_stats_on_lesson',
    'trigger_update_course_stats_on_earning',
    'update_quiz_stats',
    'trigger_update_quiz_stats',
    'update_quiz_question_totals',
    'trigger_update_quiz_question_totals',
    'increment_quiz_questions',
    'decrement_quiz_questions'
  ];
BEGIN
  FOR v_function IN
    SELECT FORMAT(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.proname = ANY (v_internal_names)
  LOOP
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM anon', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', v_function);
  END LOOP;
END;
$$;

-- ============================================================
-- 3. Prevent listing public storage buckets
-- ============================================================

-- Public buckets can still serve files by public URL without a broad SELECT
-- policy on storage.objects. Dropping these policies prevents clients from
-- listing every object in the bucket through the Storage API.
DROP POLICY IF EXISTS "Public SELECT avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public SELECT banners" ON storage.objects;
DROP POLICY IF EXISTS "Public SELECT categories" ON storage.objects;
DROP POLICY IF EXISTS "Public SELECT certificates" ON storage.objects;

COMMIT;



-- ============================================================
-- 010_fix_trigger_permissions.sql
-- ============================================================

BEGIN;

-- Make trigger functions SECURITY DEFINER so they can execute internal helper functions
-- without exposing the helper functions directly to clients via RPC.

ALTER FUNCTION trigger_update_course_stats_on_section() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION trigger_update_course_stats_on_lesson() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION trigger_update_course_stats_on_earning() SECURITY DEFINER SET search_path = public, pg_temp;

-- Quiz stats triggers
ALTER FUNCTION trigger_update_quiz_stats() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION trigger_update_quiz_question_totals() SECURITY DEFINER SET search_path = public, pg_temp;

-- Other stat/helper triggers
ALTER FUNCTION handle_new_user() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_course_rating() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_enrollment_progress() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_instructor_stats() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_qa_answer_upvotes_count() SECURITY DEFINER SET search_path = public, pg_temp;

COMMIT;



-- ============================================================
-- 010_supabase_linter_strict_authenticated_rpc_lockdown.sql
-- ============================================================
-- 010_supabase_linter_strict_authenticated_rpc_lockdown.sql
-- Strict mode for clearing authenticated_security_definer_function_executable
-- warnings.
--
-- WARNING:
-- Do not run this on production until the listed RPC flows are replaced with
-- safer alternatives such as:
--   1. SECURITY INVOKER public functions backed by proper RLS policies.
--   2. SECURITY DEFINER functions moved to a non-exposed private schema and
--      called through carefully scoped wrappers.
--   3. Supabase Edge Functions using service-role secrets on the server side.
--
-- Running this script will remove direct authenticated EXECUTE access from the
-- SECURITY DEFINER functions still reported by the Supabase linter. That makes
-- the linter happy, but current app features that call these RPCs directly can
-- fail with permission errors until they are refactored.

BEGIN;

DO $$
DECLARE
  v_function TEXT;
  v_locked_names TEXT[] := ARRAY[
    -- RLS/helper checks. These should be moved to a private schema or converted
    -- to SECURITY INVOKER only after testing every policy that calls them.
    'can_manage_course',
    'current_profile_sensitive_state',
    'is_admin',
    'is_conversation_participant',
    'is_enrolled',
    'is_instructor',

    -- Enrollment/payment/coupon RPCs.
    'confirm_enrollment_payment',
    'create_enrollment',
    'validate_coupon',

    -- Course forum/chat RPCs.
    'get_course_group_members',
    'get_instructor_forum_courses',
    'get_or_create_course_conversation',
    'get_or_create_single_conversation',
    'get_user_conversations',
    'manage_course_group_member',
    'set_course_group_enabled',
    'update_course_group_title',

    -- Instructor dashboard/management RPCs.
    'get_instructor_dashboard_stats',
    'get_instructor_enrollments_chart',
    'get_instructor_revenue_chart',
    'process_refund',

    -- Learning/quiz RPCs.
    'issue_certificate',
    'submit_quiz_attempt',
    'update_lesson_progress'
  ];
BEGIN
  FOR v_function IN
    SELECT FORMAT(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.proname = ANY (v_locked_names)
  LOOP
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM anon', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', v_function);
  END LOOP;
END;
$$;

COMMIT;



-- ============================================================
-- 011_manual_purchase_requests.sql
-- ============================================================
-- Manual purchase request workflow
-- Run this after the previous schema migrations.

ALTER TABLE parent_enrollments
DROP CONSTRAINT IF EXISTS parent_enrollments_payment_status_check;

ALTER TABLE parent_enrollments
ADD CONSTRAINT parent_enrollments_payment_status_check
CHECK (
  payment_status IN (
    'pending',
    'pending_manual_payment',
    'paid',
    'failed',
    'cancelled',
    'refunded'
  )
);

CREATE INDEX IF NOT EXISTS idx_parent_enrollments_manual_pending
ON parent_enrollments(payment_status, created_at DESC)
WHERE payment_status = 'pending_manual_payment';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'parent_enrollments'
      AND policyname = 'Users can create their own parent enrollments'
  ) THEN
    CREATE POLICY "Users can create their own parent enrollments"
    ON parent_enrollments
    FOR INSERT
    WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'enrollments'
      AND policyname = 'Users can create their own pending enrollments'
  ) THEN
    CREATE POLICY "Users can create their own pending enrollments"
    ON enrollments
    FOR INSERT
    WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'parent_enrollments'
      AND policyname = 'Admins can update parent enrollments'
  ) THEN
    CREATE POLICY "Admins can update parent enrollments"
    ON parent_enrollments
    FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'enrollments'
      AND policyname = 'Admins can update enrollments'
  ) THEN
    CREATE POLICY "Admins can update enrollments"
    ON enrollments
    FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());
  END IF;
END $$;

CREATE OR REPLACE FUNCTION approve_manual_purchase_request(
  p_parent_enrollment_id UUID,
  p_access_days INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can approve manual purchase requests';
  END IF;

  IF p_access_days NOT IN (30, 60, 90) THEN
    RAISE EXCEPTION 'Access days must be 30, 60, or 90';
  END IF;

  UPDATE parent_enrollments
  SET
    payment_status = 'paid',
    payment_method = 'manual',
    paid_at = NOW(),
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id
    AND payment_status = 'pending_manual_payment';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending manual purchase request was not found';
  END IF;

  UPDATE enrollments
  SET
    status = 'active',
    access_expires_at = NOW() + make_interval(days => p_access_days),
    enrolled_at = COALESCE(enrolled_at, NOW()),
    updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION cancel_manual_purchase_request(
  p_parent_enrollment_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can cancel manual purchase requests';
  END IF;

  UPDATE parent_enrollments
  SET
    payment_status = 'cancelled',
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id
    AND payment_status = 'pending_manual_payment';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending manual purchase request was not found';
  END IF;

  UPDATE enrollments
  SET
    status = 'refunded',
    updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id;

  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION approve_manual_purchase_request(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_manual_purchase_request(UUID) TO authenticated;



-- ============================================================
-- 013_fix_profile_function_permissions.sql
-- ============================================================
-- ============================================================
-- ðŸ”§ FIX ALL: Grant Execute on All Public Functions
-- Run this in: Supabase Dashboard â†’ SQL Editor â†’ New Query
-- ============================================================

-- â”€â”€ Core Security Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
GRANT EXECUTE ON FUNCTION public.is_instructor() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_enrolled(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.can_manage_course(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.current_profile_sensitive_state() TO authenticated, anon;

-- â”€â”€ Enrollment RPCs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
GRANT EXECUTE ON FUNCTION public.create_enrollment(UUID, TEXT, UUID, VARCHAR, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO authenticated;

-- â”€â”€ Chat / Conversations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
GRANT EXECUTE ON FUNCTION public.get_user_conversations(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_course_group_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_course_group_title(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) TO authenticated;

-- â”€â”€ Quiz Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
GRANT EXECUTE ON FUNCTION public.update_quiz_question_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_quiz_questions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_quiz_questions(UUID, INTEGER) TO authenticated;

-- â”€â”€ Verify all grants â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
SELECT
  routine_name,
  grantee,
  privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND grantee IN ('authenticated', 'anon')
ORDER BY routine_name, grantee;



-- ============================================================
-- 014_restore_instructor_rpc_permissions.sql
-- ============================================================
-- ============================================================
-- ðŸ”§ 014_restore_instructor_rpc_permissions.sql
-- Restore EXECUTE grants on RPCs revoked by 010_supabase_linter_strict_authenticated_rpc_lockdown.sql
-- Uses exception handling so missing functions are skipped safely.
-- Run in: Supabase Dashboard â†’ SQL Editor â†’ New Query
-- ============================================================

DO $$
DECLARE
  v_sql TEXT;
  v_grants TEXT[] := ARRAY[
    -- Instructor Dashboard RPCs
    'GRANT EXECUTE ON FUNCTION public.get_instructor_dashboard_stats() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_instructor_enrollments_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated',

    -- Enrollment / Payment RPCs
    'GRANT EXECUTE ON FUNCTION public.create_enrollment(UUID, TEXT, UUID, VARCHAR, DECIMAL) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.validate_coupon(VARCHAR, UUID, DECIMAL, UUID[]) TO authenticated',

    -- Learning / Quiz RPCs
    'GRANT EXECUTE ON FUNCTION public.submit_quiz_attempt(UUID, JSONB, INT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.update_lesson_progress(UUID, INTEGER, INTEGER, BOOLEAN) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.issue_certificate(UUID) TO authenticated',

    -- Security Helpers
    'GRANT EXECUTE ON FUNCTION public.is_instructor() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.is_enrolled(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.can_manage_course(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.current_profile_sensitive_state() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.is_conversation_participant(UUID, UUID) TO authenticated',

    -- Chat RPCs
    'GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID, UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_course_group_members(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.update_course_group_title(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_instructor_forum_courses() TO authenticated'
  ];
BEGIN
  FOREACH v_sql IN ARRAY v_grants LOOP
    BEGIN
      EXECUTE v_sql;
      RAISE NOTICE 'OK: %', v_sql;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'SKIPPED (function not found): %', v_sql;
    END;
  END LOOP;
END;
$$;

-- â”€â”€ Verify grants â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
SELECT
  routine_name,
  grantee,
  privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND grantee = 'authenticated'
ORDER BY routine_name;



-- ============================================================
-- 015_allow_instructor_manage_categories.sql
-- ============================================================
-- ============================================================
-- ðŸ”§ 015_allow_instructor_manage_categories.sql
-- Fix RLS on 'categories' table to allow instructors to INSERT,
-- UPDATE, and DELETE categories (not just admins).
--
-- Run in: Supabase Dashboard â†’ SQL Editor â†’ New Query
-- ============================================================

-- Drop the old admin-only policy
DROP POLICY IF EXISTS "Instructor can manage categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;

-- Allow SELECT: anyone can view active categories
DROP POLICY IF EXISTS "Anyone can view categories" ON public.categories;
CREATE POLICY "Anyone can view categories"
  ON public.categories FOR SELECT
  USING (is_active = true);

-- Allow admin: view ALL categories (including inactive)
DROP POLICY IF EXISTS "Admins can view all categories" ON public.categories;
CREATE POLICY "Admins can view all categories"
  ON public.categories FOR SELECT
  USING (is_admin());

-- Allow instructors AND admins to INSERT categories
DROP POLICY IF EXISTS "Instructor or admin can insert categories" ON public.categories;
CREATE POLICY "Instructor or admin can insert categories"
  ON public.categories FOR INSERT
  WITH CHECK (is_instructor() OR is_admin());

-- Allow instructors AND admins to UPDATE categories
DROP POLICY IF EXISTS "Instructor or admin can update categories" ON public.categories;
CREATE POLICY "Instructor or admin can update categories"
  ON public.categories FOR UPDATE
  USING (is_instructor() OR is_admin());

-- Allow instructors AND admins to DELETE categories
DROP POLICY IF EXISTS "Instructor or admin can delete categories" ON public.categories;
CREATE POLICY "Instructor or admin can delete categories"
  ON public.categories FOR DELETE
  USING (is_instructor() OR is_admin());

-- â”€â”€ Verify â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'categories'
ORDER BY policyname;



-- ============================================================
-- 016_enrollment_notification_webhook.sql
-- ============================================================
-- 016_enrollment_notification_webhook.sql
-- ÙŠÙ‚ÙˆÙ… Ø¨Ø¥Ù†Ø´Ø§Ø¡ Webhook ØªÙ„Ù‚Ø§Ø¦ÙŠ ÙŠÙØ·Ù„Ù‚ Ø¹Ù†Ø¯ Ø¥Ø¶Ø§ÙØ© ØµÙ Ø¬Ø¯ÙŠØ¯ ÙÙŠ parent_enrollments
-- ÙŠØ³ØªØ¯Ø¹ÙŠ Edge Function ØªÙØ±Ø³Ù„ Ø¥Ø´Ø¹Ø§Ø± Push Ù„Ù„Ù…Ø¯Ø±Ø³ ØµØ§Ø­Ø¨ Ø§Ù„ÙƒÙˆØ±Ø³ Ø¹Ø¨Ø± OneSignal

-- ======================================================
-- Ø§Ù„Ø·Ø±ÙŠÙ‚Ø© 1: Ø§Ø³ØªØ®Ø¯Ø§Ù… pg_net Ù„Ø¥Ø±Ø³Ø§Ù„ HTTP Request Ù…Ø¨Ø§Ø´Ø±Ø©
-- (ÙŠØ¬Ø¨ ØªÙØ¹ÙŠÙ„ Ø§Ù…ØªØ¯Ø§Ø¯ pg_net ÙÙŠ Supabase Dashboard)
-- ======================================================

-- ØªÙØ¹ÙŠÙ„ Ø§Ù…ØªØ¯Ø§Ø¯ pg_net (Ø§ÙØ¹Ù„ Ù‡Ø°Ø§ Ù…Ù† Supabase Dashboard > Database > Extensions)
-- CREATE EXTENSION IF NOT EXISTS pg_net;

-- Ø¥Ù†Ø´Ø§Ø¡ Function ØªÙØ±Ø³Ù„ Ø§Ù„Ø¥Ø´Ø¹Ø§Ø± Ø¹Ø¨Ø± HTTP Request
CREATE OR REPLACE FUNCTION notify_admin_on_new_enrollment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_supabase_url TEXT := current_setting('app.supabase_url', true);
  v_service_role_key TEXT := current_setting('app.service_role_key', true);
  v_function_url TEXT;
BEGIN
  -- URL Ø§Ù„Ù€ Edge Function Ø§Ù„Ø®Ø§ØµØ© Ø¨Ù†Ø§
  v_function_url := v_supabase_url || '/functions/v1/notify-admin-enrollment';

  -- Ø¥Ø±Ø³Ø§Ù„ HTTP Request Ù„Ù„Ù€ Edge Function
  PERFORM net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'parent_enrollments',
      'record', row_to_json(NEW)
    )
  );

  RETURN NEW;
END;
$$;

-- Ø¥Ù†Ø´Ø§Ø¡ Trigger ÙŠÙØ·Ù„Ù‚ Ø§Ù„Ù€ Function Ø¹Ù†Ø¯ Ø¥Ø¶Ø§ÙØ© Ø·Ù„Ø¨ Ø´Ø±Ø§Ø¡ Ø¬Ø¯ÙŠØ¯
DROP TRIGGER IF EXISTS trigger_notify_admin_on_enrollment ON parent_enrollments;
CREATE TRIGGER trigger_notify_admin_on_enrollment
  AFTER INSERT ON parent_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION notify_admin_on_new_enrollment();

-- ======================================================
-- Ø§Ù„Ø·Ø±ÙŠÙ‚Ø© 2: Ø¥Ù†Ø´Ø§Ø¡ Database Webhook ÙŠØ¯ÙˆÙŠØ§Ù‹ Ù…Ù† Supabase Dashboard
-- ======================================================
-- Ø§Ø°Ù‡Ø¨ Ø¥Ù„Ù‰: Database > Webhooks > Create a new hook
-- Name: notify_instructor_on_enrollment
-- Table: parent_enrollments
-- Events: INSERT
-- Type: HTTP Request (POST)
-- URL: https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/notify-admin-enrollment
-- HTTP Headers:
--   Authorization: Bearer <YOUR_SERVICE_ROLE_KEY>
--   Content-Type: application/json
 


-- ============================================================
-- 017_fix_forum_function_permissions.sql
-- ============================================================
-- 017_fix_forum_function_permissions.sql
-- Ø¥Ø¹Ø§Ø¯Ø© ØµÙ„Ø§Ø­ÙŠØ§Øª ØªÙ†ÙÙŠØ° Ø¬Ù…ÙŠØ¹ Ø§Ù„Ù€ RPC functions Ø§Ù„ØªÙŠ ØªÙ… Ø¥Ø²Ø§Ù„ØªÙ‡Ø§ Ø¨ÙˆØ§Ø³Ø·Ø© Ø³ÙƒØ±ÙŠØ¨Øª 010
-- ÙŠØ¬Ø¨ ØªØ´ØºÙŠÙ„ Ù‡Ø°Ø§ Ø§Ù„Ø³ÙƒØ±ÙŠØ¨Øª Ø¨Ø¹Ø¯ 010 Ø¯Ø§Ø¦Ù…Ø§Ù‹

DO $$
DECLARE
  v_rec RECORD;
BEGIN
  FOR v_rec IN
    SELECT FORMAT('%I.%I(%s)', n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)) AS fn_sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.proname = ANY(ARRAY[
        'can_manage_course','current_profile_sensitive_state','is_admin',
        'is_conversation_participant','is_enrolled','is_instructor',
        'confirm_enrollment_payment','create_enrollment','validate_coupon',
        'get_course_group_members','get_instructor_forum_courses',
        'get_or_create_course_conversation','get_or_create_single_conversation',
        'get_user_conversations','manage_course_group_member','set_course_group_enabled',
        'update_course_group_title','get_instructor_dashboard_stats',
        'get_instructor_enrollments_chart','get_instructor_revenue_chart',
        'process_refund','issue_certificate','submit_quiz_attempt','update_lesson_progress'
      ])
  LOOP
    EXECUTE FORMAT('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_rec.fn_sig);
  END LOOP;
END;
$$;



-- ============================================================
-- 018_course_lesson_availability_schedule.sql
-- ============================================================
-- Add availability windows for courses, sections, and lessons.
-- NULL means open-ended, preserving the current behavior.

ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

ALTER TABLE sections
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

ALTER TABLE lessons
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'courses_availability_window_check'
  ) THEN
    ALTER TABLE courses
      ADD CONSTRAINT courses_availability_window_check
      CHECK (available_until IS NULL OR available_from IS NULL OR available_until > available_from);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'sections_availability_window_check'
  ) THEN
    ALTER TABLE sections
      ADD CONSTRAINT sections_availability_window_check
      CHECK (available_until IS NULL OR available_from IS NULL OR available_until > available_from);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'lessons_availability_window_check'
  ) THEN
    ALTER TABLE lessons
      ADD CONSTRAINT lessons_availability_window_check
      CHECK (available_until IS NULL OR available_from IS NULL OR available_until > available_from);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_courses_availability
  ON courses(is_published, is_active, available_from, available_until);

CREATE INDEX IF NOT EXISTS idx_sections_availability
  ON sections(course_id, is_published, available_from, available_until);

CREATE INDEX IF NOT EXISTS idx_lessons_availability
  ON lessons(course_id, section_id, is_published, available_from, available_until);

CREATE OR REPLACE FUNCTION is_available_window(
  p_available_from TIMESTAMPTZ,
  p_available_until TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT (p_available_from IS NULL OR p_available_from <= NOW())
     AND (p_available_until IS NULL OR p_available_until > NOW());
$$;

CREATE OR REPLACE FUNCTION is_course_available(p_course_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM courses c
    WHERE c.id = p_course_id
      AND c.is_published = TRUE
      AND c.is_active = TRUE
      AND is_available_window(c.available_from, c.available_until)
  );
$$;

DROP POLICY IF EXISTS "Anyone can view published courses" ON courses;
CREATE POLICY "Anyone can view published courses" ON courses
FOR SELECT
USING (
  is_published = TRUE
  AND is_active = TRUE
  AND is_available_window(available_from, available_until)
);

DROP POLICY IF EXISTS "Anyone can view sections of published courses" ON sections;
DROP POLICY IF EXISTS "Anyone can view published sections" ON sections;
CREATE POLICY "Anyone can view sections of published courses" ON sections
FOR SELECT
USING (
  (
    is_published = TRUE
    AND is_available_window(available_from, available_until)
    AND is_course_available(course_id)
  )
  OR is_admin()
  OR EXISTS (
    SELECT 1
    FROM courses c
    WHERE c.id = sections.course_id
      AND c.teacher_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Anyone can view preview lessons" ON lessons;
CREATE POLICY "Anyone can view preview lessons" ON lessons
FOR SELECT
USING (
  is_preview = TRUE
  AND is_published = TRUE
  AND is_available_window(available_from, available_until)
  AND is_course_available(course_id)
);

DROP POLICY IF EXISTS "Enrolled students can view lessons" ON lessons;
CREATE POLICY "Enrolled students can view lessons" ON lessons
FOR SELECT
USING (
  is_published = TRUE
  AND is_available_window(available_from, available_until)
  AND is_course_available(course_id)
  AND is_enrolled(course_id)
);



-- ============================================================
-- 019_auto_notifications_triggers.sql
-- ============================================================
-- ============================================================
-- 019_auto_notifications_triggers.sql
-- Auto-notifications when a new course is published or new lesson added
-- ============================================================

-- ============================================================
-- 1. TRIGGER: Notify all students when a course is published
-- ============================================================

CREATE OR REPLACE FUNCTION notify_students_on_new_course()
RETURNS TRIGGER AS $$
DECLARE
  v_student RECORD;
  v_title_ar TEXT;
  v_title_en TEXT;
BEGIN
  -- Only fire when course transitions to published (is_published = true)
  IF (TG_OP = 'INSERT' AND NEW.is_published = TRUE)
  OR (TG_OP = 'UPDATE' AND NEW.is_published = TRUE AND (OLD.is_published = FALSE OR OLD.is_published IS NULL))
  THEN
    v_title_ar := COALESCE(NEW.title_ar, 'ÙƒÙˆØ±Ø³ Ø¬Ø¯ÙŠØ¯');
    v_title_en := COALESCE(NEW.title_en, v_title_ar);

    -- Insert a notification for every student in the platform
    FOR v_student IN
      SELECT id FROM profiles WHERE role = 'student' AND is_active = TRUE
    LOOP
      INSERT INTO notifications (
        user_id,
        title_ar,
        title_en,
        body_ar,
        body_en,
        type,
        data,
        is_read,
        created_at
      ) VALUES (
        v_student.id,
        'ÙƒÙˆØ±Ø³ Ø¬Ø¯ÙŠØ¯ Ù…ØªØ§Ø­! ðŸŽ‰',
        'New Course Available! ðŸŽ‰',
        'ØªÙ… Ø¥Ø¶Ø§ÙØ© ÙƒÙˆØ±Ø³ Ø¬Ø¯ÙŠØ¯: ' || v_title_ar || ' â€” Ø§Ø´ØªØ±Ùƒ Ø§Ù„Ø¢Ù†!',
        'A new course is now available: ' || v_title_en || ' â€” Enroll now!',
        'course_update',
        jsonb_build_object('course_id', NEW.id, 'action', 'new_course'),
        FALSE,
        NOW()
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trigger_notify_students_new_course ON courses;
CREATE TRIGGER trigger_notify_students_new_course
AFTER INSERT OR UPDATE OF is_published ON courses
FOR EACH ROW
EXECUTE FUNCTION notify_students_on_new_course();

-- ============================================================
-- 2. TRIGGER: Notify enrolled students when a new lesson is published
-- ============================================================

CREATE OR REPLACE FUNCTION notify_students_on_new_lesson()
RETURNS TRIGGER AS $$
DECLARE
  v_student RECORD;
  v_lesson_title_ar TEXT;
  v_lesson_title_en TEXT;
  v_course_title_ar TEXT;
  v_course_title_en TEXT;
BEGIN
  -- Only fire when lesson is published (newly inserted and published, or toggled to published)
  IF (TG_OP = 'INSERT' AND NEW.is_published = TRUE)
  OR (TG_OP = 'UPDATE' AND NEW.is_published = TRUE AND (OLD.is_published = FALSE OR OLD.is_published IS NULL))
  THEN
    v_lesson_title_ar := COALESCE(NEW.title_ar, 'Ø¯Ø±Ø³ Ø¬Ø¯ÙŠØ¯');
    v_lesson_title_en := COALESCE(NEW.title_en, v_lesson_title_ar);

    -- Get the course title
    SELECT title_ar, COALESCE(title_en, title_ar)
    INTO v_course_title_ar, v_course_title_en
    FROM courses WHERE id = NEW.course_id;

    -- Notify all students enrolled in this course (active enrollments only)
    FOR v_student IN
      SELECT DISTINCT e.user_id
      FROM enrollments e
      WHERE e.course_id = NEW.course_id
        AND e.status = 'active'
    LOOP
      INSERT INTO notifications (
        user_id,
        title_ar,
        title_en,
        body_ar,
        body_en,
        type,
        data,
        is_read,
        created_at
      ) VALUES (
        v_student.user_id,
        'Ø¯Ø±Ø³ Ø¬Ø¯ÙŠØ¯ ØªÙ… Ø¥Ø¶Ø§ÙØªÙ‡! ðŸ“š',
        'New Lesson Added! ðŸ“š',
        'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø¯Ø±Ø³ Ø¬Ø¯ÙŠØ¯: ' || v_lesson_title_ar || ' â€” ÙÙŠ ÙƒÙˆØ±Ø³: ' || COALESCE(v_course_title_ar, ''),
        'New lesson added: ' || v_lesson_title_en || ' â€” in course: ' || COALESCE(v_course_title_en, ''),
        'new_lesson',
        jsonb_build_object(
          'course_id', NEW.course_id,
          'lesson_id', NEW.id,
          'action', 'new_lesson'
        ),
        FALSE,
        NOW()
      );
    END LOOP;

    -- Also notify the instructor (so they know it was published successfully)
    INSERT INTO notifications (
      user_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      data,
      is_read,
      created_at
    )
    SELECT
      c.teacher_id,
      'ØªÙ… Ù†Ø´Ø± Ø§Ù„Ø¯Ø±Ø³ Ø¨Ù†Ø¬Ø§Ø­ âœ…',
      'Lesson Published Successfully âœ…',
      'ØªÙ… Ù†Ø´Ø± Ø§Ù„Ø¯Ø±Ø³: ' || v_lesson_title_ar || ' ÙÙŠ ÙƒÙˆØ±Ø³: ' || COALESCE(v_course_title_ar, ''),
      'Lesson published: ' || v_lesson_title_en || ' in course: ' || COALESCE(v_course_title_en, ''),
      'new_lesson',
      jsonb_build_object(
        'course_id', NEW.course_id,
        'lesson_id', NEW.id,
        'action', 'lesson_published'
      ),
      FALSE,
      NOW()
    FROM courses c WHERE c.id = NEW.course_id;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trigger_notify_students_new_lesson ON lessons;
CREATE TRIGGER trigger_notify_students_new_lesson
AFTER INSERT OR UPDATE OF is_published ON lessons
FOR EACH ROW
EXECUTE FUNCTION notify_students_on_new_lesson();

-- Grant access
GRANT EXECUTE ON FUNCTION notify_students_on_new_course() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_students_on_new_lesson() TO authenticated;

SELECT '019 - Auto-notification triggers for courses and lessons created successfully!' AS status;



-- ============================================================
-- 020_earnings_trigger.sql
-- ============================================================
-- ============================================================
-- 020_earnings_trigger.sql
-- Auto-insert into instructor_earnings on every active enrollment
-- ============================================================

-- Function: Called after each row inserted/updated in enrollments
CREATE OR REPLACE FUNCTION trigger_create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
  v_teacher_id UUID;
  v_price         DECIMAL(10,2);
  v_gross         DECIMAL(10,2);
  v_platform_fee  DECIMAL(10,2);
  v_net           DECIMAL(10,2);
  v_revenue_share DECIMAL(5,2) := 100.00; -- 100% to instructor (no platform fee)
BEGIN
  -- Only create earning on active enrollment with a price > 0
  IF NEW.status <> 'active' THEN
    RETURN NEW;
  END IF;

  -- Get teacher_id and price from enrollment
  v_teacher_id := NEW.teacher_id;
  v_price         := COALESCE(NEW.price, 0);

  -- If teacher_id not set on enrollment row, get it from courses table
  IF v_teacher_id IS NULL THEN
    SELECT teacher_id INTO v_teacher_id
    FROM courses WHERE id = NEW.course_id;
  END IF;

  IF v_teacher_id IS NULL THEN
    RETURN NEW; -- no instructor found, skip
  END IF;

  -- Skip if price is 0 (free course)
  IF v_price <= 0 THEN
    RETURN NEW;
  END IF;

  v_gross        := v_price;
  v_platform_fee := 0.00;                  -- adjust if platform takes a cut
  v_net          := v_gross - v_platform_fee;

  -- Avoid duplicates: only insert if no earning row exists for this enrollment
  IF NOT EXISTS (
    SELECT 1 FROM instructor_earnings WHERE enrollment_id = NEW.id
  ) THEN
    INSERT INTO instructor_earnings (
      teacher_id,
      enrollment_id,
      course_id,
      gross_amount,
      platform_fee,
      net_amount,
      revenue_share,
      status,
      available_at,
      created_at
    ) VALUES (
      v_teacher_id,
      NEW.id,
      NEW.course_id,
      v_gross,
      v_platform_fee,
      v_net,
      v_revenue_share,
      'available',
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_auto_instructor_earning ON enrollments;

CREATE TRIGGER trigger_auto_instructor_earning
AFTER INSERT OR UPDATE OF status ON enrollments
FOR EACH ROW
EXECUTE FUNCTION trigger_create_instructor_earning();

-- Make sure trigger function can't be called by clients directly
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM authenticated;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM anon;

SELECT '020 - Instructor earnings trigger created successfully!' AS status;



-- ============================================================
-- 021_update_instructor_rating_trigger.sql
-- ============================================================
-- ============================================================
-- 021_update_instructor_rating_trigger.sql
-- Automatically keeps instructor_profiles.average_rating and
-- total_reviews in sync whenever a course_review is inserted,
-- updated or deleted.
-- ============================================================

-- Helper function that recalculates the instructor rating from scratch
CREATE OR REPLACE FUNCTION update_instructor_average_rating(p_teacher_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_avg    NUMERIC(3,2);
  v_count  INT;
BEGIN
  SELECT
    ROUND(COALESCE(AVG(cr.rating), 0)::NUMERIC, 2),
    COUNT(cr.id)
  INTO v_avg, v_count
  FROM course_reviews cr
  JOIN courses c ON c.id = cr.course_id
  WHERE c.teacher_id = p_teacher_id;

  -- Upsert into instructor_profiles
  UPDATE instructor_profiles
  SET
    average_rating = v_avg,
    total_reviews  = v_count,
    updated_at     = NOW()
  WHERE teacher_id = p_teacher_id;

  -- If no row existed for this instructor, do nothing silently
  -- (the row should exist; if not, it will be fixed on next profile create)
END;
$$;

-- Trigger function called after INSERT / UPDATE / DELETE on course_reviews
CREATE OR REPLACE FUNCTION trg_sync_instructor_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_teacher_id UUID;
BEGIN
  -- Determine the teacher_id from whichever row we have
  IF TG_OP = 'DELETE' THEN
    SELECT c.teacher_id INTO v_teacher_id
    FROM courses c WHERE c.id = OLD.course_id;
  ELSE
    SELECT c.teacher_id INTO v_teacher_id
    FROM courses c WHERE c.id = NEW.course_id;
  END IF;

  IF v_teacher_id IS NOT NULL THEN
    PERFORM update_instructor_average_rating(v_teacher_id);
  END IF;

  RETURN NULL; -- AFTER trigger; return value is ignored
END;
$$;

-- Drop old trigger if it exists, then create fresh
DROP TRIGGER IF EXISTS trg_course_review_rating_sync ON course_reviews;

CREATE TRIGGER trg_course_review_rating_sync
AFTER INSERT OR UPDATE OR DELETE ON course_reviews
FOR EACH ROW
EXECUTE FUNCTION trg_sync_instructor_rating();

-- ----------------------------------------------------------------
-- Back-fill: recalculate for all existing instructors right now
-- ----------------------------------------------------------------
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT c.teacher_id
    FROM courses c
    JOIN course_reviews cr ON cr.course_id = c.id
  LOOP
    PERFORM update_instructor_average_rating(rec.teacher_id);
  END LOOP;
END;
$$;



-- ============================================================
-- 022_quiz_availability_schedule.sql
-- ============================================================
-- Add optional availability windows for quizzes.
-- Null values keep the current behavior: the quiz is available whenever published.

ALTER TABLE quizzes
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'quizzes_availability_window_check'
  ) THEN
    ALTER TABLE quizzes
      ADD CONSTRAINT quizzes_availability_window_check
      CHECK (
        available_until IS NULL
        OR available_from IS NULL
        OR available_until > available_from
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_quizzes_availability
  ON quizzes(course_id, is_published, available_from, available_until);



-- ============================================================
-- 023_course_pricing_options_and_group_links.sql
-- ============================================================
-- Course pricing options and student group links
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS pricing_options JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS group_links JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE cart_items
  ADD COLUMN IF NOT EXISTS pricing_option JSONB;

ALTER TABLE enrollments
  ADD COLUMN IF NOT EXISTS pricing_option JSONB;

CREATE INDEX IF NOT EXISTS idx_courses_pricing_options_gin
  ON courses USING gin (pricing_options);



-- ============================================================
-- 024_fix_enrollment_webhook_null_url.sql
-- ============================================================
-- ============================================================
-- 024_fix_enrollment_webhook_null_url.sql
-- Fix: null value in column "url" of relation "http_request_queue"
--      violates not-null constraint
--
-- Root cause: notify_admin_on_new_enrollment() reads app.supabase_url
-- and app.service_role_key from PostgreSQL settings. If these settings
-- are not configured, v_supabase_url is NULL, making v_function_url
-- NULL â€” which causes pg_net to throw a NOT NULL constraint violation
-- on http_request_queue.url.
--
-- Fix: Guard the HTTP call so it is skipped when the URL or key is
-- missing. The enrollment row is still created successfully; the
-- admin notification just won't fire until the settings are added.
-- ============================================================

CREATE OR REPLACE FUNCTION notify_admin_on_new_enrollment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_supabase_url     TEXT := current_setting('app.supabase_url', true);
  v_service_role_key TEXT := current_setting('app.service_role_key', true);
  v_function_url     TEXT;
BEGIN
  -- âœ… Guard: skip HTTP call if the required settings are not configured.
  --    This prevents a NOT NULL violation on http_request_queue.url.
  IF v_supabase_url IS NULL OR v_supabase_url = ''
  OR v_service_role_key IS NULL OR v_service_role_key = ''
  THEN
    RETURN NEW;
  END IF;

  -- Build the Edge Function URL
  v_function_url := v_supabase_url || '/functions/v1/notify-admin-enrollment';

  -- Send HTTP request to the Edge Function via pg_net
  PERFORM net.http_post(
    url     := v_function_url,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'type',   'INSERT',
      'table',  'parent_enrollments',
      'record', row_to_json(NEW)
    )
  );

  RETURN NEW;
END;
$$;

-- Re-create the trigger (no change needed here, just kept for reference)
DROP TRIGGER IF EXISTS trigger_notify_admin_on_enrollment ON parent_enrollments;
CREATE TRIGGER trigger_notify_admin_on_enrollment
  AFTER INSERT ON parent_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION notify_admin_on_new_enrollment();

SELECT '024 - Fixed enrollment webhook null-URL guard applied successfully!' AS status;

-- ============================================================
-- OPTIONAL: To fully enable admin push notifications, run the
-- following in Supabase Dashboard > SQL Editor:
--
--   ALTER DATABASE postgres
--     SET "app.supabase_url" = 'https://<YOUR_PROJECT_REF>.supabase.co';
--
--   ALTER DATABASE postgres
--     SET "app.service_role_key" = '<YOUR_SERVICE_ROLE_KEY>';
--
-- Then reload the configuration:
--   SELECT pg_reload_conf();
-- ============================================================



-- ============================================================
-- 026_manual_requests_without_pending_enrollments.sql
-- ============================================================
-- Manual purchase requests must not create course enrollments until approved.
-- This migration stores requested courses separately, backfills old requests,
-- and removes unapproved manual rows from enrollments.

CREATE TABLE IF NOT EXISTS manual_purchase_request_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_enrollment_id UUID NOT NULL REFERENCES parent_enrollments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  original_price DECIMAL(10,2) DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  pricing_option JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(parent_enrollment_id, course_id)
);

CREATE INDEX IF NOT EXISTS idx_manual_purchase_items_parent
ON manual_purchase_request_items(parent_enrollment_id);

CREATE INDEX IF NOT EXISTS idx_manual_purchase_items_user_course
ON manual_purchase_request_items(user_id, course_id);

CREATE INDEX IF NOT EXISTS idx_manual_purchase_items_instructor
ON manual_purchase_request_items(teacher_id);

ALTER TABLE manual_purchase_request_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their manual request items"
ON manual_purchase_request_items;
CREATE POLICY "Users can view their manual request items"
ON manual_purchase_request_items
FOR SELECT
USING (user_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Users can create their manual request items"
ON manual_purchase_request_items;
CREATE POLICY "Users can create their manual request items"
ON manual_purchase_request_items
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM parent_enrollments pe
    WHERE pe.id = parent_enrollment_id
      AND pe.user_id = auth.uid()
      AND pe.payment_method = 'manual'
      AND pe.payment_status = 'pending_manual_payment'
  )
);

DROP POLICY IF EXISTS "Admins can manage manual request items"
ON manual_purchase_request_items;
CREATE POLICY "Admins can manage manual request items"
ON manual_purchase_request_items
FOR ALL
USING (is_admin())
WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Users can create their own pending enrollments"
ON enrollments;

DROP POLICY IF EXISTS "Users can create approved free enrollments"
ON enrollments;
CREATE POLICY "Users can create approved free enrollments"
ON enrollments
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND status = 'active'
  AND price = 0
  AND EXISTS (
    SELECT 1
    FROM parent_enrollments pe
    WHERE pe.id = parent_enrollment_id
      AND pe.user_id = auth.uid()
      AND pe.payment_method = 'free'
      AND pe.payment_status = 'paid'
      AND pe.total = 0
  )
  AND EXISTS (
    SELECT 1
    FROM courses c
    WHERE c.id = course_id
      AND (
        c.is_free = TRUE
        OR COALESCE(c.discount_price, c.price, 0) = 0
      )
  )
);

-- Backfill request items from the old design where pending requests were rows
-- in enrollments. This also keeps approved requests visible in the dashboard.
INSERT INTO manual_purchase_request_items (
  parent_enrollment_id,
  user_id,
  course_id,
  teacher_id,
  price,
  original_price,
  discount,
  pricing_option,
  created_at,
  updated_at
)
SELECT DISTINCT ON (e.parent_enrollment_id, e.course_id)
  e.parent_enrollment_id,
  e.user_id,
  e.course_id,
  e.teacher_id,
  e.price,
  e.price,
  COALESCE(e.discount, 0),
  e.pricing_option,
  COALESCE(e.created_at, NOW()),
  NOW()
FROM enrollments e
JOIN parent_enrollments pe ON pe.id = e.parent_enrollment_id
WHERE pe.payment_method = 'manual'
  AND pe.payment_status IN ('pending_manual_payment', 'paid', 'cancelled')
  AND e.parent_enrollment_id IS NOT NULL
ORDER BY e.parent_enrollment_id, e.course_id, e.created_at DESC
ON CONFLICT (parent_enrollment_id, course_id) DO UPDATE
SET
  user_id = EXCLUDED.user_id,
  teacher_id = EXCLUDED.teacher_id,
  price = EXCLUDED.price,
  original_price = EXCLUDED.original_price,
  discount = EXCLUDED.discount,
  pricing_option = EXCLUDED.pricing_option,
  updated_at = NOW();

-- Remove the accidental enrollments for requests that have not been approved.
DELETE FROM enrollments e
USING parent_enrollments pe
WHERE pe.id = e.parent_enrollment_id
  AND pe.payment_method = 'manual'
  AND pe.payment_status IN ('pending_manual_payment', 'cancelled');

CREATE OR REPLACE FUNCTION approve_manual_purchase_request(
  p_parent_enrollment_id UUID,
  p_access_days INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order parent_enrollments%ROWTYPE;
  v_item RECORD;
  v_inserted_count INTEGER := 0;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can approve manual purchase requests';
  END IF;

  IF p_access_days NOT IN (30, 60, 90) THEN
    RAISE EXCEPTION 'Access days must be 30, 60, or 90';
  END IF;

  SELECT *
  INTO v_order
  FROM parent_enrollments
  WHERE id = p_parent_enrollment_id
    AND payment_status = 'pending_manual_payment'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending manual purchase request was not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM manual_purchase_request_items
    WHERE parent_enrollment_id = p_parent_enrollment_id
  ) THEN
    RAISE EXCEPTION 'Manual purchase request has no courses';
  END IF;

  UPDATE parent_enrollments
  SET
    payment_status = 'paid',
    payment_method = 'manual',
    paid_at = NOW(),
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id;

  FOR v_item IN
    SELECT *
    FROM manual_purchase_request_items
    WHERE parent_enrollment_id = p_parent_enrollment_id
  LOOP
    INSERT INTO enrollments (
      user_id,
      course_id,
      teacher_id,
      parent_enrollment_id,
      price,
      pricing_option,
      discount,
      status,
      progress_percentage,
      completed_lessons,
      total_watch_time,
      access_expires_at,
      enrolled_at,
      updated_at
    )
    VALUES (
      v_item.user_id,
      v_item.course_id,
      v_item.teacher_id,
      p_parent_enrollment_id,
      v_item.price,
      v_item.pricing_option,
      COALESCE(v_item.discount, 0),
      'active',
      0,
      0,
      0,
      NOW() + make_interval(days => p_access_days),
      NOW(),
      NOW()
    )
    ON CONFLICT (user_id, course_id)
    DO UPDATE SET
      teacher_id = EXCLUDED.teacher_id,
      parent_enrollment_id = EXCLUDED.parent_enrollment_id,
      price = EXCLUDED.price,
      pricing_option = EXCLUDED.pricing_option,
      discount = EXCLUDED.discount,
      status = 'active',
      access_expires_at = EXCLUDED.access_expires_at,
      enrolled_at = NOW(),
      updated_at = NOW()
    WHERE enrollments.status NOT IN ('active', 'completed');

    v_inserted_count := v_inserted_count + 1;
  END LOOP;

  IF v_inserted_count = 0 THEN
    RAISE EXCEPTION 'No enrollments were activated';
  END IF;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION cancel_manual_purchase_request(
  p_parent_enrollment_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can cancel manual purchase requests';
  END IF;

  UPDATE parent_enrollments
  SET
    payment_status = 'cancelled',
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id
    AND payment_status = 'pending_manual_payment';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending manual purchase request was not found';
  END IF;

  DELETE FROM enrollments
  WHERE parent_enrollment_id = p_parent_enrollment_id;

  RETURN TRUE;
END;
$$;

GRANT SELECT, INSERT ON manual_purchase_request_items TO authenticated;
GRANT EXECUTE ON FUNCTION approve_manual_purchase_request(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_manual_purchase_request(UUID) TO authenticated;



-- ============================================================
-- 027_coupon_usage_stats_fix.sql
-- ============================================================
-- Keep instructor coupon statistics in sync with paid parent enrollments.

WITH ranked_usages AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY coupon_id, enrollment_id
      ORDER BY used_at DESC, id DESC
    ) AS rn
  FROM coupon_usages
  WHERE enrollment_id IS NOT NULL
)
DELETE FROM coupon_usages cu
USING ranked_usages ranked
WHERE cu.id = ranked.id
  AND ranked.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_coupon_usages_coupon_enrollment
ON coupon_usages(coupon_id, enrollment_id)
WHERE enrollment_id IS NOT NULL;

DROP POLICY IF EXISTS "Instructors can view own coupon usages"
ON coupon_usages;
CREATE POLICY "Instructors can view own coupon usages"
ON coupon_usages
FOR SELECT
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1
    FROM coupons c
    WHERE c.id = coupon_usages.coupon_id
      AND c.teacher_id = auth.uid()
  )
  OR is_admin()
);

CREATE OR REPLACE FUNCTION public.refresh_coupon_usage_count(
  p_coupon_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_coupon_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE coupons
  SET usage_count = (
    SELECT COUNT(*)::INTEGER
    FROM coupon_usages
    WHERE coupon_id = p_coupon_id
  )
  WHERE id = p_coupon_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_coupon_usage_from_parent_enrollment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.coupon_id IS NOT NULL
     AND OLD.coupon_id IS DISTINCT FROM NEW.coupon_id THEN
    DELETE FROM coupon_usages
    WHERE coupon_id = OLD.coupon_id
      AND enrollment_id = NEW.id;

    PERFORM public.refresh_coupon_usage_count(OLD.coupon_id);
  END IF;

  IF NEW.coupon_id IS NOT NULL
     AND NEW.payment_status = 'paid' THEN
    INSERT INTO coupon_usages (
      coupon_id,
      user_id,
      enrollment_id,
      discount_amount,
      used_at
    )
    VALUES (
      NEW.coupon_id,
      NEW.user_id,
      NEW.id,
      GREATEST(COALESCE(NEW.coupon_discount, NEW.discount, 0), 0),
      COALESCE(NEW.paid_at, NOW())
    )
    ON CONFLICT (coupon_id, enrollment_id)
    WHERE enrollment_id IS NOT NULL
    DO UPDATE SET
      user_id = EXCLUDED.user_id,
      discount_amount = EXCLUDED.discount_amount,
      used_at = EXCLUDED.used_at;

    PERFORM public.refresh_coupon_usage_count(NEW.coupon_id);
  ELSE
    DELETE FROM coupon_usages
    WHERE enrollment_id = NEW.id;

    PERFORM public.refresh_coupon_usage_count(NEW.coupon_id);

    IF TG_OP = 'UPDATE' THEN
      PERFORM public.refresh_coupon_usage_count(OLD.coupon_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_coupon_usage_from_parent_enrollment
ON parent_enrollments;
CREATE TRIGGER trg_sync_coupon_usage_from_parent_enrollment
AFTER INSERT OR UPDATE OF
  payment_status,
  coupon_id,
  coupon_discount,
  discount,
  user_id,
  paid_at
ON parent_enrollments
FOR EACH ROW
EXECUTE FUNCTION public.sync_coupon_usage_from_parent_enrollment();

-- Backfill paid orders that already used coupons but never created usage rows.
INSERT INTO coupon_usages (
  coupon_id,
  user_id,
  enrollment_id,
  discount_amount,
  used_at
)
SELECT
  pe.coupon_id,
  pe.user_id,
  pe.id,
  GREATEST(COALESCE(pe.coupon_discount, pe.discount, 0), 0),
  COALESCE(pe.paid_at, pe.updated_at, pe.created_at, NOW())
FROM parent_enrollments pe
WHERE pe.coupon_id IS NOT NULL
  AND pe.payment_status = 'paid'
ON CONFLICT (coupon_id, enrollment_id)
WHERE enrollment_id IS NOT NULL
DO UPDATE SET
  user_id = EXCLUDED.user_id,
  discount_amount = EXCLUDED.discount_amount,
  used_at = EXCLUDED.used_at;

-- Remove usage rows for orders that are still pending, cancelled, or no longer
-- attached to the same coupon.
DELETE FROM coupon_usages cu
USING parent_enrollments pe
WHERE cu.enrollment_id = pe.id
  AND (
    pe.coupon_id IS NULL
    OR pe.coupon_id <> cu.coupon_id
    OR pe.payment_status <> 'paid'
  );

-- Repair any stale counters from the usage table.
UPDATE coupons c
SET usage_count = COALESCE(usage_stats.usage_count, 0)
FROM (
  SELECT c_inner.id, COUNT(cu.id)::INTEGER AS usage_count
  FROM coupons c_inner
  LEFT JOIN coupon_usages cu ON cu.coupon_id = c_inner.id
  GROUP BY c_inner.id
) AS usage_stats
WHERE usage_stats.id = c.id;

GRANT EXECUTE ON FUNCTION public.refresh_coupon_usage_count(UUID)
TO authenticated;



-- ============================================================
-- 027_fix_pricing_options_checkout.sql
-- ============================================================
-- Fix checkout totals for courses whose public price is stored in pricing_options.
-- Apply this in Supabase SQL editor after 001_individual_lms_schema.sql.

CREATE OR REPLACE FUNCTION public.course_effective_price(
  p_price NUMERIC,
  p_discount_price NUMERIC,
  p_is_free BOOLEAN,
  p_pricing_options JSONB,
  p_is_flash_sale BOOLEAN DEFAULT FALSE,
  p_flash_sale_price NUMERIC DEFAULT NULL,
  p_flash_sale_end TIMESTAMPTZ DEFAULT NULL
)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  WITH base AS (
    SELECT COALESCE(
      NULLIF(p_price, 0),
      (
        SELECT MIN(NULLIF((opt->>'price')::NUMERIC, 0))
        FROM jsonb_array_elements(COALESCE(p_pricing_options, '[]'::jsonb)) opt
      ),
      0
    ) AS base_price
  )
  SELECT CASE
    WHEN COALESCE(p_is_free, FALSE) THEN 0
    WHEN COALESCE(p_is_flash_sale, FALSE)
      AND (p_flash_sale_end IS NULL OR p_flash_sale_end > NOW())
      AND COALESCE(p_flash_sale_price, 0) > 0
      AND p_flash_sale_price < base.base_price
      THEN p_flash_sale_price
    WHEN COALESCE(p_discount_price, 0) > 0
      AND p_discount_price < base.base_price
      THEN p_discount_price
    ELSE base.base_price
  END
  FROM base;
$$;

CREATE OR REPLACE FUNCTION public.create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_total_subtotal DECIMAL := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM cart_items WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  SELECT COALESCE(SUM(public.course_effective_price(
    c.price,
    c.discount_price,
    c.is_free,
    c.pricing_options,
    c.is_flash_sale,
    c.flash_sale_price,
    c.flash_sale_end
  )), 0)
  INTO v_total_subtotal
  FROM cart_items ci
  JOIN courses c ON c.id = ci.course_id
  WHERE ci.user_id = p_user_id;

  INSERT INTO parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    p_user_id,
    GREATEST(v_total_subtotal - COALESCE(p_coupon_discount, 0), 0),
    v_total_subtotal,
    COALESCE(p_coupon_discount, 0),
    p_coupon_id, p_coupon_code, COALESCE(p_coupon_discount, 0),
    p_payment_method,
    CASE WHEN GREATEST(v_total_subtotal - COALESCE(p_coupon_discount, 0), 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;

  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.teacher_id,
      public.course_effective_price(
        c.price,
        c.discount_price,
        c.is_free,
        c.pricing_options,
        c.is_flash_sale,
        c.flash_sale_price,
        c.flash_sale_end
      ) AS final_price
    FROM cart_items ci
    JOIN courses c ON c.id = ci.course_id
    WHERE ci.user_id = p_user_id
  LOOP
    INSERT INTO enrollments (
      user_id, course_id, teacher_id, parent_enrollment_id,
      price, status, enrolled_at
    )
    VALUES (
      p_user_id, v_course.course_id, v_course.teacher_id, v_parent_enrollment_id,
      v_course.final_price,
      CASE WHEN v_course.final_price = 0 OR GREATEST(v_total_subtotal - COALESCE(p_coupon_discount, 0), 0) = 0 THEN 'active' ELSE 'pending' END,
      NOW()
    )
    ON CONFLICT (user_id, course_id) DO UPDATE SET
      parent_enrollment_id = EXCLUDED.parent_enrollment_id,
      price = EXCLUDED.price,
      status = EXCLUDED.status,
      updated_at = NOW()
    RETURNING id INTO v_enrollment_id;
  END LOOP;

  IF p_coupon_id IS NOT NULL THEN
    INSERT INTO coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (p_coupon_id, p_user_id, v_parent_enrollment_id, COALESCE(p_coupon_discount, 0));

    UPDATE coupons SET usage_count = usage_count + 1 WHERE id = p_coupon_id;
  END IF;

  DELETE FROM cart_items WHERE user_id = p_user_id;

  RETURN v_parent_enrollment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.course_effective_price(NUMERIC, NUMERIC, BOOLEAN, JSONB, BOOLEAN, NUMERIC, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_enrollment(UUID, TEXT, UUID, VARCHAR, DECIMAL) TO authenticated;



-- ============================================================
-- 027_notifications_user_scope_cleanup.sql
-- ============================================================
-- Keep notification inboxes scoped to the real recipient and account lifetime.
-- This removes stale rows that may have been copied/created before the profile existed.

DELETE FROM notifications n
USING profiles p
WHERE n.user_id = p.id
  AND n.created_at < p.created_at;

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON notifications(user_id, created_at DESC);



-- ============================================================
-- 028_coupon_discounts_in_instructor_earnings.sql
-- ============================================================
-- Instructor earnings must be calculated after per-course coupon discounts.

ALTER TABLE instructor_earnings
ADD COLUMN IF NOT EXISTS coupon_discount DECIMAL(10,2) NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION trigger_create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
  v_teacher_id UUID;
  v_gross DECIMAL(10,2);
  v_coupon_discount DECIMAL(10,2);
  v_platform_fee DECIMAL(10,2);
  v_net DECIMAL(10,2);
  v_revenue_share DECIMAL(5,2) := 100.00;
BEGIN
  IF NEW.status NOT IN ('active', 'completed') THEN
    RETURN NEW;
  END IF;

  v_teacher_id := NEW.teacher_id;
  v_gross := GREATEST(COALESCE(NEW.price, 0), 0);
  v_coupon_discount := LEAST(
    GREATEST(COALESCE(NEW.discount, 0), 0),
    v_gross
  );

  IF v_teacher_id IS NULL THEN
    SELECT teacher_id INTO v_teacher_id
    FROM courses
    WHERE id = NEW.course_id;
  END IF;

  IF v_teacher_id IS NULL OR v_gross <= 0 THEN
    RETURN NEW;
  END IF;

  v_platform_fee := 0.00;
  v_net := GREATEST(v_gross - v_coupon_discount - v_platform_fee, 0);

  INSERT INTO instructor_earnings (
    teacher_id,
    enrollment_id,
    course_id,
    gross_amount,
    coupon_discount,
    platform_fee,
    net_amount,
    revenue_share,
    status,
    available_at,
    created_at
  )
  VALUES (
    v_teacher_id,
    NEW.id,
    NEW.course_id,
    v_gross,
    v_coupon_discount,
    v_platform_fee,
    v_net,
    v_revenue_share,
    'available',
    NOW(),
    NOW()
  )
  ON CONFLICT (enrollment_id)
  DO UPDATE SET
    teacher_id = EXCLUDED.teacher_id,
    course_id = EXCLUDED.course_id,
    gross_amount = EXCLUDED.gross_amount,
    coupon_discount = EXCLUDED.coupon_discount,
    platform_fee = EXCLUDED.platform_fee,
    net_amount = EXCLUDED.net_amount,
    revenue_share = EXCLUDED.revenue_share,
    status = CASE
      WHEN instructor_earnings.status = 'paid' THEN instructor_earnings.status
      ELSE EXCLUDED.status
    END,
    available_at = COALESCE(instructor_earnings.available_at, EXCLUDED.available_at);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trigger_auto_instructor_earning ON enrollments;
CREATE TRIGGER trigger_auto_instructor_earning
AFTER INSERT OR UPDATE OF status, price, discount, teacher_id, course_id
ON enrollments
FOR EACH ROW
EXECUTE FUNCTION trigger_create_instructor_earning();

WITH ranked_earnings AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY enrollment_id
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM instructor_earnings
)
DELETE FROM instructor_earnings ie
USING ranked_earnings ranked
WHERE ie.id = ranked.id
  AND ranked.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_instructor_earnings_enrollment
ON instructor_earnings(enrollment_id);

-- Recalculate old earning rows from their enrollment row.
UPDATE instructor_earnings ie
SET
  gross_amount = GREATEST(COALESCE(e.price, 0), 0),
  coupon_discount = LEAST(
    GREATEST(COALESCE(e.discount, 0), 0),
    GREATEST(COALESCE(e.price, 0), 0)
  ),
  platform_fee = 0,
  net_amount = GREATEST(
    GREATEST(COALESCE(e.price, 0), 0)
    - LEAST(
        GREATEST(COALESCE(e.discount, 0), 0),
        GREATEST(COALESCE(e.price, 0), 0)
      ),
    0
  ),
  revenue_share = 100
FROM enrollments e
WHERE e.id = ie.enrollment_id
  AND e.status IN ('active', 'completed');

-- Create any missing earning rows for active paid enrollments.
INSERT INTO instructor_earnings (
  teacher_id,
  enrollment_id,
  course_id,
  gross_amount,
  coupon_discount,
  platform_fee,
  net_amount,
  revenue_share,
  status,
  available_at,
  created_at
)
SELECT
  COALESCE(e.teacher_id, c.teacher_id),
  e.id,
  e.course_id,
  GREATEST(COALESCE(e.price, 0), 0),
  LEAST(
    GREATEST(COALESCE(e.discount, 0), 0),
    GREATEST(COALESCE(e.price, 0), 0)
  ),
  0,
  GREATEST(
    GREATEST(COALESCE(e.price, 0), 0)
    - LEAST(
        GREATEST(COALESCE(e.discount, 0), 0),
        GREATEST(COALESCE(e.price, 0), 0)
      ),
    0
  ),
  100,
  'available',
  NOW(),
  COALESCE(e.enrolled_at, NOW())
FROM enrollments e
JOIN courses c ON c.id = e.course_id
WHERE e.status IN ('active', 'completed')
  AND GREATEST(COALESCE(e.price, 0), 0) > 0
  AND COALESCE(e.teacher_id, c.teacher_id) IS NOT NULL
ON CONFLICT (enrollment_id)
DO NOTHING;

CREATE OR REPLACE FUNCTION update_course_stats(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_section_count INT;
    v_lesson_count INT;
    v_total_revenue DECIMAL(10,2);
BEGIN
    SELECT COUNT(*) INTO v_section_count
    FROM sections
    WHERE course_id = p_course_id;

    SELECT COUNT(*) INTO v_lesson_count
    FROM lessons
    WHERE course_id = p_course_id;

    SELECT COALESCE(SUM(net_amount), 0) INTO v_total_revenue
    FROM instructor_earnings
    WHERE course_id = p_course_id
      AND status IN ('available', 'paid', 'pending');

    UPDATE courses
    SET
      section_count = v_section_count,
      lesson_count = v_lesson_count,
      total_revenue = v_total_revenue
    WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_teacher_id UUID := auth.uid();
    v_stats JSON;
    v_total_courses INT;
    v_published_courses INT;
    v_total_students INT;
    v_total_enrollments INT;
    v_monthly_enrollments INT;
    v_total_earnings NUMERIC;
    v_available_balance NUMERIC;
    v_pending_balance NUMERIC;
    v_average_rating NUMERIC;
    v_total_reviews INT;
    v_unanswered_questions INT;
BEGIN
    SELECT COUNT(*), COUNT(CASE WHEN is_published THEN 1 END)
    INTO v_total_courses, v_published_courses
    FROM courses
    WHERE teacher_id = v_teacher_id;

    SELECT
        COUNT(DISTINCT e.user_id),
        COUNT(*),
        COUNT(CASE WHEN e.enrolled_at >= DATE_TRUNC('month', NOW()) THEN 1 END)
    INTO v_total_students, v_total_enrollments, v_monthly_enrollments
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.teacher_id = v_teacher_id
      AND e.status IN ('active', 'completed');

    SELECT
      COALESCE(SUM(net_amount), 0),
      COALESCE(SUM(CASE WHEN status IN ('available', 'paid') THEN net_amount ELSE 0 END), 0),
      COALESCE(SUM(CASE WHEN status = 'pending' THEN net_amount ELSE 0 END), 0)
    INTO v_total_earnings, v_available_balance, v_pending_balance
    FROM instructor_earnings
    WHERE teacher_id = v_teacher_id;

    SELECT COALESCE(AVG(cr.rating), 0), COUNT(*)
    INTO v_average_rating, v_total_reviews
    FROM course_reviews cr
    JOIN courses c ON c.id = cr.course_id
    WHERE c.teacher_id = v_teacher_id;

    SELECT COUNT(*)
    INTO v_unanswered_questions
    FROM qa_questions q
    JOIN courses c ON c.id = q.course_id
    WHERE c.teacher_id = v_teacher_id
      AND q.is_answered = false;

    v_stats := json_build_object(
        'total_courses', COALESCE(v_total_courses, 0),
        'published_courses', COALESCE(v_published_courses, 0),
        'total_students', COALESCE(v_total_students, 0),
        'total_enrollments', COALESCE(v_total_enrollments, 0),
        'monthly_enrollments', COALESCE(v_monthly_enrollments, 0),
        'total_earnings', COALESCE(v_total_earnings, 0),
        'available_balance', COALESCE(v_available_balance, 0),
        'pending_balance', COALESCE(v_pending_balance, 0),
        'average_rating', ROUND(COALESCE(v_average_rating, 0)::numeric, 1),
        'total_reviews', COALESCE(v_total_reviews, 0),
        'unanswered_questions', COALESCE(v_unanswered_questions, 0)
    );

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION get_instructor_revenue_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_teacher_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') AS label,
        COALESCE(SUM(ie.net_amount), 0)::DECIMAL(10,2) AS value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) AS dates(date)
    LEFT JOIN instructor_earnings ie ON
        DATE_TRUNC('day', ie.created_at) = dates.date
        AND ie.teacher_id = v_teacher_id
        AND ie.status IN ('available', 'paid', 'pending')
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        PERFORM update_course_stats(course_record.id);
    END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION update_course_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_instructor_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ)
TO authenticated;

REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM authenticated;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM anon;



-- ============================================================
-- 029_fix_group_chat_unauthorized_participants.sql
-- ============================================================
-- ============================================================
-- 029_fix_group_chat_unauthorized_participants.sql
-- 
-- Problem: Students who have NOT enrolled (or have pending enrollments)
-- appear in course group conversations because:
--   1. They were added manually
--   2. Old versions of get_user_conversations auto-joined without
--      proper status filtering
--
-- Fix:
--   1. Remove any 'member' participants from group conversations
--      who are NOT actively enrolled (active/completed) in the course.
--   2. Update get_user_conversations to ONLY auto-join users who
--      have ACTIVE or COMPLETED enrollments.
-- ============================================================

-- Step 1: Clean up unauthorized participants
-- Remove members from group chats if they are not actively enrolled
DELETE FROM public.conversation_participants cp
USING public.conversations c
WHERE cp.conversation_id = c.id
  AND c.type = 'multi'
  AND c.course_id IS NOT NULL
  AND cp.role = 'member'
  AND NOT EXISTS (
    SELECT 1
    FROM public.enrollments e
    WHERE e.course_id = c.course_id
      AND e.user_id = cp.user_id
      AND e.status IN ('active', 'completed')
  )
  -- Don't remove the instructor/admin
  AND NOT EXISTS (
    SELECT 1 FROM public.courses cr
    WHERE cr.id = c.course_id
      AND cr.teacher_id = cp.user_id
  );

-- Step 2: Replace get_user_conversations with a version that
-- auto-joins ONLY on active/completed enrollments
DROP FUNCTION IF EXISTS public.get_user_conversations(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.get_user_conversations(
    p_user_id UUID,
    p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    -- Auto-join ONLY for users with ACTIVE or COMPLETED enrollments
    -- (NOT pending, NOT pending_manual_payment)
    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    SELECT
        c.id,
        p_user_id,
        CASE
            WHEN cr.teacher_id = p_user_id THEN 'admin'
            ELSE 'member'
        END
    FROM public.conversations c
    JOIN public.courses cr ON cr.id = c.course_id
    WHERE c.type = 'multi'
      AND (
          cr.teacher_id = p_user_id
          OR EXISTS (
              SELECT 1
              FROM public.enrollments e
              WHERE e.course_id = c.course_id
                AND e.user_id = p_user_id
                AND e.status IN ('active', 'completed')  -- âœ… Only active/completed
          )
      )
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key DO UPDATE
    SET role = CASE
        WHEN EXCLUDED.role = 'admin' THEN 'admin'
        ELSE conversation_participants.role
    END;

    -- Also remove user from any group chats they are no longer entitled to
    DELETE FROM public.conversation_participants cp2
    USING public.conversations c2
    WHERE cp2.conversation_id = c2.id
      AND c2.type = 'multi'
      AND c2.course_id IS NOT NULL
      AND cp2.user_id = p_user_id
      AND cp2.role = 'member'
      AND NOT EXISTS (
          SELECT 1 FROM public.enrollments e2
          WHERE e2.course_id = c2.course_id
            AND e2.user_id = p_user_id
            AND e2.status IN ('active', 'completed')
      )
      AND NOT EXISTS (
          SELECT 1 FROM public.courses cr2
          WHERE cr2.id = c2.course_id
            AND cr2.teacher_id = p_user_id
      );

    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM public.conversations c
    JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;

SELECT '029 - Fixed unauthorized group chat participants. Active-enrollment-only auto-join applied.' AS status;



-- ============================================================
-- 030_auto_set_course_price_from_options.sql
-- ============================================================
-- Auto-resolve course price to the maximum option price if price is 0 or null
CREATE OR REPLACE FUNCTION handle_course_pricing_fallback()
RETURNS TRIGGER AS $$
DECLARE
  v_max_option_price DECIMAL(10,2) := 0;
BEGIN
  -- If pricing_options is not null and is a valid json array with elements
  IF NEW.pricing_options IS NOT NULL AND jsonb_typeof(NEW.pricing_options) = 'array' AND jsonb_array_length(NEW.pricing_options) > 0 THEN
    -- Extract the maximum price from pricing_options
    SELECT COALESCE(MAX((opt->>'price')::decimal), 0)
    INTO v_max_option_price
    FROM jsonb_array_elements(NEW.pricing_options) AS opt;
    
    -- If the current price is 0 or null and we have a valid max price from options, set it automatically
    IF (NEW.price IS NULL OR NEW.price = 0) AND v_max_option_price > 0 THEN
      NEW.price := v_max_option_price;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_handle_course_pricing_fallback ON courses;

CREATE TRIGGER trg_handle_course_pricing_fallback
BEFORE INSERT OR UPDATE ON courses
FOR EACH ROW
EXECUTE FUNCTION handle_course_pricing_fallback();



-- ============================================================
-- 031_fix_coupons_rls.sql
-- ============================================================
-- ====================================================================
-- ðŸ”§ FIX: Row-Level Security (RLS) Policies for Coupons & Coupon Courses
-- ====================================================================
-- Run this SQL in your Supabase Dashboard -> SQL Editor to allow
-- instructors to successfully create, update, and manage their coupons.
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Policies for coupon_courses (Allows syncing courses to coupons)
-- --------------------------------------------------------------------
ALTER TABLE coupon_courses ENABLE ROW LEVEL SECURITY;

-- Allow select/read for all authenticated/anonymous users (e.g. cart/checkout verification)
DROP POLICY IF EXISTS "Anyone can view coupon courses" ON coupon_courses;
CREATE POLICY "Anyone can view coupon courses" ON coupon_courses FOR SELECT USING (true);

-- Allow instructors to manage (INSERT, UPDATE, DELETE) courses linked to their own coupons
DROP POLICY IF EXISTS "Instructors can manage coupon courses" ON coupon_courses;
CREATE POLICY "Instructors can manage coupon courses" ON coupon_courses FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM coupons
      WHERE coupons.id = coupon_courses.coupon_id 
        AND coupons.teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM coupons
      WHERE coupons.id = coupon_courses.coupon_id 
        AND coupons.teacher_id = auth.uid()
    )
  );

-- Allow admins full control
DROP POLICY IF EXISTS "Admins can manage coupon courses" ON coupon_courses;
CREATE POLICY "Admins can manage coupon courses" ON coupon_courses FOR ALL USING (is_admin());


-- --------------------------------------------------------------------
-- 2. Policies for coupons (Allows instructors to create/edit coupons)
-- --------------------------------------------------------------------
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

-- Students / Cart system can view active coupons
DROP POLICY IF EXISTS "Anyone can view active coupons" ON coupons;
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT USING (is_active = true);

-- Instructors can view coupons they created
DROP POLICY IF EXISTS "Instructors can view own coupons" ON coupons;
CREATE POLICY "Instructors can view own coupons" ON coupons FOR SELECT 
  USING (teacher_id = auth.uid() OR is_admin());

-- Instructors can insert/create their own coupons
DROP POLICY IF EXISTS "Instructors can insert own coupons" ON coupons;
CREATE POLICY "Instructors can insert own coupons" ON coupons FOR INSERT 
  WITH CHECK (teacher_id = auth.uid() OR is_admin());

-- Instructors can update their own coupons
DROP POLICY IF EXISTS "Instructors can update own coupons" ON coupons;
CREATE POLICY "Instructors can update own coupons" ON coupons FOR UPDATE 
  USING (teacher_id = auth.uid() OR is_admin())
  WITH CHECK (teacher_id = auth.uid() OR is_admin());

-- Instructors can delete their own coupons
DROP POLICY IF EXISTS "Instructors can delete own coupons" ON coupons;
CREATE POLICY "Instructors can delete own coupons" ON coupons FOR DELETE 
  USING (teacher_id = auth.uid() OR is_admin());

-- Admins can manage all coupons
DROP POLICY IF EXISTS "Admins can manage all coupons" ON coupons;
CREATE POLICY "Admins can manage all coupons" ON coupons FOR ALL USING (is_admin());



-- ============================================================
-- 032_quiz_section_scope_and_publish_default.sql
-- ============================================================
-- Add section-level quiz support and make new quizzes unpublished by default.

ALTER TABLE quizzes
  ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES sections(id) ON DELETE CASCADE;

ALTER TABLE quizzes
  ALTER COLUMN is_published SET DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_quizzes_section ON quizzes(section_id);

COMMENT ON COLUMN quizzes.section_id IS
  'Optional: if set and lesson_id is null, the quiz belongs to an entire course section.';



-- ============================================================
-- 033_notifications_read_timestamps.sql
-- ============================================================
-- Add optional read/update timestamps for notification inbox actions.

ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;



-- ============================================================
-- 034_decrement_enrolled_count.sql
-- ============================================================
-- ============================================================
-- Function: decrement_enrolled_count
-- Description: Decrements the enrolled_count on the courses table
--              when a student is unenrolled. Uses GREATEST(0, ...)
--              to prevent the count from going below zero.
-- Usage (Flutter): _client.rpc('decrement_enrolled_count', params: {'p_course_id': courseId})
-- ============================================================

CREATE OR REPLACE FUNCTION public.decrement_enrolled_count(p_course_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE courses
  SET enrolled_count = GREATEST(0, enrolled_count - 1)
  WHERE id = p_course_id;
END;
$$;



-- ============================================================
-- 035_instructor_unenroll_rls.sql
-- ============================================================
-- ============================================================
-- Script: 035_instructor_unenroll_rls.sql
-- Description: Adds RLS policy allowing instructors to delete
--              enrollments and lesson_progress for their own courses.
--              Also creates decrement_enrolled_count function.
-- ============================================================

-- ---------------------------------------------------------------
-- 1. Allow instructors to DELETE enrollments for their own courses
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can delete enrollments for their courses" ON enrollments;

CREATE POLICY "Instructors can delete enrollments for their courses"
ON enrollments
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = enrollments.course_id
      AND courses.teacher_id = auth.uid()
  )
);

-- ---------------------------------------------------------------
-- 2. Allow instructors to DELETE lesson_progress for their courses
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can delete lesson_progress for their courses" ON lesson_progress;

CREATE POLICY "Instructors can delete lesson_progress for their courses"
ON lesson_progress
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = lesson_progress.course_id
      AND courses.teacher_id = auth.uid()
  )
);

-- ---------------------------------------------------------------
-- 3. Create decrement_enrolled_count function (if not exists)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decrement_enrolled_count(p_course_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE courses
  SET enrolled_count = GREATEST(0, enrolled_count - 1)
  WHERE id = p_course_id;
END;
$$;



-- ============================================================
-- 036_review_reports_rls.sql
-- ============================================================
-- ============================================================
-- Script: 036_review_reports_rls.sql
-- Description: Adds missing RLS policies for the review_reports table.
--              Allows authenticated users to insert reports and read
--              their own reports.
-- ============================================================

-- ---------------------------------------------------------------
-- 1. Allow authenticated users to INSERT into review_reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can insert review reports" ON review_reports;

CREATE POLICY "Authenticated users can insert review reports"
ON review_reports
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 2. Allow users to SELECT their own review reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own review reports" ON review_reports;

CREATE POLICY "Users can view their own review reports"
ON review_reports
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 3. Allow admins/instructors to view all reports (optional)
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can view review reports for their courses" ON review_reports;

CREATE POLICY "Instructors can view review reports for their courses"
ON review_reports
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM course_reviews cr
    JOIN courses c ON c.id = cr.course_id
    WHERE cr.id = review_reports.review_id
      AND c.teacher_id = auth.uid()
  )
);



-- ============================================================
-- 037_course_reports_rls.sql
-- ============================================================
-- ============================================================
-- Script: 037_course_reports_rls.sql
-- Description: Adds missing RLS policies for the course_reports table.
--              Allows authenticated users to insert and read their reports.
-- ============================================================

-- ---------------------------------------------------------------
-- 1. Allow authenticated users to INSERT into course_reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can insert course reports" ON course_reports;

CREATE POLICY "Authenticated users can insert course reports"
ON course_reports
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 2. Allow users to SELECT their own course reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own course reports" ON course_reports;

CREATE POLICY "Users can view their own course reports"
ON course_reports
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 3. Allow instructors to view reports on their own courses
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can view reports on their courses" ON course_reports;

CREATE POLICY "Instructors can view reports on their courses"
ON course_reports
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = course_reports.course_id
      AND courses.teacher_id = auth.uid()
  )
);



-- ============================================================
-- 038_instructor_full_access.sql
-- ============================================================
-- ============================================================
-- Script: 038_instructor_full_access.sql
-- Description: Grants instructor role full access across all
--              relevant tables using the existing is_instructor()
--              helper function. Consolidates and replaces the
--              individual policies added in 035, 036, 037.
-- ============================================================

-- ============================================================
-- ENROLLMENTS â€” Full CRUD for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select all enrollments" ON enrollments;
CREATE POLICY "Instructors can select all enrollments"
ON enrollments FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert enrollments" ON enrollments;
CREATE POLICY "Instructors can insert enrollments"
ON enrollments FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update enrollments" ON enrollments;
CREATE POLICY "Instructors can update enrollments"
ON enrollments FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete enrollments" ON enrollments;
CREATE POLICY "Instructors can delete enrollments"
ON enrollments FOR DELETE TO authenticated
USING (public.is_instructor());

-- ============================================================
-- LESSON_PROGRESS â€” Full CRUD for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can select lesson_progress"
ON lesson_progress FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can insert lesson_progress"
ON lesson_progress FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can update lesson_progress"
ON lesson_progress FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can delete lesson_progress"
ON lesson_progress FOR DELETE TO authenticated
USING (public.is_instructor());

-- ============================================================
-- COURSE_REPORTS â€” Full access for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select course reports" ON course_reports;
CREATE POLICY "Instructors can select course reports"
ON course_reports FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert course reports" ON course_reports;
CREATE POLICY "Instructors can insert course reports"
ON course_reports FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update course reports" ON course_reports;
CREATE POLICY "Instructors can update course reports"
ON course_reports FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete course reports" ON course_reports;
CREATE POLICY "Instructors can delete course reports"
ON course_reports FOR DELETE TO authenticated
USING (public.is_instructor());

-- Allow regular authenticated users to INSERT their own course reports
DROP POLICY IF EXISTS "Authenticated users can insert course reports" ON course_reports;
CREATE POLICY "Authenticated users can insert course reports"
ON course_reports FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to view their own course reports
DROP POLICY IF EXISTS "Users can view their own course reports" ON course_reports;
CREATE POLICY "Users can view their own course reports"
ON course_reports FOR SELECT TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- REVIEW_REPORTS â€” Full access for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select review reports" ON review_reports;
CREATE POLICY "Instructors can select review reports"
ON review_reports FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert review reports" ON review_reports;
CREATE POLICY "Instructors can insert review reports"
ON review_reports FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update review reports" ON review_reports;
CREATE POLICY "Instructors can update review reports"
ON review_reports FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete review reports" ON review_reports;
CREATE POLICY "Instructors can delete review reports"
ON review_reports FOR DELETE TO authenticated
USING (public.is_instructor());

-- Allow regular authenticated users to INSERT their own review reports
DROP POLICY IF EXISTS "Authenticated users can insert review reports" ON review_reports;
CREATE POLICY "Authenticated users can insert review reports"
ON review_reports FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to view their own review reports
DROP POLICY IF EXISTS "Users can view their own review reports" ON review_reports;
CREATE POLICY "Users can view their own review reports"
ON review_reports FOR SELECT TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- COURSES â€” Update enrolled_count (for decrement RPC)
-- ============================================================

DROP POLICY IF EXISTS "Instructors can update courses" ON courses;
CREATE POLICY "Instructors can update courses"
ON courses FOR UPDATE TO authenticated
USING (public.is_instructor());





-- ============================================================
-- 039_get_course_details_rpc.sql
-- ============================================================
-- ============================================================
-- 039_get_course_details_rpc.sql
-- Creates get_course_details() RPC used by both web & Flutter
-- to fetch full curriculum metadata bypassing RLS.
-- Non-enrolled users see locked lessons, enrolled users see all.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_course_details(
  p_course_id UUID,
  p_locale    TEXT DEFAULT 'ar'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'sections', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id',         s.id,
            'title',      CASE
                            WHEN p_locale = 'en'
                              AND s.title_en IS NOT NULL
                              AND s.title_en <> ''
                            THEN s.title_en
                            ELSE s.title_ar
                          END,
            'sort_order', s.sort_order,
            'lessons',    COALESCE(
              (
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'id',              l.id,
                    'title',           CASE
                                         WHEN p_locale = 'en'
                                           AND l.title_en IS NOT NULL
                                           AND l.title_en <> ''
                                         THEN l.title_en
                                         ELSE l.title_ar
                                       END,
                    'type',            l.type,
                    'duration',        l.video_duration,
                    'is_preview',      l.is_preview,
                    'available_from',  l.available_from,
                    'available_until', l.available_until
                  )
                  ORDER BY l.sort_order ASC
                )
                FROM lessons l
                WHERE l.section_id = s.id
              ),
              '[]'::jsonb
            )
          )
          ORDER BY s.sort_order ASC
        )
        FROM sections s
        WHERE s.course_id   = p_course_id
          AND s.is_published = TRUE
      ),
      '[]'::jsonb
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- Grant execute to both anon (guest) and authenticated users
GRANT EXECUTE ON FUNCTION public.get_course_details(UUID, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_course_details(UUID, TEXT) TO authenticated;



-- ============================================================
-- 040_nasaq_app_schema.sql
-- ============================================================
-- Nasaq app schema foundation.
-- This migration keeps the existing LMS shape and adds teacher-scoped app flow.

begin;

create extension if not exists pgcrypto;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'payment_request_status'
  ) then
    create type payment_request_status as enum (
      'pending',
      'approved',
      'rejected',
      'cancelled'
    );
  end if;
end $$;

create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  display_name text not null,
  avatar_url text,
  bio text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(profile_id)
);

create table if not exists public.teacher_settings (
  teacher_id uuid primary key references public.teachers(id) on delete cascade,
  allow_public_profile boolean not null default true,
  allow_student_switching boolean not null default true,
  manual_payment_instructions text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.teacher_themes (
  teacher_id uuid primary key references public.teachers(id) on delete cascade,
  primary_color text not null default '#20E5DC',
  secondary_color text not null default '#117CFF',
  background_color text not null default '#01060B',
  logo_url text,
  welcome_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.teachers (profile_id, display_name, avatar_url)
select p.id, coalesce(p.name, 'Ù…Ø¯Ø±Ø³'), p.avatar_url
from public.profiles p
where p.role::text = 'instructor'
on conflict (profile_id) do nothing;

insert into public.teacher_settings (teacher_id)
select id
from public.teachers
on conflict (teacher_id) do nothing;

insert into public.teacher_themes (teacher_id)
select id
from public.teachers
on conflict (teacher_id) do nothing;

alter table public.profiles
  add column if not exists active_teacher_id uuid references public.teachers(id) on delete set null;

alter table public.courses
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

update public.courses c
set teacher_id = t.id
from public.teachers t
where c.teacher_id is null
  and c.teacher_id = t.profile_id;

create table if not exists public.student_teacher_links (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  is_active boolean not null default false,
  selected_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(student_id, teacher_id)
);

create unique index if not exists student_teacher_links_one_active_idx
  on public.student_teacher_links(student_id)
  where is_active = true;

create table if not exists public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  parent_enrollment_id uuid references public.parent_enrollments(id) on delete set null,
  course_id uuid references public.courses(id) on delete set null,
  amount numeric(10, 2) not null default 0,
  currency text not null default 'EGP',
  status payment_request_status not null default 'pending',
  payment_method text,
  proof_image_url text,
  student_note text,
  teacher_note text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_requests_student_idx
  on public.payment_requests(student_id, created_at desc);

create index if not exists payment_requests_teacher_idx
  on public.payment_requests(teacher_id, status, created_at desc);

create index if not exists payment_requests_parent_enrollment_idx
  on public.payment_requests(parent_enrollment_id);

create index if not exists courses_teacher_idx
  on public.courses(teacher_id, is_published);

create or replace function public.current_profile_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role::text from public.profiles where id = auth.uid()),
    'student'
  );
$$;

create or replace function public.current_teacher_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.teachers where profile_id = auth.uid() limit 1;
$$;

create or replace function public.admin_upsert_teacher(
  p_profile_id uuid,
  p_display_name text default null,
  p_is_active boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_teacher_id uuid;
begin
  if public.current_profile_role() <> 'admin' then
    raise exception 'Only admins can manage teachers';
  end if;

  insert into public.teachers (profile_id, display_name, is_active)
  values (
    p_profile_id,
    coalesce(
      nullif(trim(p_display_name), ''),
      (select coalesce(name, email, 'Ù…Ø¯Ø±Ø³') from public.profiles where id = p_profile_id),
      'Ù…Ø¯Ø±Ø³'
    ),
    p_is_active
  )
  on conflict (profile_id)
  do update set
    display_name = coalesce(nullif(trim(p_display_name), ''), public.teachers.display_name),
    is_active = p_is_active,
    updated_at = now()
  returning id into v_teacher_id;

  update public.profiles
  set role = 'instructor',
      updated_at = now()
  where id = p_profile_id;

  insert into public.teacher_settings (teacher_id)
  values (v_teacher_id)
  on conflict (teacher_id) do nothing;

  insert into public.teacher_themes (teacher_id)
  values (v_teacher_id)
  on conflict (teacher_id) do nothing;

  return v_teacher_id;
end;
$$;

grant execute on function public.admin_upsert_teacher(uuid, text, boolean) to authenticated;

create or replace function public.approve_payment_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.payment_requests%rowtype;
  request_teacher_profile_id uuid;
begin
  select *
  into request_row
  from public.payment_requests
  where id = request_id
  for update;

  if not found then
    raise exception 'Payment request not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and request_row.teacher_id <> public.current_teacher_id() then
    raise exception 'Not allowed';
  end if;

  select profile_id
  into request_teacher_profile_id
  from public.teachers
  where id = request_row.teacher_id;

  update public.payment_requests
  set status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      updated_at = now()
  where id = request_id;

  update public.enrollments
  set status = 'active',
      updated_at = now()
  where user_id = request_row.student_id
    and status = 'pending'
    and (
      parent_enrollment_id = request_row.parent_enrollment_id
      or (
        teacher_id = request_teacher_profile_id
        and (
          request_row.course_id is null
          or course_id = request_row.course_id
        )
      )
    );

  update public.parent_enrollments
  set payment_status = 'paid',
      paid_at = now(),
      updated_at = now()
  where id = request_row.parent_enrollment_id;
end;
$$;

create or replace function public.reject_payment_request(
  request_id uuid,
  note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.payment_requests%rowtype;
begin
  select *
  into request_row
  from public.payment_requests
  where id = request_id
  for update;

  if not found then
    raise exception 'Payment request not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and request_row.teacher_id <> public.current_teacher_id() then
    raise exception 'Not allowed';
  end if;

  update public.payment_requests
  set status = 'rejected',
      teacher_note = note,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      updated_at = now()
  where id = request_id;
end;
$$;

alter table public.teachers enable row level security;
alter table public.teacher_settings enable row level security;
alter table public.teacher_themes enable row level security;
alter table public.student_teacher_links enable row level security;
alter table public.payment_requests enable row level security;

drop policy if exists "Teachers are visible to authenticated users" on public.teachers;
create policy "Teachers are visible to authenticated users"
on public.teachers for select
to authenticated
using (is_active = true or profile_id = auth.uid() or public.current_profile_role() = 'admin');

drop policy if exists "Admins manage teachers" on public.teachers;
create policy "Admins manage teachers"
on public.teachers for all
to authenticated
using (public.current_profile_role() = 'admin')
with check (public.current_profile_role() = 'admin');

drop policy if exists "Teachers manage own settings" on public.teacher_settings;
create policy "Teachers manage own settings"
on public.teacher_settings for all
to authenticated
using (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin')
with check (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin');

drop policy if exists "Teacher themes are visible" on public.teacher_themes;
create policy "Teacher themes are visible"
on public.teacher_themes for select
to authenticated
using (true);

drop policy if exists "Teachers manage own themes" on public.teacher_themes;
create policy "Teachers manage own themes"
on public.teacher_themes for all
to authenticated
using (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin')
with check (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin');

drop policy if exists "Students view own teacher links" on public.student_teacher_links;
create policy "Students view own teacher links"
on public.student_teacher_links for select
to authenticated
using (
  student_id = auth.uid()
  or teacher_id = public.current_teacher_id()
  or public.current_profile_role() = 'admin'
);

drop policy if exists "Students choose own teachers" on public.student_teacher_links;
create policy "Students choose own teachers"
on public.student_teacher_links for insert
to authenticated
with check (student_id = auth.uid());

drop policy if exists "Students update own active teacher" on public.student_teacher_links;
create policy "Students update own active teacher"
on public.student_teacher_links for update
to authenticated
using (student_id = auth.uid() or public.current_profile_role() = 'admin')
with check (student_id = auth.uid() or public.current_profile_role() = 'admin');

drop policy if exists "Payment requests scoped select" on public.payment_requests;
create policy "Payment requests scoped select"
on public.payment_requests for select
to authenticated
using (
  student_id = auth.uid()
  or teacher_id = public.current_teacher_id()
  or public.current_profile_role() = 'admin'
);

drop policy if exists "Students create own payment requests" on public.payment_requests;
create policy "Students create own payment requests"
on public.payment_requests for insert
to authenticated
with check (student_id = auth.uid());

drop policy if exists "Teachers review own payment requests" on public.payment_requests;
create policy "Teachers review own payment requests"
on public.payment_requests for update
to authenticated
using (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin')
with check (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin');

commit;



-- ============================================================
-- 041_nasaq_teacher_scoped_purchases.sql
-- ============================================================
-- Nasaq teacher-scoped purchase workflow.
-- Run after the Ahmed/Shehab commerce migrations and 040_nasaq_app_schema.sql.

begin;

alter table public.parent_enrollments
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

alter table public.manual_purchase_request_items
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

update public.parent_enrollments pe
set teacher_id = t.id
from public.manual_purchase_request_items item
join public.teachers t on t.profile_id = item.teacher_id
where pe.id = item.parent_enrollment_id
  and pe.teacher_id is null;

update public.manual_purchase_request_items item
set teacher_id = t.id
from public.teachers t
where item.teacher_id is null
  and item.teacher_id = t.profile_id;

create index if not exists idx_parent_enrollments_teacher_manual
on public.parent_enrollments(teacher_id, payment_status, created_at desc)
where payment_method = 'manual';

create index if not exists idx_manual_purchase_items_teacher
on public.manual_purchase_request_items(teacher_id, created_at desc);

drop policy if exists "Teachers can view own manual parent enrollments"
on public.parent_enrollments;
create policy "Teachers can view own manual parent enrollments"
on public.parent_enrollments
for select
to authenticated
using (
  user_id = auth.uid()
  or public.current_profile_role() = 'admin'
  or teacher_id = public.current_teacher_id()
);

drop policy if exists "Teachers can view own manual request items"
on public.manual_purchase_request_items;
create policy "Teachers can view own manual request items"
on public.manual_purchase_request_items
for select
to authenticated
using (
  user_id = auth.uid()
  or public.current_profile_role() = 'admin'
  or teacher_id = public.current_teacher_id()
);

drop policy if exists "Users can create teacher scoped manual request items"
on public.manual_purchase_request_items;
create policy "Users can create teacher scoped manual request items"
on public.manual_purchase_request_items
for insert
to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.parent_enrollments pe
    where pe.id = parent_enrollment_id
      and pe.user_id = auth.uid()
      and pe.teacher_id = manual_purchase_request_items.teacher_id
      and pe.payment_method = 'manual'
      and pe.payment_status = 'pending_manual_payment'
  )
);

create or replace function public.approve_manual_purchase_request(
  p_parent_enrollment_id uuid,
  p_access_days integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.parent_enrollments%rowtype;
  v_item record;
  v_inserted_count integer := 0;
begin
  select *
  into v_order
  from public.parent_enrollments
  where id = p_parent_enrollment_id
    and payment_status = 'pending_manual_payment'
  for update;

  if not found then
    raise exception 'Pending manual purchase request was not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and v_order.teacher_id <> public.current_teacher_id() then
    raise exception 'Only the request teacher or an admin can approve this request';
  end if;

  if p_access_days not in (30, 60, 90) then
    raise exception 'Access days must be 30, 60, or 90';
  end if;

  if not exists (
    select 1
    from public.manual_purchase_request_items
    where parent_enrollment_id = p_parent_enrollment_id
      and teacher_id = v_order.teacher_id
  ) then
    raise exception 'Manual purchase request has no courses';
  end if;

  update public.parent_enrollments
  set payment_status = 'paid',
      payment_method = 'manual',
      paid_at = now(),
      updated_at = now()
  where id = p_parent_enrollment_id;

  for v_item in
    select *
    from public.manual_purchase_request_items
    where parent_enrollment_id = p_parent_enrollment_id
      and teacher_id = v_order.teacher_id
  loop
    insert into public.enrollments (
      user_id,
      course_id,
      teacher_id,
      parent_enrollment_id,
      price,
      pricing_option,
      discount,
      status,
      progress_percentage,
      completed_lessons,
      total_watch_time,
      access_expires_at,
      enrolled_at,
      updated_at
    )
    values (
      v_item.user_id,
      v_item.course_id,
      v_item.teacher_id,
      p_parent_enrollment_id,
      v_item.price,
      v_item.pricing_option,
      coalesce(v_item.discount, 0),
      'active',
      0,
      0,
      0,
      now() + make_interval(days => p_access_days),
      now(),
      now()
    )
    on conflict (user_id, course_id)
    do update set
      teacher_id = excluded.teacher_id,
      parent_enrollment_id = excluded.parent_enrollment_id,
      price = excluded.price,
      pricing_option = excluded.pricing_option,
      discount = excluded.discount,
      status = 'active',
      access_expires_at = excluded.access_expires_at,
      enrolled_at = now(),
      updated_at = now()
    where public.enrollments.status not in ('active', 'completed');

    v_inserted_count := v_inserted_count + 1;
  end loop;

  if v_inserted_count = 0 then
    raise exception 'No enrollments were activated';
  end if;

  return true;
end;
$$;

create or replace function public.cancel_manual_purchase_request(
  p_parent_enrollment_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.parent_enrollments%rowtype;
begin
  select *
  into v_order
  from public.parent_enrollments
  where id = p_parent_enrollment_id
    and payment_status = 'pending_manual_payment'
  for update;

  if not found then
    raise exception 'Pending manual purchase request was not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and v_order.teacher_id <> public.current_teacher_id() then
    raise exception 'Only the request teacher or an admin can cancel this request';
  end if;

  update public.parent_enrollments
  set payment_status = 'cancelled',
      updated_at = now()
  where id = p_parent_enrollment_id;

  delete from public.enrollments
  where parent_enrollment_id = p_parent_enrollment_id;

  return true;
end;
$$;

grant execute on function public.approve_manual_purchase_request(uuid, integer) to authenticated;
grant execute on function public.cancel_manual_purchase_request(uuid) to authenticated;

commit;



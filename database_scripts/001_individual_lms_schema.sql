-- ============================================================
-- 🎓 LMS (Learning Management System) - Individual/Single-Instructor LMS Database Schema
-- مخطط قاعدة البيانات لنسخة المدرس الواحد (مدرس واحد + طلاب)
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
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
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

CREATE INDEX idx_courses_instructor ON courses(instructor_id);
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
  instructor_id UUID REFERENCES profiles(id),
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
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
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
  instructor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
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
      c.instructor_id,
      CASE 
        WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
        ELSE COALESCE(c.discount_price, c.price)
      END as final_price
    FROM cart_items ci
    JOIN courses c ON c.id = ci.course_id
    WHERE ci.user_id = p_user_id
  LOOP
    INSERT INTO enrollments (
      user_id, course_id, instructor_id, parent_enrollment_id,
      price, status, enrolled_at
    )
    VALUES (
      p_user_id, v_course.course_id, v_course.instructor_id, v_parent_enrollment_id,
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
  
  SELECT name INTO v_instructor FROM profiles WHERE id = v_course.instructor_id;
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
    RETURN json_build_object('valid', false, 'error_ar', 'كود الخصم غير صحيح', 'error_en', 'Invalid coupon code');
  END IF;
  
  IF v_coupon.start_date > NOW() THEN
    RETURN json_build_object('valid', false, 'error_ar', 'كود الخصم لم يبدأ بعد', 'error_en', 'Coupon not started yet');
  END IF;
  
  IF v_coupon.end_date IS NOT NULL AND v_coupon.end_date < NOW() THEN
    RETURN json_build_object('valid', false, 'error_ar', 'كود الخصم منتهي', 'error_en', 'Coupon expired');
  END IF;
  
  IF v_coupon.usage_limit IS NOT NULL AND v_coupon.usage_count >= v_coupon.usage_limit THEN
    RETURN json_build_object('valid', false, 'error_ar', 'تم استنفاد الكوبون', 'error_en', 'Coupon exhausted');
  END IF;
  
  SELECT COUNT(*) INTO v_user_usage_count FROM coupon_usages WHERE coupon_id = v_coupon.id AND user_id = p_user_id;
  IF v_user_usage_count >= v_coupon.usage_limit_per_user THEN
    RETURN json_build_object('valid', false, 'error_ar', 'لقد استخدمت هذا الكوبون من قبل', 'error_en', 'Already used this coupon');
  END IF;
  
  IF p_cart_total < v_coupon.min_order_amount THEN
    RETURN json_build_object('valid', false, 'error_ar', 'الحد الأدنى للطلب ' || v_coupon.min_order_amount, 'error_en', 'Minimum order is ' || v_coupon.min_order_amount);
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
    v_instructor_id UUID;
BEGIN
    SELECT id INTO v_conversation_id
    FROM conversations
    WHERE course_id = p_course_id AND type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        SELECT instructor_id INTO v_instructor_id
        FROM courses WHERE id = p_course_id;

        INSERT INTO conversations (type, course_id, title, created_by)
        SELECT 'multi', p_course_id, COALESCE(c.title_ar, c.title_en, 'Course Forum'), COALESCE(v_instructor_id, p_user_id)
        FROM courses c WHERE c.id = p_course_id
        RETURNING id INTO v_conversation_id;

        IF v_instructor_id IS NOT NULL THEN
            INSERT INTO conversation_participants (conversation_id, user_id, role)
            VALUES (v_conversation_id, v_instructor_id, 'admin')
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
    v_instructor_id UUID := auth.uid();
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
    FROM courses WHERE instructor_id = v_instructor_id;
    
    -- Get student/enrollment counts
    SELECT 
        COUNT(DISTINCT e.user_id),
        COUNT(*),
        COUNT(CASE WHEN e.enrolled_at >= DATE_TRUNC('month', NOW()) THEN 1 END)
    INTO v_total_students, v_total_enrollments, v_monthly_enrollments
    FROM enrollments e 
    JOIN courses c ON c.id = e.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get earnings directly from enrollments (price paid)
    SELECT 
        COALESCE(SUM(e.price), 0)
    INTO v_total_earnings
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.instructor_id = v_instructor_id AND e.status IN ('active', 'completed');
    
    -- Available balance is equal to total earnings in single instructor setup
    v_available_balance := v_total_earnings;
    
    -- Pending balance represents courses that are pending payment
    SELECT 
        COALESCE(SUM(e.price), 0)
    INTO v_pending_balance
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.instructor_id = v_instructor_id AND e.status = 'pending';
    
    -- Get ratings
    SELECT COALESCE(AVG(cr.rating), 0), COUNT(*)
    INTO v_average_rating, v_total_reviews
    FROM course_reviews cr 
    JOIN courses c ON c.id = cr.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get unanswered questions
    SELECT COUNT(*)
    INTO v_unanswered_questions
    FROM qa_questions q 
    JOIN courses c ON c.id = q.course_id 
    WHERE c.instructor_id = v_instructor_id AND q.is_answered = false;
    
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
    v_instructor_id UUID := auth.uid();
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
        AND e.instructor_id = v_instructor_id
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
    v_instructor_id UUID := auth.uid();
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
        AND e.instructor_id = v_instructor_id
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
CREATE POLICY "Instructor can do everything on courses" ON courses FOR ALL USING (instructor_id = auth.uid() OR is_admin());

-- 15.5 sections Policies
CREATE POLICY "Anyone can view sections of published courses" ON sections FOR SELECT 
  USING (EXISTS (SELECT 1 FROM courses WHERE id = sections.course_id AND is_published = true) OR is_admin() OR is_enrolled(sections.course_id));
CREATE POLICY "Instructor can manage sections" ON sections FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses WHERE id = sections.course_id AND (instructor_id = auth.uid() OR is_admin())));

-- 15.6 lessons Policies
CREATE POLICY "View lessons if enrolled or preview" ON lessons FOR SELECT 
  USING (is_preview = true OR is_enrolled(lessons.course_id) OR is_admin());
CREATE POLICY "Instructor can manage lessons" ON lessons FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses WHERE id = lessons.course_id AND (instructor_id = auth.uid() OR is_admin())));

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
  ('مبتدئ', 'Beginner', 'beginner', 'مناسب للمبتدئين بدون خبرة سابقة', 'Suitable for beginners with no prior experience', 1, true),
  ('متوسط', 'Intermediate', 'intermediate', 'يتطلب معرفة أساسية بالموضوع', 'Requires basic knowledge of the subject', 2, true),
  ('متقدم', 'Advanced', 'advanced', 'للمتقدمين ذوي الخبرة', 'For advanced learners with experience', 3, true),
  ('جميع المستويات', 'All Levels', 'all_levels', 'مناسب لجميع المستويات', 'Suitable for all levels', 4, true)
ON CONFLICT (slug) DO NOTHING;

-- Insert default categories
INSERT INTO categories (id, name_ar, name_en, description_ar, description_en, icon_name, image_url, sort_order, is_active) VALUES
('c1000000-0000-4000-a000-000000000001', 'البرمجة والتطوير', 'Development', 'تعلم البرمجة وتطوير التطبيقات', 'Learn programming and app development', 'code', 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400', 1, true),
('c1000000-0000-4000-a000-000000000002', 'التصميم', 'Design', 'تصميم الجرافيك وواجهات المستخدم', 'Graphic design and UI/UX', 'palette', 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400', 2, true),
('c1000000-0000-4000-a000-000000000003', 'الرياضيات والعلوم', 'Math & Science', 'شرح مناهج الرياضيات والعلوم', 'Mathematics and Science curricula', 'functions', 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400', 3, true)
ON CONFLICT (id) DO NOTHING;

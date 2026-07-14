-- ============================================================
-- Migration: 20260714000800_drop_unused_columns.sql
-- Purpose  : Clean up unused columns from tables.
--            (Keeping course level relation 'level_id' and 'flash_sale_price')
-- ============================================================

BEGIN;

-- 1. Drop unused columns from courses table
-- (We keep level_id and flash_sale_price as requested)
ALTER TABLE public.courses 
  DROP COLUMN IF EXISTS max_students,
  DROP COLUMN IF EXISTS tags,
  DROP COLUMN IF EXISTS certificate_template_id;

-- 2. Drop unused columns from enrollments table
-- (These relate to unused certificate_id and refund flows)
ALTER TABLE public.enrollments
  DROP COLUMN IF EXISTS certificate_id,
  DROP COLUMN IF EXISTS refund_requested_at,
  DROP COLUMN IF EXISTS refund_reason,
  DROP COLUMN IF EXISTS refunded_at;

-- 3. Drop unused columns from payment_requests table
ALTER TABLE public.payment_requests
  DROP COLUMN IF EXISTS proof_image_url,
  DROP COLUMN IF EXISTS student_note,
  DROP COLUMN IF EXISTS teacher_note,
  DROP COLUMN IF EXISTS reviewed_by,
  DROP COLUMN IF EXISTS reviewed_at;

-- 4. Drop unused columns from teacher_settings table
ALTER TABLE public.teacher_settings
  DROP COLUMN IF EXISTS allow_public_profile,
  DROP COLUMN IF EXISTS allow_student_switching,
  DROP COLUMN IF EXISTS manual_payment_instructions;

COMMIT;

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

-- 3. Drop unused tables completely (with CASCADE to clean up dependent triggers/RLS)
DROP TABLE IF EXISTS public.certificates CASCADE;
DROP TABLE IF EXISTS public.coupon_categories CASCADE;
DROP TABLE IF EXISTS public.payment_requests CASCADE;
DROP TABLE IF EXISTS public.teacher_settings CASCADE;
DROP TABLE IF EXISTS public.announcement_reads CASCADE;

COMMIT;

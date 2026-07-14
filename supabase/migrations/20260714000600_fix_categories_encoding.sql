-- ============================================================
-- Migration: 20260714000600_fix_categories_encoding.sql
-- Purpose  : Fix garbled category name and description records in 
--            the categories table due to legacy encoding issues.
-- ============================================================

begin;

-- Fix Category 1: البرمجة والتطوير
update public.categories
set 
  name_ar = 'البرمجة والتطوير',
  description_ar = 'تعلم البرمجة وتطوير التطبيقات'
where id = 'c1000000-0000-4000-a000-000000000001';

-- Fix Category 2: التصميم
update public.categories
set 
  name_ar = 'التصميم',
  description_ar = 'تصميم الجرافيك وواجهات المستخدم'
where id = 'c1000000-0000-4000-a000-000000000002';

-- Fix Category 3: الرياضيات والعلوم
update public.categories
set 
  name_ar = 'الرياضيات والعلوم',
  description_ar = 'شرح مناهج الرياضيات والعلوم'
where id = 'c1000000-0000-4000-a000-000000000003';

commit;

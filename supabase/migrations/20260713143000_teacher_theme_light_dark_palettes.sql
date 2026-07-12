alter table public.teacher_themes
  add column if not exists light_primary_color text,
  add column if not exists light_secondary_color text,
  add column if not exists light_background_color text,
  add column if not exists dark_primary_color text,
  add column if not exists dark_secondary_color text,
  add column if not exists dark_background_color text;

alter table public.teachers
  add column if not exists cover_image_url text;

update public.teacher_themes
set
  light_primary_color = coalesce(light_primary_color, primary_color, '#20E5DC'),
  light_secondary_color = coalesce(light_secondary_color, secondary_color, '#117CFF'),
  light_background_color = coalesce(light_background_color, '#F4F9FA'),
  dark_primary_color = coalesce(dark_primary_color, primary_color, '#20E5DC'),
  dark_secondary_color = coalesce(dark_secondary_color, secondary_color, '#117CFF'),
  dark_background_color = coalesce(dark_background_color, background_color, '#01060B')
where
  light_primary_color is null
  or light_secondary_color is null
  or light_background_color is null
  or dark_primary_color is null
  or dark_secondary_color is null
  or dark_background_color is null;

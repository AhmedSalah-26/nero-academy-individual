alter table public.teacher_themes
  add column if not exists light_button_color text,
  add column if not exists dark_button_color text,
  add column if not exists light_card_color text,
  add column if not exists dark_card_color text,
  add column if not exists light_logo_url text,
  add column if not exists dark_logo_url text,
  add column if not exists light_cover_url text,
  add column if not exists dark_cover_url text;

update public.teacher_themes
set
  light_button_color = coalesce(light_button_color, light_primary_color, primary_color, '#20E5DC'),
  dark_button_color = coalesce(dark_button_color, dark_primary_color, primary_color, '#20E5DC'),
  light_card_color = coalesce(light_card_color, '#FFFFFF'),
  dark_card_color = coalesce(dark_card_color, '#071720'),
  light_cover_url = coalesce(light_cover_url, logo_url),
  dark_cover_url = coalesce(dark_cover_url, logo_url)
where
  light_button_color is null
  or dark_button_color is null
  or light_card_color is null
  or dark_card_color is null
  or light_cover_url is null
  or dark_cover_url is null;

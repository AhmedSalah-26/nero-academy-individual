'use client';

import { useEffect, useState, type ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import {
  Search,
  Check,
  AutoAwesome,
  ArrowForward,
  ArrowBack,
  Science,
  Calculate,
  Bolt,
  Biotech,
  Translate,
  Language,
  School,
  MenuBook,
  Palette,
  MusicNote,
  SportsSoccer,
  Computer,
  Psychology,
  HistoryEdu,
  Public,
  Category,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { useFadeIn, useStagger } from '../../lib/animations';
import styles from './page.module.css';

interface Category {
  id: string;
  name_ar: string;
  name_en: string;
}

const CATEGORY_ICON_MAP: Record<string, ReactNode> = {
  كيمياء: <Science fontSize="small" />,
  chemistry: <Science fontSize="small" />,
  رياضيات: <Calculate fontSize="small" />,
  math: <Calculate fontSize="small" />,
  mathematics: <Calculate fontSize="small" />,
  فيزياء: <Bolt fontSize="small" />,
  physics: <Bolt fontSize="small" />,
  أحياء: <Biotech fontSize="small" />,
  biology: <Biotech fontSize="small" />,
  عربي: <Translate fontSize="small" />,
  arabic: <Translate fontSize="small" />,
  انجليزي: <Language fontSize="small" />,
  english: <Language fontSize="small" />,
  فرنساوي: <Language fontSize="small" />,
  french: <Language fontSize="small" />,
  حاسب: <Computer fontSize="small" />,
  كمبيوتر: <Computer fontSize="small" />,
  computer: <Computer fontSize="small" />,
  programming: <Computer fontSize="small" />,
  برمجة: <Computer fontSize="small" />,
  تعليم: <School fontSize="small" />,
  education: <School fontSize="small" />,
  قراءة: <MenuBook fontSize="small" />,
  reading: <MenuBook fontSize="small" />,
  فن: <Palette fontSize="small" />,
  art: <Palette fontSize="small" />,
  موسيقى: <MusicNote fontSize="small" />,
  music: <MusicNote fontSize="small" />,
  رياضة: <SportsSoccer fontSize="small" />,
  sports: <SportsSoccer fontSize="small" />,
  نفسية: <Psychology fontSize="small" />,
  psychology: <Psychology fontSize="small" />,
  تاريخ: <HistoryEdu fontSize="small" />,
  history: <HistoryEdu fontSize="small" />,
  جغرافيا: <Public fontSize="small" />,
  geography: <Public fontSize="small" />,
};

function getCategoryIcon(nameAr: string, nameEn: string): ReactNode {
  const keyAr = nameAr?.toLowerCase().trim();
  const keyEn = nameEn?.toLowerCase().trim();
  if (keyAr && CATEGORY_ICON_MAP[keyAr]) return CATEGORY_ICON_MAP[keyAr];
  if (keyEn && CATEGORY_ICON_MAP[keyEn]) return CATEGORY_ICON_MAP[keyEn];
  for (const key of Object.keys(CATEGORY_ICON_MAP)) {
    if (keyAr?.includes(key) || keyEn?.includes(key)) return CATEGORY_ICON_MAP[key];
  }
  return <Category fontSize="small" />;
}

export default function InterestsPage() {
  const { lang, t, user, profile, refreshAuth, loading: authLoading } = useApp();
  const router = useRouter();
  const [categories, setCategories] = useState<Category[]>([]);
  const [selected, setSelected] = useState<Set<string>>(
    () => new Set(profile?.interests || [])
  );
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const heroRef = useFadeIn<HTMLElement>();
  const gridRef = useStagger<HTMLDivElement>(`.${styles.chip}`);

  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      router.push('/login?redirect=/interests');
      return;
    }

    if (profile?.interests && profile.interests.length > 0) {
      router.push('/');
      return;
    }

    async function load() {
      const { data } = await supabase
        .from('categories')
        .select('id, name_ar, name_en')
        .eq('is_active', true)
        .order('name_ar', { ascending: true });
      setCategories((data || []) as Category[]);
      setLoading(false);
    }

    load();
  }, [authLoading, user, profile, router]);

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const filtered = categories.filter((c) => {
    const term = query.trim().toLowerCase();
    if (!term) return true;
    const name = lang === 'ar' ? c.name_ar : c.name_en;
    return name?.toLowerCase().includes(term);
  });

  const handleSave = async () => {
    if (!user) return;
    if (selected.size < 3) {
      setError(t.minInterests);
      return;
    }
    setSaving(true);
    setError(null);

    const { error: updateError } = await supabase
      .from('profiles')
      .update({ interests: Array.from(selected) })
      .eq('id', user.id);

    if (updateError) {
      setError(updateError.message);
      setSaving(false);
      return;
    }

    await refreshAuth();
    router.push('/');
  };

  if (authLoading || !user) return null;

  const minReached = selected.size >= 3;
  const countLabel = lang === 'ar'
    ? `متابعة (${selected.size} محدد)`
    : `Continue (${selected.size} selected)`;

  return (
    <main className={`${styles.page} fade-in`}>
      <section ref={heroRef} className={`${styles.hero} glass`}>
        <div className={styles.eyebrow}>
          <AutoAwesome fontSize="small" style={{ verticalAlign: 'middle', marginInlineEnd: 6 }} />
          {lang === 'ar' ? 'خطوة واحدة تفصلك عن البدء' : 'One step away from getting started'}
        </div>
        <h1 className={`${styles.title} gradient-text`}>{t.interestsTitle}</h1>
        <p className={styles.subtitle}>{t.interestsSubtitle}</p>
      </section>

      <div className={styles.toolbar}>
        <Search fontSize="small" style={{ color: 'var(--text-muted)', marginInlineStart: 8, flexShrink: 0 }} />
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={t.interestsSearch}
          className={styles.search}
        />
      </div>

      {error && <div className={styles.error}>{error}</div>}

      {loading ? (
        <div className={styles.loading}>{t.loading}</div>
      ) : filtered.length === 0 ? (
        <div className={styles.empty}>
          {lang === 'ar' ? 'لا توجد تصنيفات مطابقة' : 'No matching categories'}
        </div>
      ) : (
        <div ref={gridRef} className={styles.grid}>
          {filtered.map((category) => {
            const isSelected = selected.has(category.id);
            return (
              <button
                key={category.id}
                type="button"
                onClick={() => toggle(category.id)}
                className={`${styles.chip} ${isSelected ? styles.selected : ''}`}
                aria-pressed={isSelected}
              >
                <span className={styles.check}>{isSelected && <Check fontSize="small" />}</span>
                <span className={styles.chipIcon}>
                  {getCategoryIcon(category.name_ar, category.name_en)}
                </span>
                {lang === 'ar' ? category.name_ar : category.name_en}
              </button>
            );
          })}
        </div>
      )}

      <div className={styles.actions}>
        <button
          type="button"
          onClick={() => router.push('/')}
          className={styles.skipBtn}
          disabled={saving}
        >
          {t.interestsSkip}
        </button>
        <button
          type="button"
          onClick={handleSave}
          disabled={saving || !minReached}
          className={`${styles.saveBtn} gradient-bg`}
        >
          {saving ? (
            t.saving
          ) : (
            <>
              {countLabel}
              {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
            </>
          )}
        </button>
      </div>

      <div className={styles.suggestTopic}>
        <a href="mailto:support@shahab.tech">
          {lang === 'ar'
            ? 'اقترح موضوع غير موجود'
            : 'Suggest a topic not listed'}
        </a>
      </div>
    </main>
  );
}

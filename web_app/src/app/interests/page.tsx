'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Check, Sparkles, ArrowRight, ArrowLeft } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { useFadeIn, useStagger } from '../../lib/animations';
import styles from './page.module.css';

interface Category {
  id: string;
  name_ar: string;
  name_en: string;
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

    // Users who already set interests can skip this page
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
    if (selected.size === 0) {
      setError(t.interestsMin);
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

  return (
    <main className={`${styles.page} fade-in`}>
      <section ref={heroRef} className={`${styles.hero} glass`}>
        <div className={styles.eyebrow}>
          <Sparkles size={13} style={{ verticalAlign: 'middle', marginInlineEnd: 6 }} />
          {lang === 'ar' ? 'خطوة واحدة تفصلك عن البدء' : 'One step away from getting started'}
        </div>
        <h1 className={`${styles.title} gradient-text`}>{t.interestsTitle}</h1>
        <p className={styles.subtitle}>{t.interestsSubtitle}</p>
      </section>

      <div className={styles.toolbar}>
        <Search size={18} style={{ color: 'var(--text-muted)', marginInlineStart: 8, flexShrink: 0 }} />
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
                <span className={styles.check}>{isSelected && <Check size={14} />}</span>
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
          disabled={saving || selected.size === 0}
          className={`${styles.saveBtn} gradient-bg`}
        >
          {saving ? (
            t.saving
          ) : (
            <>
              {t.interestsSave}
              {lang === 'ar' ? <ArrowLeft size={16} /> : <ArrowRight size={16} />}
            </>
          )}
        </button>
      </div>
    </main>
  );
}

'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { MessagesSquare, RefreshCw, Users } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import styles from '../student-features.module.css';

type Forum = {
  id: string;
  title?: string | null;
  type: string;
  updated_at: string;
  courses?: { title_ar: string; title_en?: string | null } | null;
};

async function fetchForums() {
  const richQuery = await supabase
    .from('conversations')
    .select('id,title,type,updated_at,courses(title_ar,title_en)')
    .order('updated_at', { ascending: false });

  if (!richQuery.error) return richQuery.data || [];

  const fallbackQuery = await supabase
    .from('conversations')
    .select('id,title,type,updated_at')
    .order('updated_at', { ascending: false });

  if (fallbackQuery.error) throw fallbackQuery.error;
  return fallbackQuery.data || [];
}

export default function ForumsPage() {
  const { lang, user, loading: authLoading } = useApp();
  const [items, setItems] = useState<Forum[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const [retryKey, setRetryKey] = useState(0);

  useEffect(() => {
    if (authLoading || !user) return;

    let cancelled = false;
    const loadingTimer = window.setTimeout(() => {
      if (!cancelled) {
        setLoading(true);
        setError(false);
      }
    }, 0);

    const timeout = window.setTimeout(() => {
      if (!cancelled) {
        setError(true);
        setLoading(false);
      }
    }, 9000);

    fetchForums()
      .then((data) => {
        if (cancelled) return;
        setItems(data as unknown as Forum[]);
      })
      .catch(() => {
        if (!cancelled) setError(true);
      })
      .finally(() => {
        if (!cancelled) {
          window.clearTimeout(timeout);
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
      window.clearTimeout(loadingTimer);
      window.clearTimeout(timeout);
    };
  }, [authLoading, user, retryKey]);

  return (
    <main className={styles.page}>
      <FeaturePageHero
        icon={MessagesSquare}
        eyebrow="COMMUNITY"
        title={lang === 'ar' ? 'المنتديات والمناقشات' : 'Forums'}
        subtitle={
          lang === 'ar'
            ? 'ناقش الدروس واسأل زملاءك وتواصل مع المدرس.'
            : 'Discuss lessons with your community.'
        }
      />

      {authLoading || loading ? (
        <div className={styles.loading}>
          {lang === 'ar' ? 'جاري تحميل المجتمع...' : 'Loading community...'}
        </div>
      ) : !user ? (
        <div className={styles.empty}>
          {lang === 'ar' ? 'سجل الدخول للانضمام للمناقشات' : 'Sign in to join discussions'}
        </div>
      ) : error ? (
        <div className={styles.empty}>
          <MessagesSquare size={38} />
          <strong>
            {lang === 'ar' ? 'تعذر تحميل المجتمع حالياً' : 'Could not load community right now'}
          </strong>
          <button className={styles.action} onClick={() => setRetryKey((key) => key + 1)}>
            <RefreshCw size={14} />
            {lang === 'ar' ? 'إعادة المحاولة' : 'Retry'}
          </button>
        </div>
      ) : !items.length ? (
        <div className={styles.empty}>
          <MessagesSquare size={38} />
          <strong>
            {lang === 'ar' ? 'لا توجد مناقشات متاحة حالياً' : 'No discussions available yet'}
          </strong>
        </div>
      ) : (
        <section className={styles.grid}>
          {items.map((forum) => (
            <Link href={`/forums/${forum.id}`} className={styles.card} key={forum.id}>
              <div className={styles.cardIcon}>
                <Users />
              </div>
              <h3>
                {forum.title ||
                  (lang === 'ar' ? forum.courses?.title_ar : forum.courses?.title_en) ||
                  (lang === 'ar' ? 'مجموعة نقاش' : 'Discussion group')}
              </h3>
              <p>{forum.type === 'multi' ? (lang === 'ar' ? 'مناقشة جماعية' : 'Group discussion') : (lang === 'ar' ? 'محادثة مباشرة' : 'Direct chat')}</p>
              <div className={styles.meta}>
                <span>{new Date(forum.updated_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}</span>
                <span className={styles.badge}>{lang === 'ar' ? 'دخول' : 'Open'}</span>
              </div>
            </Link>
          ))}
        </section>
      )}
    </main>
  );
}

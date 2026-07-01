'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Forum as ForumIcon, Refresh, Groups, Lock, Public } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { AppBackButton, FilterChips, ShimmerEffect, EmptyState, UserAvatar } from '../../components/ui';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

type Forum = {
  id: string;
  title?: string | null;
  type: string;
  updated_at: string;
  courses?: { title_ar: string; title_en?: string | null } | null;
  last_message_preview?: string;
  participant_count?: number;
};

type FilterType = 'all' | 'group' | 'private';

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

function timeAgo(dateStr: string, lang: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return lang === 'ar' ? 'الآن' : 'just now';
  if (mins < 60) return lang === 'ar' ? `منذ ${mins} دقيقة` : `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return lang === 'ar' ? `منذ ${hrs} ساعة` : `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return lang === 'ar' ? `منذ ${days} يوم` : `${days}d ago`;
}

export default function ForumsPage() {
  const pageRef = usePageTransition();
  const { lang, user, profile, loading: authLoading } = useApp();
  const [items, setItems] = useState<Forum[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [retryKey, setRetryKey] = useState(0);
  const [filter, setFilter] = useState<FilterType>('all');

  useEffect(() => {
    if (authLoading || !user) return;
    let cancelled = false;
    fetchForums()
      .then((data) => { if (!cancelled) setItems(data as unknown as Forum[]); })
      .catch(() => { if (!cancelled) setError(true); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [authLoading, user, retryKey]);

  const filtered = items.filter((f) => {
    if (filter === 'all') return true;
    if (filter === 'group') return f.type === 'multi';
    if (filter === 'private') return f.type !== 'multi';
    return true;
  });

  const filterOptions = [
    { id: 'all', label: lang === 'ar' ? 'الكل' : 'All' },
    { id: 'group', label: lang === 'ar' ? 'مجموعات' : 'Groups' },
    { id: 'private', label: lang === 'ar' ? 'خاصة' : 'Private' },
  ];

  const isInstructor = profile?.role === 'instructor';

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.header}>
        <AppBackButton />
        <h1>{lang === 'ar' ? 'المنتديات' : 'Forums'}</h1>
      </div>

      <div className={styles.filterRow}>
        <FilterChips items={filterOptions} selected={[filter]} onChange={(ids) => setFilter((ids[0] || 'all') as FilterType)} />
      </div>

      {loading ? (
        <div className={styles.shimmerGrid}>{Array.from({ length: 4 }).map((_, i) => <ShimmerEffect key={i} height={72} />)}</div>
      ) : !user ? (
        <EmptyState type="forum" />
      ) : error ? (
        <div className={styles.errorState}>
          <ForumIcon fontSize="large" />
          <strong>{lang === 'ar' ? 'تعذر التحميل' : 'Could not load'}</strong>
          <button className={styles.retryBtn} onClick={() => { setRetryKey((k) => k + 1); setLoading(true); setError(false); }}>
            <Refresh fontSize="small" />{lang === 'ar' ? 'إعادة' : 'Retry'}
          </button>
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState type="forum" />
      ) : (
        <section className={styles.list}>
          {filtered.map((forum) => {
            const isGroup = forum.type === 'multi';
            return (
              <Link href={`/forums/${forum.id}`} className={styles.card} key={forum.id}>
                <div className={`${styles.avatarIcon} ${isGroup ? styles.avatarGroup : styles.avatarPrivate}`}>
                  {isGroup ? <Groups fontSize="small" /> : <Lock fontSize="small" />}
                </div>
                <div className={styles.cardBody}>
                  <h3>{forum.title || (lang === 'ar' ? forum.courses?.title_ar : forum.courses?.title_en) || (lang === 'ar' ? 'مجموعة نقاش' : 'Discussion group')}</h3>
                  <span className={`${styles.typeBadge} ${isGroup ? styles.typeGroup : styles.typePrivate}`}>
                    {isGroup ? (lang === 'ar' ? 'جماعي' : 'Group') : (lang === 'ar' ? 'خاص' : 'Private')}
                  </span>
                </div>
                <div className={styles.cardMeta}>
                  <span className={styles.timeAgo}>{timeAgo(forum.updated_at, lang)}</span>
                </div>
              </Link>
            );
          })}
        </section>
      )}
    </main>
  );
}

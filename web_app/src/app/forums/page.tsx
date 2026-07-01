'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Forum as ForumIcon,
  Refresh,
  Groups,
  Lock,
  PeopleAlt,
  ChevronLeft,
  ChevronRight,
} from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { AppBackButton, FilterChips, ShimmerEffect, EmptyState } from '../../components/ui';
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

async function fetchForums(userId: string): Promise<Forum[]> {
  const { data, error } = await supabase.rpc('get_user_conversations', {
    p_user_id: userId,
    p_type: null,
  });

  if (error) throw error;
  if (!data || data.length === 0) return [];

  const courseIds = (data as Array<{ course_id: string | null }>)
    .map((r) => r.course_id)
    .filter((id): id is string => Boolean(id));

  let courseTitles: Record<string, { title_ar: string; title_en?: string | null }> = {};
  if (courseIds.length > 0) {
    const { data: courses } = await supabase
      .from('courses')
      .select('id, title_ar, title_en')
      .in('id', courseIds);
    if (courses) {
      for (const c of courses) {
        courseTitles[c.id] = { title_ar: c.title_ar, title_en: c.title_en };
      }
    }
  }

  return (data as Array<{
    conversation_id: string;
    conversation_type: string;
    conversation_title: string | null;
    course_id: string | null;
    last_message_created_at: string | null;
    last_message_text: string | null;
    participants_count: number;
  }>).map((r) => ({
    id: r.conversation_id,
    title: r.conversation_title,
    type: r.conversation_type,
    updated_at: r.last_message_created_at || new Date().toISOString(),
    courses: r.course_id ? courseTitles[r.course_id] || null : null,
    last_message_preview: r.last_message_text || undefined,
    participant_count: r.participants_count,
  }));
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
  const { lang, user, loading: authLoading } = useApp();
  const router = useRouter();
  const [items, setItems] = useState<Forum[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [retryKey, setRetryKey] = useState(0);
  const [filter, setFilter] = useState<FilterType>('all');

  useEffect(() => {
    if (authLoading || !user) return;
    let cancelled = false;
    fetchForums(user.id)
      .then((data) => { if (!cancelled) setItems(data); })
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

  const groupCount = items.filter((f) => f.type === 'multi').length;
  const privateCount = items.filter((f) => f.type !== 'multi').length;

  return (
    <main ref={pageRef} className={styles.page}>

      {/* Hero Header */}
      <div className={styles.hero}>
        <div className={styles.heroText}>
          <h1>{lang === 'ar' ? 'المنتديات' : 'Forums'}</h1>
          <p>
            {lang === 'ar'
              ? 'تواصل مع زملائك ومدرسيك في مجتمعات الكورسات'
              : 'Connect with classmates and instructors in course communities'}
          </p>
        </div>
        <div className={styles.heroIcon}>
          <ForumIcon fontSize="large" />
        </div>
      </div>

      {/* Toolbar */}
      <div className={styles.toolbar}>
        <FilterChips
          items={filterOptions}
          selected={[filter]}
          onChange={(ids) => setFilter((ids[0] || 'all') as FilterType)}
        />
        {!loading && !error && (
          <div className={styles.statsRow}>
            <span className={styles.statBadge}>
              <Groups fontSize="inherit" />
              <span>{groupCount}</span>
              {lang === 'ar' ? ' مجموعة' : ' groups'}
            </span>
            <span className={styles.statBadge}>
              <Lock fontSize="inherit" />
              <span>{privateCount}</span>
              {lang === 'ar' ? ' خاص' : ' private'}
            </span>
          </div>
        )}
      </div>

      {/* Content */}
      {loading ? (
        <div className={styles.shimmerGrid}>
          {Array.from({ length: 6 }).map((_, i) => (
            <ShimmerEffect key={i} height={140} />
          ))}
        </div>
      ) : !user ? (
        <EmptyState
          type="forum"
          title={lang === 'ar' ? 'سجل الدخول أولاً' : 'Login Required'}
          message={lang === 'ar' ? 'يجب تسجيل الدخول للوصول إلى مجموعات النقاش والمنتديات.' : 'You need to login to access discussion groups.'}
          actionLabel={lang === 'ar' ? 'تسجيل الدخول' : 'Login'}
          onAction={() => router.push('/login?redirect=/forums')}
        />
      ) : error ? (
        <div className={styles.errorState}>
          <ForumIcon fontSize="large" />
          <strong>{lang === 'ar' ? 'تعذر التحميل' : 'Could not load'}</strong>
          <button
            className={styles.retryBtn}
            onClick={() => { setRetryKey((k) => k + 1); setLoading(true); setError(false); }}
          >
            <Refresh fontSize="small" />
            {lang === 'ar' ? 'إعادة المحاولة' : 'Retry'}
          </button>
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          type="forum"
          title={lang === 'ar' ? 'لا توجد مجموعات نقاش' : 'No forums found'}
          message={lang === 'ar' ? 'اشترك في كورس لتنضم تلقائياً إلى مجموعات النقاش الخاصة به.' : 'Enroll in a course to automatically join its discussion group.'}
          actionLabel={lang === 'ar' ? 'استكشف الكورسات' : 'Explore Courses'}
          onAction={() => router.push('/')}
        />
      ) : (
        <section className={styles.list}>
          {filtered.map((forum) => {
            const isGroup = forum.type === 'multi';
            const title =
              forum.title ||
              (lang === 'ar' ? forum.courses?.title_ar : forum.courses?.title_en) ||
              (lang === 'ar' ? 'مجموعة نقاش' : 'Discussion group');

            return (
              <Link href={`/forums/${forum.id}`} className={styles.card} key={forum.id}>
                {/* Top row */}
                <div className={styles.cardTop}>
                  <div className={`${styles.avatarIcon} ${isGroup ? styles.avatarGroup : styles.avatarPrivate}`}>
                    {isGroup ? <Groups /> : <Lock />}
                  </div>
                  <div className={styles.cardBody}>
                    <h3 className={styles.cardTitle}>{title}</h3>
                    <span className={`${styles.typeBadge} ${isGroup ? styles.typeGroup : styles.typePrivate}`}>
                      {isGroup ? (lang === 'ar' ? 'جماعي' : 'Group') : (lang === 'ar' ? 'خاص' : 'Private')}
                    </span>
                  </div>
                </div>

                {/* Preview message */}
                {forum.last_message_preview && (
                  <p className={styles.messagePreview}>
                    {forum.last_message_preview.slice(0, 80)}
                    {forum.last_message_preview.length > 80 ? '...' : ''}
                  </p>
                )}

                {/* Footer */}
                <div className={styles.cardFooter}>
                  <div className={styles.cardMeta}>
                    {forum.participant_count != null && (
                      <span className={styles.metaItem}>
                        <PeopleAlt sx={{ fontSize: 14 }} />
                        {forum.participant_count}
                      </span>
                    )}
                    <span className={styles.metaItem}>
                      {timeAgo(forum.updated_at, lang)}
                    </span>
                  </div>
                  <span className={styles.arrowIcon}>
                    {lang === 'ar' ? <ChevronLeft fontSize="small" /> : <ChevronRight fontSize="small" />}
                  </span>
                </div>
              </Link>
            );
          })}
        </section>
      )}
    </main>
  );
}

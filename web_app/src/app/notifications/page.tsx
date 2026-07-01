'use client';

import { useEffect, useState, useMemo, useCallback } from 'react';
import {
  Notifications, DoneAll, Campaign, School, Quiz as QuizIcon,
  WorkspacePremium, Forum, Message, Update, Stars, Redeem,
} from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { AppBackButton, FilterChips, ShimmerEffect, EmptyState } from '../../components/ui';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface Notice {
  id: string;
  title_ar: string;
  title_en?: string;
  body_ar: string;
  body_en?: string;
  type: string;
  is_read: boolean;
  created_at: string;
}

const TYPE_CONFIG: Record<string, { icon: React.ElementType; color: string }> = {
  instructorMessage: { icon: Message, color: '#2563EB' },
  courseUpdate: { icon: School, color: '#059669' },
  quizResult: { icon: QuizIcon, color: '#D97706' },
  certificateIssued: { icon: WorkspacePremium, color: '#7C3AED' },
  forumReply: { icon: Forum, color: '#0891B2' },
  announcement: { icon: Campaign, color: '#DC2626' },
  system: { icon: Update, color: '#6B7280' },
  promotion: { icon: Redeem, color: '#EC4899' },
  achievement: { icon: Stars, color: '#F59E0B' },
  default: { icon: Notifications, color: '#6B7280' },
};

function groupByDate(items: Notice[], lang: string): { label: string; items: Notice[] }[] {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today.getTime() - 86400000);
  const groups: Record<string, Notice[]> = {};
  const order: string[] = [];

  for (const item of items) {
    const d = new Date(item.created_at);
    const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    let key: string;
    if (dayStart.getTime() === today.getTime()) key = lang === 'ar' ? 'اليوم' : 'Today';
    else if (dayStart.getTime() === yesterday.getTime()) key = lang === 'ar' ? 'أمس' : 'Yesterday';
    else key = d.toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US', { month: 'short', day: 'numeric' });
    if (!groups[key]) { groups[key] = []; order.push(key); }
    groups[key].push(item);
  }

  return order.map((key) => ({ label: key, items: groups[key] }));
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

export default function NotificationsPage() {
  const pageRef = usePageTransition();
  const { lang, user } = useApp();
  const [items, setItems] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    supabase.from('notifications').select('*').eq('user_id', user.id).order('created_at', { ascending: false })
      .then(({ data }) => { setItems((data || []) as Notice[]); setLoading(false); });
  }, [user]);

  const markAll = useCallback(async () => {
    if (!user) return;
    await supabase.from('notifications').update({ is_read: true }).eq('user_id', user.id).eq('is_read', false);
    setItems((prev) => prev.map((n) => ({ ...n, is_read: true })));
  }, [user]);

  const markAsRead = useCallback(async (id: string) => {
    await supabase.from('notifications').update({ is_read: true }).eq('id', id);
    setItems((prev) => prev.map((n) => n.id === id ? { ...n, is_read: true } : n));
  }, []);

  const grouped = useMemo(() => groupByDate(items, lang), [items, lang]);
  const unreadCount = items.filter((n) => !n.is_read).length;

  if (loading) {
    return (
      <main className={styles.page}>
        <div className={styles.header}><h1>{lang === 'ar' ? 'الإشعارات' : 'Notifications'}</h1></div>
        <div className={styles.shimmerGrid}>{Array.from({ length: 5 }).map((_, i) => <ShimmerEffect key={i} height={72} />)}</div>
      </main>
    );
  }

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.header}>
        <h1>{lang === 'ar' ? 'الإشعارات' : 'Notifications'}</h1>
        {unreadCount > 0 && <span className={styles.unreadBadge}>{unreadCount}</span>}
      </div>

      {unreadCount > 0 && (
        <div className={styles.toolbar}>
          <button className={styles.markAllBtn} onClick={markAll} type="button">
            <DoneAll fontSize="small" />
            <span>{lang === 'ar' ? 'تحديد الكل كمقروء' : 'Mark all as read'}</span>
          </button>
        </div>
      )}

      {!user ? (
        <EmptyState
          type="notifications"
          title={lang === 'ar' ? 'يرجى تسجيل الدخول' : 'Please Login'}
          message={lang === 'ar' ? 'يجب تسجيل الدخول لعرض الإشعارات الخاصة بك.' : 'Please login to view your notifications.'}
        />
      ) : items.length === 0 ? (
        <EmptyState
          type="notifications"
          title={lang === 'ar' ? 'لا توجد إشعارات جديدة' : 'No new notifications'}
          message={lang === 'ar' ? 'سنقوم بتنبيهك بمجرد وجود تحديثات أو رسائل جديدة.' : "We'll let you know when there are updates or new messages."}
        />
      ) : (
        <div className={styles.groups}>
          {grouped.map((group) => (
            <div key={group.label} className={styles.group}>
              <div className={styles.groupLabel}>{group.label}</div>
              {group.items.map((n, i) => {
                const cfg = TYPE_CONFIG[n.type] || TYPE_CONFIG.default;
                const Icon = cfg.icon;
                return (
                  <article
                    key={n.id}
                    className={`${styles.card} ${!n.is_read ? styles.cardUnread : ''}`}
                    style={{ animationDelay: `${i * 50}ms` }}
                    onClick={() => { if (!n.is_read) markAsRead(n.id); }}
                  >
                    <div className={styles.iconWrap} style={{ background: `${cfg.color}18`, color: cfg.color }}>
                      <Icon fontSize="small" />
                    </div>
                    <div className={styles.cardBody}>
                      <h3>{lang === 'ar' ? n.title_ar : n.title_en || n.title_ar}</h3>
                      <p>{lang === 'ar' ? n.body_ar : n.body_en || n.body_ar}</p>
                    </div>
                    <div className={styles.cardMeta}>
                      <span className={styles.timeAgo}>{timeAgo(n.created_at, lang)}</span>
                      {!n.is_read && <span className={styles.dot} />}
                    </div>
                  </article>
                );
              })}
            </div>
          ))}
        </div>
      )}
    </main>
  );
}

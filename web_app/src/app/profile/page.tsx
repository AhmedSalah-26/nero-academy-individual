'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  School,
  Person,
  Edit,
  Notifications,
  PlayCircle,
  Receipt,
  Forum,
  Favorite,
  Settings,
  ChevronRight,
  Logout,
  Dashboard,
  EmojiEvents,
} from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { AppButton, ResponsiveDialog } from '../../components/ui';
import styles from './page.module.css';
import { usePageTransition } from '../../lib/animations';

export default function ProfilePage() {
  const pageRef = usePageTransition();
  const { lang, profile, user, signOut, enrolledCourseIds } = useApp();
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [enrollments, setEnrollments] = useState<any[]>([]);
  const [loadingStats, setLoadingStats] = useState(true);

  useEffect(() => {
    const userId = user?.id;
    if (!userId) {
      setLoadingStats(false);
      return;
    }
    async function fetchStats() {
      try {
        const { data } = await supabase
          .from('enrollments')
          .select('id, completed_lessons')
          .eq('user_id', userId)
          .in('status', ['active', 'completed']);
        if (data) {
          setEnrollments(data);
        }
      } catch (err) {
        console.error('Error fetching stats:', err);
      } finally {
        setLoadingStats(false);
      }
    }
    fetchStats();
  }, [user]);

  const isInstructor = profile?.role === 'instructor';
  const name = profile?.name || (lang === 'ar' ? 'الملف الشخصي' : 'Profile');
  const email = user?.email || (lang === 'ar' ? 'سجل الدخول لإدارة بياناتك' : 'Sign in to manage your data');

  const completedLessons = enrollments.reduce((sum, item) => sum + (item.completed_lessons || 0), 0);
  const level = Math.max(1, Math.ceil((completedLessons + enrollments.length) / 5));
  const points = completedLessons * 25 + enrollments.length * 100;
  const nextLevelTarget = Math.max((level + 1) * 250, 250);
  const levelProgress = Math.min(100, Math.round((points / nextLevelTarget) * 100));

  const levelLabel = level >= 10
    ? (lang === 'ar' ? 'المستوى الذهبي' : 'Gold Level')
    : level >= 5
    ? (lang === 'ar' ? 'المستوى الفضي' : 'Silver Level')
    : (lang === 'ar' ? 'المستوى البرونزي' : 'Bronze Level');

  const menuItems = [
    ...(isInstructor
      ? [{ id: 'dashboard', icon: Dashboard, ar: 'لوحة تحكم المدرس', en: 'Instructor Dashboard', href: '/instructor' }]
      : []),
    { id: 'edit', icon: Edit, ar: 'تعديل الملف الشخصي', en: 'Edit Profile', href: '/edit-profile' },
    { id: 'notifications', icon: Notifications, ar: 'الإشعارات', en: 'Notifications', href: '/notifications' },
    { id: 'learning', icon: PlayCircle, ar: 'تعليمي', en: 'My Learning', href: '/my-learning' },
    { id: 'orders', icon: Receipt, ar: 'حالة الطلبات', en: 'Orders Status', href: '/orders-status' },
    { id: 'forums', icon: Forum, ar: 'المنتديات', en: 'Forums', href: '/forums' },
    { id: 'wishlist', icon: Favorite, ar: 'المفضلة', en: 'Wishlist', href: '/wishlist' },
    { id: 'settings', icon: Settings, ar: 'الإعدادات', en: 'Settings', href: '/settings' },
  ];

  const getInitials = (nameStr?: string) => {
    if (!nameStr) return '?';
    const parts = nameStr.trim().split(/\s+/);
    if (parts.length === 1) return parts[0][0];
    return parts[0][0] + parts[parts.length - 1][0];
  };

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.profileCard}>
        {/* Avatar with online dot */}
        <div className={styles.avatarWrapper}>
          {profile?.avatar_url ? (
            <img src={profile.avatar_url} alt={name} />
          ) : (
            <span className={styles.avatarInitials}>{getInitials(profile?.name)}</span>
          )}
          <span className={styles.onlineDot} />
        </div>

        {/* Name and Email */}
        <h2 className={styles.userName}>{name}</h2>
        <span className={styles.userEmail}>{email}</span>

        {/* Divider line */}
        <div className={styles.cardDivider} />

        {/* Stats Row: Course count & Usage hours instead of Level & Points */}
        <div className={styles.statsRow}>
          <div className={styles.statCol}>
            <span className={styles.statValue}>{enrolledCourseIds.length}</span>
            <span className={styles.statLabel}>{lang === 'ar' ? 'عدد الدورات' : 'Courses'}</span>
          </div>
          <div className={styles.statColDivider} />
          <div className={styles.statCol}>
            <span className={styles.statValue}>
              {Math.round((completedLessons * 1.2 + 1) * 10) / 10}
            </span>
            <span className={styles.statLabel}>{lang === 'ar' ? 'ساعات الاستخدام' : 'Usage Hours'}</span>
          </div>
        </div>
      </div>

      <div className={styles.menuCard}>
        {menuItems.map(({ id, icon: Icon, ar, en, href }) => (
          <Link key={id} href={href} className={styles.menuLink}>
            <span className={styles.menuIcon}><Icon fontSize="small" /></span>
            <span className={styles.menuTitle}>{lang === 'ar' ? ar : en}</span>
            <ChevronRight className={styles.menuChevron} />
          </Link>
        ))}
      </div>

      {user && (
        <div className={styles.logoutSection}>
          <AppButton
            variant="outline"
            fullWidth
            onClick={() => setLogoutOpen(true)}
            startIcon={<Logout fontSize="small" />}
            style={{ borderColor: 'var(--error)', color: 'var(--error)' }}
          >
            {lang === 'ar' ? 'تسجيل الخروج' : 'Log Out'}
          </AppButton>
        </div>
      )}

      <span className={styles.version}>Version 2.4.0</span>

      <ResponsiveDialog
        open={logoutOpen}
        onClose={() => setLogoutOpen(false)}
        title={lang === 'ar' ? 'تسجيل الخروج' : 'Log Out'}
        destructive
        actions={
          <>
            <AppButton variant="text" onClick={() => setLogoutOpen(false)}>
              {lang === 'ar' ? 'إلغاء' : 'Cancel'}
            </AppButton>
            <AppButton
              variant="error"
              onClick={() => {
                setLogoutOpen(false);
                void signOut();
              }}
            >
              {lang === 'ar' ? 'تسجيل الخروج' : 'Log Out'}
            </AppButton>
          </>
        }
      >
        {lang === 'ar' ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to log out?'}
      </ResponsiveDialog>
    </main>
  );
}

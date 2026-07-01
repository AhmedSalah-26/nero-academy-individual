'use client';

import { useState } from 'react';
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
  Whatshot,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { UserAvatar, AppCard, AppButton, ResponsiveDialog } from '../../components/ui';
import styles from './page.module.css';
import { usePageTransition } from '../../lib/animations';

export default function ProfilePage() {
  const pageRef = usePageTransition();
  const { lang, profile, user, signOut, enrolledCourseIds } = useApp();
  const [logoutOpen, setLogoutOpen] = useState(false);

  const isInstructor = profile?.role === 'instructor';
  const coursesCount = enrolledCourseIds.length;
  const streak = 0;

  const name = profile?.name || (lang === 'ar' ? 'الملف الشخصي' : 'Profile');
  const email = user?.email || (lang === 'ar' ? 'سجل الدخول لإدارة بياناتك' : 'Sign in to manage your data');

  const menuItems = [
    ...(isInstructor
      ? [{ id: 'dashboard', icon: Dashboard, ar: 'لوحة تحكم المدرس', en: 'Instructor Dashboard', href: '/instructor' }]
      : []),
    { id: 'edit', icon: Edit, ar: 'تعديل الملف الشخصي', en: 'Edit Profile', href: '/edit-profile' },
    { id: 'notifications', icon: Notifications, ar: 'الإشعارات', en: 'Notifications', href: '/notifications' },
    { id: 'learning', icon: PlayCircle, ar: 'تعليمي', en: 'My Learning', href: '/my-learning' },
    { id: 'orders', icon: Receipt, ar: 'حالة الطلبات', en: 'Orders Status', href: '/orders' },
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
      <header className={styles.header}>
        <div className={styles.avatarWrapper}>
          {profile?.avatar_url ? (
            <img src={profile.avatar_url} alt={name} />
          ) : (
            <span className={styles.avatarInitials}>{getInitials(profile?.name)}</span>
          )}
        </div>
        <span className={styles.userName}>{name}</span>
        <span className={styles.userEmail}>{email}</span>
      </header>

      <div className={styles.statsCard}>
        <div className={styles.statItem}>
          <span className={styles.statValue}>{coursesCount}</span>
          <span className={styles.statLabel}>{lang === 'ar' ? 'الكورسات' : 'Courses'}</span>
        </div>
        <div className={styles.statDivider} />
        <div className={styles.statItem}>
          <span className={styles.statValue}>{streak}</span>
          <span className={styles.statLabel}>{lang === 'ar' ? 'أيام متتالية' : 'Day Streak'}</span>
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

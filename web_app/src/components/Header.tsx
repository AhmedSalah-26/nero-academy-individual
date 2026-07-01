'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Home,
  PlayCircle,
  Forum,
  Person,
  Notifications,
  ShoppingCart,
  Favorite,
  History,
  LightMode,
  DarkMode,
  Login,
  Logout,
} from '@mui/icons-material';
import { useApp } from '../context/AppContext';
import { BottomNavBar } from './ui';
import styles from './Header.module.css';

const MOBILE_NAV_ITEMS = [
  { id: 'home', label_ar: 'الرئيسية', label_en: 'Home', icon: Home, href: '/' },
  { id: 'learning', label_ar: 'تعليمي', label_en: 'My Learning', icon: PlayCircle, href: '/my-learning' },
  { id: 'forums', label_ar: 'المنتديات', label_en: 'Forums', icon: Forum, href: '/forums' },
  { id: 'profile', label_ar: 'حسابي', label_en: 'Profile', icon: Person, href: '/profile' },
];

export function Header() {
  const { lang, t, user, profile, cart, signOut, theme, toggleTheme } = useApp();
  const pathname = usePathname();

  const isActive = (path: string) => {
    if (path === '/') return pathname === path;
    if (path === '/courses') return pathname.startsWith('/courses') || pathname.startsWith('/search');
    if (path === '/forums') return pathname.startsWith('/forums') || pathname.startsWith('/community');
    return pathname.startsWith(path);
  };

  const desktopNavItems = user ? [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home' },
    { href: '/my-learning', label: lang === 'ar' ? 'تعليمي' : 'My Learning' },
    { href: '/forums', label: lang === 'ar' ? 'المنتديات' : 'Forums' },
    { href: '/courses', label: lang === 'ar' ? 'الكورسات' : 'Courses' },
  ] : [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home' },
    { href: '/#courses', label: lang === 'ar' ? 'الكورسات' : 'Courses' },
    { href: '/#method', label: lang === 'ar' ? 'طريقة التعلم' : 'How it works' },
    { href: '/#reviews', label: lang === 'ar' ? 'آراء الطلاب' : 'Reviews' },
  ];

  const mobileActiveId = MOBILE_NAV_ITEMS.find(item => isActive(item.href))?.id || 'home';

  return (
    <>
      <header className={styles.header}>
        <div className={styles.container}>
          <Link href="/" className={styles.logo} aria-label={t.appName}>
            <span className={styles.logoIcon}><Home fontSize="small" /></span>
            <span className={styles.logoText}>
              <b>{lang === 'ar' ? 'شهاب Tech' : 'Shahab Tech'}</b>
              <small>{lang === 'ar' ? 'منصة التعليم' : 'Learning Platform'}</small>
            </span>
          </Link>

          <nav className={styles.nav} aria-label={lang === 'ar' ? 'التنقل الرئيسي' : 'Main navigation'}>
            {desktopNavItems.map((item) => (
              <Link key={item.href} href={item.href} className={`${styles.navLink} ${isActive(item.href) ? styles.active : ''}`}>
                {item.label}
              </Link>
            ))}
          </nav>

          <div className={styles.actions}>
            {user && (
              <>
                <Link href="/notifications" className={styles.squareButton} aria-label={t.notifications}>
                  <Notifications fontSize="small" />
                </Link>
                <Link href="/wishlist" className={styles.squareButton} aria-label={lang === 'ar' ? 'المفضلة' : 'Wishlist'}>
                  <Favorite fontSize="small" />
                </Link>
                <Link href="/history" className={styles.squareButton} aria-label={lang === 'ar' ? 'السجل' : 'History'}>
                  <History fontSize="small" />
                </Link>
              </>
            )}
            <Link href="/cart" className={styles.squareButton} aria-label={t.cart}>
              <ShoppingCart fontSize="small" />
              {cart.length > 0 && <span className={styles.cartBadge}>{cart.length}</span>}
            </Link>
            <button onClick={toggleTheme} className={styles.squareButton} title={theme === 'light' ? 'Dark Mode' : 'Light Mode'}>
              {theme === 'light' ? <DarkMode fontSize="small" /> : <LightMode fontSize="small" />}
            </button>
            {user ? (
              <div className={styles.userCard}>
                <Link href="/profile" className={styles.userProfile}>
                  <span className={styles.avatar}>
                    {profile?.avatar_url ? <img src={profile.avatar_url} alt={profile.name || ''} /> : <Person fontSize="small" />}
                  </span>
                  <span className={styles.userName}>{profile?.name || user.email}</span>
                </Link>
                <button onClick={signOut} className={styles.logout} title={t.logout}><Logout fontSize="small" /></button>
              </div>
            ) : (
              <Link href="/login" className={styles.loginButton}><Login fontSize="small" />{t.login}</Link>
            )}
          </div>
        </div>
      </header>

      <BottomNavBar
        items={MOBILE_NAV_ITEMS.map(item => ({
          id: item.id,
          label: lang === 'ar' ? item.label_ar : item.label_en,
          icon: <item.icon fontSize="small" />,
          href: item.href,
        }))}
        activeId={mobileActiveId}
      />
    </>
  );
}

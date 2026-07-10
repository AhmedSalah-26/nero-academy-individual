'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Person,
  Notifications,
  ShoppingCart,
  Favorite,
  History,
  Receipt,
  LightMode,
  DarkMode,
  Login,
  Logout,
  Search,
  Settings,
} from '@mui/icons-material';
import { useApp } from '../context/AppContext';
import styles from './Header.module.css';

import { useState, useEffect, useRef } from 'react';

export function Header() {
  const { lang, t, user, profile, cart, signOut, theme, toggleTheme } = useApp();
  const pathname = usePathname();
  const [isVisible, setIsVisible] = useState(true);
  const [isFloating, setIsFloating] = useState(false);
  const lastScrollY = useRef(0);
  const scrollAccumulator = useRef(0);

  useEffect(() => {
    // Set initial scroll position on mount
    lastScrollY.current = window.scrollY;
    setIsFloating(window.scrollY > 10);

    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      const diff = currentScrollY - lastScrollY.current;

      // Update floating state
      setIsFloating(currentScrollY > 10);

      // Always show header near the top of the page
      if (currentScrollY <= 60) {
        setIsVisible(true);
        scrollAccumulator.current = 0;
        lastScrollY.current = currentScrollY;
        return;
      }

      // Determine consecutive scroll direction accumulator
      const wasScrollingUp = scrollAccumulator.current < 0;
      const isScrollingUpNow = diff < 0;

      if (wasScrollingUp !== isScrollingUpNow) {
        scrollAccumulator.current = 0; // Reset accumulator on direction change
      }

      scrollAccumulator.current += diff;

      // Apply threshold: ignore consecutive scroll changes smaller than 10px
      if (scrollAccumulator.current < -10) {
        setIsVisible(true);
        scrollAccumulator.current = 0; // Reset after toggle
      } else if (scrollAccumulator.current > 10 && currentScrollY > 120) {
        setIsVisible(false);
        scrollAccumulator.current = 0; // Reset after toggle
      }

      lastScrollY.current = currentScrollY;
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

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

  return (
    <header className={`${styles.header} ${isVisible ? '' : styles.hidden} ${isFloating ? styles.floating : ''}`}>
        <div className={styles.container}>
          <div className={styles.logoWrapper}>
            <Link href="/" className={styles.logo} aria-label={t.appName}>
              <span className={styles.logoIcon} aria-hidden="true">
                <span className={styles.logoNumber}>92</span>
                <span className={styles.logoSymbol}>U</span>
                <span className={styles.logoMass}>238.03</span>
              </span>
              <span className={styles.logoText}>
                <b>Dr UneXpected</b>
                <small>{lang === 'ar' ? 'منصة الكيمياء' : 'Chemistry Platform'}</small>
              </span>
            </Link>

            <Link href="/search" className={styles.headerSearch} aria-label={lang === 'ar' ? 'بحث' : 'Search'}>
              <Search className={styles.headerSearchIcon} />
              <span className={styles.headerSearchText}>
                {lang === 'ar' ? 'ابحث عن درس...' : 'Search...'}
              </span>
            </Link>
          </div>

          <nav className={styles.nav} aria-label={lang === 'ar' ? 'التنقل الرئيسي' : 'Main navigation'}>
            {desktopNavItems.map((item) => (
              <Link key={item.href} href={item.href} className={`${styles.navLink} ${isActive(item.href) ? styles.active : ''}`}>
                {item.label}
              </Link>
            ))}
          </nav>

          <div className={styles.actions}>
            {user && (
              <div className={styles.extraActions}>
                <Link href="/notifications" className={styles.squareButton} aria-label={t.notifications}>
                  <Notifications fontSize="small" />
                </Link>
                <Link href="/wishlist" className={styles.squareButton} aria-label={lang === 'ar' ? 'المفضلة' : 'Wishlist'}>
                  <Favorite fontSize="small" />
                </Link>
                <Link href="/history" className={styles.squareButton} aria-label={lang === 'ar' ? 'السجل' : 'History'}>
                  <History fontSize="small" />
                </Link>
                <Link href="/orders-status" className={styles.squareButton} aria-label={lang === 'ar' ? 'الطلبات' : 'Orders'}>
                  <Receipt fontSize="small" />
                </Link>
              </div>
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
                <div className={styles.userProfile}>
                  <span className={styles.avatar}>
                    {profile?.avatar_url ? <img src={profile.avatar_url} alt={profile.name || ''} /> : <Person fontSize="small" />}
                  </span>
                  <span className={styles.userName}>{profile?.name || user.email}</span>
                </div>
                <Link href="/profile" className={styles.settings} title={lang === 'ar' ? 'الملف الشخصي' : 'Profile'}>
                  <Settings fontSize="small" />
                </Link>
                <button onClick={signOut} className={styles.logout} title={t.logout}><Logout fontSize="small" /></button>
              </div>
            ) : (
              <Link href="/login" className={styles.loginButton}><Login fontSize="small" />{t.login}</Link>
            )}
          </div>
        </div>
    </header>
  );
}


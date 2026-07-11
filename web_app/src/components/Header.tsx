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
  Language as LanguageIcon,
} from '@mui/icons-material';
import { useState, useEffect, useRef } from 'react';
import { useApp } from '../context/AppContext';
import styles from './Header.module.css';

const SCROLL_THRESHOLD = 10;
const FLOATING_OFFSET = 10;
const TOP_REVEAL_OFFSET = 60;
const HIDE_AFTER_OFFSET = 120;
const SCROLL_IDLE_DELAY = 180;

type HeaderScrollState = {
  isVisible: boolean;
  isFloating: boolean;
  isScrolling: boolean;
};

export function Header() {
  const { lang, t, user, profile, cart, signOut, theme, toggleTheme, toggleLang } = useApp();
  const pathname = usePathname();
  const [scrollState, setScrollState] = useState<HeaderScrollState>({
    isVisible: true,
    isFloating: false,
    isScrolling: false,
  });
  const scrollStateRef = useRef(scrollState);
  const lastScrollY = useRef(0);
  const scrollAccumulator = useRef(0);
  const animationFrame = useRef<number | null>(null);
  const scrollIdleTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const touchStartY = useRef<number | null>(null);

  useEffect(() => {
    const updateScrollState = (nextState: Partial<HeaderScrollState>) => {
      const currentState = scrollStateRef.current;
      const mergedState = { ...currentState, ...nextState };

      if (
        mergedState.isVisible === currentState.isVisible &&
        mergedState.isFloating === currentState.isFloating &&
        mergedState.isScrolling === currentState.isScrolling
      ) {
        return;
      }

      scrollStateRef.current = mergedState;
      setScrollState(mergedState);
    };

    const markScrolling = () => {
      updateScrollState({ isScrolling: true });

      if (scrollIdleTimer.current) {
        clearTimeout(scrollIdleTimer.current);
      }

      scrollIdleTimer.current = setTimeout(() => {
        updateScrollState({ isScrolling: false });
      }, SCROLL_IDLE_DELAY);
    };

    const getScrollY = () =>
      Math.max(
        window.scrollY,
        document.documentElement.scrollTop,
        document.body.scrollTop,
        0
      );

    const processScrollDelta = (
      diff: number,
      currentScrollY: number,
      nextState: Partial<HeaderScrollState>
    ) => {
      if (currentScrollY <= TOP_REVEAL_OFFSET) {
        nextState.isVisible = true;
        scrollAccumulator.current = 0;
        return;
      }

      if (Math.abs(diff) < 1) {
        return;
      }

      const changedDirection =
        scrollAccumulator.current !== 0 &&
        Math.sign(scrollAccumulator.current) !== Math.sign(diff);

      if (changedDirection) {
        scrollAccumulator.current = 0;
      }

      scrollAccumulator.current += diff;

      if (scrollAccumulator.current <= -SCROLL_THRESHOLD) {
        nextState.isVisible = true;
        scrollAccumulator.current = 0;
      } else if (
        scrollAccumulator.current >= SCROLL_THRESHOLD &&
        currentScrollY > HIDE_AFTER_OFFSET
      ) {
        nextState.isVisible = false;
        scrollAccumulator.current = 0;
      }
    };

    lastScrollY.current = getScrollY();
    updateScrollState({
      isVisible: true,
      isFloating: lastScrollY.current > FLOATING_OFFSET,
      isScrolling: false,
    });

    const handleScroll = () => {
      markScrolling();

      if (animationFrame.current !== null) {
        return;
      }

      animationFrame.current = window.requestAnimationFrame(() => {
        animationFrame.current = null;

        const currentScrollY = getScrollY();
        const diff = currentScrollY - lastScrollY.current;
        const nextState: Partial<HeaderScrollState> = {
          isFloating: currentScrollY > FLOATING_OFFSET,
        };

        processScrollDelta(diff, currentScrollY, nextState);

        updateScrollState(nextState);
        lastScrollY.current = currentScrollY;
      });
    };

    const handleDirectionalInput = (diff: number) => {
      markScrolling();

      const currentScrollY = getScrollY();
      const nextState: Partial<HeaderScrollState> = {
        isFloating: currentScrollY > FLOATING_OFFSET,
      };

      processScrollDelta(diff, currentScrollY, nextState);
      updateScrollState(nextState);
    };

    const handleWheel = (event: WheelEvent) => {
      handleDirectionalInput(event.deltaY);
    };

    const handleTouchStart = (event: TouchEvent) => {
      touchStartY.current = event.touches[0]?.clientY ?? null;
    };

    const handleTouchMove = (event: TouchEvent) => {
      const currentTouchY = event.touches[0]?.clientY;
      if (touchStartY.current === null || currentTouchY === undefined) {
        return;
      }

      handleDirectionalInput(touchStartY.current - currentTouchY);
      touchStartY.current = currentTouchY;
    };

    const handleResize = () => {
      if (getScrollY() <= TOP_REVEAL_OFFSET) {
        updateScrollState({ isVisible: true });
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    window.addEventListener('wheel', handleWheel, { passive: true });
    window.addEventListener('touchstart', handleTouchStart, { passive: true });
    window.addEventListener('touchmove', handleTouchMove, { passive: true });
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('scroll', handleScroll);
      window.removeEventListener('wheel', handleWheel);
      window.removeEventListener('touchstart', handleTouchStart);
      window.removeEventListener('touchmove', handleTouchMove);
      window.removeEventListener('resize', handleResize);

      if (animationFrame.current !== null) {
        window.cancelAnimationFrame(animationFrame.current);
      }

      if (scrollIdleTimer.current) {
        clearTimeout(scrollIdleTimer.current);
      }
    };
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
    <>
      <header
        className={`${styles.header} ${scrollState.isVisible ? '' : styles.hidden} ${
          scrollState.isFloating || scrollState.isScrolling ? styles.floating : ''
        }`}
      >
        <div className={styles.container}>
          <div className={styles.logoWrapper}>
            <Link href="/" className={styles.logo} aria-label={t.appName}>
              <span className={styles.logoIcon}>
                <img src="/logo2.png" alt="Logo" className={styles.logoImg} />
              </span>
              <span className={styles.logoText}>
                <b>{lang === 'ar' ? 'شهاب Tech' : 'Shahab Tech'}</b>
                <small>{lang === 'ar' ? 'منصة التعليم' : 'Learning Platform'}</small>
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
                <Link href="/orders-status" className={styles.squareButton} aria-label={lang === 'ar' ? 'الطلبات' : 'Orders'}>
                  <Receipt fontSize="small" />
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
            <button onClick={toggleLang} className={styles.squareButton} title={lang === 'ar' ? 'English' : 'العربية'} aria-label="Change language">
              <LanguageIcon fontSize="small" />
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
      <div className={styles.headerSpacer} aria-hidden="true" />
    </>
  );
}

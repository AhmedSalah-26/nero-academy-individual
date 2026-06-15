'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  BookOpen,
  ChevronDown,
  ClipboardCheck,
  FlaskConical,
  Globe,
  Home,
  LogIn,
  LogOut,
  Moon,
  ShoppingCart,
  Sun,
  User,
  Users,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import styles from './Header.module.css';

export function Header() {
  const { lang, t, user, profile, cart, toggleLang, signOut, theme, toggleTheme } = useApp();
  const pathname = usePathname();
  const isActive = (path: string) => path === '/' ? pathname === path : pathname.startsWith(path);

  const mobileNavItems = user ? [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home', icon: Home },
    { href: '/courses', label: lang === 'ar' ? 'الكورسات' : 'Courses', icon: BookOpen },
    { href: '/my-learning', label: lang === 'ar' ? 'تعلمي' : 'Learning', icon: ClipboardCheck },
    { href: '/community', label: lang === 'ar' ? 'المجتمع' : 'Community', icon: Users },
    { href: '/profile', label: lang === 'ar' ? 'حسابي' : 'Profile', icon: User },
  ] : [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home', icon: Home },
    { href: '/courses', label: lang === 'ar' ? 'الكورسات' : 'Courses', icon: BookOpen },
    { href: '/login', label: lang === 'ar' ? 'دخول' : 'Login', icon: User },
  ];

  const desktopNavItems = user ? [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home' },
    { href: '/courses', label: lang === 'ar' ? 'الكورسات' : 'Courses' },
    { href: '/my-learning', label: lang === 'ar' ? 'كورساتي' : 'My learning' },
    { href: '/community', label: lang === 'ar' ? 'المجتمع' : 'Community' },
    { href: '/exams', label: lang === 'ar' ? 'الامتحانات' : 'Exams' },
  ] : [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home' },
    { href: '/#courses', label: lang === 'ar' ? 'الكورسات' : 'Courses' },
    { href: '/#method', label: lang === 'ar' ? 'طريقة التعلم' : 'How it works' },
    { href: '/#reviews', label: lang === 'ar' ? 'آراء الطلاب' : 'Reviews' },
  ];

  return (
    <>
      <header className={styles.header}>
        <div className={styles.container}>
          <Link href="/" className={styles.logo} aria-label={t.appName}>
            <span className={styles.logoIcon}><FlaskConical size={22} strokeWidth={2.3} /></span>
            <span className={styles.logoText}>
              <b>{lang === 'ar' ? 'أحمد الشيخ' : 'Ahmed El-Sheikh'}</b>
              <small>{lang === 'ar' ? 'منصة الكيمياء' : 'Chemistry platform'}</small>
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
            <button onClick={toggleLang} className={styles.actionButton} title="Language">
              <Globe size={15} /><span>{lang === 'ar' ? 'EN' : 'عربي'}</span>
            </button>
            <button onClick={toggleTheme} className={styles.squareButton} title={theme === 'light' ? 'Dark Mode' : 'Light Mode'}>
              {theme === 'light' ? <Moon size={17} /> : <Sun size={17} />}
            </button>
            <Link href="/cart" className={styles.squareButton} aria-label={t.cart}>
              <ShoppingCart size={18} />
              {cart.length > 0 && <span className={styles.cartBadge}>{cart.length}</span>}
            </Link>
            {user ? (
              <div className={styles.userCard}>
                <Link href="/profile" className={styles.userProfile}>
                  <span className={styles.avatar}>
                    {profile?.avatar_url ? <img src={profile.avatar_url} alt={profile.name || ''} /> : <User size={16} />}
                  </span>
                  <span className={styles.userName}>{profile?.name || user.email}</span>
                </Link>
                <button onClick={signOut} className={styles.logout} title={t.logout}><LogOut size={16} /></button>
              </div>
            ) : (
              <Link href="/login" className={styles.loginButton}><LogIn size={15} />{t.login}<ChevronDown size={13} /></Link>
            )}
          </div>
        </div>
      </header>

      <nav className={`${styles.mobileNav} ${user ? styles.mobileNavLoggedIn : styles.mobileNavGuest}`} aria-label={lang === 'ar' ? 'التنقل للموبايل' : 'Mobile navigation'}>
        {mobileNavItems.map((item) => {
          const Icon = item.icon;
          return (
            <Link key={item.href} href={item.href} className={`${styles.mobileNavItem} ${isActive(item.href) ? styles.mobileActive : ''}`}>
              <Icon size={19} /><span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
    </>
  );
}

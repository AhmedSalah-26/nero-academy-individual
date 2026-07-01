'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Home,
  School,
  Forum,
  Person,
  MenuBook,
  ShoppingCart,
  Login
} from '@mui/icons-material';
import { useApp } from '../context/AppContext';
import styles from './BottomNavbar.module.css';

export function BottomNavbar() {
  const { lang, user, cart } = useApp();
  const pathname = usePathname();

  const isActive = (path: string) => {
    if (path === '/') return pathname === path;
    if (path === '/courses') return pathname.startsWith('/courses') || pathname.startsWith('/search');
    if (path === '/forums') return pathname.startsWith('/forums') || pathname.startsWith('/community');
    return pathname.startsWith(path);
  };

  const navItems = user ? [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home', icon: <Home /> },
    { href: '/courses', label: lang === 'ar' ? 'الكورسات' : 'Courses', icon: <MenuBook /> },
    { href: '/my-learning', label: lang === 'ar' ? 'تعليمي' : 'My Learning', icon: <School /> },
    { href: '/forums', label: lang === 'ar' ? 'المنتديات' : 'Forums', icon: <Forum /> },
    { href: '/profile', label: lang === 'ar' ? 'حسابي' : 'Profile', icon: <Person /> },
  ] : [
    { href: '/', label: lang === 'ar' ? 'الرئيسية' : 'Home', icon: <Home /> },
    { href: '/courses', label: lang === 'ar' ? 'الكورسات' : 'Courses', icon: <MenuBook /> },
    { href: '/cart', label: lang === 'ar' ? 'السلة' : 'Cart', icon: (
      <div className={styles.cartIconWrapper}>
        <ShoppingCart />
        {cart.length > 0 && <span className={styles.cartBadge}>{cart.length}</span>}
      </div>
    ) },
    { href: '/login', label: lang === 'ar' ? 'دخول' : 'Login', icon: <Login /> },
  ];

  return (
    <nav className={styles.bottomNav} aria-label={lang === 'ar' ? 'التنقل السفلي' : 'Bottom navigation'}>
      {navItems.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          className={`${styles.navLink} ${isActive(item.href) ? styles.active : ''}`}
        >
          <span className={styles.icon}>{item.icon}</span>
          <span className={styles.label}>{item.label}</span>
        </Link>
      ))}
    </nav>
  );
}

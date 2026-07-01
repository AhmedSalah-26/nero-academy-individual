'use client';

import Link from 'next/link';
import styles from './BottomNavBar.module.css';

interface BottomNavItem {
  id: string;
  label: string;
  icon: React.ReactNode;
  href: string;
}

interface BottomNavBarProps {
  items: BottomNavItem[];
  activeId: string;
  className?: string;
}

export default function BottomNavBar({ items, activeId, className }: BottomNavBarProps) {
  return (
    <nav className={`${styles.navBar} ${className || ''}`}>
      {items.slice(0, 4).map((item) => (
        <Link
          key={item.id}
          href={item.href}
          className={`${styles.tab} ${activeId === item.id ? styles.active : ''}`}
        >
          <span className={styles.tabIcon}>{item.icon}</span>
          <span className={styles.tabLabel}>{item.label}</span>
        </Link>
      ))}
    </nav>
  );
}

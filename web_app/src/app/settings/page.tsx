'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Bell,
  ChevronLeft,
  CircleHelp,
  FileText,
  Globe,
  LogOut,
  Moon,
  PlayCircle,
  Shield,
  Sun,
  User,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import styles from './page.module.css';

function SettingSwitch({ checked, onChange, label }: { checked: boolean; onChange: () => void; label: string }) {
  return <button type="button" role="switch" aria-checked={checked} aria-label={label} onClick={onChange} className={`${styles.switch} ${checked ? styles.switchOn : ''}`}><i /></button>;
}

export default function SettingsPage() {
  const { lang, theme, toggleLang, toggleTheme, profile, user, signOut } = useApp();
  const [notifications, setNotifications] = useState(() => typeof window === 'undefined' || localStorage.getItem('nero_notifications') !== 'false');
  const [autoplay, setAutoplay] = useState(() => typeof window !== 'undefined' && localStorage.getItem('nero_video_autoplay') === 'true');

  const togglePreference = (key: string, value: boolean, setter: (value: boolean) => void) => {
    const next = !value;
    setter(next);
    localStorage.setItem(key, String(next));
  };

  const supportLinks = [
    { href: '/qa', icon: CircleHelp, ar: 'مركز المساعدة', en: 'Help center', detailAr: 'الأسئلة الشائعة والتواصل مع الدعم', detailEn: 'FAQs and support' },
    { href: '/privacy', icon: Shield, ar: 'سياسة الخصوصية', en: 'Privacy policy', detailAr: 'كيف نحمي بياناتك', detailEn: 'How we protect your data' },
    { href: '/terms', icon: FileText, ar: 'شروط الاستخدام', en: 'Terms of service', detailAr: 'قواعد وشروط استخدام المنصة', detailEn: 'Platform terms and rules' },
  ];

  return (
    <main className={styles.page}>
      <header className={styles.header}>
        <div>
          <span>{lang === 'ar' ? 'الحساب والتفضيلات' : 'Account & preferences'}</span>
          <h1>{lang === 'ar' ? 'الإعدادات' : 'Settings'}</h1>
        </div>
      </header>

      <section className={styles.profileCard}>
        <div className={styles.avatar}>{profile?.avatar_url ? <img src={profile.avatar_url} alt="" /> : <User size={26} />}</div>
        <div><strong>{profile?.name || (lang === 'ar' ? 'الملف الشخصي' : 'Profile')}</strong><small>{user?.email || (lang === 'ar' ? 'سجل الدخول لإدارة بياناتك' : 'Sign in to manage your data')}</small></div>
        <Link href="/profile"><ChevronLeft size={18} /></Link>
      </section>

      <section className={styles.section}>
        <h2>{lang === 'ar' ? 'التفضيلات' : 'Preferences'}</h2>
        <div className={styles.group}>
          <button className={styles.row} onClick={toggleLang}>
            <span className={styles.icon}><Globe size={19} /></span>
            <span className={styles.label}><strong>{lang === 'ar' ? 'اللغة' : 'Language'}</strong><small>{lang === 'ar' ? 'العربية' : 'English'}</small></span>
            <span className={styles.value}>{lang === 'ar' ? 'EN' : 'عربي'}</span>
          </button>
          <div className={styles.row}>
            <span className={styles.icon}>{theme === 'light' ? <Sun size={19} /> : <Moon size={19} />}</span>
            <span className={styles.label}><strong>{lang === 'ar' ? 'الوضع الداكن' : 'Dark mode'}</strong><small>{theme === 'dark' ? (lang === 'ar' ? 'مفعّل' : 'Enabled') : (lang === 'ar' ? 'غير مفعّل' : 'Disabled')}</small></span>
            <SettingSwitch checked={theme === 'dark'} onChange={toggleTheme} label="Dark mode" />
          </div>
          <div className={styles.row}>
            <span className={styles.icon}><Bell size={19} /></span>
            <span className={styles.label}><strong>{lang === 'ar' ? 'الإشعارات' : 'Notifications'}</strong><small>{lang === 'ar' ? 'تنبيهات الدروس والردود' : 'Lessons and replies alerts'}</small></span>
            <SettingSwitch checked={notifications} onChange={() => togglePreference('nero_notifications', notifications, setNotifications)} label="Notifications" />
          </div>
          <div className={styles.row}>
            <span className={styles.icon}><PlayCircle size={19} /></span>
            <span className={styles.label}><strong>{lang === 'ar' ? 'تشغيل الفيديو تلقائيًا' : 'Video autoplay'}</strong><small>{lang === 'ar' ? 'تشغيل الدرس عند فتحه' : 'Play lessons when opened'}</small></span>
            <SettingSwitch checked={autoplay} onChange={() => togglePreference('nero_video_autoplay', autoplay, setAutoplay)} label="Video autoplay" />
          </div>
        </div>
      </section>

      <section className={styles.section}>
        <h2>{lang === 'ar' ? 'الدعم والقانونية' : 'Support & legal'}</h2>
        <div className={styles.group}>
          {supportLinks.map(({ href, icon: Icon, ar, en, detailAr, detailEn }) => <Link href={href} className={styles.row} key={href}><span className={styles.icon}><Icon size={19} /></span><span className={styles.label}><strong>{lang === 'ar' ? ar : en}</strong><small>{lang === 'ar' ? detailAr : detailEn}</small></span><ChevronLeft size={17} /></Link>)}
        </div>
      </section>

      {user && <button className={styles.logout} onClick={() => void signOut()}><LogOut size={18} />{lang === 'ar' ? 'تسجيل الخروج' : 'Log out'}</button>}
      <small className={styles.version}>Version 2.4.0</small>
    </main>
  );
}

'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Language,
  ChevronRight,
  ExpandMore,
  Check,
  Help as HelpIcon,
  Description,
  Shield,
  DarkMode,
  LightMode,
  Notifications,
  Logout,
  WhatsApp,
  Person,
  DeleteForever,
  PlayCircle,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { AppCard, AppButton, ResponsiveDialog, SectionHeader, AppBackButton } from '../../components/ui';
import styles from './page.module.css';
import { usePageTransition } from '../../lib/animations';

function SettingSwitch({ checked, onChange, label }: { checked: boolean; onChange: () => void; label: string }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={onChange}
      className={`${styles.switch} ${checked ? styles.switchOn : ''}`}
    >
      <i />
    </button>
  );
}

export default function SettingsPage() {
  const pageRef = usePageTransition();
  const { lang, theme, toggleLang, toggleTheme, profile, user, signOut } = useApp();
  const [notifications, setNotifications] = useState(() => typeof window === 'undefined' || localStorage.getItem('nero_notifications') !== 'false');
  const [autoplay, setAutoplay] = useState(() => typeof window !== 'undefined' && localStorage.getItem('nero_video_autoplay') === 'true');
  const [langExpanded, setLangExpanded] = useState(false);
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const l = lang === 'ar';

  const togglePreference = (key: string, value: boolean, setter: (v: boolean) => void) => {
    const next = !value;
    setter(next);
    localStorage.setItem(key, String(next));
  };

  const supportLinks = [
    { href: '/privacy', icon: Shield, ar: 'سياسة الخصوصية', en: 'Privacy Policy', detailAr: 'كيف نحمي بياناتك', detailEn: 'How we protect your data' },
    { href: '/terms', icon: Description, ar: 'شروط الاستخدام', en: 'Terms of Service', detailAr: 'قواعد وشروط استخدام المنصة', detailEn: 'Platform terms and rules' },
  ];

  const handleDeleteAccount = async () => {
    if (!user) return;
    try {
      await signOut();
    } catch (err) {
      console.error('Delete account error:', err);
    }
    setDeleteOpen(false);
  };

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.header}>
        <AppBackButton />
        <h1 className={styles.headerTitle}>{l ? 'الإعدادات' : 'Settings'}</h1>
      </div>

      <section className={styles.section}>
        <SectionHeader title={l ? 'التفضيلات' : 'Preferences'} />
        <div className={styles.card}>
          <div className={styles.expansionTile}>
            <button
              className={styles.expansionHeader}
              onClick={() => setLangExpanded(!langExpanded)}
              type="button"
            >
              <span className={styles.icon}><Language fontSize="small" /></span>
              <span className={styles.label}>
                <strong>{l ? 'اللغة' : 'Language'}</strong>
                <small>{lang === 'ar' ? 'العربية' : 'English'}</small>
              </span>
              <ExpandMore
                className={`${styles.expansionExpand} ${langExpanded ? styles.expansionExpandExpanded : ''}`}
              />
            </button>
            <div className={`${styles.expansionBody} ${langExpanded ? styles.expansionBodyOpen : ''}`}>
              <button
                className={`${styles.langOption} ${lang === 'ar' ? styles.langOptionActive : ''}`}
                onClick={() => { if (lang !== 'ar') toggleLang(); setLangExpanded(false); }}
                type="button"
              >
                العربية
                {lang === 'ar' && <Check className={styles.langOptionCheck} />}
              </button>
              <button
                className={`${styles.langOption} ${lang === 'en' ? styles.langOptionActive : ''}`}
                onClick={() => { if (lang !== 'en') toggleLang(); setLangExpanded(false); }}
                type="button"
              >
                English
                {lang === 'en' && <Check className={styles.langOptionCheck} />}
              </button>
            </div>
          </div>

          <div className={styles.row}>
            <span className={styles.icon}>
              {theme === 'light' ? <LightMode fontSize="small" /> : <DarkMode fontSize="small" />}
            </span>
            <span className={styles.label}>
              <strong>{l ? 'الوضع الداكن' : 'Dark Mode'}</strong>
              <small>{theme === 'dark' ? (l ? 'مفعّل' : 'Enabled') : (l ? 'غير مفعّل' : 'Disabled')}</small>
            </span>
            <SettingSwitch checked={theme === 'dark'} onChange={toggleTheme} label="Dark mode" />
          </div>

          <div className={styles.row}>
            <span className={styles.icon}><Notifications fontSize="small" /></span>
            <span className={styles.label}>
              <strong>{l ? 'الإشعارات' : 'Notifications'}</strong>
              <small>{l ? 'تنبيهات الدروس والردود' : 'Lessons and replies alerts'}</small>
            </span>
            <SettingSwitch
              checked={notifications}
              onChange={() => togglePreference('nero_notifications', notifications, setNotifications)}
              label="Notifications"
            />
          </div>

          <div className={styles.row}>
            <span className={styles.icon}><PlayCircle fontSize="small" /></span>
            <span className={styles.label}>
              <strong>{l ? 'تشغيل الفيديو تلقائيًا' : 'Video Autoplay'}</strong>
              <small>{l ? 'تشغيل الدرس عند فتحه' : 'Play lessons when opened'}</small>
            </span>
            <SettingSwitch
              checked={autoplay}
              onChange={() => togglePreference('nero_video_autoplay', autoplay, setAutoplay)}
              label="Video autoplay"
            />
          </div>
        </div>
      </section>

      <section className={styles.section}>
        <SectionHeader title={l ? 'الدعم والقانونية' : 'Support & Legal'} />

        <a
          href="https://wa.me/201012345678"
          target="_blank"
          rel="noopener noreferrer"
          className={styles.whatsappCard}
        >
          <WhatsApp className={styles.whatsappIcon} />
          <div className={styles.whatsappInfo}>
            <span className={styles.whatsappTitle}>{l ? 'مركز المساعدة' : 'Help Center'}</span>
            <span className={styles.whatsappDetail}>{l ? 'تواصل عبر واتساب' : 'Contact via WhatsApp'}: +20 101 234 5678</span>
          </div>
        </a>

        <div className={styles.card} style={{ marginTop: 12 }}>
          {supportLinks.map(({ href, icon: Icon, ar, en, detailAr, detailEn }) => (
            <Link href={href} className={styles.row} key={href}>
              <span className={styles.icon}><Icon fontSize="small" /></span>
              <span className={styles.label}>
                <strong>{l ? ar : en}</strong>
                <small>{l ? detailAr : detailEn}</small>
              </span>
              <ChevronRight className={styles.chevron} />
            </Link>
          ))}
        </div>
      </section>

      {user && (
        <div className={styles.logoutSection}>
          <AppButton
            variant="outline"
            fullWidth
            onClick={() => setLogoutOpen(true)}
            startIcon={<Logout fontSize="small" />}
            style={{ borderColor: 'var(--error)', color: 'var(--error)' }}
          >
            {l ? 'تسجيل الخروج' : 'Log Out'}
          </AppButton>
        </div>
      )}

      {user && (
        <div className={styles.deleteSection}>
          <AppButton
            variant="text"
            fullWidth
            onClick={() => setDeleteOpen(true)}
            startIcon={<DeleteForever fontSize="small" />}
            style={{ color: 'var(--error)' }}
          >
            {l ? 'حذف الحساب' : 'Delete Account'}
          </AppButton>
        </div>
      )}

      <span className={styles.version}>Version 2.4.0</span>

      <ResponsiveDialog
        open={logoutOpen}
        onClose={() => setLogoutOpen(false)}
        title={l ? 'تسجيل الخروج' : 'Log Out'}
        destructive
        actions={
          <>
            <AppButton variant="text" onClick={() => setLogoutOpen(false)}>
              {l ? 'إلغاء' : 'Cancel'}
            </AppButton>
            <AppButton
              variant="error"
              onClick={() => {
                setLogoutOpen(false);
                void signOut();
              }}
            >
              {l ? 'تسجيل الخروج' : 'Log Out'}
            </AppButton>
          </>
        }
      >
        {l ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to log out?'}
      </ResponsiveDialog>

      <ResponsiveDialog
        open={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        title={l ? 'حذف الحساب' : 'Delete Account'}
        destructive
        actions={
          <>
            <AppButton variant="text" onClick={() => setDeleteOpen(false)}>
              {l ? 'إلغاء' : 'Cancel'}
            </AppButton>
            <AppButton variant="error" onClick={handleDeleteAccount}>
              {l ? 'حذف' : 'Delete'}
            </AppButton>
          </>
        }
      >
        {l ? 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.' : 'Are you sure you want to delete your account? This cannot be undone.'}
      </ResponsiveDialog>
    </main>
  );
}

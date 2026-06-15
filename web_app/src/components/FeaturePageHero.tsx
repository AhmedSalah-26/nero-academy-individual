import React from 'react';
import type { LucideIcon } from 'lucide-react';
import styles from '../app/student-features.module.css';

export function FeaturePageHero({
  icon: Icon,
  eyebrow,
  title,
  subtitle,
}: {
  icon: LucideIcon;
  eyebrow: string;
  title: string;
  subtitle: string;
}) {
  return (
    <section className={styles.hero}>
      <div className={styles.heroCopy}>
        <span className={styles.eyebrow}>{eyebrow}</span>
        <h1 className={styles.title}>{title}</h1>
        <p className={styles.subtitle}>{subtitle}</p>
      </div>
      <div className={styles.heroIcon}><Icon size={42} /></div>
    </section>
  );
}

import type { Language } from './translations';

export const NumberUtils = {
  formatCompact(num: number, lang: Language = 'ar'): string {
    if (num < 1000) return String(num);
    if (num < 1_000_000) {
      const val = num / 1000;
      return val % 1 === 0 ? `${val}K` : `${val.toFixed(1)}K`;
    }
    if (num < 1_000_000_000) {
      const val = num / 1_000_000;
      return val % 1 === 0 ? `${val}M` : `${val.toFixed(1)}M`;
    }
    const val = num / 1_000_000_000;
    return val % 1 === 0 ? `${val}B` : `${val.toFixed(1)}B`;
  },

  formatPrice(price: number, lang: Language = 'ar'): string {
    const currency = lang === 'ar' ? 'ج.م' : 'EGP';
    const formatted = price % 1 === 0 ? String(Math.round(price)) : price.toFixed(2);
    return lang === 'ar' ? `${formatted} ${currency}` : `${currency} ${formatted}`;
  },

  formatDuration(totalMinutes: number, lang: Language = 'ar'): string {
    const hours = Math.floor(totalMinutes / 60);
    const mins = totalMinutes % 60;
    if (lang === 'ar') {
      if (hours === 0) return `${mins} د`;
      if (mins === 0) return `${hours} س`;
      return `${hours} س ${mins} د`;
    }
    if (hours === 0) return `${mins}m`;
    if (mins === 0) return `${hours}h`;
    return `${hours}h ${mins}m`;
  },
};

export const AppDateUtils = {
  getRelativeTime(date: Date | string, lang: Language = 'ar'): string {
    const now = new Date();
    const d = typeof date === 'string' ? new Date(date) : date;
    const diffMs = now.getTime() - d.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);
    const diffWeek = Math.floor(diffDay / 7);
    const diffMonth = Math.floor(diffDay / 30);

    if (lang === 'ar') {
      if (diffSec < 60) return 'الآن';
      if (diffMin < 60) return `منذ ${diffMin} د`;
      if (diffHour < 24) return `منذ ${diffHour} س`;
      if (diffDay < 7) return `منذ ${diffDay} ي`;
      if (diffWeek < 5) return `منذ ${diffWeek} أسبوع`;
      if (diffMonth < 12) return `منذ ${diffMonth} شهر`;
      return `منذ ${Math.floor(diffMonth / 12)} سنة`;
    }
    if (diffSec < 60) return 'just now';
    if (diffMin < 60) return `${diffMin}m ago`;
    if (diffHour < 24) return `${diffHour}h ago`;
    if (diffDay < 7) return `${diffDay}d ago`;
    if (diffWeek < 5) return `${diffWeek}w ago`;
    if (diffMonth < 12) return `${diffMonth}mo ago`;
    return `${Math.floor(diffMonth / 12)}y ago`;
  },

  getDateGroup(date: Date | string, lang: Language = 'ar'): string {
    const now = new Date();
    const d = typeof date === 'string' ? new Date(date) : date;
    const diffMs = now.getTime() - d.getTime();
    const diffDay = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDay === 0) return lang === 'ar' ? 'اليوم' : 'Today';
    if (diffDay === 1) return lang === 'ar' ? 'أمس' : 'Yesterday';

    return d.toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  },
};

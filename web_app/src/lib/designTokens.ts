export const AppColors = {
  primary: '#2563EB',
  primaryLight: '#DBEAFE',
  primaryDark: '#1D4ED8',
  primaryOnDark: '#93C5FD',
  primaryGlow: 'rgba(37, 99, 235, 0.10)',
  background: '#F7F6F8',
  surface: '#FFFFFF',
  surfaceCard: '#FFFFFF',
  surfaceHover: 'rgba(37, 99, 235, 0.04)',
  surfaceSoft: '#F3F4F6',
  cardDark: '#172033',
  surfaceDark: '#0F172A',
  textMain: '#111827',
  textMuted: '#6B7280',
  textSecondary: '#9CA3AF',
  border: 'rgba(0, 0, 0, 0.10)',
  borderLight: 'rgba(0, 0, 0, 0.05)',
  success: '#22C55E',
  successLight: 'rgba(34, 197, 94, 0.10)',
  error: '#EF4444',
  errorLight: 'rgba(239, 68, 68, 0.10)',
  warning: '#F59E0B',
  warningLight: 'rgba(245, 158, 11, 0.10)',
  info: '#3B82F6',
  infoLight: 'rgba(59, 130, 246, 0.10)',
  rating: '#B47D00',
  glassBg: 'rgba(255, 255, 255, 0.72)',
  glassBorder: 'rgba(0, 0, 0, 0.08)',
} as const;

export const AppColorsDark = {
  ...AppColors,
  primary: '#93C5FD',
  primaryDark: '#2563EB',
  primaryLight: '#1E3A5F',
  primaryOnDark: '#93C5FD',
  primaryGlow: 'rgba(147, 197, 253, 0.15)',
  background: '#0F172A',
  surface: 'rgba(30, 41, 59, 0.86)',
  surfaceCard: '#1E293B',
  surfaceHover: 'rgba(37, 99, 235, 0.12)',
  surfaceSoft: '#1E293B',
  textMain: '#F1F5F9',
  textMuted: '#94A3B8',
  textSecondary: '#64748B',
  border: 'rgba(148, 163, 184, 0.15)',
  borderLight: 'rgba(148, 163, 184, 0.08)',
  glassBg: 'rgba(15, 23, 42, 0.72)',
  glassBorder: 'rgba(148, 163, 184, 0.12)',
} as const;

export const AppRadius = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  '2xl': 32,
  full: 9999,
} as const;

export const AppSpacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  '2xl': 48,
  '3xl': 64,
} as const;

export const AppTextStyles = {
  xs: '0.75rem',
  sm: '0.875rem',
  base: '1rem',
  lg: '1.125rem',
  xl: '1.25rem',
  '2xl': '1.5rem',
  '3xl': '2rem',
  '4xl': '2.5rem',
  '5xl': '3rem',
} as const;

export const AppFontWeights = {
  light: 300,
  normal: 400,
  medium: 500,
  semibold: 600,
  bold: 700,
  extrabold: 800,
} as const;

export const AppShadows = {
  xs: '0 1px 2px rgba(0, 0, 0, 0.05)',
  sm: '0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06)',
  md: '0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06)',
  lg: '0 10px 15px rgba(0, 0, 0, 0.1), 0 4px 6px rgba(0, 0, 0, 0.05)',
  xl: '0 20px 25px rgba(0, 0, 0, 0.1), 0 8px 10px rgba(0, 0, 0, 0.04)',
  primary: '0 16px 34px rgba(37, 99, 235, 0.18)',
} as const;

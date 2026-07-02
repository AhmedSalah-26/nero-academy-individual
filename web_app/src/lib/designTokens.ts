export const AppColors = {
  primary: '#6F7A3A',
  primaryLight: '#8C8B4A',
  primaryDark: '#4F5A28',
  primaryOnDark: '#8C8B4A',
  primaryGlow: 'rgba(111, 122, 58, 0.16)',
  background: '#EEF0E4',
  surface: '#F7F8EE',
  surfaceCard: '#FBFCF3',
  surfaceHover: 'rgba(111, 122, 58, 0.10)',
  surfaceSoft: '#E2E6D2',
  cardDark: '#172414',
  surfaceDark: '#101B10',
  textMain: '#182012',
  textMuted: '#5F674C',
  textSecondary: '#78805F',
  border: 'rgba(79, 82, 45, 0.18)',
  borderLight: 'rgba(79, 82, 45, 0.09)',
  success: '#22C55E',
  successLight: 'rgba(34, 197, 94, 0.10)',
  error: '#EF4444',
  errorLight: 'rgba(239, 68, 68, 0.10)',
  warning: '#F59E0B',
  warningLight: 'rgba(245, 158, 11, 0.10)',
  info: '#86A35A',
  infoLight: 'rgba(134, 163, 90, 0.12)',
  rating: '#B47D00',
  glassBg: 'rgba(251, 252, 243, 0.76)',
  glassBorder: 'rgba(105, 111, 63, 0.16)',
} as const;

export const AppColorsDark = {
  ...AppColors,
  primary: '#8C8B4A',
  primaryDark: '#80671F',
  primaryLight: '#3A3B19',
  primaryOnDark: '#A7A35A',
  primaryGlow: 'rgba(140, 139, 74, 0.18)',
  background: '#071008',
  surface: 'rgba(16, 27, 16, 0.88)',
  surfaceCard: '#101B10',
  surfaceHover: 'rgba(140, 139, 74, 0.10)',
  surfaceSoft: '#182617',
  textMain: '#F1F2E6',
  textMuted: '#B8BEA2',
  textSecondary: '#8F966F',
  border: 'rgba(111, 122, 58, 0.18)',
  borderLight: 'rgba(111, 122, 58, 0.09)',
  glassBg: 'rgba(7, 16, 8, 0.74)',
  glassBorder: 'rgba(111, 122, 58, 0.16)',
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
  primary: '0 16px 34px rgba(111, 122, 58, 0.20)',
} as const;

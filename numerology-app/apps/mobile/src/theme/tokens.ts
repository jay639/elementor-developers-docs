/**
 * Design tokens for the Ank Jyoti app.
 *
 * The palette is deliberately restrained: deep navy, a single warm gold accent
 * and off-white surfaces. It should read like a modern fintech or wellness app
 * rather than a traditional astrology site - no heavy gradients, no clutter.
 */

export const palette = {
  navy: '#12203F',
  navyLight: '#1C2F57',
  navyDeep: '#0C1730',
  gold: '#C9A227',
  goldSoft: '#F6EFD9',
  beige: '#F1EDE4',
  purple: '#6C5B9E',
  charcoal: '#1B1D22',
  white: '#FFFFFF',
  offWhite: '#FBFAF7',
  grey100: '#F3F3F0',
  grey200: '#E4E4E0',
  grey400: '#9CA0A8',
  grey600: '#6B7280',
  success: '#1F7A4D',
  successSoft: '#E6F4EC',
  warning: '#9A6B00',
  warningSoft: '#FBF3DF',
  danger: '#B3261E',
  dangerSoft: '#FBEDEC',
} as const;

export interface ThemeColors {
  background: string;
  surface: string;
  surfaceAlt: string;
  primary: string;
  primaryContrast: string;
  accent: string;
  accentSoft: string;
  text: string;
  textMuted: string;
  border: string;
  success: string;
  successSoft: string;
  warning: string;
  warningSoft: string;
  danger: string;
  dangerSoft: string;
  overlay: string;
}

export const lightColors: ThemeColors = {
  background: palette.offWhite,
  surface: palette.white,
  surfaceAlt: palette.grey100,
  primary: palette.navy,
  primaryContrast: palette.white,
  accent: palette.gold,
  accentSoft: palette.goldSoft,
  text: palette.charcoal,
  textMuted: palette.grey600,
  border: palette.grey200,
  success: palette.success,
  successSoft: palette.successSoft,
  warning: palette.warning,
  warningSoft: palette.warningSoft,
  danger: palette.danger,
  dangerSoft: palette.dangerSoft,
  overlay: 'rgba(12, 23, 48, 0.45)',
};

/** Dark mode keeps the same hierarchy so number cards stay readable. */
export const darkColors: ThemeColors = {
  background: '#0B1220',
  surface: '#141C2E',
  surfaceAlt: '#1B2438',
  primary: '#E8EDF7',
  primaryContrast: '#0B1220',
  accent: '#E0BE4B',
  accentSoft: '#2A2718',
  text: '#F2F4F8',
  textMuted: '#A5AEC0',
  border: '#25304A',
  success: '#5FCF97',
  successSoft: '#12301F',
  warning: '#E8C46B',
  warningSoft: '#2E2612',
  danger: '#F08B84',
  dangerSoft: '#331A18',
  overlay: 'rgba(0, 0, 0, 0.6)',
};

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48,
} as const;

export const radius = {
  sm: 10,
  md: 14,
  lg: 20,
  pill: 999,
} as const;

/** Font sizes scale with the device text size, so they are base values. */
export const fontSize = {
  caption: 12,
  small: 13,
  body: 15,
  bodyLarge: 17,
  title: 20,
  heading: 24,
  display: 34,
  number: 64,
} as const;

export const fontWeight = {
  regular: '400',
  medium: '500',
  semibold: '600',
  bold: '700',
} as const;

/** Minimum touch target, per the accessibility guidance. */
export const MIN_TOUCH_TARGET = 44;

export const shadow = {
  card: {
    shadowColor: '#0C1730',
    shadowOpacity: 0.07,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 6 },
    elevation: 2,
  },
  raised: {
    shadowColor: '#0C1730',
    shadowOpacity: 0.12,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 10 },
    elevation: 5,
  },
} as const;

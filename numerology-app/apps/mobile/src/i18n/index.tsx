import React, { createContext, useCallback, useContext, useMemo } from 'react';
import * as Localization from 'expo-localization';
import { LOCALE_NAMES, translations, type Dictionary, type Locale } from './translations';

export type { Locale };
export { LOCALE_NAMES };

export const SUPPORTED_LOCALES: Locale[] = ['en', 'hi', 'mr'];

/** Falls back to English when the device language is not supported. */
export function deviceLocale(): Locale {
  const tag = Localization.getLocales()[0]?.languageCode ?? 'en';
  return (SUPPORTED_LOCALES as string[]).includes(tag) ? (tag as Locale) : 'en';
}

type Path = string;

/** Reads a dotted path such as "home.todaysNumber" out of the dictionary. */
function lookup(dictionary: Dictionary, path: Path): string {
  const value = path
    .split('.')
    .reduce<unknown>((current, key) => (current as Record<string, unknown> | undefined)?.[key], dictionary);
  return typeof value === 'string' ? value : path;
}

interface I18nContextValue {
  locale: Locale;
  t: (path: Path, params?: Record<string, string | number>) => string;
}

const I18nContext = createContext<I18nContextValue>({ locale: 'en', t: (path) => path });

export function I18nProvider({ locale, children }: { locale: Locale; children: React.ReactNode }) {
  const t = useCallback(
    (path: Path, params?: Record<string, string | number>) => {
      const template = lookup(translations[locale], path);
      if (!params) return template;
      return template.replace(/\{(\w+)\}/g, (_match, key: string) => String(params[key] ?? ''));
    },
    [locale],
  );

  const value = useMemo(() => ({ locale, t }), [locale, t]);
  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useTranslation(): I18nContextValue {
  return useContext(I18nContext);
}

/** Month names for the date picker, in each supported language. */
export const MONTH_NAMES: Record<Locale, string[]> = {
  en: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  hi: ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्तूबर', 'नवंबर', 'दिसंबर'],
  mr: ['जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून', 'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'],
};

/** Formats an ISO date as "15 August 1995" in the active language. */
export function formatLongDate(iso: string, locale: Locale): string {
  const [year, month, day] = iso.split('-').map(Number);
  if (!year || !month || !day) return iso;
  return `${day} ${MONTH_NAMES[locale][month - 1] ?? ''} ${year}`;
}

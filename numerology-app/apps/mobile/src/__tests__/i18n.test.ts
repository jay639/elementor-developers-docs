import { formatLongDate } from '../i18n';
import { translations, LOCALE_NAMES } from '../i18n/translations';

describe('translations', () => {
  const locales = ['en', 'hi', 'mr'] as const;

  it('supports English, Hindi and Marathi', () => {
    expect(Object.keys(LOCALE_NAMES)).toEqual(['en', 'hi', 'mr']);
  });

  /** Collects every dotted key path in a dictionary. */
  function paths(value: unknown, prefix = ''): string[] {
    if (typeof value !== 'object' || value === null) return [prefix];
    return Object.entries(value as Record<string, unknown>).flatMap(([key, child]) =>
      paths(child, prefix ? `${prefix}.${key}` : key),
    );
  }

  it('has no missing keys in any language', () => {
    const english = paths(translations.en).sort();
    for (const locale of locales) {
      expect(paths(translations[locale]).sort()).toEqual(english);
    }
  });

  it('has no untranslated strings left in Hindi or Marathi', () => {
    // A handful of strings are legitimately identical (the placeholder name in
    // the name example), so only the bulk is compared.
    for (const locale of ['hi', 'mr'] as const) {
      const identical = paths(translations.en).filter((path) => {
        const english = path.split('.').reduce<any>((current, key) => current?.[key], translations.en);
        const other = path.split('.').reduce<any>((current, key) => current?.[key], translations[locale]);
        return typeof english === 'string' && english === other;
      });
      expect(identical.length).toBeLessThan(6);
    }
  });

  it('keeps interpolation placeholders in every language', () => {
    for (const locale of locales) {
      expect(translations[locale].home.basedOnDate).toContain('{date}');
      expect(translations[locale].name.ignored).toContain('{characters}');
    }
  });
});

describe('formatLongDate', () => {
  it('uses the month names of the active language', () => {
    expect(formatLongDate('1995-08-15', 'en')).toBe('15 August 1995');
    expect(formatLongDate('1995-08-15', 'hi')).toBe('15 अगस्त 1995');
    expect(formatLongDate('1995-08-15', 'mr')).toBe('15 ऑगस्ट 1995');
  });

  it('returns the input unchanged when it is not a date', () => {
    expect(formatLongDate('not-a-date', 'en')).toBe('not-a-date');
  });
});

import type { Request } from 'express';
import { DEFAULT_LOCALE, SUPPORTED_LOCALES, type Locale } from '@numerology/core';

/**
 * Resolves the locale for a request from (in order) an explicit query
 * parameter, the X-Locale header, or the Accept-Language header.
 */
export function resolveLocale(req: Request): Locale {
  const candidates = [
    typeof req.query.locale === 'string' ? req.query.locale : undefined,
    req.get('x-locale') ?? undefined,
    req.get('accept-language')?.split(',')[0],
  ];

  for (const candidate of candidates) {
    if (!candidate) continue;
    const normalised = candidate.trim().toLowerCase().slice(0, 2) as Locale;
    if (SUPPORTED_LOCALES.includes(normalised)) return normalised;
  }
  return DEFAULT_LOCALE;
}

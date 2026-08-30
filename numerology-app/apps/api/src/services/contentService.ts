import type { Locale } from '@numerology/core';
import { prisma } from '../lib/prisma';
import { CacheKeys, cached, invalidate } from '../lib/cache';

export interface NumberContent {
  number: number;
  name: string;
  title: string;
  summary: string;
  personality: string;
  behaviour: string;
  strengths: string[];
  weaknesses: string[];
  career: string;
  relationships: string;
  general: string;
  luckyNumbers: number[];
  unfavourableNumbers: number[];
  colors: string[];
  notes: string | null;
}

export interface CombinationContent {
  mulank: number;
  bhagyank: number;
  title: string;
  description: string;
  personality: string;
  strengths: string[];
  challenges: string[];
  career: string;
  relationships: string;
  recommendations: string;
}

/**
 * Content is looked up in the requested locale and falls back to English when a
 * translation has not been written yet, so the app never shows an empty screen.
 */
async function withFallback<T>(locale: Locale, load: (locale: Locale) => Promise<T | null>): Promise<T | null> {
  const primary = await load(locale);
  if (primary) return primary;
  return locale === 'en' ? null : load('en');
}

export async function getNumberContent(number: number, locale: Locale): Promise<NumberContent | null> {
  return cached(`${CacheKeys.numbers}:${number}:${locale}`, async () =>
    withFallback(locale, async (candidate) => {
      const row = await prisma.numerologyNumber.findFirst({
        where: { number, locale: candidate, isPublished: true },
      });
      if (!row) return null;
      const { id, createdAt, updatedAt, locale: _locale, isPublished, ...content } = row;
      return content as NumberContent;
    }),
  );
}

export async function getAllNumberContent(locale: Locale): Promise<NumberContent[]> {
  return cached(`${CacheKeys.numbers}:all:${locale}`, async () => {
    const results = await Promise.all(
      [1, 2, 3, 4, 5, 6, 7, 8, 9].map((number) => getNumberContent(number, locale)),
    );
    return results.filter((item): item is NumberContent => item !== null);
  });
}

/**
 * Combination interpretation for a Mulank/Bhagyank pair. Returns null when the
 * administrator has not published a row - the caller then falls back to the two
 * individual number interpretations.
 */
export async function getCombinationContent(
  mulank: number,
  bhagyank: number,
  locale: Locale,
): Promise<CombinationContent | null> {
  return cached(`${CacheKeys.combination}:${mulank}:${bhagyank}:${locale}`, async () =>
    withFallback(locale, async (candidate) => {
      const row = await prisma.mulankBhagyankCombination.findFirst({
        where: { mulank, bhagyank, locale: candidate, isPublished: true },
      });
      if (!row) return null;
      const { id, createdAt, updatedAt, locale: _locale, isPublished, ...content } = row;
      return content as CombinationContent;
    }),
  );
}

export interface DailyInsight {
  number: number;
  title: string;
  message: string;
}

export async function getDailyInsight(number: number, locale: Locale): Promise<DailyInsight | null> {
  return cached(`${CacheKeys.daily}:${number}:${locale}`, async () =>
    withFallback(locale, async (candidate) => {
      const row = await prisma.dailyNumberInsight.findFirst({ where: { number, locale: candidate } });
      return row ? { number: row.number, title: row.title, message: row.message } : null;
    }),
  );
}

export type LegalType = 'TERMS' | 'PRIVACY' | 'DISCLAIMER' | 'ABOUT';

export async function getLegalDocument(type: LegalType, locale: Locale) {
  return cached(`${CacheKeys.legal}:${type}:${locale}`, async () =>
    withFallback(locale, async (candidate) => {
      const row = await prisma.legalDocument.findFirst({ where: { type, locale: candidate } });
      return row
        ? { type: row.type, title: row.title, body: row.body, version: row.version, updatedAt: row.updatedAt }
        : null;
    }),
  );
}

export function invalidateContent(): void {
  invalidate(CacheKeys.numbers, CacheKeys.combination, CacheKeys.daily, CacheKeys.legal);
}

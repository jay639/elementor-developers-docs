import {
  DEFAULT_MARRIAGE_WEIGHTS,
  buildChaldeanMap,
  type ChaldeanMap,
  type MarriageRule,
  type MarriageScoreWeights,
  type NumberCompatibilityRule,
  type SingleDigit,
} from '@numerology/core';
import { prisma } from '../lib/prisma';
import { CacheKeys, cached, invalidate } from '../lib/cache';
import { getSetting } from './settingsService';

/**
 * All configurable numerology rules are loaded from the database here and
 * passed into the calculation engine. No rule is ever hard-coded in a route
 * handler, a service or the mobile app.
 */

export async function getMarriageRules(): Promise<MarriageRule[]> {
  return cached(CacheKeys.marriageRules, async () => {
    const rows = await prisma.marriageCompatibilityRule.findMany({ orderBy: { driverNumber: 'asc' } });
    return rows.map((row) => ({
      driverNumber: row.driverNumber as SingleDigit,
      compatibleMulank: row.compatibleMulank,
      compatibleBhagyank: row.compatibleBhagyank,
      enabled: row.enabled,
      note: null,
    }));
  });
}

/** Administrator notes for each rule, keyed by locale. */
export async function getMarriageRuleNotes(): Promise<Record<number, Record<string, string>>> {
  const rows = await prisma.marriageCompatibilityRule.findMany({
    select: { driverNumber: true, notes: true },
  });
  return Object.fromEntries(
    rows.map((row) => [row.driverNumber, (row.notes ?? {}) as Record<string, string>]),
  );
}

export async function getNumberCompatibilityRules(): Promise<NumberCompatibilityRule[]> {
  return cached(CacheKeys.numberRules, async () => {
    const rows = await prisma.numberCompatibilityRule.findMany({ orderBy: { baseNumber: 'asc' } });
    return rows.map((row) => ({
      baseNumber: row.baseNumber as SingleDigit,
      friendly: row.friendly,
      neutral: row.neutral,
      unfriendly: row.unfriendly,
      enabled: row.enabled,
    }));
  });
}

export async function getChaldeanMap(): Promise<ChaldeanMap> {
  return cached(CacheKeys.chaldean, async () => {
    const rows = await prisma.chaldeanMapping.findMany({ where: { enabled: true } });
    return Object.fromEntries(rows.map((row) => [row.letter.toUpperCase(), row.value]));
  });
}

/** The Chaldean table grouped by value, as the admin panel displays it. */
export async function getChaldeanGroups(): Promise<Record<number, string[]>> {
  const rows = await prisma.chaldeanMapping.findMany({ orderBy: [{ value: 'asc' }, { letter: 'asc' }] });
  const groups: Record<number, string[]> = { 1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [], 8: [], 9: [] };
  for (const row of rows) {
    if (!groups[row.value]) groups[row.value] = [];
    groups[row.value]!.push(row.letter.toUpperCase());
  }
  return groups;
}

export async function getMarriageWeights(): Promise<MarriageScoreWeights> {
  const stored = await getSetting<Partial<MarriageScoreWeights>>('marriage.scoreWeights');
  return {
    mulankMatch: Number(stored?.mulankMatch ?? DEFAULT_MARRIAGE_WEIGHTS.mulankMatch),
    bhagyankMatch: Number(stored?.bhagyankMatch ?? DEFAULT_MARRIAGE_WEIGHTS.bhagyankMatch),
  };
}

/** Rebuilds the Chaldean map from an administrator supplied group table. */
export function chaldeanGroupsToMap(groups: Record<number, string[]>): ChaldeanMap {
  return buildChaldeanMap(groups);
}

export function invalidateRules(): void {
  invalidate(CacheKeys.marriageRules, CacheKeys.numberRules, CacheKeys.chaldean);
}

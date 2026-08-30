import {
  buildChaldeanMap,
  calculateChaldeanName,
  calculateCoreNumbersFromDob,
  calculateDailyNumber,
  calculateMarriageCompatibility,
  calculateNumberCompatibility,
  calculateNumberRoot,
  DEFAULT_CHALDEAN_GROUPS,
  DEFAULT_MARRIAGE_RULES,
  DEFAULT_NUMBER_COMPATIBILITY_RULES,
  type MarriageRule,
  type NumberCompatibilityRule,
  type SingleDigit,
} from '@numerology/core';
import { api } from '../api/endpoints';
import type {
  CompatibilityResult,
  CoreNumbersResult,
  DailyResult,
  LuckyNumberResult,
  NameResult,
  NumberContent,
} from '../api/endpoints';
import { StorageKeys, readJson, writeJson } from './storage';
import { translations, type Locale } from '../i18n/translations';

/**
 * Offline calculation layer.
 *
 * The core arithmetic runs on the device using the same engine the server uses,
 * with the rule tables and interpretation text cached from the last successful
 * sync. Results produced here are marked `offline: true` so the UI can say the
 * calculation was done on the device and is not stored in cloud history.
 */

interface CachedRules {
  marriage: MarriageRule[];
  numbers: NumberCompatibilityRule[];
  chaldean: Record<string, string[]>;
}

interface CachedContent {
  locale: Locale;
  numbers: NumberContent[];
}

const fallbackRules: CachedRules = {
  marriage: DEFAULT_MARRIAGE_RULES,
  numbers: DEFAULT_NUMBER_COMPATIBILITY_RULES,
  chaldean: DEFAULT_CHALDEAN_GROUPS,
};

/** Refreshes the offline caches. Called after a successful online request. */
export async function syncOfflineCaches(locale: Locale): Promise<void> {
  try {
    const [rules, numbers] = await Promise.all([api.rules(), api.numbers()]);
    await Promise.all([
      writeJson(StorageKeys.cachedRules, rules.data),
      writeJson(StorageKeys.cachedContent, { locale, numbers: numbers.data } satisfies CachedContent),
    ]);
  } catch {
    // A failed sync simply leaves the previous cache in place.
  }
}

async function loadRules(): Promise<CachedRules> {
  const cached = await readJson<CachedRules>(StorageKeys.cachedRules);
  if (!cached) return fallbackRules;
  return {
    marriage: cached.marriage?.length ? cached.marriage : fallbackRules.marriage,
    numbers: cached.numbers?.length ? cached.numbers : fallbackRules.numbers,
    chaldean: cached.chaldean ?? fallbackRules.chaldean,
  };
}

async function loadContent(locale: Locale): Promise<NumberContent[]> {
  const cached = await readJson<CachedContent>(StorageKeys.cachedContent);
  return cached && cached.locale === locale ? cached.numbers : [];
}

function contentFor(numbers: NumberContent[], number: number): NumberContent | null {
  return numbers.find((item) => item.number === number) ?? null;
}

function matchLabel(locale: Locale, level: string): string {
  const labels = translations[locale].match as Record<string, string>;
  return labels[level] ?? level;
}

function axisLabel(locale: Locale, axis: 'MULANK' | 'BHAGYANK'): string {
  return axis === 'MULANK' ? translations[locale].common.mulank : translations[locale].common.bhagyank;
}

export async function offlineCoreNumbers(dob: string, locale: Locale): Promise<CoreNumbersResult> {
  const numbers = calculateCoreNumbersFromDob(dob);
  const content = await loadContent(locale);
  return {
    dob: numbers.dob,
    mulank: numbers.mulank,
    bhagyank: numbers.bhagyank,
    breakdown: { mulank: numbers.mulankBreakdown, bhagyank: numbers.bhagyankBreakdown },
    mulankContent: contentFor(content, numbers.mulank),
    bhagyankContent: contentFor(content, numbers.bhagyank),
    // Combination text is not cached offline; the app falls back to the two
    // individual interpretations, exactly as the API does.
    combination: null,
    combinationFallback: true,
    disclaimer: translations[locale].onboarding.disclaimer,
  };
}

export async function offlineLuckyNumber(
  value: string,
  dob: string | null,
  locale: Locale,
): Promise<LuckyNumberResult> {
  const root = calculateNumberRoot(value);
  const core = dob ? calculateCoreNumbersFromDob(dob) : null;
  const [rules, content] = await Promise.all([loadRules(), loadContent(locale)]);

  const compatibility = calculateNumberCompatibility(root.root, core?.mulank ?? null, core?.bhagyank ?? null, {
    rules: rules.numbers,
  });

  return {
    input: root.input,
    digits: root.digits,
    compound: root.compound,
    root: root.root,
    breakdown: root.breakdown,
    mulank: compatibility.mulank,
    bhagyank: compatibility.bhagyank,
    comparisons: compatibility.comparisons.map((comparison) => ({
      axis: comparison.axis,
      axisLabel: axisLabel(locale, comparison.axis),
      axisValue: comparison.axisValue,
      level: comparison.level,
      levelLabel: matchLabel(locale, comparison.level),
      message: '',
    })),
    overall: compatibility.overall,
    overallLabel: matchLabel(locale, compatibility.overall),
    score: compatibility.score,
    summary: '',
    rootContent: contentFor(content, root.root),
    needsDob: core === null,
    needsDobMessage: core === null ? translations[locale].home.addDobTitle : null,
    disclaimer: translations[locale].onboarding.disclaimer,
  };
}

export async function offlineName(name: string, dob: string | null, locale: Locale): Promise<NameResult> {
  const [rules, content] = await Promise.all([loadRules(), loadContent(locale)]);
  const result = calculateChaldeanName(name, buildChaldeanMap(normaliseGroups(rules.chaldean)));

  let comparison: NameResult['comparison'] = null;
  if (dob) {
    const core = calculateCoreNumbersFromDob(dob);
    const compatibility = calculateNumberCompatibility(result.root, core.mulank, core.bhagyank, {
      rules: rules.numbers,
    });
    comparison = {
      mulank: core.mulank,
      bhagyank: core.bhagyank,
      axes: compatibility.comparisons.map((item) => ({
        axis: item.axis,
        axisValue: item.axisValue,
        level: item.level,
        levelLabel: matchLabel(locale, item.level),
        message: '',
      })),
      overall: compatibility.overall,
      overallLabel: matchLabel(locale, compatibility.overall),
      score: compatibility.score,
    };
  }

  return {
    name: result.name,
    letters: result.letters,
    compound: result.compound,
    root: result.root,
    breakdown: result.breakdown,
    ignoredCharacters: result.ignoredCharacters,
    rootContent: contentFor(content, result.root),
    comparison,
    needsDob: dob === null,
    needsDobMessage: dob === null ? translations[locale].name.addDobForPersonalised : null,
    disclaimer: translations[locale].onboarding.disclaimer,
  };
}

/** The cached table arrives keyed by string; the engine wants numeric keys. */
function normaliseGroups(groups: Record<string, string[]>): Record<number, string[]> {
  return Object.fromEntries(Object.entries(groups).map(([value, letters]) => [Number(value), letters]));
}

export async function offlineCompatibility(
  maleDob: string,
  femaleDob: string,
  locale: Locale,
): Promise<CompatibilityResult> {
  const [rules, content] = await Promise.all([loadRules(), loadContent(locale)]);
  const result = calculateMarriageCompatibility(maleDob, femaleDob, { rules: rules.marriage });
  const copy = translations[locale];

  return {
    male: { dob: result.male.dob, mulank: result.male.mulank, bhagyank: result.male.bhagyank },
    female: { dob: result.female.dob, mulank: result.female.mulank, bhagyank: result.female.bhagyank },
    directions: [result.maleToFemale, result.femaleToMale].map((direction) => ({
      direction: direction.direction,
      driverNumber: direction.driverNumber,
      targetMulank: direction.targetMulank,
      targetBhagyank: direction.targetBhagyank,
      matched: direction.matched,
      matchedVia: direction.matchedVia,
      viaNote: null,
      compatibleMulank: direction.compatibleMulank,
      compatibleBhagyank: direction.compatibleBhagyank,
      ruleMissing: direction.ruleMissing,
      note: null,
    })),
    verdict: result.verdict,
    verdictLabel: matchLabel(locale, result.verdict),
    matchedDirections: result.matchedDirections,
    score: result.score,
    summary: '',
    reasons: [],
    maleContent: contentFor(content, result.male.mulank),
    femaleContent: contentFor(content, result.female.mulank),
    kundaliReferral: { enabled: true, url: '', label: copy.compatibility.exploreKundali, note: copy.compatibility.deeperBody },
    disclaimer: copy.onboarding.disclaimer,
    marriageDisclaimer: copy.compatibility.deeperBody,
  };
}

export async function offlineDaily(locale: Locale, date?: string): Promise<DailyResult> {
  const daily = calculateDailyNumber(date ?? new Date());
  const content = await loadContent(locale);
  return {
    date: daily.date,
    number: daily.number,
    breakdown: daily.breakdown,
    insight: null,
    content: contentFor(content, daily.number),
  };
}

export type { SingleDigit };

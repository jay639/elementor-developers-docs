import {
  calculateChaldeanName,
  calculateCoreNumbersFromDob,
  calculateDailyNumber,
  calculateMarriageCompatibility,
  calculateNumberCompatibility,
  calculateNumberRoot,
  type ChaldeanNameResult,
  type CoreNumbers,
  type Locale,
  type SingleDigit,
} from '@numerology/core';
import {
  getChaldeanMap,
  getMarriageRuleNotes,
  getMarriageRules,
  getMarriageWeights,
  getNumberCompatibilityRules,
} from './rulesService';
import { getCombinationContent, getDailyInsight, getNumberContent } from './contentService';
import { getSetting } from './settingsService';
import { messages } from './messages';

/**
 * The single place where a numerology result is assembled: the pure engine from
 * @numerology/core does the arithmetic, the database supplies the rules and the
 * interpretation text, and this service joins the two together.
 *
 * Route handlers never calculate anything themselves.
 */

export interface CoreNumbersResponse {
  dob: string;
  mulank: number;
  bhagyank: number;
  breakdown: { mulank: CoreNumbers['mulankBreakdown']; bhagyank: CoreNumbers['bhagyankBreakdown'] };
  mulankContent: Awaited<ReturnType<typeof getNumberContent>>;
  bhagyankContent: Awaited<ReturnType<typeof getNumberContent>>;
  combination: Awaited<ReturnType<typeof getCombinationContent>>;
  /** True when no combination row exists and the two number interpretations are used instead. */
  combinationFallback: boolean;
  disclaimer: string;
}

export async function buildCoreNumbers(dob: string, locale: Locale): Promise<CoreNumbersResponse> {
  const numbers = calculateCoreNumbersFromDob(dob);
  const [mulankContent, bhagyankContent, combination] = await Promise.all([
    getNumberContent(numbers.mulank, locale),
    getNumberContent(numbers.bhagyank, locale),
    getCombinationContent(numbers.mulank, numbers.bhagyank, locale),
  ]);

  return {
    dob: numbers.dob,
    mulank: numbers.mulank,
    bhagyank: numbers.bhagyank,
    breakdown: { mulank: numbers.mulankBreakdown, bhagyank: numbers.bhagyankBreakdown },
    mulankContent,
    bhagyankContent,
    combination,
    combinationFallback: combination === null,
    disclaimer: messages.disclaimers(locale).general,
  };
}

export interface LuckyNumberResponse {
  input: string;
  digits: number[];
  compound: number;
  root: number;
  breakdown: ReturnType<typeof calculateNumberRoot>['breakdown'];
  mulank: number | null;
  bhagyank: number | null;
  comparisons: Array<{
    axis: 'MULANK' | 'BHAGYANK';
    axisLabel: string;
    axisValue: number;
    level: string;
    levelLabel: string;
    message: string;
  }>;
  overall: string;
  overallLabel: string;
  score: number;
  summary: string;
  rootContent: Awaited<ReturnType<typeof getNumberContent>>;
  needsDob: boolean;
  needsDobMessage: string | null;
  disclaimer: string;
}

export async function buildLuckyNumber(
  value: string,
  dob: string | null,
  locale: Locale,
): Promise<LuckyNumberResponse> {
  const rootResult = calculateNumberRoot(value);
  const core = dob ? calculateCoreNumbersFromDob(dob) : null;
  const rules = await getNumberCompatibilityRules();

  const compatibility = calculateNumberCompatibility(
    rootResult.root,
    core?.mulank ?? null,
    core?.bhagyank ?? null,
    { rules },
  );
  const rootContent = await getNumberContent(rootResult.root, locale);

  return {
    input: rootResult.input,
    digits: rootResult.digits,
    compound: rootResult.compound,
    root: rootResult.root,
    breakdown: rootResult.breakdown,
    mulank: compatibility.mulank,
    bhagyank: compatibility.bhagyank,
    comparisons: compatibility.comparisons.map((comparison) => ({
      axis: comparison.axis,
      axisLabel: messages.axisLabel(locale, comparison.axis),
      axisValue: comparison.axisValue,
      level: comparison.level,
      levelLabel: messages.verdictLabel(locale, comparison.level),
      message: messages.axisSentence(
        locale,
        comparison.level,
        comparison.axis,
        rootResult.root,
        comparison.axisValue,
      ),
    })),
    overall: compatibility.overall,
    overallLabel: messages.verdictLabel(locale, compatibility.overall),
    score: compatibility.score,
    summary: core
      ? messages.numberMatchSummary(locale, compatibility.overall)
      : messages.missingDob(locale),
    rootContent,
    needsDob: core === null,
    needsDobMessage: core === null ? messages.missingDob(locale) : null,
    disclaimer: messages.disclaimers(locale).general,
  };
}

export interface NameNumerologyResponse {
  name: string;
  letters: ChaldeanNameResult['letters'];
  compound: number;
  root: number;
  breakdown: ChaldeanNameResult['breakdown'];
  ignoredCharacters: string[];
  rootContent: Awaited<ReturnType<typeof getNumberContent>>;
  comparison: {
    mulank: number;
    bhagyank: number;
    axes: Array<{ axis: 'MULANK' | 'BHAGYANK'; axisValue: number; level: string; levelLabel: string; message: string }>;
    overall: string;
    overallLabel: string;
    score: number;
  } | null;
  needsDob: boolean;
  needsDobMessage: string | null;
  disclaimer: string;
}

export async function buildNameNumerology(
  name: string,
  dob: string | null,
  locale: Locale,
): Promise<NameNumerologyResponse> {
  const map = await getChaldeanMap();
  const result = calculateChaldeanName(name, map);
  const rootContent = await getNumberContent(result.root, locale);

  let comparison: NameNumerologyResponse['comparison'] = null;
  if (dob) {
    const core = calculateCoreNumbersFromDob(dob);
    const rules = await getNumberCompatibilityRules();
    const compatibility = calculateNumberCompatibility(result.root, core.mulank, core.bhagyank, { rules });
    comparison = {
      mulank: core.mulank,
      bhagyank: core.bhagyank,
      axes: compatibility.comparisons.map((item) => ({
        axis: item.axis,
        axisValue: item.axisValue,
        level: item.level,
        levelLabel: messages.verdictLabel(locale, item.level),
        message: messages.nameComparison(locale, item.level, item.axis, item.axisValue),
      })),
      overall: compatibility.overall,
      overallLabel: messages.verdictLabel(locale, compatibility.overall),
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
    rootContent,
    comparison,
    needsDob: dob === null,
    needsDobMessage: dob === null ? messages.missingDob(locale) : null,
    disclaimer: messages.disclaimers(locale).general,
  };
}

interface KundaliReferralSetting {
  enabled?: boolean;
  url?: string;
  label?: Record<string, string>;
  note?: Record<string, string>;
}

export interface MarriageResponse {
  male: { dob: string; mulank: number; bhagyank: number };
  female: { dob: string; mulank: number; bhagyank: number };
  directions: Array<{
    direction: 'MALE_TO_FEMALE' | 'FEMALE_TO_MALE';
    driverNumber: number;
    targetMulank: number;
    targetBhagyank: number;
    matched: boolean;
    matchedVia: string;
    viaNote: string | null;
    compatibleMulank: number[];
    compatibleBhagyank: number[];
    ruleMissing: boolean;
    note: string | null;
  }>;
  verdict: string;
  verdictLabel: string;
  matchedDirections: number;
  score: number;
  summary: string;
  reasons: string[];
  maleContent: Awaited<ReturnType<typeof getNumberContent>>;
  femaleContent: Awaited<ReturnType<typeof getNumberContent>>;
  kundaliReferral: { enabled: boolean; url: string; label: string; note: string } | null;
  disclaimer: string;
  marriageDisclaimer: string;
}

export async function buildMarriageCompatibility(
  maleDob: string,
  femaleDob: string,
  locale: Locale,
): Promise<MarriageResponse> {
  const [rules, weights, notes] = await Promise.all([
    getMarriageRules(),
    getMarriageWeights(),
    getMarriageRuleNotes(),
  ]);

  const result = calculateMarriageCompatibility(maleDob, femaleDob, { rules, weights });
  const [maleContent, femaleContent, referral] = await Promise.all([
    getNumberContent(result.male.mulank, locale),
    getNumberContent(result.female.mulank, locale),
    getSetting<KundaliReferralSetting>('marriage.kundaliReferral'),
  ]);

  const directions = [result.maleToFemale, result.femaleToMale].map((direction) => ({
    direction: direction.direction,
    driverNumber: direction.driverNumber,
    targetMulank: direction.targetMulank,
    targetBhagyank: direction.targetBhagyank,
    matched: direction.matched,
    matchedVia: direction.matchedVia,
    viaNote: direction.matched ? messages.viaNote(locale, direction.matchedVia) : null,
    compatibleMulank: direction.compatibleMulank,
    compatibleBhagyank: direction.compatibleBhagyank,
    ruleMissing: direction.ruleMissing,
    note: notes[direction.driverNumber]?.[locale] ?? null,
  }));

  return {
    male: { dob: result.male.dob, mulank: result.male.mulank, bhagyank: result.male.bhagyank },
    female: { dob: result.female.dob, mulank: result.female.mulank, bhagyank: result.female.bhagyank },
    directions,
    verdict: result.verdict,
    verdictLabel: messages.verdictLabel(locale, result.verdict),
    matchedDirections: result.matchedDirections,
    score: result.score,
    summary: messages.marriageSummary(locale, result.verdict),
    reasons: result.reasons.map((reason) => messages.reason(locale, reason)),
    maleContent,
    femaleContent,
    // The referral is only ever an invitation to consult an astrologer; the app
    // never claims to perform Kundali matching itself.
    kundaliReferral: referral?.enabled
      ? {
          enabled: true,
          url: referral.url ?? '',
          label: referral.label?.[locale] ?? referral.label?.en ?? '',
          note: referral.note?.[locale] ?? referral.note?.en ?? '',
        }
      : null,
    disclaimer: messages.disclaimers(locale).general,
    marriageDisclaimer: messages.disclaimers(locale).marriage,
  };
}

export interface DailyNumberResponse {
  date: string;
  number: number;
  breakdown: ReturnType<typeof calculateDailyNumber>['breakdown'];
  insight: Awaited<ReturnType<typeof getDailyInsight>>;
  content: Awaited<ReturnType<typeof getNumberContent>>;
}

/**
 * Today's Lucky Number. The date is always supplied by the caller (the device
 * date, or the server date when absent) and never hard-coded, so the number
 * changes every day on its own.
 */
export async function buildDailyNumber(date: string | undefined, locale: Locale): Promise<DailyNumberResponse> {
  const daily = calculateDailyNumber(date ?? new Date());
  const [insight, content] = await Promise.all([
    getDailyInsight(daily.number, locale),
    getNumberContent(daily.number, locale),
  ]);
  return { date: daily.date, number: daily.number, breakdown: daily.breakdown, insight, content };
}

/** Mulank and Bhagyank only, used when saving a profile. */
export function coreNumbersFor(dob: string): { mulank: SingleDigit; bhagyank: SingleDigit } {
  const numbers = calculateCoreNumbersFromDob(dob);
  return { mulank: numbers.mulank, bhagyank: numbers.bhagyank };
}

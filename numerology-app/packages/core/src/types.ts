/**
 * Shared types for the numerology calculation engine.
 *
 * The engine is intentionally pure: it never talks to a database, a network or
 * a UI framework. Everything that an administrator can configure (compatibility
 * rules, Chaldean letter mapping, scoring weights) is passed in as data, so the
 * exact same code path runs on the server, in the admin panel preview and
 * offline inside the mobile app.
 */

/** A single digit numerology number. */
export type SingleDigit = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;

/** Locales supported by the product. */
export type Locale = 'en' | 'hi' | 'mr';

export const SUPPORTED_LOCALES: readonly Locale[] = ['en', 'hi', 'mr'] as const;
export const DEFAULT_LOCALE: Locale = 'en';

export const SINGLE_DIGITS: readonly SingleDigit[] = [1, 2, 3, 4, 5, 6, 7, 8, 9] as const;

/** A calendar date expressed without any timezone ambiguity. */
export interface DateParts {
  day: number;
  month: number;
  year: number;
}

/**
 * One step of a digit-sum reduction, kept so the UI can show users exactly how
 * a number was derived ("1+5+0+8+1+9+9+5 = 38 → 3+8 = 11 → 1+1 = 2").
 */
export interface ReductionStep {
  /** The digits that were added together in this step. */
  digits: number[];
  /** The sum of those digits. */
  sum: number;
  /** Human readable expression, e.g. "1 + 5 + 0 + 8 = 14". */
  expression: string;
}

export interface ReductionResult {
  /** The final value, reduced to a single digit (or a preserved master number). */
  value: number;
  /** The first sum produced by the reduction, before further reduction. */
  compound: number;
  /** Every reduction step, in order. */
  steps: ReductionStep[];
}

export interface CoreNumbers {
  mulank: SingleDigit;
  bhagyank: SingleDigit;
  mulankBreakdown: ReductionResult;
  bhagyankBreakdown: ReductionResult;
}

export interface NumberRootResult {
  /** The raw input exactly as the user typed it. */
  input: string;
  /** Only the digits that were kept for the calculation. */
  digits: number[];
  /** The sum of all digits before reduction (e.g. 45 for 9876543210). */
  compound: number;
  /** The reduced single digit root. */
  root: SingleDigit;
  breakdown: ReductionResult;
}

/** Chaldean letter -> value mapping. Keys are single uppercase A-Z letters. */
export type ChaldeanMap = Record<string, number>;

export interface ChaldeanLetter {
  letter: string;
  value: number;
  /** False when the character was skipped (unsupported character). */
  counted: boolean;
}

export interface ChaldeanNameResult {
  /** The name after trimming and whitespace normalisation. */
  name: string;
  letters: ChaldeanLetter[];
  /** The full sum of every letter value - never lose this number. */
  compound: number;
  /** The compound number reduced to a single digit. */
  root: SingleDigit;
  breakdown: ReductionResult;
  /** Characters that could not be mapped, so the UI can warn the user. */
  ignoredCharacters: string[];
}

/** Verdict for a single comparison between two numbers. */
export type MatchLevel = 'STRONG_MATCH' | 'GOOD_MATCH' | 'NEUTRAL' | 'WEAK_MATCH';

/** Verdict for the marriage compatibility engine. */
export type CompatibilityVerdict = 'STRONG_MATCH' | 'GOOD_MATCH' | 'NOT_MATCHED';

/**
 * A directional marriage compatibility rule.
 *
 * `driverNumber` is the Mulank of the person the rule is evaluated *from*. The
 * rule matches when the other person's Mulank appears in `compatibleMulank`
 * OR their Bhagyank appears in `compatibleBhagyank`.
 */
export interface MarriageRule {
  driverNumber: SingleDigit;
  compatibleMulank: number[];
  compatibleBhagyank: number[];
  enabled: boolean;
  /** Optional administrator supplied explanation shown on the result screen. */
  note?: string | null;
}

export interface DirectionResult {
  /** 'MALE_TO_FEMALE' evaluates the male Mulank rule against the female numbers. */
  direction: 'MALE_TO_FEMALE' | 'FEMALE_TO_MALE';
  /** The Mulank whose rule was evaluated. */
  driverNumber: SingleDigit;
  /** The other person's Mulank and Bhagyank. */
  targetMulank: SingleDigit;
  targetBhagyank: SingleDigit;
  matched: boolean;
  /** Which side of the rule produced the match. */
  matchedVia: 'MULANK' | 'BHAGYANK' | 'BOTH' | 'NONE';
  /** True when no enabled rule existed for `driverNumber`. */
  ruleMissing: boolean;
  compatibleMulank: number[];
  compatibleBhagyank: number[];
  note?: string | null;
}

export interface MarriageScoreWeights {
  /** Score awarded when a direction matches through the Mulank. */
  mulankMatch: number;
  /** Score awarded when a direction matches only through the Bhagyank. */
  bhagyankMatch: number;
}

export interface MarriageCompatibilityResult {
  /** Both partners' numbers, with the canonical ISO date they were derived from. */
  male: CoreNumbers & { dob: string };
  female: CoreNumbers & { dob: string };
  maleToFemale: DirectionResult;
  femaleToMale: DirectionResult;
  /** STRONG when both directions match, GOOD when exactly one does. */
  verdict: CompatibilityVerdict;
  /** Number of directions that matched (0, 1 or 2). */
  matchedDirections: number;
  /** Weighted score, 0-100, so the admin panel can tune the presentation. */
  score: number;
  /** Machine readable reasons; the API turns these into localised sentences. */
  reasons: CompatibilityReason[];
}

export interface CompatibilityReason {
  code:
    | 'BOTH_DIRECTIONS'
    | 'MALE_TO_FEMALE_ONLY'
    | 'FEMALE_TO_MALE_ONLY'
    | 'NO_DIRECTION'
    | 'RULE_MISSING';
  direction?: 'MALE_TO_FEMALE' | 'FEMALE_TO_MALE';
  via?: 'MULANK' | 'BHAGYANK' | 'BOTH' | 'NONE';
  /** Values interpolated into the localised message. */
  params: Record<string, string | number>;
}

/**
 * Configurable relationship between a base number and every other number, used
 * by the Lucky Number Finder.
 */
export interface NumberCompatibilityRule {
  baseNumber: SingleDigit;
  friendly: number[];
  neutral: number[];
  unfriendly: number[];
  enabled: boolean;
}

export interface AxisComparison {
  axis: 'MULANK' | 'BHAGYANK';
  axisValue: SingleDigit;
  level: MatchLevel;
  /** 0-2, used to derive the overall verdict. */
  points: number;
}

export interface NumberCompatibilityResult {
  root: SingleDigit;
  mulank: SingleDigit | null;
  bhagyank: SingleDigit | null;
  comparisons: AxisComparison[];
  overall: MatchLevel;
  /** 0-100 score for the progress ring on the result card. */
  score: number;
}

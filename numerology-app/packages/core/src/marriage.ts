import { calculateCoreNumbersFromDob } from './numbers';
import type {
  CompatibilityReason,
  CoreNumbers,
  DateParts,
  DirectionResult,
  MarriageCompatibilityResult,
  MarriageRule,
  MarriageScoreWeights,
  SingleDigit,
} from './types';

/**
 * The default rule table shipped with the product and seeded into the database.
 * Every row is editable from the admin panel; the engine never hard-codes them.
 *
 * A row reads: "someone whose Mulank is `driverNumber` matches a partner whose
 * Mulank is one of `compatibleMulank`, or whose Bhagyank is one of
 * `compatibleBhagyank`".
 */
export const DEFAULT_MARRIAGE_RULES: MarriageRule[] = [
  { driverNumber: 1, compatibleMulank: [1, 4, 7], compatibleBhagyank: [1, 4, 7], enabled: true },
  { driverNumber: 2, compatibleMulank: [2, 7], compatibleBhagyank: [2, 7], enabled: true },
  { driverNumber: 3, compatibleMulank: [3], compatibleBhagyank: [3], enabled: true },
  { driverNumber: 4, compatibleMulank: [1, 4], compatibleBhagyank: [1, 4], enabled: true },
  { driverNumber: 5, compatibleMulank: [5, 6], compatibleBhagyank: [5, 6], enabled: true },
  { driverNumber: 6, compatibleMulank: [5, 6, 9], compatibleBhagyank: [5, 6, 9], enabled: true },
  { driverNumber: 7, compatibleMulank: [1, 2, 7], compatibleBhagyank: [1, 2, 7], enabled: true },
  { driverNumber: 8, compatibleMulank: [1, 3, 5, 6], compatibleBhagyank: [1, 3, 5, 6], enabled: true },
  { driverNumber: 9, compatibleMulank: [6, 9], compatibleBhagyank: [6, 9], enabled: true },
];

export const DEFAULT_MARRIAGE_WEIGHTS: MarriageScoreWeights = {
  mulankMatch: 50,
  bhagyankMatch: 35,
};

function findRule(rules: MarriageRule[], driverNumber: SingleDigit): MarriageRule | undefined {
  return rules.find((rule) => rule.driverNumber === driverNumber && rule.enabled);
}

/**
 * Evaluates one direction of the compatibility check: the rule belonging to
 * `driver`'s Mulank is tested against `target`'s Mulank and Bhagyank.
 */
export function evaluateDirection(
  direction: DirectionResult['direction'],
  driver: Pick<CoreNumbers, 'mulank'>,
  target: Pick<CoreNumbers, 'mulank' | 'bhagyank'>,
  rules: MarriageRule[] = DEFAULT_MARRIAGE_RULES,
): DirectionResult {
  const rule = findRule(rules, driver.mulank);

  if (!rule) {
    return {
      direction,
      driverNumber: driver.mulank,
      targetMulank: target.mulank,
      targetBhagyank: target.bhagyank,
      matched: false,
      matchedVia: 'NONE',
      ruleMissing: true,
      compatibleMulank: [],
      compatibleBhagyank: [],
      note: null,
    };
  }

  const mulankMatch = rule.compatibleMulank.includes(target.mulank);
  const bhagyankMatch = rule.compatibleBhagyank.includes(target.bhagyank);
  const matchedVia: DirectionResult['matchedVia'] = mulankMatch && bhagyankMatch
    ? 'BOTH'
    : mulankMatch
      ? 'MULANK'
      : bhagyankMatch
        ? 'BHAGYANK'
        : 'NONE';

  return {
    direction,
    driverNumber: driver.mulank,
    targetMulank: target.mulank,
    targetBhagyank: target.bhagyank,
    matched: mulankMatch || bhagyankMatch,
    matchedVia,
    ruleMissing: false,
    compatibleMulank: [...rule.compatibleMulank],
    compatibleBhagyank: [...rule.compatibleBhagyank],
    note: rule.note ?? null,
  };
}

function directionScore(result: DirectionResult, weights: MarriageScoreWeights): number {
  if (!result.matched) return 0;
  // A Mulank match is the stronger signal; a Bhagyank-only match still counts.
  return result.matchedVia === 'BHAGYANK' ? weights.bhagyankMatch : weights.mulankMatch;
}

function buildReasons(
  maleToFemale: DirectionResult,
  femaleToMale: DirectionResult,
): CompatibilityReason[] {
  const reasons: CompatibilityReason[] = [];

  if (maleToFemale.ruleMissing || femaleToMale.ruleMissing) {
    reasons.push({
      code: 'RULE_MISSING',
      params: {
        male: maleToFemale.driverNumber,
        female: femaleToMale.driverNumber,
      },
    });
  }

  const params = {
    maleMulank: maleToFemale.driverNumber,
    maleBhagyank: femaleToMale.targetBhagyank,
    femaleMulank: femaleToMale.driverNumber,
    femaleBhagyank: maleToFemale.targetBhagyank,
  };

  if (maleToFemale.matched && femaleToMale.matched) {
    reasons.push({ code: 'BOTH_DIRECTIONS', params });
  } else if (maleToFemale.matched) {
    reasons.push({
      code: 'MALE_TO_FEMALE_ONLY',
      direction: 'MALE_TO_FEMALE',
      via: maleToFemale.matchedVia,
      params,
    });
  } else if (femaleToMale.matched) {
    reasons.push({
      code: 'FEMALE_TO_MALE_ONLY',
      direction: 'FEMALE_TO_MALE',
      via: femaleToMale.matchedVia,
      params,
    });
  } else {
    reasons.push({ code: 'NO_DIRECTION', params });
  }

  return reasons;
}

export interface MarriageCompatibilityOptions {
  rules?: MarriageRule[];
  weights?: MarriageScoreWeights;
  now?: Date;
}

/**
 * Marriage compatibility, evaluated in BOTH directions.
 *
 * The traditional tables are written from the man's Mulank outwards, but that
 * silently assumes the man's number is the only controlling one. This engine
 * runs the rule table twice - male -> female and female -> male - and grades
 * the outcome:
 *
 *   both directions match -> STRONG_MATCH
 *   exactly one matches   -> GOOD_MATCH
 *   neither matches       -> NOT_MATCHED
 */
export function calculateMarriageCompatibility(
  maleDob: string | Date | DateParts,
  femaleDob: string | Date | DateParts,
  options: MarriageCompatibilityOptions = {},
): MarriageCompatibilityResult {
  const rules = options.rules ?? DEFAULT_MARRIAGE_RULES;
  const weights = options.weights ?? DEFAULT_MARRIAGE_WEIGHTS;
  const now = options.now ?? new Date();

  const male = calculateCoreNumbersFromDob(maleDob, now);
  const female = calculateCoreNumbersFromDob(femaleDob, now);

  const maleToFemale = evaluateDirection('MALE_TO_FEMALE', male, female, rules);
  const femaleToMale = evaluateDirection('FEMALE_TO_MALE', female, male, rules);

  const matchedDirections = Number(maleToFemale.matched) + Number(femaleToMale.matched);
  const verdict = matchedDirections === 2
    ? 'STRONG_MATCH'
    : matchedDirections === 1
      ? 'GOOD_MATCH'
      : 'NOT_MATCHED';

  const rawScore = directionScore(maleToFemale, weights) + directionScore(femaleToMale, weights);
  const score = Math.max(0, Math.min(100, Math.round(rawScore)));

  return {
    male,
    female,
    maleToFemale,
    femaleToMale,
    verdict,
    matchedDirections,
    score,
    reasons: buildReasons(maleToFemale, femaleToMale),
  };
}

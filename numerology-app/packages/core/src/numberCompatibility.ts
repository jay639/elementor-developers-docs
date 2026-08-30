import type {
  AxisComparison,
  MatchLevel,
  NumberCompatibilityResult,
  NumberCompatibilityRule,
  SingleDigit,
} from './types';

/**
 * Default friendly / neutral / unfriendly relationships between the numbers
 * 1-9, seeded into `number_compatibility_rules` and editable by an administrator.
 * The Lucky Number Finder never hard-codes these relationships.
 */
export const DEFAULT_NUMBER_COMPATIBILITY_RULES: NumberCompatibilityRule[] = [
  { baseNumber: 1, friendly: [1, 2, 3, 5, 9], neutral: [4, 6, 7], unfriendly: [8], enabled: true },
  { baseNumber: 2, friendly: [1, 2, 5, 7], neutral: [3, 4, 6], unfriendly: [8, 9], enabled: true },
  { baseNumber: 3, friendly: [1, 3, 5, 6, 9], neutral: [2, 7, 8], unfriendly: [4], enabled: true },
  { baseNumber: 4, friendly: [1, 4, 5, 6, 7], neutral: [2, 8], unfriendly: [3, 9], enabled: true },
  { baseNumber: 5, friendly: [1, 3, 5, 6], neutral: [2, 4, 7, 8, 9], unfriendly: [], enabled: true },
  { baseNumber: 6, friendly: [3, 5, 6, 8, 9], neutral: [1, 4, 7], unfriendly: [2], enabled: true },
  { baseNumber: 7, friendly: [1, 2, 4, 7], neutral: [3, 5, 6, 8], unfriendly: [9], enabled: true },
  { baseNumber: 8, friendly: [3, 5, 6, 8], neutral: [2, 4, 7], unfriendly: [1, 9], enabled: true },
  { baseNumber: 9, friendly: [1, 3, 6, 9], neutral: [4, 5, 8], unfriendly: [2, 7], enabled: true },
];

const POINTS: Record<MatchLevel, number> = {
  STRONG_MATCH: 2,
  GOOD_MATCH: 2,
  NEUTRAL: 1,
  WEAK_MATCH: 0,
};

function compareAxis(
  axis: AxisComparison['axis'],
  axisValue: SingleDigit,
  root: SingleDigit,
  rules: NumberCompatibilityRule[],
): AxisComparison {
  const rule = rules.find((candidate) => candidate.baseNumber === axisValue && candidate.enabled);

  let level: MatchLevel = 'NEUTRAL';
  if (rule) {
    if (root === axisValue || rule.friendly.includes(root)) {
      level = 'STRONG_MATCH';
    } else if (rule.unfriendly.includes(root)) {
      level = 'WEAK_MATCH';
    } else {
      level = 'NEUTRAL';
    }
  }

  return { axis, axisValue, level, points: POINTS[level] };
}

export interface NumberCompatibilityOptions {
  rules?: NumberCompatibilityRule[];
}

/**
 * Compares the root of a user supplied number (vehicle, mobile, house...) with
 * the user's Mulank and Bhagyank.
 *
 * Both axes strong -> STRONG_MATCH, one strong -> GOOD_MATCH, otherwise the
 * combined score decides between NEUTRAL and WEAK_MATCH. When the user has no
 * saved date of birth the axes are simply omitted and the caller shows the
 * "add your date of birth" prompt.
 */
export function calculateNumberCompatibility(
  root: SingleDigit,
  mulank: SingleDigit | null,
  bhagyank: SingleDigit | null,
  options: NumberCompatibilityOptions = {},
): NumberCompatibilityResult {
  const rules = options.rules ?? DEFAULT_NUMBER_COMPATIBILITY_RULES;
  const comparisons: AxisComparison[] = [];

  if (mulank !== null) comparisons.push(compareAxis('MULANK', mulank, root, rules));
  if (bhagyank !== null) comparisons.push(compareAxis('BHAGYANK', bhagyank, root, rules));

  if (comparisons.length === 0) {
    return { root, mulank, bhagyank, comparisons, overall: 'NEUTRAL', score: 50 };
  }

  const strongCount = comparisons.filter((item) => item.level === 'STRONG_MATCH').length;
  const weakCount = comparisons.filter((item) => item.level === 'WEAK_MATCH').length;
  const totalPoints = comparisons.reduce((sum, item) => sum + item.points, 0);
  const maxPoints = comparisons.length * 2;

  let overall: MatchLevel;
  if (strongCount === comparisons.length) {
    overall = 'STRONG_MATCH';
  } else if (strongCount > 0) {
    overall = 'GOOD_MATCH';
  } else if (weakCount === comparisons.length) {
    overall = 'WEAK_MATCH';
  } else {
    overall = 'NEUTRAL';
  }

  return {
    root,
    mulank,
    bhagyank,
    comparisons,
    overall,
    score: Math.round((totalPoints / maxPoints) * 100),
  };
}

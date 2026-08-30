import { describe, expect, it } from 'vitest';
import {
  DEFAULT_NUMBER_COMPATIBILITY_RULES,
  calculateNumberCompatibility,
  calculateNumberRoot,
  type NumberCompatibilityRule,
  type SingleDigit,
} from '../index';

describe('the seeded number compatibility table', () => {
  it('classifies every number 1-9 exactly once for each base number', () => {
    for (const rule of DEFAULT_NUMBER_COMPATIBILITY_RULES) {
      const all = [...rule.friendly, ...rule.neutral, ...rule.unfriendly].sort((a, b) => a - b);
      expect(all).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    }
  });

  it('covers every base number', () => {
    expect(DEFAULT_NUMBER_COMPATIBILITY_RULES.map((r) => r.baseNumber)).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
  });
});

describe('calculateNumberCompatibility', () => {
  it('reports a strong match when both axes are friendly', () => {
    // Root 5 is friendly to both 1 and 3.
    const result = calculateNumberCompatibility(5, 1, 3);
    expect(result.overall).toBe('STRONG_MATCH');
    expect(result.score).toBe(100);
    expect(result.comparisons).toHaveLength(2);
  });

  it('reports a good match when only one axis is friendly', () => {
    // Root 8 is unfriendly to 1 but friendly to 6.
    const result = calculateNumberCompatibility(8, 1, 6);
    expect(result.overall).toBe('GOOD_MATCH');
    expect(result.comparisons[0]).toMatchObject({ axis: 'MULANK', level: 'WEAK_MATCH' });
    expect(result.comparisons[1]).toMatchObject({ axis: 'BHAGYANK', level: 'STRONG_MATCH' });
  });

  it('reports a weak match when both axes are unfriendly', () => {
    // Root 9 is unfriendly to both 2 and 8.
    const result = calculateNumberCompatibility(9, 2, 8);
    expect(result.overall).toBe('WEAK_MATCH');
    expect(result.score).toBe(0);
  });

  it('treats an identical number as a strong match', () => {
    const result = calculateNumberCompatibility(7, 7, 7);
    expect(result.overall).toBe('STRONG_MATCH');
  });

  it('works with only a mulank when no bhagyank is available', () => {
    const result = calculateNumberCompatibility(1, 1, null);
    expect(result.comparisons).toHaveLength(1);
    expect(result.overall).toBe('STRONG_MATCH');
  });

  it('stays neutral when the user has no date of birth', () => {
    const result = calculateNumberCompatibility(4, null, null);
    expect(result.comparisons).toHaveLength(0);
    expect(result.overall).toBe('NEUTRAL');
  });

  it('honours an administrator edited table', () => {
    const rules: NumberCompatibilityRule[] = DEFAULT_NUMBER_COMPATIBILITY_RULES.map((rule) =>
      rule.baseNumber === 1 ? { ...rule, friendly: [8], neutral: [1, 2, 3, 4, 5, 6, 7], unfriendly: [9] } : rule,
    );
    expect(calculateNumberCompatibility(8, 1, 1).overall).toBe('WEAK_MATCH');
    expect(calculateNumberCompatibility(8, 1, 1, { rules }).overall).toBe('STRONG_MATCH');
  });

  it('falls back to neutral when a rule is disabled', () => {
    const rules = DEFAULT_NUMBER_COMPATIBILITY_RULES.map((rule) =>
      rule.baseNumber === 2 ? { ...rule, enabled: false } : rule,
    );
    const result = calculateNumberCompatibility(9, 2, 2, { rules });
    expect(result.overall).toBe('NEUTRAL');
  });

  it('never throws for any combination', () => {
    for (let root = 1; root <= 9; root += 1) {
      for (let mulank = 1; mulank <= 9; mulank += 1) {
        for (let bhagyank = 1; bhagyank <= 9; bhagyank += 1) {
          const result = calculateNumberCompatibility(
            root as SingleDigit,
            mulank as SingleDigit,
            bhagyank as SingleDigit,
          );
          expect(result.score).toBeGreaterThanOrEqual(0);
          expect(result.score).toBeLessThanOrEqual(100);
        }
      }
    }
  });

  it('works end to end from a vehicle number', () => {
    // The worked example: DOB 15/08/1995 -> mulank 6, bhagyank 2; number 1234 -> root 1.
    const { root } = calculateNumberRoot('1234');
    const result = calculateNumberCompatibility(root, 6, 2);
    expect(root).toBe(1);
    expect(result.comparisons.map((c) => c.axis)).toEqual(['MULANK', 'BHAGYANK']);
  });
});

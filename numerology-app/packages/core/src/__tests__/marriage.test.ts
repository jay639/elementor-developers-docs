import { describe, expect, it } from 'vitest';
import {
  DEFAULT_MARRIAGE_RULES,
  calculateMarriageCompatibility,
  evaluateDirection,
  type MarriageRule,
  type SingleDigit,
} from '../index';

const NOW = new Date(2026, 7, 30);

/**
 * Builds a date of birth that produces the requested Mulank and Bhagyank, so the
 * rule table can be exercised for every combination without hand-picking dates.
 */
function dobFor(mulank: SingleDigit, bhagyank: SingleDigit): string {
  for (let year = 1950; year <= 2005; year += 1) {
    for (let month = 1; month <= 12; month += 1) {
      for (let day = 1; day <= 28; day += 1) {
        const dayRoot = ((day - 1) % 9) + 1;
        if (dayRoot !== mulank) continue;
        const digits = `${String(day).padStart(2, '0')}${String(month).padStart(2, '0')}${year}`
          .split('')
          .reduce((sum, char) => sum + Number(char), 0);
        const root = ((digits - 1) % 9) + 1;
        if (root === bhagyank) {
          return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        }
      }
    }
  }
  throw new Error(`No date of birth found for mulank ${mulank} / bhagyank ${bhagyank}`);
}

describe('dobFor helper', () => {
  it('produces dates with the requested numbers', () => {
    for (let mulank = 1; mulank <= 9; mulank += 1) {
      for (let bhagyank = 1; bhagyank <= 9; bhagyank += 1) {
        const dob = dobFor(mulank as SingleDigit, bhagyank as SingleDigit);
        const result = calculateMarriageCompatibility(dob, dob, { now: NOW });
        expect(result.male.mulank).toBe(mulank);
        expect(result.male.bhagyank).toBe(bhagyank);
      }
    }
  });
});

describe('the seeded rule table', () => {
  it('matches the rules given in the specification', () => {
    const table = Object.fromEntries(
      DEFAULT_MARRIAGE_RULES.map((rule) => [rule.driverNumber, rule.compatibleMulank]),
    );
    expect(table).toEqual({
      1: [1, 4, 7],
      2: [2, 7],
      3: [3],
      4: [1, 4],
      5: [5, 6],
      6: [5, 6, 9],
      7: [1, 2, 7],
      8: [1, 3, 5, 6],
      9: [6, 9],
    });
  });

  it('uses the same numbers for the Bhagyank side of every rule', () => {
    for (const rule of DEFAULT_MARRIAGE_RULES) {
      expect(rule.compatibleBhagyank).toEqual(rule.compatibleMulank);
    }
  });
});

describe('evaluateDirection', () => {
  it.each(DEFAULT_MARRIAGE_RULES)(
    'mulank $driverNumber matches every listed partner mulank',
    (rule) => {
      for (const partnerMulank of rule.compatibleMulank) {
        const result = evaluateDirection(
          'MALE_TO_FEMALE',
          { mulank: rule.driverNumber },
          // Bhagyank deliberately set to a number outside the rule where possible,
          // so the match can only come from the Mulank.
          { mulank: partnerMulank as SingleDigit, bhagyank: pickOutside(rule) },
          DEFAULT_MARRIAGE_RULES,
        );
        expect(result.matched).toBe(true);
        expect(result.matchedVia).toBe('MULANK');
      }
    },
  );

  it.each(DEFAULT_MARRIAGE_RULES)(
    'mulank $driverNumber matches through the partner bhagyank alone',
    (rule) => {
      for (const partnerBhagyank of rule.compatibleBhagyank) {
        const result = evaluateDirection(
          'MALE_TO_FEMALE',
          { mulank: rule.driverNumber },
          { mulank: pickOutside(rule), bhagyank: partnerBhagyank as SingleDigit },
          DEFAULT_MARRIAGE_RULES,
        );
        expect(result.matched).toBe(true);
        expect(result.matchedVia).toBe('BHAGYANK');
      }
    },
  );

  it.each(DEFAULT_MARRIAGE_RULES)(
    'mulank $driverNumber does not match numbers outside its rule',
    (rule) => {
      for (let n = 1; n <= 9; n += 1) {
        if (rule.compatibleMulank.includes(n) || rule.compatibleBhagyank.includes(n)) continue;
        const result = evaluateDirection(
          'MALE_TO_FEMALE',
          { mulank: rule.driverNumber },
          { mulank: n as SingleDigit, bhagyank: n as SingleDigit },
          DEFAULT_MARRIAGE_RULES,
        );
        expect(result.matched).toBe(false);
        expect(result.matchedVia).toBe('NONE');
      }
    },
  );

  it('reports BOTH when the mulank and the bhagyank both match', () => {
    const result = evaluateDirection(
      'MALE_TO_FEMALE',
      { mulank: 1 },
      { mulank: 4, bhagyank: 7 },
      DEFAULT_MARRIAGE_RULES,
    );
    expect(result.matchedVia).toBe('BOTH');
  });

  it('flags a missing rule instead of silently matching', () => {
    const result = evaluateDirection(
      'MALE_TO_FEMALE',
      { mulank: 5 },
      { mulank: 5, bhagyank: 5 },
      DEFAULT_MARRIAGE_RULES.filter((rule) => rule.driverNumber !== 5),
    );
    expect(result.ruleMissing).toBe(true);
    expect(result.matched).toBe(false);
  });

  it('treats a disabled rule as missing', () => {
    const rules: MarriageRule[] = DEFAULT_MARRIAGE_RULES.map((rule) =>
      rule.driverNumber === 3 ? { ...rule, enabled: false } : rule,
    );
    const result = evaluateDirection('MALE_TO_FEMALE', { mulank: 3 }, { mulank: 3, bhagyank: 3 }, rules);
    expect(result.ruleMissing).toBe(true);
  });
});

function pickOutside(rule: MarriageRule): SingleDigit {
  for (let n = 1; n <= 9; n += 1) {
    if (!rule.compatibleMulank.includes(n) && !rule.compatibleBhagyank.includes(n)) {
      return n as SingleDigit;
    }
  }
  throw new Error(`Rule ${rule.driverNumber} matches every number`);
}

describe('calculateMarriageCompatibility (bidirectional)', () => {
  it('returns STRONG_MATCH when both directions match', () => {
    // Male mulank 1, female mulank 1: rule 1 accepts 1 in both directions.
    const male = dobFor(1, 3);
    const female = dobFor(1, 5);
    const result = calculateMarriageCompatibility(male, female, { now: NOW });
    expect(result.maleToFemale.matched).toBe(true);
    expect(result.femaleToMale.matched).toBe(true);
    expect(result.matchedDirections).toBe(2);
    expect(result.verdict).toBe('STRONG_MATCH');
    expect(result.reasons[0]?.code).toBe('BOTH_DIRECTIONS');
  });

  it('returns GOOD_MATCH when only the male -> female direction matches', () => {
    // Male mulank 8 accepts female mulank 3; female mulank 3 only accepts 3.
    const male = dobFor(8, 8);
    const female = dobFor(3, 4);
    const result = calculateMarriageCompatibility(male, female, { now: NOW });
    expect(result.maleToFemale.matched).toBe(true);
    expect(result.femaleToMale.matched).toBe(false);
    expect(result.verdict).toBe('GOOD_MATCH');
    expect(result.reasons[0]?.code).toBe('MALE_TO_FEMALE_ONLY');
  });

  it('returns GOOD_MATCH when only the female -> male direction matches', () => {
    // Female mulank 8 accepts male mulank 3; male mulank 3 only accepts 3.
    const male = dobFor(3, 4);
    const female = dobFor(8, 8);
    const result = calculateMarriageCompatibility(male, female, { now: NOW });
    expect(result.maleToFemale.matched).toBe(false);
    expect(result.femaleToMale.matched).toBe(true);
    expect(result.verdict).toBe('GOOD_MATCH');
    expect(result.reasons[0]?.code).toBe('FEMALE_TO_MALE_ONLY');
  });

  it('does not assume the male mulank is the only controlling number', () => {
    const male = dobFor(3, 4);
    const female = dobFor(8, 8);
    const forward = calculateMarriageCompatibility(male, female, { now: NOW });
    const reverse = calculateMarriageCompatibility(female, male, { now: NOW });
    // The same pair produces the same verdict whichever way round it is entered.
    expect(forward.verdict).toBe(reverse.verdict);
    expect(forward.matchedDirections).toBe(reverse.matchedDirections);
  });

  it('returns NOT_MATCHED when neither direction matches', () => {
    // Mulank 3 only accepts 3; mulank 2 only accepts 2 and 7.
    const male = dobFor(3, 4);
    const female = dobFor(2, 5);
    const result = calculateMarriageCompatibility(male, female, { now: NOW });
    expect(result.verdict).toBe('NOT_MATCHED');
    expect(result.matchedDirections).toBe(0);
    expect(result.score).toBe(0);
    expect(result.reasons[0]?.code).toBe('NO_DIRECTION');
  });

  it('explains a bhagyank-only match explicitly', () => {
    // Male mulank 3 rejects female mulank 5 but accepts female bhagyank 3.
    const male = dobFor(3, 7);
    const female = dobFor(5, 3);
    const result = calculateMarriageCompatibility(male, female, { now: NOW });
    expect(result.maleToFemale.matched).toBe(true);
    expect(result.maleToFemale.matchedVia).toBe('BHAGYANK');
  });

  it('scores a double mulank match higher than a bhagyank-only match', () => {
    const strong = calculateMarriageCompatibility(dobFor(1, 3), dobFor(1, 5), { now: NOW });
    const partial = calculateMarriageCompatibility(dobFor(3, 7), dobFor(5, 3), { now: NOW });
    expect(strong.score).toBeGreaterThan(partial.score);
    expect(strong.score).toBeLessThanOrEqual(100);
  });

  it('exposes both partners numbers for the result screen', () => {
    const result = calculateMarriageCompatibility('1995-08-15', '1990-01-01', { now: NOW });
    expect(result.male.mulank).toBe(6);
    expect(result.male.bhagyank).toBe(2);
    expect(result.female.mulank).toBe(1);
    expect(result.female.bhagyank).toBe(3);
  });

  it('validates both dates of birth', () => {
    expect(() => calculateMarriageCompatibility('2030-01-01', '1995-08-15', { now: NOW })).toThrow();
    expect(() => calculateMarriageCompatibility('1995-08-15', '1995-02-30', { now: NOW })).toThrow();
  });

  it('honours an administrator edited rule table', () => {
    const rules: MarriageRule[] = DEFAULT_MARRIAGE_RULES.map((rule) =>
      rule.driverNumber === 3 ? { ...rule, compatibleMulank: [2, 3], compatibleBhagyank: [2, 3] } : rule,
    );
    const male = dobFor(3, 4);
    const female = dobFor(2, 5);
    expect(calculateMarriageCompatibility(male, female, { now: NOW }).verdict).toBe('NOT_MATCHED');
    expect(calculateMarriageCompatibility(male, female, { now: NOW, rules }).verdict).toBe('GOOD_MATCH');
  });

  it('covers every mulank pair without throwing', () => {
    for (let m = 1; m <= 9; m += 1) {
      for (let f = 1; f <= 9; f += 1) {
        const result = calculateMarriageCompatibility(
          dobFor(m as SingleDigit, 1),
          dobFor(f as SingleDigit, 1),
          { now: NOW },
        );
        expect(['STRONG_MATCH', 'GOOD_MATCH', 'NOT_MATCHED']).toContain(result.verdict);
        expect(result.matchedDirections).toBe(
          Number(result.maleToFemale.matched) + Number(result.femaleToMale.matched),
        );
      }
    }
  });
});

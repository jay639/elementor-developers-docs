import { describe, expect, it } from 'vitest';
import {
  MAX_NUMBER_DIGITS,
  NumerologyError,
  calculateBhagyank,
  calculateCoreNumbers,
  calculateCoreNumbersFromDob,
  calculateDailyNumber,
  calculateMulank,
  calculateNumberRoot,
  extractDigits,
  reduceToSingleDigit,
} from '../index';

describe('reduceToSingleDigit', () => {
  it('leaves single digits untouched', () => {
    for (let n = 1; n <= 9; n += 1) {
      expect(reduceToSingleDigit(n)).toBe(n);
    }
  });

  it('reduces repeatedly until a single digit remains', () => {
    expect(reduceToSingleDigit(29)).toBe(2); // 2+9=11 -> 1+1=2
    expect(reduceToSingleDigit(999)).toBe(9); // 27 -> 9
    expect(reduceToSingleDigit(1234567890)).toBe(9);
  });

  it('optionally preserves master numbers', () => {
    expect(reduceToSingleDigit(29, { keepMasterNumbers: true })).toBe(11);
    expect(reduceToSingleDigit(29)).toBe(2);
  });
});

describe('calculateMulank', () => {
  // The full 1-31 table from the product specification.
  const expected: Record<number, number> = {
    1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9,
    10: 1, 11: 2, 12: 3, 13: 4, 14: 5, 15: 6, 16: 7, 17: 8, 18: 9,
    19: 1, 20: 2, 21: 3, 22: 4, 23: 5, 24: 6, 25: 7, 26: 8, 27: 9,
    28: 1, 29: 2, 30: 3, 31: 4,
  };

  it.each(Object.entries(expected))('day %s -> mulank %s', (day, mulank) => {
    // January has 31 days, so every day in the table is a real date.
    expect(calculateMulank({ day: Number(day), month: 1, year: 1990 })).toBe(mulank);
  });

  it('accepts every supported date format', () => {
    expect(calculateMulank('1995-08-15')).toBe(6);
    expect(calculateMulank('15/08/1995')).toBe(6);
    expect(calculateMulank('15-08-1995')).toBe(6);
    expect(calculateMulank('15.08.1995')).toBe(6);
    expect(calculateMulank(new Date(1995, 7, 15))).toBe(6);
  });
});

describe('calculateBhagyank', () => {
  it('matches the worked example from the specification', () => {
    // 1+5+0+8+1+9+9+5 = 38 -> 3+8 = 11 -> 1+1 = 2
    expect(calculateBhagyank('1995-08-15')).toBe(2);
  });

  it('handles single digit days and months', () => {
    // 05/07/2001 -> 0+5+0+7+2+0+0+1 = 15 -> 6
    expect(calculateBhagyank('2001-07-05')).toBe(6);
  });

  it('handles leap day birthdays', () => {
    // 29/02/2000 -> 2+9+0+2+2+0+0+0 = 15 -> 6
    expect(calculateBhagyank('2000-02-29')).toBe(6);
    expect(calculateMulank('2000-02-29')).toBe(2);
  });

  it('shows the full working', () => {
    const { bhagyankBreakdown } = calculateCoreNumbers('1995-08-15');
    expect(bhagyankBreakdown.compound).toBe(38);
    expect(bhagyankBreakdown.steps.map((step) => step.expression)).toEqual([
      '1 + 5 + 0 + 8 + 1 + 9 + 9 + 5 = 38',
      '3 + 8 = 11',
      '1 + 1 = 2',
    ]);
  });
});

describe('calculateCoreNumbersFromDob', () => {
  const now = new Date(2026, 7, 30);

  it('returns the canonical ISO date alongside the numbers', () => {
    const result = calculateCoreNumbersFromDob('15/08/1995', now);
    expect(result).toMatchObject({ dob: '1995-08-15', mulank: 6, bhagyank: 2 });
  });

  it('rejects impossible dates', () => {
    expect(() => calculateCoreNumbersFromDob('2023-02-30', now)).toThrow(NumerologyError);
    expect(() => calculateCoreNumbersFromDob('2023-13-01', now)).toThrow(/not a real calendar date/);
    expect(() => calculateCoreNumbersFromDob('1999-02-29', now)).toThrow(NumerologyError);
    expect(() => calculateCoreNumbersFromDob('not a date', now)).toThrow(/Unrecognised date format/);
  });

  it('accepts 29 February in a leap year', () => {
    expect(() => calculateCoreNumbersFromDob('2000-02-29', now)).not.toThrow();
    expect(() => calculateCoreNumbersFromDob('2024-02-29', now)).not.toThrow();
  });

  it('rejects future dates', () => {
    expect(() => calculateCoreNumbersFromDob('2026-08-31', now)).toThrow(/cannot be in the future/);
    expect(() => calculateCoreNumbersFromDob('2026-08-30', now)).not.toThrow();
  });

  it('rejects dates before 1900', () => {
    expect(() => calculateCoreNumbersFromDob('1899-12-31', now)).toThrow(/1900/);
  });
});

describe('calculateNumberRoot', () => {
  it('reduces a plain number', () => {
    const result = calculateNumberRoot('1234');
    expect(result.compound).toBe(10);
    expect(result.root).toBe(1);
  });

  it('reduces a mobile number', () => {
    const result = calculateNumberRoot('9876543210');
    expect(result.compound).toBe(45);
    expect(result.root).toBe(9);
  });

  it('strips letters, spaces and separators from a vehicle number', () => {
    const result = calculateNumberRoot('MH-31-AB-1234');
    expect(result.digits).toEqual([3, 1, 1, 2, 3, 4]);
    expect(result.compound).toBe(14);
    expect(result.root).toBe(5);
  });

  it('accepts formatted mobile numbers', () => {
    // Separators are ignored, so the formatting a user types never changes the root.
    expect(calculateNumberRoot('98765 43210').root).toBe(9);
    expect(calculateNumberRoot('98765-43210').root).toBe(9);
    // A country code contributes its own digits: 9 + 1 + 45 = 55 -> 10 -> 1.
    expect(calculateNumberRoot('+91 98765 43210').root).toBe(1);
  });

  it('accepts numeric input', () => {
    expect(calculateNumberRoot(1234).root).toBe(1);
  });

  it('rejects empty input', () => {
    expect(() => calculateNumberRoot('')).toThrow(/enter a number/);
    expect(() => calculateNumberRoot('   ')).toThrow(/enter a number/);
  });

  it('rejects input without digits', () => {
    expect(() => calculateNumberRoot('ABCD')).toThrow(/does not contain any digits/);
    expect(() => calculateNumberRoot('###')).toThrow(/does not contain any digits/);
  });

  it('rejects a number that is too long', () => {
    expect(() => calculateNumberRoot('1'.repeat(MAX_NUMBER_DIGITS + 1))).toThrow(/at most/);
    expect(() => calculateNumberRoot('1'.repeat(MAX_NUMBER_DIGITS))).not.toThrow();
  });

  it('rejects a number that reduces to zero', () => {
    expect(() => calculateNumberRoot('0000')).toThrow(/between 1 and 9/);
  });

  it('records the calculation breakdown', () => {
    const result = calculateNumberRoot('1234');
    expect(result.breakdown.steps.map((step) => step.expression)).toEqual([
      '1 + 2 + 3 + 4 = 10',
      '1 + 0 = 1',
    ]);
  });
});

describe('extractDigits', () => {
  it('keeps only 0-9', () => {
    expect(extractDigits('MH 31 AB 1234')).toEqual([3, 1, 1, 2, 3, 4]);
    expect(extractDigits('अ1ब2')).toEqual([1, 2]);
  });
});

describe("calculateDailyNumber", () => {
  it('matches the worked example from the specification', () => {
    // 31/08/2026 -> 3+1+0+8+2+0+2+6 = 22 -> 2+2 = 4
    const result = calculateDailyNumber(new Date(2026, 7, 31));
    expect(result.number).toBe(4);
    expect(result.date).toBe('2026-08-31');
    expect(result.breakdown.compound).toBe(22);
  });

  it('changes from one day to the next', () => {
    const first = calculateDailyNumber(new Date(2026, 7, 30));
    const second = calculateDailyNumber(new Date(2026, 7, 31));
    expect(first.number).not.toBe(second.number);
  });

  it('is derived from the supplied date, never hard-coded', () => {
    expect(calculateDailyNumber('2024-01-01').number).toBe(1); // 0+1+0+1+2+0+2+4 = 10 -> 1
    expect(calculateDailyNumber('2026-08-31').number).toBe(4);
  });
});

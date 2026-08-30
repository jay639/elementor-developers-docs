import { describe, expect, it } from 'vitest';
import {
  ageInYears,
  daysInMonth,
  formatISODate,
  isLeapYear,
  isValidDateParts,
  parseDate,
  parseDateOfBirth,
} from '../index';

describe('isLeapYear', () => {
  it('follows the Gregorian rules', () => {
    expect(isLeapYear(2024)).toBe(true);
    expect(isLeapYear(2023)).toBe(false);
    expect(isLeapYear(1900)).toBe(false);
    expect(isLeapYear(2000)).toBe(true);
  });
});

describe('daysInMonth', () => {
  it('handles February in leap and common years', () => {
    expect(daysInMonth(2, 2024)).toBe(29);
    expect(daysInMonth(2, 2023)).toBe(28);
    expect(daysInMonth(4, 2023)).toBe(30);
    expect(daysInMonth(12, 2023)).toBe(31);
  });
});

describe('isValidDateParts', () => {
  it('rejects impossible dates', () => {
    expect(isValidDateParts({ day: 31, month: 4, year: 2023 })).toBe(false);
    expect(isValidDateParts({ day: 29, month: 2, year: 2023 })).toBe(false);
    expect(isValidDateParts({ day: 29, month: 2, year: 2024 })).toBe(true);
    expect(isValidDateParts({ day: 0, month: 1, year: 2023 })).toBe(false);
    expect(isValidDateParts({ day: 1, month: 13, year: 2023 })).toBe(false);
    expect(isValidDateParts({ day: 1.5, month: 1, year: 2023 })).toBe(false);
  });
});

describe('parseDate', () => {
  it('never shifts a date across a timezone boundary', () => {
    expect(parseDate('1995-08-15')).toEqual({ day: 15, month: 8, year: 1995 });
    expect(formatISODate(parseDate('15/08/1995'))).toBe('1995-08-15');
  });

  it('rejects a rubbish value', () => {
    expect(() => parseDate('15/08/95')).toThrow(/Unrecognised/);
    expect(() => parseDate('')).toThrow(/Unrecognised/);
    expect(() => parseDate(new Date('nonsense'))).toThrow(/invalid Date/);
  });
});

describe('parseDateOfBirth', () => {
  const now = new Date(2026, 7, 30);

  it('accepts today', () => {
    expect(() => parseDateOfBirth('2026-08-30', now)).not.toThrow();
  });

  it('rejects tomorrow', () => {
    expect(() => parseDateOfBirth('2026-08-31', now)).toThrow(/future/);
  });
});

describe('ageInYears', () => {
  const now = new Date(2026, 7, 30);

  it('counts whole years only', () => {
    expect(ageInYears({ day: 15, month: 8, year: 1995 }, now)).toBe(31);
    expect(ageInYears({ day: 31, month: 8, year: 1995 }, now)).toBe(30);
  });
});

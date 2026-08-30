import { formatISODate, parseDate, parseDateOfBirth, todayParts } from './dates';
import { NumerologyError } from './errors';
import { reduceDigits, reduceToSingleDigitStrict, toDigits } from './reduce';
import type { CoreNumbers, DateParts, NumberRootResult, ReductionResult, SingleDigit } from './types';

/** Maximum number of digits accepted by the Lucky Number Finder. */
export const MAX_NUMBER_DIGITS = 32;

/**
 * Mulank (Driver Number) is derived from the DAY of birth only.
 * 15 -> 1 + 5 = 6, 29 -> 2 + 9 = 11 -> 1 + 1 = 2.
 */
export function calculateMulank(dob: string | Date | DateParts): SingleDigit {
  const parts = parseDate(dob);
  return reduceToSingleDigitStrict(parts.day);
}

export function calculateMulankBreakdown(dob: string | Date | DateParts): ReductionResult {
  const parts = parseDate(dob);
  return reduceDigits(toDigits(parts.day));
}

/**
 * Bhagyank (Conductor Number) uses every digit of the complete date of birth.
 * 15/08/1995 -> 1+5+0+8+1+9+9+5 = 38 -> 3+8 = 11 -> 1+1 = 2.
 */
export function calculateBhagyank(dob: string | Date | DateParts): SingleDigit {
  return calculateBhagyankBreakdown(dob).value as SingleDigit;
}

export function calculateBhagyankBreakdown(dob: string | Date | DateParts): ReductionResult {
  const parts = parseDate(dob);
  // Day and month are zero padded so the working shown to the user matches the
  // way the date is written down: 15/08/1995 -> 1 + 5 + 0 + 8 + 1 + 9 + 9 + 5.
  const digits = [
    String(parts.day).padStart(2, '0'),
    String(parts.month).padStart(2, '0'),
    String(parts.year).padStart(4, '0'),
  ]
    .join('')
    .split('')
    .map(Number);
  return reduceDigits(digits);
}

/** Mulank + Bhagyank together, with the full working shown for both. */
export function calculateCoreNumbers(dob: string | Date | DateParts): CoreNumbers {
  const parts = parseDate(dob);
  const mulankBreakdown = calculateMulankBreakdown(parts);
  const bhagyankBreakdown = calculateBhagyankBreakdown(parts);
  return {
    mulank: mulankBreakdown.value as SingleDigit,
    bhagyank: bhagyankBreakdown.value as SingleDigit,
    mulankBreakdown,
    bhagyankBreakdown,
  };
}

/** Validates a date of birth and returns the derived numbers in one call. */
export function calculateCoreNumbersFromDob(
  dob: string | Date | DateParts,
  now: Date = new Date(),
): CoreNumbers & { dob: string } {
  const parts = parseDateOfBirth(dob, now);
  return { ...calculateCoreNumbers(parts), dob: formatISODate(parts) };
}

/**
 * Extracts the digits from any user supplied number. Spaces, hyphens, dots and
 * letters (e.g. "MH-31-AB-1234") are ignored; only 0-9 is kept.
 */
export function extractDigits(input: string): number[] {
  return String(input)
    .split('')
    .filter((char) => char >= '0' && char <= '9')
    .map(Number);
}

/**
 * Root number for a vehicle number, mobile number, house number or any other
 * user supplied value.
 */
export function calculateNumberRoot(input: string | number): NumberRootResult {
  const raw = String(input ?? '');
  if (raw.trim().length === 0) {
    throw new NumerologyError('EMPTY_NUMBER', 'Please enter a number.');
  }
  const digits = extractDigits(raw);
  if (digits.length === 0) {
    throw new NumerologyError('NO_DIGITS', 'The value you entered does not contain any digits.');
  }
  if (digits.length > MAX_NUMBER_DIGITS) {
    throw new NumerologyError(
      'NUMBER_TOO_LONG',
      `Please enter at most ${MAX_NUMBER_DIGITS} digits.`,
    );
  }
  const breakdown = reduceDigits(digits);
  if (breakdown.value < 1) {
    throw new NumerologyError('NO_DIGITS', 'This number does not reduce to a value between 1 and 9.');
  }
  return {
    input: raw.trim(),
    digits,
    compound: breakdown.compound,
    root: breakdown.value as SingleDigit,
    breakdown,
  };
}

export interface DailyNumberResult {
  date: string;
  parts: DateParts;
  number: SingleDigit;
  breakdown: ReductionResult;
}

/**
 * Today's Lucky Number: every digit of the current date reduced to 1-9.
 * 31/08/2026 -> 3+1+0+8+2+0+2+6 = 22 -> 2+2 = 4.
 */
export function calculateDailyNumber(date: string | Date | DateParts = new Date()): DailyNumberResult {
  const parts = date instanceof Date ? todayParts(date) : parseDate(date);
  const breakdown = calculateBhagyankBreakdown(parts);
  return {
    date: formatISODate(parts),
    parts,
    number: breakdown.value as SingleDigit,
    breakdown,
  };
}

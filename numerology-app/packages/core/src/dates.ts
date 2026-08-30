import { NumerologyError } from './errors';
import type { DateParts } from './types';

/** The earliest date of birth accepted by the product. */
export const MIN_BIRTH_YEAR = 1900;

const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;
const DMY_DATE = /^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})$/;

export function isLeapYear(year: number): boolean {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

export function daysInMonth(month: number, year: number): number {
  const lengths = [31, isLeapYear(year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return lengths[month - 1] ?? 0;
}

/** True when day/month/year describe a real calendar date. */
export function isValidDateParts(parts: DateParts): boolean {
  const { day, month, year } = parts;
  if (!Number.isInteger(day) || !Number.isInteger(month) || !Number.isInteger(year)) return false;
  if (month < 1 || month > 12) return false;
  if (year < 1 || year > 9999) return false;
  if (day < 1 || day > daysInMonth(month, year)) return false;
  return true;
}

/**
 * Accepts `YYYY-MM-DD`, `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`, a `Date`, or an
 * already parsed {@link DateParts} object. Dates are treated as plain calendar
 * dates: no timezone conversion ever happens, so a birthday never shifts by a day.
 */
export function parseDate(input: string | Date | DateParts): DateParts {
  if (input instanceof Date) {
    if (Number.isNaN(input.getTime())) {
      throw new NumerologyError('INVALID_DATE', 'Received an invalid Date object.');
    }
    return { day: input.getDate(), month: input.getMonth() + 1, year: input.getFullYear() };
  }

  if (typeof input === 'object' && input !== null) {
    if (!isValidDateParts(input)) {
      throw new NumerologyError('INVALID_DATE', 'The supplied date is not a real calendar date.');
    }
    return { day: input.day, month: input.month, year: input.year };
  }

  const value = String(input).trim();
  let parts: DateParts | null = null;

  const iso = ISO_DATE.exec(value);
  if (iso) {
    parts = { year: Number(iso[1]), month: Number(iso[2]), day: Number(iso[3]) };
  } else {
    const dmy = DMY_DATE.exec(value);
    if (dmy) {
      parts = { day: Number(dmy[1]), month: Number(dmy[2]), year: Number(dmy[3]) };
    }
  }

  if (!parts) {
    throw new NumerologyError('INVALID_DATE', `Unrecognised date format: "${value}".`);
  }
  if (!isValidDateParts(parts)) {
    throw new NumerologyError('INVALID_DATE', `"${value}" is not a real calendar date.`);
  }
  return parts;
}

/** Formats parts back to the canonical storage format `YYYY-MM-DD`. */
export function formatISODate(parts: DateParts): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${String(parts.year).padStart(4, '0')}-${pad(parts.month)}-${pad(parts.day)}`;
}

/** Today's calendar date in the runtime's local timezone. */
export function todayParts(now: Date = new Date()): DateParts {
  return { day: now.getDate(), month: now.getMonth() + 1, year: now.getFullYear() };
}

function compareParts(a: DateParts, b: DateParts): number {
  if (a.year !== b.year) return a.year - b.year;
  if (a.month !== b.month) return a.month - b.month;
  return a.day - b.day;
}

/**
 * Validates a date of birth: it must be a real date, not in the future and not
 * absurdly far in the past.
 */
export function parseDateOfBirth(input: string | Date | DateParts, now: Date = new Date()): DateParts {
  const parts = parseDate(input);
  if (parts.year < MIN_BIRTH_YEAR) {
    throw new NumerologyError('DATE_TOO_OLD', `Dates before ${MIN_BIRTH_YEAR} are not supported.`);
  }
  if (compareParts(parts, todayParts(now)) > 0) {
    throw new NumerologyError('FUTURE_DATE', 'A date of birth cannot be in the future.');
  }
  return parts;
}

/** Age in whole years, used for analytics buckets only. */
export function ageInYears(dob: DateParts, now: Date = new Date()): number {
  const today = todayParts(now);
  let age = today.year - dob.year;
  if (today.month < dob.month || (today.month === dob.month && today.day < dob.day)) {
    age -= 1;
  }
  return age;
}

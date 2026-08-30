import { NumerologyError } from './errors';
import type { ReductionResult, ReductionStep, SingleDigit } from './types';

const isSingleDigit = (value: number): value is SingleDigit => value >= 1 && value <= 9;

/** Splits a non-negative integer into its decimal digits. */
export function toDigits(value: number): number[] {
  const normalised = Math.abs(Math.trunc(value));
  return String(normalised)
    .split('')
    .map((char) => Number(char));
}

function buildStep(digits: number[]): ReductionStep {
  const sum = digits.reduce((total, digit) => total + digit, 0);
  return {
    digits: [...digits],
    sum,
    expression: `${digits.join(' + ')} = ${sum}`,
  };
}

export interface ReduceOptions {
  /**
   * Master numbers (11, 22, 33) are preserved by some numerology traditions.
   * The Indian Mulank/Bhagyank system used by this product always reduces to a
   * single digit, so this defaults to false and is exposed only so future
   * modules can opt in without forking the engine.
   */
  keepMasterNumbers?: boolean;
}

const MASTER_NUMBERS = new Set([11, 22, 33]);

/**
 * Reduces a list of digits to a single digit, recording every intermediate step.
 */
export function reduceDigits(digits: number[], options: ReduceOptions = {}): ReductionResult {
  if (digits.length === 0) {
    throw new NumerologyError('NO_DIGITS', 'Cannot reduce an empty list of digits.');
  }

  const steps: ReductionStep[] = [];
  let current = digits;
  let firstStep = buildStep(current);
  steps.push(firstStep);
  let value = firstStep.sum;
  const compound = firstStep.sum;

  while (value > 9) {
    if (options.keepMasterNumbers && MASTER_NUMBERS.has(value)) {
      break;
    }
    current = toDigits(value);
    const step = buildStep(current);
    steps.push(step);
    value = step.sum;
  }

  return { value, compound, steps };
}

/**
 * Repeatedly adds the digits of `value` until a single digit remains.
 * `reduceToSingleDigit(29)` -> 2 (2 + 9 = 11 -> 1 + 1 = 2).
 */
export function reduceToSingleDigit(value: number, options: ReduceOptions = {}): number {
  return reduceDigits(toDigits(value), options).value;
}

/**
 * Same as {@link reduceToSingleDigit} but narrows the result to 1-9. Throws when
 * the input reduces to 0, which only happens for the number 0 itself.
 */
export function reduceToSingleDigitStrict(value: number): SingleDigit {
  const reduced = reduceToSingleDigit(value);
  if (!isSingleDigit(reduced)) {
    throw new NumerologyError('NO_DIGITS', `Value ${value} does not reduce to a number between 1 and 9.`);
  }
  return reduced;
}

export { isSingleDigit };

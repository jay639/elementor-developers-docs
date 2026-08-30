import { NumerologyError } from './errors';
import { reduceDigits } from './reduce';
import type { ChaldeanLetter, ChaldeanMap, ChaldeanNameResult, SingleDigit } from './types';

export const MAX_NAME_LENGTH = 80;

/**
 * The standard Chaldean mapping. There is no letter assigned to 9 in the
 * traditional Chaldean system - that is intentional, not an omission.
 * Administrators can override this table from the admin panel; it is only the
 * fallback used when the app runs offline before the first sync.
 */
export const DEFAULT_CHALDEAN_GROUPS: Record<number, string[]> = {
  1: ['A', 'I', 'J', 'Q', 'Y'],
  2: ['B', 'K', 'R'],
  3: ['C', 'G', 'L', 'S'],
  4: ['D', 'M', 'T'],
  5: ['E', 'H', 'N', 'X'],
  6: ['U', 'V', 'W'],
  7: ['O', 'Z'],
  8: ['F', 'P'],
  9: [],
};

/** Expands a value -> letters table into the flat letter -> value map. */
export function buildChaldeanMap(groups: Record<number, string[]> = DEFAULT_CHALDEAN_GROUPS): ChaldeanMap {
  const map: ChaldeanMap = {};
  for (const [value, letters] of Object.entries(groups)) {
    for (const letter of letters) {
      map[letter.toUpperCase()] = Number(value);
    }
  }
  return map;
}

export const DEFAULT_CHALDEAN_MAP: ChaldeanMap = buildChaldeanMap();

/** Trims, collapses repeated spaces and uppercases a name for calculation. */
export function normaliseName(name: string): string {
  return String(name ?? '')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Calculates the Chaldean value of a name.
 *
 * Both numbers are returned and stored: the compound number (the raw total,
 * e.g. 17 for RAHUL) carries meaning of its own and must never be discarded,
 * and the root number is the compound reduced to a single digit (17 -> 8).
 */
export function calculateChaldeanName(
  name: string,
  map: ChaldeanMap = DEFAULT_CHALDEAN_MAP,
): ChaldeanNameResult {
  const normalised = normaliseName(name);
  if (normalised.length === 0) {
    throw new NumerologyError('EMPTY_NAME', 'Please enter a name.');
  }
  if (normalised.length > MAX_NAME_LENGTH) {
    throw new NumerologyError('NAME_TOO_LONG', `Please enter at most ${MAX_NAME_LENGTH} characters.`);
  }

  const letters: ChaldeanLetter[] = [];
  const ignoredCharacters: string[] = [];
  const values: number[] = [];

  for (const character of normalised) {
    const upper = character.toUpperCase();
    const value = map[upper];
    if (typeof value === 'number') {
      letters.push({ letter: upper, value, counted: true });
      values.push(value);
    } else {
      letters.push({ letter: character, value: 0, counted: false });
      if (character.trim().length > 0) {
        ignoredCharacters.push(character);
      }
    }
  }

  if (values.length === 0) {
    throw new NumerologyError(
      'NO_MAPPABLE_LETTERS',
      'None of the characters in this name are part of the Chaldean system.',
    );
  }

  const breakdown = reduceDigits(values);
  return {
    name: normalised,
    letters,
    compound: breakdown.compound,
    root: breakdown.value as SingleDigit,
    breakdown,
    ignoredCharacters: [...new Set(ignoredCharacters)],
  };
}

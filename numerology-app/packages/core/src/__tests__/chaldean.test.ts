import { describe, expect, it } from 'vitest';
import {
  DEFAULT_CHALDEAN_GROUPS,
  DEFAULT_CHALDEAN_MAP,
  MAX_NAME_LENGTH,
  NumerologyError,
  buildChaldeanMap,
  calculateChaldeanName,
  normaliseName,
} from '../index';

describe('Chaldean mapping', () => {
  it('matches the standard table', () => {
    expect(DEFAULT_CHALDEAN_GROUPS).toEqual({
      1: ['A', 'I', 'J', 'Q', 'Y'],
      2: ['B', 'K', 'R'],
      3: ['C', 'G', 'L', 'S'],
      4: ['D', 'M', 'T'],
      5: ['E', 'H', 'N', 'X'],
      6: ['U', 'V', 'W'],
      7: ['O', 'Z'],
      8: ['F', 'P'],
      9: [],
    });
  });

  it('assigns no letter to 9', () => {
    expect(Object.values(DEFAULT_CHALDEAN_MAP)).not.toContain(9);
  });

  it('covers all 26 letters exactly once', () => {
    const letters = Object.keys(DEFAULT_CHALDEAN_MAP).sort();
    expect(letters).toHaveLength(26);
    expect(new Set(letters).size).toBe(26);
  });
});

describe('calculateChaldeanName', () => {
  it('matches the worked example: RAHUL', () => {
    const result = calculateChaldeanName('RAHUL');
    // R=2 A=1 H=5 U=6 L=3 -> 17 -> 8
    expect(result.letters.filter((l) => l.counted).map((l) => l.value)).toEqual([2, 1, 5, 6, 3]);
    expect(result.compound).toBe(17);
    expect(result.root).toBe(8);
  });

  it('is case insensitive', () => {
    expect(calculateChaldeanName('rahul').compound).toBe(17);
    expect(calculateChaldeanName('RaHuL').compound).toBe(17);
  });

  it('keeps the compound number separate from the root', () => {
    const result = calculateChaldeanName('Rahul');
    expect(result.compound).toBe(17);
    expect(result.root).toBe(8);
    expect(result.compound).not.toBe(result.root);
  });

  it('handles full names with spaces', () => {
    const result = calculateChaldeanName('  Rahul   Sharma  ');
    expect(result.name).toBe('Rahul Sharma');
    // S=3 H=5 A=1 R=2 M=4 A=1 -> 16, plus 17 = 33 -> 6
    expect(result.compound).toBe(33);
    expect(result.root).toBe(6);
  });

  it('reports characters it could not map', () => {
    const result = calculateChaldeanName('Rahul-99');
    expect(result.ignoredCharacters).toEqual(['-', '9']);
    expect(result.compound).toBe(17);
  });

  it('honours an administrator supplied mapping', () => {
    const custom = buildChaldeanMap({ ...DEFAULT_CHALDEAN_GROUPS, 9: ['R'], 2: ['B', 'K'] });
    expect(calculateChaldeanName('RAHUL', custom).compound).toBe(24); // R now 9
  });

  it('rejects empty names', () => {
    expect(() => calculateChaldeanName('')).toThrow(/enter a name/);
    expect(() => calculateChaldeanName('   ')).toThrow(/enter a name/);
  });

  it('rejects names that are too long', () => {
    expect(() => calculateChaldeanName('A'.repeat(MAX_NAME_LENGTH + 1))).toThrow(/at most/);
  });

  it('rejects names with no mappable letters', () => {
    expect(() => calculateChaldeanName('12345')).toThrow(NumerologyError);
    expect(() => calculateChaldeanName('राहुल')).toThrow(/Chaldean system/);
  });

  it('records the reduction steps', () => {
    const result = calculateChaldeanName('RAHUL');
    expect(result.breakdown.steps.map((s) => s.expression)).toEqual([
      '2 + 1 + 5 + 6 + 3 = 17',
      '1 + 7 = 8',
    ]);
  });
});

describe('normaliseName', () => {
  it('trims and collapses whitespace', () => {
    expect(normaliseName('  Rahul   Kumar  Sharma ')).toBe('Rahul Kumar Sharma');
  });
});

import { offlineCompatibility, offlineCoreNumbers, offlineDaily, offlineLuckyNumber, offlineName } from '../lib/offline';

/**
 * The offline path must produce exactly the same numbers as the server, because
 * both run the same @numerology/core engine. These tests pin that contract.
 */
describe('on-device calculations', () => {
  it('calculates Mulank and Bhagyank without a network', async () => {
    const result = await offlineCoreNumbers('1995-08-15', 'en');
    expect(result).toMatchObject({ dob: '1995-08-15', mulank: 6, bhagyank: 2 });
    expect(result.breakdown.bhagyank.compound).toBe(38);
    // No combination text is cached offline, so the app falls back to the two
    // individual interpretations - the same rule the API applies.
    expect(result.combinationFallback).toBe(true);
  });

  it('calculates a vehicle number root without a network', async () => {
    const result = await offlineLuckyNumber('MH-31-AB-1234', '1995-08-15', 'en');
    expect(result).toMatchObject({ compound: 14, root: 5, mulank: 6, bhagyank: 2 });
    expect(result.comparisons).toHaveLength(2);
    expect(result.needsDob).toBe(false);
  });

  it('asks for a date of birth when none is saved', async () => {
    const result = await offlineLuckyNumber('1234', null, 'en');
    expect(result.root).toBe(1);
    expect(result.needsDob).toBe(true);
    expect(result.needsDobMessage).toBeTruthy();
  });

  it('calculates a Chaldean name value without a network', async () => {
    const result = await offlineName('Rahul', '1995-08-15', 'en');
    expect(result).toMatchObject({ compound: 17, root: 8 });
    expect(result.comparison).toMatchObject({ mulank: 6, bhagyank: 2 });
  });

  it('checks compatibility in both directions without a network', async () => {
    const matched = await offlineCompatibility('1990-01-01', '1991-01-10', 'en');
    expect(matched.verdict).toBe('STRONG_MATCH');
    expect(matched.directions).toHaveLength(2);
    expect(matched.matchedDirections).toBe(2);

    const unmatched = await offlineCompatibility('1990-01-03', '1990-01-02', 'en');
    expect(unmatched.verdict).toBe('NOT_MATCHED');
    // Even offline the Kundali referral and the disclaimer are present.
    expect(unmatched.kundaliReferral?.enabled).toBe(true);
    expect(unmatched.marriageDisclaimer.length).toBeGreaterThan(20);
  });

  it("calculates today's number from the date, not a hard-coded value", async () => {
    const first = await offlineDaily('en', '2026-08-31');
    expect(first).toMatchObject({ date: '2026-08-31', number: 4 });
    const second = await offlineDaily('en', '2026-08-30');
    expect(second.number).not.toBe(first.number);
  });

  it('rejects an impossible date on the device too', async () => {
    await expect(offlineCoreNumbers('2023-02-30', 'en')).rejects.toThrow();
  });

  it('answers in the selected language', async () => {
    const hindi = await offlineCompatibility('1990-01-01', '1991-01-10', 'hi');
    expect(hindi.verdictLabel).toBe('मजबूत मेल');
    const marathi = await offlineCompatibility('1990-01-01', '1991-01-10', 'mr');
    expect(marathi.verdictLabel).toBe('मजबूत जुळणी');
  });
});

import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { app, auth, createUser } from './helpers';
import { prisma } from '../lib/prisma';

afterAll(async () => {
  await prisma.$disconnect();
});

describe('POST /api/v1/numerology/calculate', () => {
  it('returns the worked example from the specification', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/calculate')
      .send({ dateOfBirth: '1995-08-15' })
      .expect(200);

    expect(response.body.data).toMatchObject({ dob: '1995-08-15', mulank: 6, bhagyank: 2 });
    expect(response.body.data.mulankContent.number).toBe(6);
    expect(response.body.data.bhagyankContent.number).toBe(2);
    expect(response.body.data.combination).toMatchObject({ mulank: 6, bhagyank: 2 });
    expect(response.body.data.disclaimer).toContain('not guaranteed');
  });

  it('works without an account', async () => {
    await request(app).post('/api/v1/numerology/calculate').send({ dateOfBirth: '15/08/1995' }).expect(200);
  });

  it('serves content in Hindi and Marathi', async () => {
    const hindi = await request(app)
      .post('/api/v1/numerology/calculate')
      .set('X-Locale', 'hi')
      .send({ dateOfBirth: '1995-08-15' })
      .expect(200);
    expect(hindi.body.data.mulankContent.title).toContain('अंक 6');

    const marathi = await request(app)
      .post('/api/v1/numerology/calculate?locale=mr')
      .send({ dateOfBirth: '1995-08-15' })
      .expect(200);
    expect(marathi.body.data.mulankContent.title).toContain('अंक 6');
    expect(marathi.body.data.combination.title).toContain('मूलांक 6');
  });

  it('rejects an impossible date with a friendly message', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/calculate')
      .send({ dateOfBirth: '2023-02-30' })
      .expect(422);
    expect(response.body.error.message).toBe('Please enter a valid date of birth.');
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('rejects a future date', async () => {
    const nextYear = new Date();
    nextYear.setFullYear(nextYear.getFullYear() + 1);
    const response = await request(app)
      .post('/api/v1/numerology/calculate')
      .send({ dateOfBirth: nextYear.toISOString().slice(0, 10) })
      .expect(422);
    expect(response.body.error.message).toContain('future');
  });

  it('asks for a date of birth when none is available', async () => {
    const response = await request(app).post('/api/v1/numerology/calculate').send({}).expect(422);
    expect(response.body.error.details.needsDob).toBe(true);
  });

  it('never returns a stack trace to the client', async () => {
    const response = await request(app).post('/api/v1/numerology/calculate').send({ dateOfBirth: 'x' }).expect(422);
    expect(JSON.stringify(response.body)).not.toContain('at ');
  });
});

describe('the global date of birth', () => {
  it('is used automatically once saved, and is not overwritten by a one-off calculation', async () => {
    const user = await createUser();

    await request(app)
      .post('/api/v1/numerology/calculate')
      .set(auth(user.accessToken))
      .send({ dateOfBirth: '1995-08-15', save: true })
      .expect(200);

    // No date of birth in the body: the saved one is used.
    const automatic = await request(app)
      .post('/api/v1/numerology/calculate')
      .set(auth(user.accessToken))
      .send({})
      .expect(200);
    expect(automatic.body.data).toMatchObject({ dob: '1995-08-15', mulank: 6, bhagyank: 2 });
    expect(automatic.body.data.dobFromProfile).toBe(true);

    // A one-off calculation with a different date does not change the profile.
    await request(app)
      .post('/api/v1/numerology/calculate')
      .set(auth(user.accessToken))
      .send({ dateOfBirth: '1990-01-01' })
      .expect(200);

    const profile = await request(app).get('/api/v1/profile').set(auth(user.accessToken)).expect(200);
    expect(profile.body.data.profile.dateOfBirth).toBe('1995-08-15');
    expect(profile.body.data.profile.mulank).toBe(6);
    expect(profile.body.data.profile.bhagyank).toBe(2);
  });

  it('is used by the lucky number finder without asking again', async () => {
    const user = await createUser();
    await request(app)
      .put('/api/v1/profile')
      .set(auth(user.accessToken))
      .send({ dateOfBirth: '1995-08-15' })
      .expect(200);

    const response = await request(app)
      .post('/api/v1/numerology/lucky-number')
      .set(auth(user.accessToken))
      .send({ number: '1234' })
      .expect(200);

    expect(response.body.data).toMatchObject({ root: 1, mulank: 6, bhagyank: 2, dobFromProfile: true });
  });
});

describe('POST /api/v1/numerology/lucky-number', () => {
  it('calculates the root of a vehicle number', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/lucky-number')
      .send({ number: 'MH-31-AB-1234' })
      .expect(200);

    expect(response.body.data).toMatchObject({ compound: 14, root: 5, needsDob: true });
    expect(response.body.data.digits).toEqual([3, 1, 1, 2, 3, 4]);
    expect(response.body.data.needsDobMessage).toContain('date of birth');
  });

  it('calculates the root of a mobile number', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/lucky-number')
      .send({ number: '9876543210' })
      .expect(200);
    expect(response.body.data).toMatchObject({ compound: 45, root: 9 });
  });

  it('compares the number against the mulank and the bhagyank', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/lucky-number')
      .send({ number: '1234', dateOfBirth: '1995-08-15' })
      .expect(200);

    expect(response.body.data.comparisons).toHaveLength(2);
    expect(response.body.data.comparisons[0]).toMatchObject({ axis: 'MULANK', axisValue: 6 });
    expect(response.body.data.comparisons[1]).toMatchObject({ axis: 'BHAGYANK', axisValue: 2 });
    expect(['STRONG_MATCH', 'GOOD_MATCH', 'NEUTRAL', 'WEAK_MATCH']).toContain(response.body.data.overall);
  });

  it('rejects a value with no digits', async () => {
    const response = await request(app).post('/api/v1/numerology/lucky-number').send({ number: 'ABCD' }).expect(422);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('rejects an empty value', async () => {
    await request(app).post('/api/v1/numerology/lucky-number').send({ number: '' }).expect(422);
  });

  it('rejects a number that is too long', async () => {
    await request(app).post('/api/v1/numerology/lucky-number').send({ number: '1'.repeat(40) }).expect(422);
  });
});

describe('POST /api/v1/numerology/name', () => {
  it('matches the worked example: RAHUL', async () => {
    const response = await request(app).post('/api/v1/numerology/name').send({ name: 'Rahul' }).expect(200);
    expect(response.body.data).toMatchObject({ name: 'Rahul', compound: 17, root: 8 });
    expect(response.body.data.rootContent.number).toBe(8);
  });

  it('keeps both the compound and the root number', async () => {
    const response = await request(app).post('/api/v1/numerology/name').send({ name: 'Rahul Sharma' }).expect(200);
    expect(response.body.data.compound).toBe(33);
    expect(response.body.data.root).toBe(6);
  });

  it('compares the name with the saved numbers when a date of birth exists', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/name')
      .send({ name: 'Rahul', dateOfBirth: '1995-08-15' })
      .expect(200);
    expect(response.body.data.comparison).toMatchObject({ mulank: 6, bhagyank: 2 });
    expect(response.body.data.comparison.axes).toHaveLength(2);
  });

  it('asks for a date of birth when none is available', async () => {
    const response = await request(app).post('/api/v1/numerology/name').send({ name: 'Rahul' }).expect(200);
    expect(response.body.data.comparison).toBeNull();
    expect(response.body.data.needsDobMessage).toContain('date of birth');
  });

  it('rejects a name with no Chaldean letters', async () => {
    const response = await request(app).post('/api/v1/numerology/name').send({ name: '12345' }).expect(422);
    expect(response.body.error.message).toContain('English letters');
  });

  it('rejects an empty name', async () => {
    await request(app).post('/api/v1/numerology/name').send({ name: '   ' }).expect(422);
  });
});

describe('POST /api/v1/numerology/compatibility', () => {
  it('evaluates both directions and returns a strong match when both agree', async () => {
    // Both partners have Mulank 1; rule 1 accepts 1 in both directions.
    const response = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-01', femaleDateOfBirth: '1991-01-10' })
      .expect(200);

    expect(response.body.data.directions).toHaveLength(2);
    expect(response.body.data.directions[0].direction).toBe('MALE_TO_FEMALE');
    expect(response.body.data.directions[1].direction).toBe('FEMALE_TO_MALE');
    expect(response.body.data.verdict).toBe('STRONG_MATCH');
    expect(response.body.data.matchedDirections).toBe(2);
    expect(response.body.data.verdictLabel).toBe('Strong Match');
  });

  it('explains why a pair does not match without alarming language', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-03', femaleDateOfBirth: '1990-01-02' })
      .expect(200);

    expect(response.body.data.verdict).toBe('NOT_MATCHED');
    expect(response.body.data.summary).toContain('configured numerology compatibility rules');
    const text = JSON.stringify(response.body.data).toLowerCase();
    expect(text).not.toContain('divorce');
    expect(text).not.toContain('will fail');
    expect(text).not.toContain('should not marry');
  });

  it('offers the Kundali referral without claiming to perform Kundali matching', async () => {
    const response = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-03', femaleDateOfBirth: '1990-01-02' })
      .expect(200);

    expect(response.body.data.kundaliReferral.note).toContain('does not perform Vedic Kundali');
    expect(response.body.data.marriageDisclaimer).toContain('sole basis');
  });

  it('gives the same verdict whichever partner is entered first', async () => {
    const first = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-03', femaleDateOfBirth: '1990-01-08' })
      .expect(200);
    const second = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-08', femaleDateOfBirth: '1990-01-03' })
      .expect(200);

    expect(first.body.data.verdict).toBe(second.body.data.verdict);
    expect(first.body.data.matchedDirections).toBe(second.body.data.matchedDirections);
  });

  it('validates both dates', async () => {
    await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1995-02-30', femaleDateOfBirth: '1995-08-15' })
      .expect(422);
    await request(app).post('/api/v1/numerology/compatibility').send({ maleDateOfBirth: '1995-08-15' }).expect(422);
  });
});

describe("GET /api/v1/numerology/daily", () => {
  it('calculates the number from the supplied date', async () => {
    const response = await request(app).get('/api/v1/numerology/daily?date=2026-08-31').expect(200);
    expect(response.body.data).toMatchObject({ date: '2026-08-31', number: 4 });
    expect(response.body.data.breakdown.compound).toBe(22);
    expect(response.body.data.insight.title).toBe('A day for practical work');
  });

  it('changes from one day to the next', async () => {
    const first = await request(app).get('/api/v1/numerology/daily?date=2026-08-30').expect(200);
    const second = await request(app).get('/api/v1/numerology/daily?date=2026-08-31').expect(200);
    expect(first.body.data.number).not.toBe(second.body.data.number);
  });

  it('defaults to today when no date is supplied', async () => {
    const response = await request(app).get('/api/v1/numerology/daily').expect(200);
    expect(response.body.data.date).toBe(new Date().toISOString().slice(0, 10));
  });
});

describe('GET /api/v1/numerology/summary', () => {
  it('returns everything the home screen needs', async () => {
    const user = await createUser();
    await request(app)
      .put('/api/v1/profile')
      .set(auth(user.accessToken))
      .send({ dateOfBirth: '1995-08-15' })
      .expect(200);

    const response = await request(app).get('/api/v1/numerology/summary').set(auth(user.accessToken)).expect(200);
    expect(response.body.data.numbers).toMatchObject({ mulank: 6, bhagyank: 2 });
    expect(response.body.data.daily.number).toBeGreaterThanOrEqual(1);
    expect(response.body.data.needsDob).toBe(false);
  });

  it('prompts for a date of birth when the visitor has none', async () => {
    const response = await request(app).get('/api/v1/numerology/summary').expect(200);
    expect(response.body.data.needsDob).toBe(true);
    expect(response.body.data.numbers).toBeNull();
  });
});

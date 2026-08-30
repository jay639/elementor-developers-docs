import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { app, auth, createGuestSession, createUser } from './helpers';
import { prisma } from '../lib/prisma';

afterAll(async () => {
  await prisma.$disconnect();
});

describe('guest mode', () => {
  it('lets a visitor start without an account', async () => {
    const guest = await createGuestSession();
    expect(guest.accessToken).toBeTruthy();

    const response = await request(app).get('/api/v1/profile').set(auth(guest.accessToken)).expect(200);
    expect(response.body.data.isGuest).toBe(true);
    expect(response.body.data.email).toBeNull();
  });

  it('keeps the guest history when the guest creates an account', async () => {
    const guest = await createGuestSession();
    await request(app)
      .post('/api/v1/numerology/calculate')
      .set(auth(guest.accessToken))
      .send({ dateOfBirth: '1995-08-15', save: true })
      .expect(200);

    const email = `upgrade-${Date.now()}@test.local`;
    const upgraded = await request(app)
      .post('/api/v1/auth/register')
      .set(auth(guest.accessToken))
      .send({ email, password: 'Password123', displayName: 'Upgraded' })
      .expect(201);

    expect(upgraded.body.data.user.id).toBe(guest.userId);

    const history = await request(app)
      .get('/api/v1/history')
      .set(auth(upgraded.body.data.tokens.accessToken))
      .expect(200);
    expect(history.body.data).toHaveLength(1);
    expect(history.body.meta.total).toBe(1);
  });
});

describe('registration and login', () => {
  it('registers, then signs in with the same credentials', async () => {
    const user = await createUser();
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: user.email, password: user.password })
      .expect(200);
    expect(login.body.data.tokens.accessToken).toBeTruthy();
  });

  it('rejects a weak password', async () => {
    const response = await request(app)
      .post('/api/v1/auth/register')
      .send({ email: `weak-${Date.now()}@test.local`, password: 'short' })
      .expect(422);
    expect(JSON.stringify(response.body.error.details)).toContain('at least 8 characters');
  });

  it('rejects a duplicate email', async () => {
    const user = await createUser();
    const response = await request(app)
      .post('/api/v1/auth/register')
      .send({ email: user.email, password: 'Password123' })
      .expect(409);
    expect(response.body.error.code).toBe('CONFLICT');
  });

  it('gives the same message for a wrong email and a wrong password', async () => {
    const user = await createUser();
    const wrongPassword = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: user.email, password: 'WrongPassword1' })
      .expect(401);
    const wrongEmail = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: `missing-${Date.now()}@test.local`, password: 'Password123' })
      .expect(401);
    expect(wrongPassword.body.error.message).toBe(wrongEmail.body.error.message);
  });

  it('never returns the password hash', async () => {
    const user = await createUser();
    const profile = await request(app).get('/api/v1/profile').set(auth(user.accessToken)).expect(200);
    expect(JSON.stringify(profile.body)).not.toContain('passwordHash');
    expect(JSON.stringify(profile.body)).not.toContain(user.password);
  });

  it('stores the password as a bcrypt hash, never in plain text', async () => {
    const user = await createUser();
    const row = await prisma.user.findUniqueOrThrow({
      where: { id: user.userId },
      select: { passwordHash: true },
    });
    expect(row.passwordHash).toMatch(/^\$2[aby]\$/);
    expect(row.passwordHash).not.toContain(user.password);
  });
});

describe('sessions', () => {
  it('rotates the refresh token and rejects the old one', async () => {
    const user = await createUser();
    const refreshed = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(200);
    expect(refreshed.body.data.tokens.refreshToken).not.toBe(user.refreshToken);

    await request(app).post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
  });

  it('rejects a refresh token after logout', async () => {
    const user = await createUser();
    await request(app).post('/api/v1/auth/logout').send({ refreshToken: user.refreshToken }).expect(200);
    await request(app).post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
  });

  it('only stores a hash of the refresh token', async () => {
    const user = await createUser();
    const rows = await prisma.refreshToken.findMany({ where: { userId: user.userId } });
    expect(rows).toHaveLength(1);
    expect(rows[0]!.tokenHash).not.toBe(user.refreshToken);
    expect(rows[0]!.tokenHash).toHaveLength(64);
  });

  it('refuses a protected route without a token', async () => {
    await request(app).get('/api/v1/profile').expect(401);
    await request(app).get('/api/v1/history').expect(401);
  });

  it('refuses a tampered token', async () => {
    const user = await createUser();
    await request(app).get('/api/v1/profile').set(auth(`${user.accessToken}x`)).expect(401);
  });

  it('does not accept a user token on an admin route', async () => {
    const user = await createUser();
    await request(app).get('/api/v1/admin/auth/me').set(auth(user.accessToken)).expect(401);
  });
});

describe('profile', () => {
  it('updates the date of birth and recalculates the numbers', async () => {
    const user = await createUser();
    const response = await request(app)
      .put('/api/v1/profile')
      .set(auth(user.accessToken))
      .send({ dateOfBirth: '15/08/1995', displayName: 'Rahul' })
      .expect(200);
    expect(response.body.data).toMatchObject({ dateOfBirth: '1995-08-15', mulank: 6, bhagyank: 2 });
  });

  it('clears the numbers when the date of birth is removed', async () => {
    const user = await createUser();
    await request(app).put('/api/v1/profile').set(auth(user.accessToken)).send({ dateOfBirth: '1995-08-15' });
    const response = await request(app)
      .put('/api/v1/profile')
      .set(auth(user.accessToken))
      .send({ dateOfBirth: null })
      .expect(200);
    expect(response.body.data).toMatchObject({ dateOfBirth: null, mulank: null, bhagyank: null });
  });

  it('rejects an invalid date of birth', async () => {
    const user = await createUser();
    await request(app)
      .put('/api/v1/profile')
      .set(auth(user.accessToken))
      .send({ dateOfBirth: '31/02/1995' })
      .expect(422);
  });

  it('updates preferences including the language', async () => {
    const user = await createUser();
    const response = await request(app)
      .put('/api/v1/profile/preferences')
      .set(auth(user.accessToken))
      .send({ locale: 'mr', theme: 'DARK', analyticsConsent: true })
      .expect(200);
    expect(response.body.data).toMatchObject({ locale: 'mr', theme: 'DARK', analyticsConsent: true });
  });

  it('deletes the account and removes the personal data', async () => {
    const user = await createUser();
    await request(app).put('/api/v1/profile').set(auth(user.accessToken)).send({ dateOfBirth: '1995-08-15' });
    await request(app).delete('/api/v1/profile').set(auth(user.accessToken)).expect(204);

    const row = await prisma.user.findUniqueOrThrow({ where: { id: user.userId } });
    expect(row.deletedAt).not.toBeNull();
    expect(row.email).toBeNull();
    expect(row.passwordHash).toBeNull();
    expect(await prisma.userProfile.findUnique({ where: { userId: user.userId } })).toBeNull();

    await request(app).get('/api/v1/profile').set(auth(user.accessToken)).expect(401);
  });
});

describe('analytics consent', () => {
  it('does not record events for a user who has not consented', async () => {
    const user = await createUser();
    const response = await request(app)
      .post('/api/v1/analytics/events')
      .set(auth(user.accessToken))
      .send({ name: 'app_open' })
      .expect(200);
    expect(response.body.data).toMatchObject({ recorded: false, reason: 'CONSENT_NOT_GIVEN' });
  });

  it('records events once consent is given, without personal fields', async () => {
    const user = await createUser();
    await request(app)
      .put('/api/v1/profile/preferences')
      .set(auth(user.accessToken))
      .send({ analyticsConsent: true })
      .expect(200);

    await request(app)
      .post('/api/v1/analytics/events')
      .set(auth(user.accessToken))
      .send({ name: 'lucky_number_checked', properties: { screen: 'tools', dob: '1995-08-15', email: 'x@y.z' } })
      .expect(200);

    const event = await prisma.analyticsEvent.findFirst({
      where: { userId: user.userId, name: 'lucky_number_checked' },
      orderBy: { createdAt: 'desc' },
    });
    expect(event?.properties).toEqual({ screen: 'tools' });
  });

  it('rejects an unknown event name', async () => {
    await request(app).post('/api/v1/analytics/events').send({ name: 'not_a_real_event' }).expect(422);
  });
});

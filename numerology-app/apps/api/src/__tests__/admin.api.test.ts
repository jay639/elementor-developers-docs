import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { adminSession, app, auth, createUser } from './helpers';
import { prisma } from '../lib/prisma';
import { hashPassword } from '../lib/password';
import { invalidateRules } from '../services/rulesService';

afterAll(async () => {
  await prisma.$disconnect();
});

/** Creates an administrator with a specific role, to test the permission model. */
async function createAdmin(roleKey: string, password = 'AdminPass123') {
  const role = await prisma.adminRole.findUniqueOrThrow({ where: { key: roleKey } });
  const email = `admin-${roleKey.toLowerCase()}-${Date.now()}@test.local`;
  await prisma.adminUser.create({
    data: { email, passwordHash: await hashPassword(password), name: roleKey, roleId: role.id },
  });
  const response = await request(app).post('/api/v1/admin/auth/login').send({ email, password }).expect(200);
  return { email, accessToken: response.body.data.tokens.accessToken as string };
}

describe('admin authentication', () => {
  it('signs in the seeded super administrator', async () => {
    const session = await adminSession();
    expect(session.admin.role).toBe('SUPER_ADMIN');
    expect(session.admin.permissions).toContain('content:write');
    expect(JSON.stringify(session.admin)).not.toContain('passwordHash');
  });

  it('rejects wrong credentials', async () => {
    await request(app)
      .post('/api/v1/admin/auth/login')
      .send({ email: process.env.SEED_ADMIN_EMAIL, password: 'WrongPassword1' })
      .expect(401);
  });

  it('does not accept an admin token on a user route', async () => {
    const session = await adminSession();
    await request(app).get('/api/v1/profile').set(auth(session.accessToken)).expect(401);
  });

  it('requires a token for every admin route', async () => {
    await request(app).get('/api/v1/admin/users').expect(401);
    await request(app).get('/api/v1/admin/analytics').expect(401);
    await request(app).get('/api/v1/admin/compatibility-rules').expect(401);
  });

  it('records the login in the audit log', async () => {
    await adminSession();
    const log = await prisma.auditLog.findFirst({ where: { action: 'admin.login' }, orderBy: { createdAt: 'desc' } });
    expect(log).not.toBeNull();
  });
});

describe('role based access control', () => {
  it('lets a content admin edit content but not users', async () => {
    const admin = await createAdmin('CONTENT_ADMIN');
    await request(app).get('/api/v1/admin/numerology/numbers').set(auth(admin.accessToken)).expect(200);
    await request(app).get('/api/v1/admin/users').set(auth(admin.accessToken)).expect(403);
  });

  it('lets an analyst read but not write', async () => {
    const admin = await createAdmin('ANALYST');
    await request(app).get('/api/v1/admin/analytics').set(auth(admin.accessToken)).expect(200);
    await request(app)
      .put('/api/v1/admin/compatibility-rules/1')
      .set(auth(admin.accessToken))
      .send({ compatibleMulank: [1], compatibleBhagyank: [1] })
      .expect(403);
  });

  it('lets a support admin view users but not delete them', async () => {
    const admin = await createAdmin('SUPPORT_ADMIN');
    const user = await createUser();
    await request(app).get(`/api/v1/admin/users/${user.userId}`).set(auth(admin.accessToken)).expect(200);
    await request(app).delete(`/api/v1/admin/users/${user.userId}`).set(auth(admin.accessToken)).expect(403);
  });

  it('applies a role change immediately, without waiting for the token to expire', async () => {
    const admin = await createAdmin('CONTENT_ADMIN');
    await request(app).get('/api/v1/admin/numerology/numbers').set(auth(admin.accessToken)).expect(200);

    const analyst = await prisma.adminRole.findUniqueOrThrow({ where: { key: 'ANALYST' } });
    await prisma.adminUser.update({ where: { email: admin.email }, data: { roleId: analyst.id } });

    await request(app)
      .put('/api/v1/admin/numerology/numbers/1/en')
      .set(auth(admin.accessToken))
      .send({})
      .expect(403);
  });

  it('blocks a disabled administrator', async () => {
    const admin = await createAdmin('CONTENT_ADMIN');
    await prisma.adminUser.update({ where: { email: admin.email }, data: { status: 'DISABLED' } });
    await request(app).get('/api/v1/admin/numerology/numbers').set(auth(admin.accessToken)).expect(403);
  });
});

describe('admin content management', () => {
  it('edits a number interpretation and the change reaches the app immediately', async () => {
    const session = await adminSession();
    const current = await request(app)
      .get('/api/v1/admin/numerology/numbers/1/en')
      .set(auth(session.accessToken))
      .expect(200);

    const edited = { ...current.body.data, summary: 'Edited by the automated test.' };
    delete edited.id;
    delete edited.createdAt;
    delete edited.updatedAt;
    delete edited.locale;
    delete edited.number;

    await request(app)
      .put('/api/v1/admin/numerology/numbers/1/en')
      .set(auth(session.accessToken))
      .send(edited)
      .expect(200);

    const publicView = await request(app).get('/api/v1/content/numbers/1').expect(200);
    expect(publicView.body.data.summary).toBe('Edited by the automated test.');

    // Restore the seeded content for the other tests.
    await request(app)
      .put('/api/v1/admin/numerology/numbers/1/en')
      .set(auth(session.accessToken))
      .send({ ...edited, summary: current.body.data.summary })
      .expect(200);
  });

  it('writes an audit entry with the before and after values', async () => {
    const log = await prisma.auditLog.findFirst({
      where: { action: 'content.number_updated' },
      orderBy: { createdAt: 'desc' },
    });
    expect(log).not.toBeNull();
    expect(log?.before).not.toBeNull();
    expect(log?.after).not.toBeNull();
  });

  it('lists all 81 combinations for a locale', async () => {
    const session = await adminSession();
    const response = await request(app)
      .get('/api/v1/admin/numerology/combinations?pageSize=100&locale=hi')
      .set(auth(session.accessToken))
      .expect(200);
    expect(response.body.meta.total).toBe(81);
    expect(response.body.data).toHaveLength(81);
  });

  it('rejects invalid content', async () => {
    const session = await adminSession();
    await request(app)
      .put('/api/v1/admin/numerology/numbers/1/en')
      .set(auth(session.accessToken))
      .send({ name: '', title: '' })
      .expect(422);
  });
});

describe('admin rule management', () => {
  it('changes a marriage rule and the calculation follows it', async () => {
    const session = await adminSession();

    // Mulank 3 accepts only 3 by default, so 3 and 2 do not match.
    const before = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-03', femaleDateOfBirth: '1990-01-02' })
      .expect(200);
    expect(before.body.data.verdict).toBe('NOT_MATCHED');

    await request(app)
      .put('/api/v1/admin/compatibility-rules/3')
      .set(auth(session.accessToken))
      .send({ compatibleMulank: [2, 3], compatibleBhagyank: [2, 3] })
      .expect(200);

    const after = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-03', femaleDateOfBirth: '1990-01-02' })
      .expect(200);
    expect(after.body.data.verdict).toBe('GOOD_MATCH');

    // Restore the seeded rule.
    await request(app)
      .put('/api/v1/admin/compatibility-rules/3')
      .set(auth(session.accessToken))
      .send({ compatibleMulank: [3], compatibleBhagyank: [3] })
      .expect(200);
    invalidateRules();

    const restored = await request(app)
      .post('/api/v1/numerology/compatibility')
      .send({ maleDateOfBirth: '1990-01-03', femaleDateOfBirth: '1990-01-02' })
      .expect(200);
    expect(restored.body.data.verdict).toBe('NOT_MATCHED');
  });

  it('rejects a number rule that puts a number in two categories', async () => {
    const session = await adminSession();
    await request(app)
      .put('/api/v1/admin/number-rules/1')
      .set(auth(session.accessToken))
      .send({ friendly: [1, 2], neutral: [2, 3], unfriendly: [4] })
      .expect(422);
  });

  it('exposes the Chaldean table grouped by value, with nothing on 9', async () => {
    const session = await adminSession();
    const response = await request(app)
      .get('/api/v1/admin/chaldean-mappings')
      .set(auth(session.accessToken))
      .expect(200);
    expect(response.body.data.groups['1']).toEqual(['A', 'I', 'J', 'Q', 'Y']);
    expect(response.body.data.groups['9']).toEqual([]);
    expect(response.body.data.letters).toHaveLength(26);
  });

  it('rejects a Chaldean table that maps a letter twice', async () => {
    const session = await adminSession();
    await request(app)
      .put('/api/v1/admin/chaldean-mappings')
      .set(auth(session.accessToken))
      .send({ groups: { 1: ['A'], 2: ['A'] } })
      .expect(422);
  });

  it('changes the Chaldean table and the name calculation follows it', async () => {
    const session = await adminSession();
    const original = await request(app)
      .get('/api/v1/admin/chaldean-mappings')
      .set(auth(session.accessToken))
      .expect(200);

    const groups = { ...original.body.data.groups };
    // Move R from 2 to 9: RAHUL should then be 24 instead of 17.
    groups['2'] = groups['2'].filter((letter: string) => letter !== 'R');
    groups['9'] = ['R'];

    await request(app)
      .put('/api/v1/admin/chaldean-mappings')
      .set(auth(session.accessToken))
      .send({ groups })
      .expect(200);

    const changed = await request(app).post('/api/v1/numerology/name').send({ name: 'Rahul' }).expect(200);
    expect(changed.body.data.compound).toBe(24);

    await request(app)
      .put('/api/v1/admin/chaldean-mappings')
      .set(auth(session.accessToken))
      .send({ groups: original.body.data.groups })
      .expect(200);

    const restored = await request(app).post('/api/v1/numerology/name').send({ name: 'Rahul' }).expect(200);
    expect(restored.body.data.compound).toBe(17);
  });
});

describe('admin user management', () => {
  it('lists users without exposing credentials', async () => {
    await createUser();
    const session = await adminSession();
    const response = await request(app).get('/api/v1/admin/users').set(auth(session.accessToken)).expect(200);
    expect(response.body.meta.total).toBeGreaterThan(0);
    expect(JSON.stringify(response.body)).not.toContain('passwordHash');
  });

  it('searches users by email', async () => {
    const user = await createUser();
    const session = await adminSession();
    const response = await request(app)
      .get(`/api/v1/admin/users?search=${encodeURIComponent(user.email)}`)
      .set(auth(session.accessToken))
      .expect(200);
    expect(response.body.data).toHaveLength(1);
    expect(response.body.data[0].email).toBe(user.email);
  });

  it('disables a user and ends their session immediately', async () => {
    const user = await createUser();
    const session = await adminSession();

    await request(app)
      .patch(`/api/v1/admin/users/${user.userId}/status`)
      .set(auth(session.accessToken))
      .send({ status: 'DISABLED' })
      .expect(200);

    // The access token is refused, the revoked refresh token signs the app out,
    // and a fresh sign in is refused with the reason.
    await request(app).get('/api/v1/profile').set(auth(user.accessToken)).expect(403);
    await request(app).post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: user.email, password: user.password })
      .expect(403);
    expect(login.body.error.message).toContain('disabled');
  });

  it('deletes a user and removes their personal data', async () => {
    const user = await createUser();
    const session = await adminSession();
    await request(app).delete(`/api/v1/admin/users/${user.userId}`).set(auth(session.accessToken)).expect(204);

    const row = await prisma.user.findUniqueOrThrow({ where: { id: user.userId } });
    expect(row.email).toBeNull();
    expect(row.deletedAt).not.toBeNull();

    const log = await prisma.auditLog.findFirst({
      where: { action: 'users.deleted', entityId: user.userId },
    });
    expect(log).not.toBeNull();
  });
});

describe('admin analytics and settings', () => {
  it('returns dashboard figures', async () => {
    const session = await adminSession();
    const response = await request(app).get('/api/v1/admin/analytics').set(auth(session.accessToken)).expect(200);
    expect(response.body.data.totals.users).toBeGreaterThan(0);
    expect(response.body.data.dailyActivity).toHaveLength(30);
    expect(Array.isArray(response.body.data.calculationsByType)).toBe(true);
  });

  it('updates a setting and the app sees the new value', async () => {
    const session = await adminSession();
    await request(app)
      .put('/api/v1/admin/settings/history.pageSize')
      .set(auth(session.accessToken))
      .send({ value: 25 })
      .expect(200);

    const settings = await request(app).get('/api/v1/settings').expect(200);
    expect(settings.body.data['history.pageSize']).toBe(25);

    await request(app)
      .put('/api/v1/admin/settings/history.pageSize')
      .set(auth(session.accessToken))
      .send({ value: 20 })
      .expect(200);
  });

  it('never exposes private settings to the app', async () => {
    const settings = await request(app).get('/api/v1/settings').expect(200);
    expect(settings.body.data['marriage.scoreWeights']).toBeUndefined();
  });

  it('turns maintenance mode on and off without locking out the admin panel', async () => {
    const session = await adminSession();
    await request(app)
      .put('/api/v1/admin/settings/maintenance')
      .set(auth(session.accessToken))
      .send({ value: { enabled: true, message: { en: 'Back soon.' } } })
      .expect(200);

    const blocked = await request(app)
      .post('/api/v1/numerology/calculate')
      .send({ dateOfBirth: '1995-08-15' })
      .expect(503);
    expect(blocked.body.error.code).toBe('MAINTENANCE');

    // The admin panel keeps working, which is how maintenance is turned off.
    await request(app).get('/api/v1/admin/analytics').set(auth(session.accessToken)).expect(200);

    await request(app)
      .put('/api/v1/admin/settings/maintenance')
      .set(auth(session.accessToken))
      .send({ value: { enabled: false, message: { en: 'Back soon.' } } })
      .expect(200);

    await request(app).post('/api/v1/numerology/calculate').send({ dateOfBirth: '1995-08-15' }).expect(200);
  });

  it('lists the audit log for a super administrator only', async () => {
    const session = await adminSession();
    await request(app).get('/api/v1/admin/audit-logs').set(auth(session.accessToken)).expect(200);

    const analyst = await createAdmin('ANALYST');
    await request(app).get('/api/v1/admin/audit-logs').set(auth(analyst.accessToken)).expect(403);
  });
});

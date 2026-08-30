import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { app, auth, createUser } from './helpers';
import { prisma } from '../lib/prisma';

afterAll(async () => {
  await prisma.$disconnect();
});

/** Performs a few calculations so there is something in the history. */
async function seedHistory(token: string) {
  await request(app)
    .post('/api/v1/numerology/lucky-number')
    .set(auth(token))
    .send({ number: 'MH31AB1234', dateOfBirth: '1995-08-15' })
    .expect(200);
  await request(app).post('/api/v1/numerology/name').set(auth(token)).send({ name: 'Rahul' }).expect(200);
  await request(app)
    .post('/api/v1/numerology/compatibility')
    .set(auth(token))
    .send({ maleDateOfBirth: '1995-08-15', femaleDateOfBirth: '1990-01-01' })
    .expect(200);
}

describe('calculation history', () => {
  it('records each calculation with its input and result', async () => {
    const user = await createUser();
    await seedHistory(user.accessToken);

    const response = await request(app).get('/api/v1/history').set(auth(user.accessToken)).expect(200);
    expect(response.body.meta.total).toBe(3);

    const lucky = response.body.data.find((row: { type: string }) => row.type === 'LUCKY_NUMBER');
    expect(lucky.label).toBe('MH31AB1234');
    expect(lucky.result.root).toBe(5);

    const name = response.body.data.find((row: { type: string }) => row.type === 'NAME_NUMEROLOGY');
    expect(name.result).toMatchObject({ compound: 17, root: 8 });

    const compatibility = response.body.data.find(
      (row: { type: string }) => row.type === 'MARRIAGE_COMPATIBILITY',
    );
    expect(compatibility.result.verdict).toBeTruthy();
  });

  it('is not recorded for signed out visitors', async () => {
    const before = await prisma.calculationHistory.count();
    await request(app).post('/api/v1/numerology/name').send({ name: 'Anonymous' }).expect(200);
    expect(await prisma.calculationHistory.count()).toBe(before);
  });

  it('paginates', async () => {
    const user = await createUser();
    await seedHistory(user.accessToken);

    const page1 = await request(app)
      .get('/api/v1/history?page=1&pageSize=2')
      .set(auth(user.accessToken))
      .expect(200);
    expect(page1.body.data).toHaveLength(2);
    expect(page1.body.meta).toMatchObject({ page: 1, pageSize: 2, total: 3, totalPages: 2, hasMore: true });

    const page2 = await request(app)
      .get('/api/v1/history?page=2&pageSize=2')
      .set(auth(user.accessToken))
      .expect(200);
    expect(page2.body.data).toHaveLength(1);
    expect(page2.body.meta.hasMore).toBe(false);
  });

  it('filters by type and searches by label', async () => {
    const user = await createUser();
    await seedHistory(user.accessToken);

    const filtered = await request(app)
      .get('/api/v1/history?type=NAME_NUMEROLOGY')
      .set(auth(user.accessToken))
      .expect(200);
    expect(filtered.body.data).toHaveLength(1);

    const searched = await request(app)
      .get('/api/v1/history?search=MH31')
      .set(auth(user.accessToken))
      .expect(200);
    expect(searched.body.data).toHaveLength(1);
  });

  it('deletes a single entry and clears the rest', async () => {
    const user = await createUser();
    await seedHistory(user.accessToken);

    const list = await request(app).get('/api/v1/history').set(auth(user.accessToken)).expect(200);
    const first = list.body.data[0];

    await request(app).delete(`/api/v1/history/${first.id}`).set(auth(user.accessToken)).expect(204);
    await request(app).get(`/api/v1/history/${first.id}`).set(auth(user.accessToken)).expect(404);

    const cleared = await request(app).delete('/api/v1/history').set(auth(user.accessToken)).expect(200);
    expect(cleared.body.data.cleared).toBe(2);

    const empty = await request(app).get('/api/v1/history').set(auth(user.accessToken)).expect(200);
    expect(empty.body.data).toHaveLength(0);
  });

  it('never shows one user the history of another', async () => {
    const owner = await createUser();
    const other = await createUser();
    await seedHistory(owner.accessToken);

    const list = await request(app).get('/api/v1/history').set(auth(owner.accessToken)).expect(200);
    const entry = list.body.data[0];

    await request(app).get(`/api/v1/history/${entry.id}`).set(auth(other.accessToken)).expect(404);
    await request(app).delete(`/api/v1/history/${entry.id}`).set(auth(other.accessToken)).expect(404);

    const otherList = await request(app).get('/api/v1/history').set(auth(other.accessToken)).expect(200);
    expect(otherList.body.data).toHaveLength(0);
  });
});

describe('saved results', () => {
  it('saves, lists and removes a favourite', async () => {
    const user = await createUser();
    const created = await request(app)
      .post('/api/v1/favourites')
      .set(auth(user.accessToken))
      .send({ type: 'LUCKY_NUMBER', label: 'MH31AB1234', input: { number: 'MH31AB1234' }, result: { root: 5 } })
      .expect(201);

    const list = await request(app).get('/api/v1/favourites').set(auth(user.accessToken)).expect(200);
    expect(list.body.data).toHaveLength(1);
    expect(list.body.data[0].label).toBe('MH31AB1234');

    await request(app)
      .delete(`/api/v1/favourites/${created.body.data.id}`)
      .set(auth(user.accessToken))
      .expect(204);

    const afterDelete = await request(app).get('/api/v1/favourites').set(auth(user.accessToken)).expect(200);
    expect(afterDelete.body.data).toHaveLength(0);
  });

  it('requires an account', async () => {
    await request(app).get('/api/v1/favourites').expect(401);
  });
});

describe('public content endpoints', () => {
  it('serves all nine numbers for offline caching', async () => {
    const response = await request(app).get('/api/v1/content/numbers').expect(200);
    expect(response.body.data).toHaveLength(9);
  });

  it('serves the rule tables the app caches for offline calculation', async () => {
    const response = await request(app).get('/api/v1/content/rules').expect(200);
    expect(response.body.data.marriage).toHaveLength(9);
    expect(response.body.data.numbers).toHaveLength(9);
    expect(response.body.data.chaldean['1']).toEqual(['A', 'I', 'J', 'Q', 'Y']);
  });

  it('serves the legal documents in every supported language', async () => {
    for (const locale of ['en', 'hi', 'mr']) {
      const response = await request(app).get(`/api/v1/content/legal/DISCLAIMER?locale=${locale}`).expect(200);
      expect(response.body.data.body.length).toBeGreaterThan(50);
    }
  });

  it('reports its health', async () => {
    const response = await request(app).get('/health').expect(200);
    expect(response.body).toMatchObject({ status: 'ok', database: 'up' });
  });
});

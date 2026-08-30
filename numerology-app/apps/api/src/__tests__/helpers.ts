import request from 'supertest';
import type { Express } from 'express';
import { createApp } from '../app';

export const app: Express = createApp();

export interface Session {
  accessToken: string;
  refreshToken: string;
  userId: string;
}

/** Registers a fresh account and returns its tokens. */
export async function createUser(overrides: Partial<{ email: string; password: string; displayName: string }> = {}) {
  const email = overrides.email ?? `user-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@test.local`;
  const password = overrides.password ?? 'Password123';
  const response = await request(app)
    .post('/api/v1/auth/register')
    .send({ email, password, displayName: overrides.displayName ?? 'Test User' })
    .expect(201);

  return {
    email,
    password,
    userId: response.body.data.user.id as string,
    accessToken: response.body.data.tokens.accessToken as string,
    refreshToken: response.body.data.tokens.refreshToken as string,
  };
}

export async function createGuestSession() {
  const response = await request(app).post('/api/v1/auth/guest').expect(201);
  return {
    userId: response.body.data.user.id as string,
    accessToken: response.body.data.tokens.accessToken as string,
    refreshToken: response.body.data.tokens.refreshToken as string,
  };
}

/** Signs in as the seeded super administrator. */
export async function adminSession() {
  const response = await request(app)
    .post('/api/v1/admin/auth/login')
    .send({ email: process.env.SEED_ADMIN_EMAIL, password: process.env.SEED_ADMIN_PASSWORD })
    .expect(200);
  return {
    accessToken: response.body.data.tokens.accessToken as string,
    refreshToken: response.body.data.tokens.refreshToken as string,
    admin: response.body.data.admin,
  };
}

export const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

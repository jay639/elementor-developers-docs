import crypto from 'node:crypto';
import jwt, { type SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';
import { AppError } from './errors';

export type TokenAudience = 'user' | 'admin';

export interface UserTokenPayload {
  sub: string;
  type: 'user';
  isGuest: boolean;
}

export interface AdminTokenPayload {
  sub: string;
  type: 'admin';
  role: string;
  permissions: string[];
}

const ACCESS_SECRETS: Record<TokenAudience, string> = {
  user: env.JWT_ACCESS_SECRET,
  admin: env.ADMIN_JWT_ACCESS_SECRET,
};

const ACCESS_TTL: Record<TokenAudience, string> = {
  user: env.ACCESS_TOKEN_TTL,
  admin: env.ADMIN_ACCESS_TOKEN_TTL,
};

export const REFRESH_TTL_DAYS: Record<TokenAudience, number> = {
  user: env.REFRESH_TOKEN_TTL_DAYS,
  admin: env.ADMIN_REFRESH_TOKEN_TTL_DAYS,
};

export function signAccessToken(audience: TokenAudience, payload: UserTokenPayload | AdminTokenPayload): string {
  const options: SignOptions = {
    expiresIn: ACCESS_TTL[audience] as SignOptions['expiresIn'],
    issuer: 'ankjyoti-api',
    audience,
  };
  return jwt.sign(payload, ACCESS_SECRETS[audience], options);
}

export function verifyAccessToken<T extends UserTokenPayload | AdminTokenPayload>(
  audience: TokenAudience,
  token: string,
): T {
  try {
    return jwt.verify(token, ACCESS_SECRETS[audience], { issuer: 'ankjyoti-api', audience }) as T;
  } catch {
    throw AppError.unauthorized('Your session has expired. Please sign in again.');
  }
}

/**
 * Refresh tokens are opaque random strings, not JWTs: they can be revoked
 * server side. Only the SHA-256 hash is stored, so a database leak does not
 * hand out usable sessions.
 */
export function generateRefreshToken(): { token: string; tokenHash: string } {
  const token = crypto.randomBytes(48).toString('base64url');
  return { token, tokenHash: hashToken(token) };
}

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function refreshExpiry(audience: TokenAudience, from: Date = new Date()): Date {
  const expires = new Date(from);
  expires.setDate(expires.getDate() + REFRESH_TTL_DAYS[audience]);
  return expires;
}

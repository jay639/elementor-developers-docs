import type { NextFunction, Request, Response } from 'express';
import type { Locale } from '@numerology/core';
import { AppError } from '../lib/errors';
import { verifyAccessToken, type AdminTokenPayload, type UserTokenPayload } from '../lib/tokens';
import { prisma } from '../lib/prisma';
import { resolveLocale } from '../lib/locale';

export interface AuthenticatedUser {
  id: string;
  isGuest: boolean;
}

export interface AuthenticatedAdmin {
  id: string;
  role: string;
  permissions: string[];
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      admin?: AuthenticatedAdmin;
      locale: Locale;
    }
  }
}

/** Attaches the resolved locale to every request. */
export function localeMiddleware(req: Request, _res: Response, next: NextFunction) {
  req.locale = resolveLocale(req);
  next();
}

function bearerToken(req: Request): string | null {
  const header = req.get('authorization');
  if (!header?.toLowerCase().startsWith('bearer ')) return null;
  const token = header.slice(7).trim();
  return token.length > 0 ? token : null;
}

/**
 * Populates req.user when a valid token is present, but allows the request
 * through otherwise. Used by calculation endpoints, which work for signed out
 * visitors too.
 */
export async function optionalUser(req: Request, _res: Response, next: NextFunction) {
  const token = bearerToken(req);
  if (!token) {
    next();
    return;
  }
  try {
    const payload = verifyAccessToken<UserTokenPayload>('user', token);
    const user = await prisma.user.findFirst({
      where: { id: payload.sub, deletedAt: null, status: 'ACTIVE' },
      select: { id: true, isGuest: true },
    });
    if (user) req.user = { id: user.id, isGuest: user.isGuest };
    next();
  } catch {
    // An invalid token is treated as "signed out" rather than an error, so a
    // stale token never blocks a calculation.
    next();
  }
}

/** Requires a signed in user (guest sessions count as signed in). */
export async function requireUser(req: Request, _res: Response, next: NextFunction) {
  const token = bearerToken(req);
  if (!token) {
    next(AppError.unauthorized());
    return;
  }
  try {
    const payload = verifyAccessToken<UserTokenPayload>('user', token);
    const user = await prisma.user.findFirst({
      where: { id: payload.sub, deletedAt: null },
      select: { id: true, isGuest: true, status: true },
    });
    if (!user) {
      next(AppError.unauthorized());
      return;
    }
    if (user.status === 'DISABLED') {
      next(AppError.forbidden('This account has been disabled. Please contact support.'));
      return;
    }
    req.user = { id: user.id, isGuest: user.isGuest };
    next();
  } catch (error) {
    next(error);
  }
}

/** Requires a full account: guest sessions cannot use cloud-only features. */
export function requireAccount(req: Request, _res: Response, next: NextFunction) {
  if (!req.user) {
    next(AppError.unauthorized());
    return;
  }
  if (req.user.isGuest) {
    next(AppError.forbidden('Create an account to use this feature.'));
    return;
  }
  next();
}

/**
 * Admin authentication. Completely separate from user authentication: a
 * different token secret, a different audience claim and a different table, so
 * a user token can never be used against an admin endpoint.
 */
export function requireAdmin(...permissions: string[]) {
  return async (req: Request, _res: Response, next: NextFunction) => {
    const token = bearerToken(req);
    if (!token) {
      next(AppError.unauthorized());
      return;
    }
    try {
      const payload = verifyAccessToken<AdminTokenPayload>('admin', token);
      const admin = await prisma.adminUser.findFirst({
        where: { id: payload.sub, deletedAt: null },
        select: { id: true, status: true, role: { select: { key: true, permissions: true } } },
      });
      if (!admin) {
        next(AppError.unauthorized());
        return;
      }
      if (admin.status === 'DISABLED') {
        next(AppError.forbidden('This administrator account has been disabled.'));
        return;
      }

      // Permissions are read from the database on every request, so revoking a
      // role takes effect immediately instead of when the token expires.
      const granted = admin.role.permissions;
      const missing = permissions.filter((permission) => !granted.includes(permission));
      if (missing.length > 0) {
        next(AppError.forbidden(`You do not have permission to do that (${missing.join(', ')}).`));
        return;
      }

      req.admin = { id: admin.id, role: admin.role.key, permissions: granted };
      next();
    } catch (error) {
      next(error);
    }
  };
}

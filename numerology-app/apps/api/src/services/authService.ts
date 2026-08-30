import type { Request } from 'express';
import { prisma } from '../lib/prisma';
import { AppError } from '../lib/errors';
import { hashPassword, verifyPassword } from '../lib/password';
import {
  generateRefreshToken,
  hashToken,
  refreshExpiry,
  signAccessToken,
  type TokenAudience,
} from '../lib/tokens';

export interface SessionTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
}

function requestContext(req: Request) {
  return { userAgent: req.get('user-agent') ?? null, ip: req.ip ?? null };
}

async function issueUserSession(userId: string, isGuest: boolean, req: Request): Promise<SessionTokens> {
  const { token, tokenHash } = generateRefreshToken();
  const expiresAt = refreshExpiry('user');
  await prisma.refreshToken.create({
    data: { userId, tokenHash, expiresAt, ...requestContext(req) },
  });
  await prisma.user.update({ where: { id: userId }, data: { lastLoginAt: new Date() } });
  return {
    accessToken: signAccessToken('user', { sub: userId, type: 'user', isGuest }),
    refreshToken: token,
    expiresAt: expiresAt.toISOString(),
  };
}

/** Creates an anonymous account so a visitor can sync without giving an email. */
export async function createGuest(req: Request) {
  const user = await prisma.user.create({
    data: {
      isGuest: true,
      provider: 'GUEST',
      profile: { create: {} },
      preferences: { create: { locale: req.locale } },
    },
    select: { id: true, isGuest: true },
  });
  return { user, tokens: await issueUserSession(user.id, true, req) };
}

export async function register(
  req: Request,
  input: { email: string; password: string; displayName?: string; dateOfBirth?: string | null },
) {
  const email = input.email.toLowerCase();
  const existing = await prisma.user.findFirst({ where: { email, deletedAt: null } });
  if (existing) {
    throw AppError.conflict('An account with this email already exists. Please sign in instead.');
  }

  const passwordHash = await hashPassword(input.password);

  // A guest who signs up keeps the account they already have, so their history
  // and saved date of birth survive the upgrade.
  const guestId = req.user?.isGuest ? req.user.id : null;
  const user = guestId
    ? await prisma.user.update({
        where: { id: guestId },
        data: {
          email,
          passwordHash,
          isGuest: false,
          provider: 'EMAIL',
          profile: { upsert: { create: { displayName: input.displayName ?? null }, update: { displayName: input.displayName ?? undefined } } },
        },
        select: { id: true, isGuest: true },
      })
    : await prisma.user.create({
        data: {
          email,
          passwordHash,
          isGuest: false,
          provider: 'EMAIL',
          profile: { create: { displayName: input.displayName ?? null } },
          preferences: { create: { locale: req.locale } },
        },
        select: { id: true, isGuest: true },
      });

  return { user, tokens: await issueUserSession(user.id, false, req) };
}

export async function login(req: Request, input: { email: string; password: string }) {
  const user = await prisma.user.findFirst({
    where: { email: input.email.toLowerCase(), deletedAt: null },
    select: { id: true, passwordHash: true, status: true, isGuest: true },
  });

  // The same message is returned whether the email or the password was wrong,
  // so the endpoint cannot be used to discover which emails are registered.
  const invalid = AppError.unauthorized('Email or password is incorrect.');
  if (!user?.passwordHash) throw invalid;
  if (!(await verifyPassword(input.password, user.passwordHash))) throw invalid;
  if (user.status === 'DISABLED') {
    throw AppError.forbidden('This account has been disabled. Please contact support.');
  }

  return { user: { id: user.id, isGuest: user.isGuest }, tokens: await issueUserSession(user.id, user.isGuest, req) };
}

/** Rotates a refresh token: the old one is revoked as soon as it is used. */
export async function refreshUserSession(req: Request, refreshToken: string): Promise<SessionTokens> {
  const stored = await prisma.refreshToken.findUnique({
    where: { tokenHash: hashToken(refreshToken) },
    select: { id: true, userId: true, expiresAt: true, revokedAt: true, user: { select: { isGuest: true, status: true, deletedAt: true } } },
  });

  if (!stored || stored.revokedAt || stored.expiresAt < new Date() || stored.user.deletedAt) {
    throw AppError.unauthorized('Your session has expired. Please sign in again.');
  }
  if (stored.user.status === 'DISABLED') {
    throw AppError.forbidden('This account has been disabled. Please contact support.');
  }

  await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
  return issueUserSession(stored.userId, stored.user.isGuest, req);
}

export async function logout(refreshToken: string): Promise<void> {
  await prisma.refreshToken.updateMany({
    where: { tokenHash: hashToken(refreshToken), revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

export async function logoutAll(userId: string): Promise<void> {
  await prisma.refreshToken.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } });
}

// ---------------------------------------------------------------------------
// Administrators - a completely separate credential store and token audience.
// ---------------------------------------------------------------------------

async function issueAdminSession(adminUserId: string, role: string, permissions: string[], req: Request) {
  const { token, tokenHash } = generateRefreshToken();
  const expiresAt = refreshExpiry('admin');
  await prisma.adminRefreshToken.create({ data: { adminUserId, tokenHash, expiresAt, ...requestContext(req) } });
  await prisma.adminUser.update({ where: { id: adminUserId }, data: { lastLoginAt: new Date() } });
  return {
    accessToken: signAccessToken('admin', { sub: adminUserId, type: 'admin', role, permissions }),
    refreshToken: token,
    expiresAt: expiresAt.toISOString(),
  };
}

export async function adminLogin(req: Request, input: { email: string; password: string }) {
  const admin = await prisma.adminUser.findFirst({
    where: { email: input.email.toLowerCase(), deletedAt: null },
    select: {
      id: true,
      name: true,
      email: true,
      passwordHash: true,
      status: true,
      mustChangePassword: true,
      role: { select: { key: true, name: true, permissions: true } },
    },
  });

  const invalid = AppError.unauthorized('Email or password is incorrect.');
  if (!admin) throw invalid;
  if (!(await verifyPassword(input.password, admin.passwordHash))) throw invalid;
  if (admin.status === 'DISABLED') throw AppError.forbidden('This administrator account has been disabled.');

  const tokens = await issueAdminSession(admin.id, admin.role.key, admin.role.permissions, req);
  return {
    admin: {
      id: admin.id,
      name: admin.name,
      email: admin.email,
      role: admin.role.key,
      roleName: admin.role.name,
      permissions: admin.role.permissions,
      mustChangePassword: admin.mustChangePassword,
    },
    tokens,
  };
}

export async function refreshAdminSession(req: Request, refreshToken: string) {
  const stored = await prisma.adminRefreshToken.findUnique({
    where: { tokenHash: hashToken(refreshToken) },
    select: {
      id: true,
      adminUserId: true,
      expiresAt: true,
      revokedAt: true,
      admin: { select: { status: true, deletedAt: true, role: { select: { key: true, permissions: true } } } },
    },
  });

  if (!stored || stored.revokedAt || stored.expiresAt < new Date() || stored.admin.deletedAt) {
    throw AppError.unauthorized('Your session has expired. Please sign in again.');
  }
  if (stored.admin.status === 'DISABLED') {
    throw AppError.forbidden('This administrator account has been disabled.');
  }

  await prisma.adminRefreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
  return issueAdminSession(stored.adminUserId, stored.admin.role.key, stored.admin.role.permissions, req);
}

export async function adminLogout(refreshToken: string): Promise<void> {
  await prisma.adminRefreshToken.updateMany({
    where: { tokenHash: hashToken(refreshToken), revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

export async function changeAdminPassword(adminUserId: string, currentPassword: string, newPassword: string) {
  const admin = await prisma.adminUser.findUniqueOrThrow({
    where: { id: adminUserId },
    select: { passwordHash: true },
  });
  if (!(await verifyPassword(currentPassword, admin.passwordHash))) {
    throw AppError.validation('Your current password is incorrect.');
  }
  await prisma.adminUser.update({
    where: { id: adminUserId },
    data: { passwordHash: await hashPassword(newPassword), mustChangePassword: false },
  });
  // Every other admin session is invalidated after a password change.
  await prisma.adminRefreshToken.updateMany({
    where: { adminUserId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

export type { TokenAudience };

import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../../lib/async';
import { pathParam } from '../../lib/params';
import { noContent, ok, pageMeta } from '../../lib/http';
import { AppError } from '../../lib/errors';
import { validate } from '../../middleware/validate';
import { requireAdmin } from '../../middleware/auth';
import { prisma } from '../../lib/prisma';
import { audit } from '../../services/auditService';
import { adminUserStatusSchema, idParamSchema, paginationSchema } from '../schemas';

export const adminUsersRouter = Router();

const listQuery = paginationSchema.extend({
  status: z.enum(['ACTIVE', 'DISABLED']).optional(),
  type: z.enum(['GUEST', 'ACCOUNT']).optional(),
});

/**
 * GET /admin/users
 * Passwords are never selected, so they can never be returned by accident.
 */
adminUsersRouter.get(
  '/',
  requireAdmin('users:read'),
  validate(listQuery, 'query'),
  asyncHandler(async (req, res) => {
    const { page, pageSize, search, status, type } = req.query as unknown as {
      page: number;
      pageSize: number;
      search?: string;
      status?: 'ACTIVE' | 'DISABLED';
      type?: 'GUEST' | 'ACCOUNT';
    };

    const where = {
      deletedAt: null,
      ...(status ? { status } : {}),
      ...(type ? { isGuest: type === 'GUEST' } : {}),
      ...(search
        ? {
            OR: [
              { email: { contains: search, mode: 'insensitive' as const } },
              { profile: { displayName: { contains: search, mode: 'insensitive' as const } } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
        select: {
          id: true,
          email: true,
          isGuest: true,
          status: true,
          provider: true,
          lastLoginAt: true,
          createdAt: true,
          profile: { select: { displayName: true, mulank: true, bhagyank: true } },
          _count: { select: { history: true } },
        },
      }),
      prisma.user.count({ where }),
    ]);

    return ok(res, items, pageMeta(page, pageSize, total));
  }),
);

/** GET /admin/users/:id - profile plus recent activity, never credentials. */
adminUsersRouter.get(
  '/:id',
  requireAdmin('users:read'),
  validate(idParamSchema, 'params'),
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findFirst({
      where: { id: pathParam(req, 'id'), deletedAt: null },
      select: {
        id: true,
        email: true,
        isGuest: true,
        status: true,
        provider: true,
        lastLoginAt: true,
        createdAt: true,
        profile: true,
        preferences: true,
        history: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
          take: 20,
          select: { id: true, type: true, label: true, primaryNumber: true, secondaryNumber: true, createdAt: true },
        },
        _count: { select: { history: true, favourites: true } },
      },
    });
    if (!user) throw AppError.notFound('That user does not exist.');
    return ok(res, user);
  }),
);

/** PATCH /admin/users/:id/status - enable or disable an account. */
adminUsersRouter.patch(
  '/:id/status',
  requireAdmin('users:write'),
  validate(idParamSchema, 'params'),
  validate(adminUserStatusSchema),
  asyncHandler(async (req, res) => {
    const before = await prisma.user.findFirst({
      where: { id: pathParam(req, 'id'), deletedAt: null },
      select: { id: true, status: true },
    });
    if (!before) throw AppError.notFound('That user does not exist.');

    const after = await prisma.user.update({
      where: { id: before.id },
      data: { status: req.body.status },
      select: { id: true, status: true },
    });

    // Disabling an account also ends every active session immediately.
    if (req.body.status === 'DISABLED') {
      await prisma.refreshToken.updateMany({
        where: { userId: before.id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }

    await audit({
      adminUserId: req.admin!.id,
      action: req.body.status === 'DISABLED' ? 'users.disabled' : 'users.enabled',
      entityType: 'User',
      entityId: before.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

/**
 * DELETE /admin/users/:id
 * Personal data is removed immediately and the account row is soft deleted,
 * which is what the privacy policy commits to.
 */
adminUsersRouter.delete(
  '/:id',
  requireAdmin('users:delete'),
  validate(idParamSchema, 'params'),
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findFirst({
      where: { id: pathParam(req, 'id'), deletedAt: null },
      select: { id: true, email: true, isGuest: true },
    });
    if (!user) throw AppError.notFound('That user does not exist.');

    await prisma.$transaction([
      prisma.userProfile.deleteMany({ where: { userId: user.id } }),
      prisma.favourite.deleteMany({ where: { userId: user.id } }),
      prisma.calculationHistory.deleteMany({ where: { userId: user.id } }),
      prisma.deviceToken.deleteMany({ where: { userId: user.id } }),
      prisma.refreshToken.deleteMany({ where: { userId: user.id } }),
      prisma.analyticsEvent.updateMany({ where: { userId: user.id }, data: { userId: null } }),
      prisma.user.update({
        where: { id: user.id },
        data: { deletedAt: new Date(), email: null, passwordHash: null, status: 'DISABLED' },
      }),
    ]);

    await audit({
      adminUserId: req.admin!.id,
      action: 'users.deleted',
      entityType: 'User',
      entityId: user.id,
      before: { id: user.id, isGuest: user.isGuest },
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return noContent(res);
  }),
);

/** GET /admin/users/:id/history - paginated activity for support. */
adminUsersRouter.get(
  '/:id/history',
  requireAdmin('users:read'),
  validate(idParamSchema, 'params'),
  validate(paginationSchema, 'query'),
  asyncHandler(async (req, res) => {
    const { page, pageSize } = req.query as unknown as { page: number; pageSize: number };
    const where = { userId: pathParam(req, 'id'), deletedAt: null };
    const [items, total] = await Promise.all([
      prisma.calculationHistory.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      prisma.calculationHistory.count({ where }),
    ]);
    return ok(res, items, pageMeta(page, pageSize, total));
  }),
);

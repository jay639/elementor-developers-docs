import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../../lib/async';
import { pathParam } from '../../lib/params';
import { ok, pageMeta } from '../../lib/http';
import { AppError } from '../../lib/errors';
import { validate } from '../../middleware/validate';
import { requireAdmin } from '../../middleware/auth';
import { prisma } from '../../lib/prisma';
import { audit } from '../../services/auditService';
import { invalidateSettings } from '../../services/settingsService';
import { getOverview } from '../../services/analyticsService';
import { paginationSchema, settingSchema } from '../schemas';

export const adminSettingsRouter = Router();

/** GET /admin/settings */
adminSettingsRouter.get(
  '/settings',
  requireAdmin('settings:read'),
  asyncHandler(async (_req, res) =>
    ok(res, await prisma.appSetting.findMany({ orderBy: [{ group: 'asc' }, { key: 'asc' }] })),
  ),
);

/** PUT /admin/settings/:key */
adminSettingsRouter.put(
  '/settings/:key',
  requireAdmin('settings:write'),
  validate(z.object({ key: z.string().min(1).max(80) }), 'params'),
  validate(settingSchema),
  asyncHandler(async (req, res) => {
    const key = pathParam(req, 'key');
    const before = await prisma.appSetting.findUnique({ where: { key } });
    if (!before) throw AppError.notFound('That setting does not exist.');

    const after = await prisma.appSetting.update({
      where: { key },
      data: { value: req.body.value as object },
    });

    invalidateSettings();
    await audit({
      adminUserId: req.admin!.id,
      action: 'settings.updated',
      entityType: 'AppSetting',
      entityId: after.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

/** GET /admin/analytics - dashboard figures. */
adminSettingsRouter.get(
  '/analytics',
  requireAdmin('analytics:read'),
  asyncHandler(async (req, res) => {
    const days = z.coerce.number().int().min(7).max(90).default(30).parse(req.query.days ?? 30);
    return ok(res, await getOverview(days));
  }),
);

/** GET /admin/audit-logs */
adminSettingsRouter.get(
  '/audit-logs',
  requireAdmin('audit:read'),
  validate(paginationSchema, 'query'),
  asyncHandler(async (req, res) => {
    const { page, pageSize, search } = req.query as unknown as {
      page: number;
      pageSize: number;
      search?: string;
    };
    const where = search
      ? {
          OR: [
            { action: { contains: search, mode: 'insensitive' as const } },
            { entityType: { contains: search, mode: 'insensitive' as const } },
          ],
        }
      : {};

    const [items, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
        include: { admin: { select: { id: true, name: true, email: true } } },
      }),
      prisma.auditLog.count({ where }),
    ]);
    return ok(res, items, pageMeta(page, pageSize, total));
  }),
);

/** GET /admin/roles */
adminSettingsRouter.get(
  '/roles',
  requireAdmin('admins:read'),
  asyncHandler(async (_req, res) => ok(res, await prisma.adminRole.findMany({ orderBy: { key: 'asc' } }))),
);

/** GET /admin/admins - administrator accounts, never their password hashes. */
adminSettingsRouter.get(
  '/admins',
  requireAdmin('admins:read'),
  asyncHandler(async (_req, res) =>
    ok(
      res,
      await prisma.adminUser.findMany({
        where: { deletedAt: null },
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          name: true,
          email: true,
          status: true,
          lastLoginAt: true,
          createdAt: true,
          role: { select: { key: true, name: true } },
        },
      }),
    ),
  ),
);

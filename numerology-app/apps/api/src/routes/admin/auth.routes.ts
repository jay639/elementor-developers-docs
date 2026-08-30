import { Router } from 'express';
import { asyncHandler } from '../../lib/async';
import { ok } from '../../lib/http';
import { validate } from '../../middleware/validate';
import { requireAdmin } from '../../middleware/auth';
import { authLimiter } from '../../middleware/rateLimit';
import { adminChangePasswordSchema, adminLoginSchema, refreshSchema } from '../schemas';
import * as authService from '../../services/authService';
import { audit } from '../../services/auditService';
import { prisma } from '../../lib/prisma';

export const adminAuthRouter = Router();

/** POST /admin/auth/login - separate credential store from the mobile app. */
adminAuthRouter.post(
  '/login',
  authLimiter,
  validate(adminLoginSchema),
  asyncHandler(async (req, res) => {
    const { admin, tokens } = await authService.adminLogin(req, req.body);
    await audit({
      adminUserId: admin.id,
      action: 'admin.login',
      entityType: 'AdminUser',
      entityId: admin.id,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, { admin, tokens });
  }),
);

adminAuthRouter.post(
  '/refresh',
  authLimiter,
  validate(refreshSchema),
  asyncHandler(async (req, res) => ok(res, { tokens: await authService.refreshAdminSession(req, req.body.refreshToken) })),
);

adminAuthRouter.post(
  '/logout',
  validate(refreshSchema),
  asyncHandler(async (req, res) => {
    await authService.adminLogout(req.body.refreshToken);
    return ok(res, { loggedOut: true });
  }),
);

/** GET /admin/auth/me - the signed in administrator and their permissions. */
adminAuthRouter.get(
  '/me',
  requireAdmin(),
  asyncHandler(async (req, res) => {
    const admin = await prisma.adminUser.findUniqueOrThrow({
      where: { id: req.admin!.id },
      select: {
        id: true,
        name: true,
        email: true,
        lastLoginAt: true,
        mustChangePassword: true,
        role: { select: { key: true, name: true, permissions: true } },
      },
    });
    return ok(res, {
      id: admin.id,
      name: admin.name,
      email: admin.email,
      lastLoginAt: admin.lastLoginAt,
      mustChangePassword: admin.mustChangePassword,
      role: admin.role.key,
      roleName: admin.role.name,
      permissions: admin.role.permissions,
    });
  }),
);

/** POST /admin/auth/change-password */
adminAuthRouter.post(
  '/change-password',
  requireAdmin(),
  validate(adminChangePasswordSchema),
  asyncHandler(async (req, res) => {
    await authService.changeAdminPassword(req.admin!.id, req.body.currentPassword, req.body.newPassword);
    await audit({
      adminUserId: req.admin!.id,
      action: 'admin.password_changed',
      entityType: 'AdminUser',
      entityId: req.admin!.id,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, { changed: true });
  }),
);

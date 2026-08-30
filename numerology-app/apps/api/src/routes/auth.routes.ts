import { Router } from 'express';
import { asyncHandler } from '../lib/async';
import { created, ok } from '../lib/http';
import { validate } from '../middleware/validate';
import { optionalUser, requireUser } from '../middleware/auth';
import { authLimiter } from '../middleware/rateLimit';
import { loginSchema, refreshSchema, registerSchema } from './schemas';
import * as authService from '../services/authService';
import { prisma } from '../lib/prisma';
import { coreNumbersFor } from '../services/numerologyService';
import { track } from '../services/analyticsService';

export const authRouter = Router();

/** POST /auth/guest - start using the app without an account. */
authRouter.post(
  '/guest',
  authLimiter,
  asyncHandler(async (req, res) => {
    const { user, tokens } = await authService.createGuest(req);
    await track({ name: 'app_open', userId: user.id, locale: req.locale, properties: { mode: 'guest' } });
    return created(res, { user: { id: user.id, isGuest: true }, tokens });
  }),
);

/** POST /auth/register - create a full account (upgrades a guest in place). */
authRouter.post(
  '/register',
  authLimiter,
  optionalUser,
  validate(registerSchema),
  asyncHandler(async (req, res) => {
    const { user, tokens } = await authService.register(req, req.body);

    if (req.body.dateOfBirth) {
      const numbers = coreNumbersFor(req.body.dateOfBirth);
      await prisma.userProfile.upsert({
        where: { userId: user.id },
        create: { userId: user.id, dateOfBirth: new Date(`${req.body.dateOfBirth}T00:00:00Z`), ...numbers },
        update: { dateOfBirth: new Date(`${req.body.dateOfBirth}T00:00:00Z`), ...numbers },
      });
    }

    return created(res, { user: { id: user.id, isGuest: false }, tokens });
  }),
);

/** POST /auth/login */
authRouter.post(
  '/login',
  authLimiter,
  validate(loginSchema),
  asyncHandler(async (req, res) => {
    const { user, tokens } = await authService.login(req, req.body);
    return ok(res, { user, tokens });
  }),
);

/** POST /auth/refresh - rotates the refresh token. */
authRouter.post(
  '/refresh',
  authLimiter,
  validate(refreshSchema),
  asyncHandler(async (req, res) => {
    const tokens = await authService.refreshUserSession(req, req.body.refreshToken);
    return ok(res, { tokens });
  }),
);

/** POST /auth/logout */
authRouter.post(
  '/logout',
  validate(refreshSchema),
  asyncHandler(async (req, res) => {
    await authService.logout(req.body.refreshToken);
    return ok(res, { loggedOut: true });
  }),
);

/** POST /auth/logout-all - signs the account out on every device. */
authRouter.post(
  '/logout-all',
  requireUser,
  asyncHandler(async (req, res) => {
    await authService.logoutAll(req.user!.id);
    return ok(res, { loggedOut: true });
  }),
);

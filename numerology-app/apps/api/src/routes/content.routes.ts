import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../lib/async';
import { pathParam } from '../lib/params';
import { ok } from '../lib/http';
import { AppError } from '../lib/errors';
import { validate } from '../middleware/validate';
import { optionalUser } from '../middleware/auth';
import {
  getAllNumberContent,
  getCombinationContent,
  getLegalDocument,
  getNumberContent,
  type LegalType,
} from '../services/contentService';
import { getChaldeanGroups, getMarriageRules, getNumberCompatibilityRules } from '../services/rulesService';
import { getPublicSettings } from '../services/settingsService';
import { track } from '../services/analyticsService';
import { analyticsEventSchema, deviceTokenSchema } from './schemas';
import { ALLOWED_EVENTS } from '../services/analyticsService';
import { prisma } from '../lib/prisma';
import { requireUser } from '../middleware/auth';

export const contentRouter = Router();

const numberParam = z.object({ number: z.coerce.number().int().min(1).max(9) });
const combinationParams = z.object({
  mulank: z.coerce.number().int().min(1).max(9),
  bhagyank: z.coerce.number().int().min(1).max(9),
});

/** GET /content/numbers - all nine interpretations, for offline caching. */
contentRouter.get(
  '/numbers',
  asyncHandler(async (req, res) => ok(res, await getAllNumberContent(req.locale))),
);

/** GET /content/numbers/:number */
contentRouter.get(
  '/numbers/:number',
  validate(numberParam, 'params'),
  asyncHandler(async (req, res) => {
    const content = await getNumberContent(Number(pathParam(req, 'number')), req.locale);
    if (!content) throw AppError.notFound('This interpretation is not available yet.');
    return ok(res, content);
  }),
);

/** GET /content/combinations/:mulank/:bhagyank */
contentRouter.get(
  '/combinations/:mulank/:bhagyank',
  validate(combinationParams, 'params'),
  asyncHandler(async (req, res) => {
    const { mulank, bhagyank } = req.params as unknown as { mulank: number; bhagyank: number };
    const content = await getCombinationContent(Number(mulank), Number(bhagyank), req.locale);
    if (!content) throw AppError.notFound('This combination has not been published yet.');
    return ok(res, content);
  }),
);

/**
 * GET /content/rules - the rule tables the mobile app caches so that
 * calculations keep working offline.
 */
contentRouter.get(
  '/rules',
  asyncHandler(async (_req, res) => {
    const [marriage, numbers, chaldean] = await Promise.all([
      getMarriageRules(),
      getNumberCompatibilityRules(),
      getChaldeanGroups(),
    ]);
    return ok(res, { marriage, numbers, chaldean });
  }),
);

/** GET /content/legal/:type */
contentRouter.get(
  '/legal/:type',
  validate(z.object({ type: z.enum(['TERMS', 'PRIVACY', 'DISCLAIMER', 'ABOUT']) }), 'params'),
  asyncHandler(async (req, res) => {
    const document = await getLegalDocument(pathParam(req, 'type') as LegalType, req.locale);
    if (!document) throw AppError.notFound('This document is not available yet.');
    return ok(res, document);
  }),
);

export const settingsRouter = Router();

/** GET /settings - public app configuration, read at startup. */
settingsRouter.get(
  '/',
  asyncHandler(async (_req, res) => ok(res, await getPublicSettings())),
);

export const analyticsRouter = Router();
analyticsRouter.use(optionalUser);

/**
 * POST /analytics/events - records one usage event.
 * Only events on the allow list are stored, and personal fields are stripped.
 */
analyticsRouter.post(
  '/events',
  validate(analyticsEventSchema),
  asyncHandler(async (req, res) => {
    if (!(ALLOWED_EVENTS as readonly string[]).includes(req.body.name)) {
      throw AppError.validation('Unknown analytics event.');
    }

    // Signed in users must have consented; anonymous events carry no identity.
    if (req.user) {
      const preferences = await prisma.userPreference.findUnique({
        where: { userId: req.user.id },
        select: { analyticsConsent: true },
      });
      if (!preferences?.analyticsConsent) {
        return ok(res, { recorded: false, reason: 'CONSENT_NOT_GIVEN' });
      }
    }

    await track({
      name: req.body.name,
      userId: req.user?.id ?? null,
      sessionId: req.body.sessionId ?? null,
      properties: req.body.properties,
      locale: req.locale,
      platform: req.body.platform,
      appVersion: req.body.appVersion,
    });
    return ok(res, { recorded: true });
  }),
);

export const devicesRouter = Router();
devicesRouter.use(requireUser);

/** POST /devices - registers a push notification token. */
devicesRouter.post(
  '/',
  validate(deviceTokenSchema),
  asyncHandler(async (req, res) => {
    const device = await prisma.deviceToken.upsert({
      where: { token: req.body.token },
      create: {
        userId: req.user!.id,
        token: req.body.token,
        platform: req.body.platform,
        locale: req.locale,
        enabled: req.body.enabled,
      },
      update: { userId: req.user!.id, platform: req.body.platform, locale: req.locale, enabled: req.body.enabled },
    });
    return ok(res, { id: device.id, enabled: device.enabled });
  }),
);

/** DELETE /devices/:token - unregisters a device. */
devicesRouter.delete(
  '/:token',
  asyncHandler(async (req, res) => {
    await prisma.deviceToken.deleteMany({ where: { token: pathParam(req, 'token'), userId: req.user!.id } });
    return ok(res, { removed: true });
  }),
);

import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../../lib/async';
import { ok, pageMeta } from '../../lib/http';
import { AppError } from '../../lib/errors';
import { validate } from '../../middleware/validate';
import { requireAdmin } from '../../middleware/auth';
import { prisma } from '../../lib/prisma';
import { audit } from '../../services/auditService';
import { invalidateContent } from '../../services/contentService';
import {
  combinationContentSchema,
  dailyInsightSchema,
  legalDocumentSchema,
  numberContentSchema,
  paginationSchema,
} from '../schemas';

export const adminContentRouter = Router();

const localeParam = z.enum(['en', 'hi', 'mr']);
const numberLocaleParams = z.object({ number: z.coerce.number().int().min(1).max(9), locale: localeParam });
const combinationParams = z.object({
  mulank: z.coerce.number().int().min(1).max(9),
  bhagyank: z.coerce.number().int().min(1).max(9),
  locale: localeParam,
});

// --- Number content -------------------------------------------------------

/** GET /admin/numerology/numbers?locale=en */
adminContentRouter.get(
  '/numbers',
  requireAdmin('content:read'),
  asyncHandler(async (req, res) => {
    const locale = localeParam.parse(req.query.locale ?? 'en');
    const rows = await prisma.numerologyNumber.findMany({ where: { locale }, orderBy: { number: 'asc' } });
    return ok(res, rows);
  }),
);

adminContentRouter.get(
  '/numbers/:number/:locale',
  requireAdmin('content:read'),
  validate(numberLocaleParams, 'params'),
  asyncHandler(async (req, res) => {
    const { number, locale } = req.params as unknown as { number: number; locale: 'en' | 'hi' | 'mr' };
    const row = await prisma.numerologyNumber.findUnique({
      where: { number_locale: { number: Number(number), locale } },
    });
    if (!row) throw AppError.notFound('This number has not been written in this language yet.');
    return ok(res, row);
  }),
);

/** PUT /admin/numerology/numbers/:number/:locale */
adminContentRouter.put(
  '/numbers/:number/:locale',
  requireAdmin('content:write'),
  validate(numberLocaleParams, 'params'),
  validate(numberContentSchema),
  asyncHandler(async (req, res) => {
    const { number, locale } = req.params as unknown as { number: number; locale: 'en' | 'hi' | 'mr' };
    const key = { number: Number(number), locale };
    const before = await prisma.numerologyNumber.findUnique({ where: { number_locale: key } });

    const after = await prisma.numerologyNumber.upsert({
      where: { number_locale: key },
      create: { ...key, ...req.body },
      update: req.body,
    });

    invalidateContent();
    await audit({
      adminUserId: req.admin!.id,
      action: 'content.number_updated',
      entityType: 'NumerologyNumber',
      entityId: after.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

// --- 81 combinations ------------------------------------------------------

/** GET /admin/numerology/combinations - searchable and paginated. */
adminContentRouter.get(
  '/combinations',
  requireAdmin('content:read'),
  validate(paginationSchema, 'query'),
  asyncHandler(async (req, res) => {
    const { page, pageSize, search } = req.query as unknown as {
      page: number;
      pageSize: number;
      search?: string;
    };
    const locale = localeParam.parse((req.query as Record<string, unknown>).locale ?? 'en');

    const where = {
      locale,
      ...(search
        ? {
            OR: [
              { title: { contains: search, mode: 'insensitive' as const } },
              { description: { contains: search, mode: 'insensitive' as const } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      prisma.mulankBhagyankCombination.findMany({
        where,
        orderBy: [{ mulank: 'asc' }, { bhagyank: 'asc' }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      prisma.mulankBhagyankCombination.count({ where }),
    ]);
    return ok(res, items, pageMeta(page, pageSize, total));
  }),
);

adminContentRouter.get(
  '/combinations/:mulank/:bhagyank/:locale',
  requireAdmin('content:read'),
  validate(combinationParams, 'params'),
  asyncHandler(async (req, res) => {
    const { mulank, bhagyank, locale } = req.params as unknown as {
      mulank: number;
      bhagyank: number;
      locale: 'en' | 'hi' | 'mr';
    };
    const row = await prisma.mulankBhagyankCombination.findUnique({
      where: {
        mulank_bhagyank_locale: { mulank: Number(mulank), bhagyank: Number(bhagyank), locale },
      },
    });
    if (!row) throw AppError.notFound('This combination has not been written in this language yet.');
    return ok(res, row);
  }),
);

/** PUT /admin/numerology/combinations/:mulank/:bhagyank/:locale */
adminContentRouter.put(
  '/combinations/:mulank/:bhagyank/:locale',
  requireAdmin('content:write'),
  validate(combinationParams, 'params'),
  validate(combinationContentSchema),
  asyncHandler(async (req, res) => {
    const { mulank, bhagyank, locale } = req.params as unknown as {
      mulank: number;
      bhagyank: number;
      locale: 'en' | 'hi' | 'mr';
    };
    const key = { mulank: Number(mulank), bhagyank: Number(bhagyank), locale };
    const before = await prisma.mulankBhagyankCombination.findUnique({
      where: { mulank_bhagyank_locale: key },
    });

    const after = await prisma.mulankBhagyankCombination.upsert({
      where: { mulank_bhagyank_locale: key },
      create: { ...key, ...req.body },
      update: req.body,
    });

    invalidateContent();
    await audit({
      adminUserId: req.admin!.id,
      action: 'content.combination_updated',
      entityType: 'MulankBhagyankCombination',
      entityId: after.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

// --- Daily number insights ------------------------------------------------

adminContentRouter.get(
  '/daily-insights',
  requireAdmin('content:read'),
  asyncHandler(async (req, res) => {
    const locale = localeParam.parse(req.query.locale ?? 'en');
    return ok(res, await prisma.dailyNumberInsight.findMany({ where: { locale }, orderBy: { number: 'asc' } }));
  }),
);

adminContentRouter.put(
  '/daily-insights/:number/:locale',
  requireAdmin('content:write'),
  validate(numberLocaleParams, 'params'),
  validate(dailyInsightSchema),
  asyncHandler(async (req, res) => {
    const { number, locale } = req.params as unknown as { number: number; locale: 'en' | 'hi' | 'mr' };
    const key = { number: Number(number), locale };
    const before = await prisma.dailyNumberInsight.findUnique({ where: { number_locale: key } });
    const after = await prisma.dailyNumberInsight.upsert({
      where: { number_locale: key },
      create: { ...key, ...req.body },
      update: req.body,
    });
    invalidateContent();
    await audit({
      adminUserId: req.admin!.id,
      action: 'content.daily_insight_updated',
      entityType: 'DailyNumberInsight',
      entityId: after.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

// --- Legal documents ------------------------------------------------------

adminContentRouter.get(
  '/legal',
  requireAdmin('content:read'),
  asyncHandler(async (req, res) => {
    const locale = localeParam.parse(req.query.locale ?? 'en');
    return ok(res, await prisma.legalDocument.findMany({ where: { locale }, orderBy: { type: 'asc' } }));
  }),
);

adminContentRouter.put(
  '/legal/:type/:locale',
  requireAdmin('content:write'),
  validate(
    z.object({ type: z.enum(['TERMS', 'PRIVACY', 'DISCLAIMER', 'ABOUT']), locale: localeParam }),
    'params',
  ),
  validate(legalDocumentSchema),
  asyncHandler(async (req, res) => {
    const { type, locale } = req.params as unknown as {
      type: 'TERMS' | 'PRIVACY' | 'DISCLAIMER' | 'ABOUT';
      locale: 'en' | 'hi' | 'mr';
    };
    const before = await prisma.legalDocument.findUnique({ where: { type_locale: { type, locale } } });
    const after = await prisma.legalDocument.upsert({
      where: { type_locale: { type, locale } },
      create: { type, locale, ...req.body, publishedAt: new Date() },
      update: { ...req.body, publishedAt: new Date() },
    });
    invalidateContent();
    await audit({
      adminUserId: req.admin!.id,
      action: 'content.legal_updated',
      entityType: 'LegalDocument',
      entityId: after.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

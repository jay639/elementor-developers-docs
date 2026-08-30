import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../../lib/async';
import { pathParam } from '../../lib/params';
import { ok } from '../../lib/http';
import { AppError } from '../../lib/errors';
import { validate } from '../../middleware/validate';
import { requireAdmin } from '../../middleware/auth';
import { prisma } from '../../lib/prisma';
import { audit } from '../../services/auditService';
import { invalidateRules } from '../../services/rulesService';
import { chaldeanMappingSchema, marriageRuleSchema, numberRuleSchema } from '../schemas';

export const adminRulesRouter = Router();

const driverParam = z.object({ driverNumber: z.coerce.number().int().min(1).max(9) });
const baseParam = z.object({ baseNumber: z.coerce.number().int().min(1).max(9) });

/**
 * GET /admin/compatibility-rules
 * The nine marriage rules. The engine evaluates each rule in both directions,
 * so editing a row changes how that number behaves as a driver AND how partners
 * with that number are matched against.
 */
adminRulesRouter.get(
  '/compatibility-rules',
  requireAdmin('rules:read'),
  asyncHandler(async (_req, res) =>
    ok(res, await prisma.marriageCompatibilityRule.findMany({ orderBy: { driverNumber: 'asc' } })),
  ),
);

/** PUT /admin/compatibility-rules/:driverNumber */
adminRulesRouter.put(
  '/compatibility-rules/:driverNumber',
  requireAdmin('rules:write'),
  validate(driverParam, 'params'),
  validate(marriageRuleSchema),
  asyncHandler(async (req, res) => {
    const driverNumber = Number(pathParam(req, 'driverNumber'));
    const before = await prisma.marriageCompatibilityRule.findUnique({ where: { driverNumber } });
    if (!before) throw AppError.notFound('That rule does not exist.');

    const after = await prisma.marriageCompatibilityRule.update({
      where: { driverNumber },
      data: {
        compatibleMulank: [...new Set(req.body.compatibleMulank as number[])].sort((a, b) => a - b),
        compatibleBhagyank: [...new Set(req.body.compatibleBhagyank as number[])].sort((a, b) => a - b),
        ...(req.body.enabled === undefined ? {} : { enabled: req.body.enabled }),
        ...(req.body.notes === undefined ? {} : { notes: req.body.notes }),
      },
    });

    invalidateRules();
    await audit({
      adminUserId: req.admin!.id,
      action: 'rules.marriage_updated',
      entityType: 'MarriageCompatibilityRule',
      entityId: after.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

/** GET /admin/number-rules - friendly/neutral/unfriendly table. */
adminRulesRouter.get(
  '/number-rules',
  requireAdmin('rules:read'),
  asyncHandler(async (_req, res) =>
    ok(res, await prisma.numberCompatibilityRule.findMany({ orderBy: { baseNumber: 'asc' } })),
  ),
);

/** PUT /admin/number-rules/:baseNumber */
adminRulesRouter.put(
  '/number-rules/:baseNumber',
  requireAdmin('rules:write'),
  validate(baseParam, 'params'),
  validate(numberRuleSchema),
  asyncHandler(async (req, res) => {
    const baseNumber = Number(pathParam(req, 'baseNumber'));
    const before = await prisma.numberCompatibilityRule.findUnique({ where: { baseNumber } });
    if (!before) throw AppError.notFound('That rule does not exist.');

    const after = await prisma.numberCompatibilityRule.update({
      where: { baseNumber },
      data: {
        friendly: req.body.friendly,
        neutral: req.body.neutral,
        unfriendly: req.body.unfriendly,
        ...(req.body.enabled === undefined ? {} : { enabled: req.body.enabled }),
      },
    });

    invalidateRules();
    await audit({
      adminUserId: req.admin!.id,
      action: 'rules.number_updated',
      entityType: 'NumberCompatibilityRule',
      entityId: after.id,
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, after);
  }),
);

/** GET /admin/chaldean-mappings - the letter table, grouped by value. */
adminRulesRouter.get(
  '/chaldean-mappings',
  requireAdmin('rules:read'),
  asyncHandler(async (_req, res) => {
    const rows = await prisma.chaldeanMapping.findMany({ orderBy: [{ value: 'asc' }, { letter: 'asc' }] });
    const groups: Record<number, string[]> = { 1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [], 8: [], 9: [] };
    for (const row of rows) groups[row.value]?.push(row.letter);
    return ok(res, { groups, letters: rows });
  }),
);

/**
 * PUT /admin/chaldean-mappings
 * Replaces the whole table in one transaction. A letter may appear only once,
 * and the table is rejected if it would leave a letter unmapped.
 */
adminRulesRouter.put(
  '/chaldean-mappings',
  requireAdmin('rules:write'),
  validate(chaldeanMappingSchema),
  asyncHandler(async (req, res) => {
    const groups = req.body.groups as Record<string, string[]>;
    const assignments = new Map<string, number>();

    for (const [value, letters] of Object.entries(groups)) {
      for (const rawLetter of letters) {
        const letter = rawLetter.toUpperCase();
        if (assignments.has(letter)) {
          throw AppError.validation(`Letter ${letter} is assigned to more than one value.`);
        }
        assignments.set(letter, Number(value));
      }
    }
    if (assignments.size === 0) {
      throw AppError.validation('At least one letter must be mapped.');
    }

    const before = await prisma.chaldeanMapping.findMany({ orderBy: { letter: 'asc' } });

    await prisma.$transaction([
      prisma.chaldeanMapping.deleteMany({}),
      prisma.chaldeanMapping.createMany({
        data: [...assignments.entries()].map(([letter, value]) => ({ letter, value, enabled: true })),
      }),
    ]);

    const after = await prisma.chaldeanMapping.findMany({ orderBy: { letter: 'asc' } });
    invalidateRules();
    await audit({
      adminUserId: req.admin!.id,
      action: 'rules.chaldean_updated',
      entityType: 'ChaldeanMapping',
      before,
      after,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
    return ok(res, { groups, letters: after });
  }),
);

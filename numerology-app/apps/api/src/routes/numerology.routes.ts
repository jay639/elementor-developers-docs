import { Router, type Request } from 'express';
import { formatISODate, parseDateOfBirth } from '@numerology/core';
import { asyncHandler } from '../lib/async';
import { ok } from '../lib/http';
import { AppError } from '../lib/errors';
import { validate } from '../middleware/validate';
import { optionalUser } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import {
  compatibilitySchema,
  coreNumbersSchema,
  dailyNumberSchema,
  luckyNumberSchema,
  nameNumerologySchema,
} from './schemas';
import {
  buildCoreNumbers,
  buildDailyNumber,
  buildLuckyNumber,
  buildMarriageCompatibility,
  buildNameNumerology,
  coreNumbersFor,
} from '../services/numerologyService';
import { recordHistory } from '../services/historyService';
import { track } from '../services/analyticsService';
import { messages } from '../services/messages';

export const numerologyRouter = Router();

// Calculations work for guests and signed out visitors; a token only adds
// history and the saved global date of birth.
numerologyRouter.use(optionalUser);

/** The user's saved global date of birth, if they have one. */
async function savedDob(userId: string | undefined): Promise<string | null> {
  if (!userId) return null;
  const profile = await prisma.userProfile.findUnique({
    where: { userId },
    select: { dateOfBirth: true },
  });
  return profile?.dateOfBirth ? profile.dateOfBirth.toISOString().slice(0, 10) : null;
}

/**
 * Stores a date of birth as the user's global date of birth. Called only when
 * the client explicitly sends `save: true`, so a one-off calculation never
 * overwrites the saved value.
 */
async function persistDob(userId: string, iso: string) {
  const numbers = coreNumbersFor(iso);
  await prisma.userProfile.upsert({
    where: { userId },
    create: { userId, dateOfBirth: new Date(`${iso}T00:00:00Z`), ...numbers },
    update: { dateOfBirth: new Date(`${iso}T00:00:00Z`), ...numbers },
  });
}

/**
 * Resolves which date of birth to use: the one sent with the request, or the
 * user's saved date of birth. This is what makes the global date of birth work
 * everywhere without asking the user again.
 */
async function resolveDob(
  req: Request,
  supplied: string | null | undefined,
): Promise<{ iso: string | null; fromProfile: boolean }> {
  if (supplied) {
    return { iso: formatISODate(parseDateOfBirth(supplied)), fromProfile: false };
  }
  const stored = await savedDob(req.user?.id);
  return { iso: stored, fromProfile: stored !== null };
}

/** POST /numerology/calculate - Mulank, Bhagyank and their interpretation. */
numerologyRouter.post(
  '/calculate',
  validate(coreNumbersSchema),
  asyncHandler(async (req, res) => {
    const { iso, fromProfile } = await resolveDob(req, req.body.dateOfBirth);
    if (!iso) {
      throw AppError.validation(messages.missingDob(req.locale), { needsDob: true });
    }

    const result = await buildCoreNumbers(iso, req.locale);

    if (req.user && req.body.save && !fromProfile) {
      await persistDob(req.user.id, iso);
    }
    if (req.user) {
      await recordHistory({
        userId: req.user.id,
        type: 'CORE_NUMBERS',
        label: iso,
        input: { dateOfBirth: iso },
        result: { mulank: result.mulank, bhagyank: result.bhagyank },
        primaryNumber: result.mulank,
        secondaryNumber: result.bhagyank,
        locale: req.locale,
      });
    }
    await track({ name: 'mulank_calculated', userId: req.user?.id, locale: req.locale });

    return ok(res, { ...result, dobFromProfile: fromProfile });
  }),
);

/** POST /numerology/lucky-number - any vehicle, mobile or house number. */
numerologyRouter.post(
  '/lucky-number',
  validate(luckyNumberSchema),
  asyncHandler(async (req, res) => {
    const { iso, fromProfile } = await resolveDob(req, req.body.dateOfBirth);
    const result = await buildLuckyNumber(req.body.number, iso, req.locale);

    if (req.user && req.body.save && iso && !fromProfile) {
      await persistDob(req.user.id, iso);
    }
    if (req.user) {
      await recordHistory({
        userId: req.user.id,
        type: 'LUCKY_NUMBER',
        label: result.input,
        input: { number: result.input, dateOfBirth: iso },
        result: { root: result.root, compound: result.compound, overall: result.overall, score: result.score },
        primaryNumber: result.root,
        secondaryNumber: result.mulank,
        locale: req.locale,
      });
    }
    await track({ name: 'lucky_number_checked', userId: req.user?.id, locale: req.locale });

    return ok(res, { ...result, dobFromProfile: fromProfile });
  }),
);

/** POST /numerology/name - Chaldean name numerology. */
numerologyRouter.post(
  '/name',
  validate(nameNumerologySchema),
  asyncHandler(async (req, res) => {
    const { iso, fromProfile } = req.body.compareWithDob
      ? await resolveDob(req, req.body.dateOfBirth)
      : { iso: null, fromProfile: false };

    const result = await buildNameNumerology(req.body.name, iso, req.locale);

    if (req.user) {
      await recordHistory({
        userId: req.user.id,
        type: 'NAME_NUMEROLOGY',
        label: result.name,
        input: { name: result.name, dateOfBirth: iso },
        result: { compound: result.compound, root: result.root },
        primaryNumber: result.root,
        secondaryNumber: result.compound,
        locale: req.locale,
      });
    }
    await track({ name: 'name_numerology_used', userId: req.user?.id, locale: req.locale });

    return ok(res, { ...result, dobFromProfile: fromProfile });
  }),
);

/** POST /numerology/compatibility - bidirectional marriage compatibility. */
numerologyRouter.post(
  '/compatibility',
  validate(compatibilitySchema),
  asyncHandler(async (req, res) => {
    const result = await buildMarriageCompatibility(
      req.body.maleDateOfBirth,
      req.body.femaleDateOfBirth,
      req.locale,
    );

    if (req.user) {
      await recordHistory({
        userId: req.user.id,
        type: 'MARRIAGE_COMPATIBILITY',
        label: `${result.male.dob} / ${result.female.dob}`,
        input: { maleDateOfBirth: result.male.dob, femaleDateOfBirth: result.female.dob },
        result: {
          verdict: result.verdict,
          score: result.score,
          matchedDirections: result.matchedDirections,
          male: result.male,
          female: result.female,
        },
        primaryNumber: result.male.mulank,
        secondaryNumber: result.female.mulank,
        locale: req.locale,
      });
    }
    await track({
      name: 'compatibility_checked',
      userId: req.user?.id,
      locale: req.locale,
      properties: { verdict: result.verdict },
    });

    return ok(res, result);
  }),
);

/** GET /numerology/daily - Today's Lucky Number, derived from the date. */
numerologyRouter.get(
  '/daily',
  validate(dailyNumberSchema, 'query'),
  asyncHandler(async (req, res) => {
    const date = (req.query as { date?: string }).date;
    const result = await buildDailyNumber(date, req.locale);
    await track({ name: 'daily_number_viewed', userId: req.user?.id, locale: req.locale });
    return ok(res, result);
  }),
);

/** GET /numerology/summary - everything the home screen needs in one call. */
numerologyRouter.get(
  '/summary',
  asyncHandler(async (req, res) => {
    const iso = await savedDob(req.user?.id);
    const [daily, core] = await Promise.all([
      buildDailyNumber(undefined, req.locale),
      iso ? buildCoreNumbers(iso, req.locale) : Promise.resolve(null),
    ]);

    return ok(res, {
      daily,
      numbers: core ? { dob: core.dob, mulank: core.mulank, bhagyank: core.bhagyank } : null,
      needsDob: core === null,
      needsDobMessage: core === null ? messages.missingDob(req.locale) : null,
    });
  }),
);

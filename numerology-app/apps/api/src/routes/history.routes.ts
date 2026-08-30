import { Router } from 'express';
import { asyncHandler } from '../lib/async';
import { pathParam } from '../lib/params';
import { created, noContent, ok, pageMeta } from '../lib/http';
import { AppError } from '../lib/errors';
import { validate } from '../middleware/validate';
import { requireUser } from '../middleware/auth';
import { favouriteSchema, historyQuerySchema, idParamSchema, paginationSchema } from './schemas';
import { clearHistory, deleteHistoryEntry, listHistory } from '../services/historyService';
import { prisma } from '../lib/prisma';
import { track } from '../services/analyticsService';

export const historyRouter = Router();

historyRouter.use(requireUser);

/** GET /history - paginated calculation history. */
historyRouter.get(
  '/',
  validate(historyQuerySchema, 'query'),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as { page: number; pageSize: number; type?: never; search?: string };
    const { items, total } = await listHistory({ userId: req.user!.id, ...query });
    await track({ name: 'history_viewed', userId: req.user!.id, locale: req.locale });
    return ok(res, items, pageMeta(query.page, query.pageSize, total));
  }),
);

/** GET /history/:id */
historyRouter.get(
  '/:id',
  validate(idParamSchema, 'params'),
  asyncHandler(async (req, res) => {
    const id = pathParam(req, 'id');
    const entry = await prisma.calculationHistory.findFirst({
      where: { id, userId: req.user!.id, deletedAt: null },
    });
    if (!entry) throw AppError.notFound('That calculation is no longer available.');
    return ok(res, entry);
  }),
);

/** DELETE /history/:id */
historyRouter.delete(
  '/:id',
  validate(idParamSchema, 'params'),
  asyncHandler(async (req, res) => {
    const deleted = await deleteHistoryEntry(req.user!.id, pathParam(req, 'id'));
    if (!deleted) throw AppError.notFound('That calculation is no longer available.');
    return noContent(res);
  }),
);

/** DELETE /history - clears the whole history. */
historyRouter.delete(
  '/',
  asyncHandler(async (req, res) => {
    const count = await clearHistory(req.user!.id);
    await track({ name: 'history_cleared', userId: req.user!.id, locale: req.locale });
    return ok(res, { cleared: count });
  }),
);

export const favouritesRouter = Router();
favouritesRouter.use(requireUser);

/** GET /favourites - saved calculations. */
favouritesRouter.get(
  '/',
  validate(paginationSchema, 'query'),
  asyncHandler(async (req, res) => {
    const { page, pageSize } = req.query as unknown as { page: number; pageSize: number };
    const where = { userId: req.user!.id, deletedAt: null };
    const [items, total] = await Promise.all([
      prisma.favourite.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      prisma.favourite.count({ where }),
    ]);
    return ok(res, items, pageMeta(page, pageSize, total));
  }),
);

/** POST /favourites */
favouritesRouter.post(
  '/',
  validate(favouriteSchema),
  asyncHandler(async (req, res) => {
    const favourite = await prisma.favourite.create({
      data: {
        userId: req.user!.id,
        historyId: req.body.historyId ?? null,
        type: req.body.type,
        label: req.body.label,
        input: req.body.input,
        result: req.body.result,
      },
    });
    await track({ name: 'favourite_saved', userId: req.user!.id, locale: req.locale });
    return created(res, favourite);
  }),
);

/** DELETE /favourites/:id */
favouritesRouter.delete(
  '/:id',
  validate(idParamSchema, 'params'),
  asyncHandler(async (req, res) => {
    const result = await prisma.favourite.updateMany({
      where: { id: pathParam(req, 'id'), userId: req.user!.id, deletedAt: null },
      data: { deletedAt: new Date() },
    });
    if (result.count === 0) throw AppError.notFound('That saved result is no longer available.');
    return noContent(res);
  }),
);

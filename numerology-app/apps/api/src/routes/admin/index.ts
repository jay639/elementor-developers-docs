import { Router } from 'express';
import { adminAuthRouter } from './auth.routes';
import { adminContentRouter } from './content.routes';
import { adminRulesRouter } from './rules.routes';
import { adminUsersRouter } from './users.routes';
import { adminSettingsRouter } from './settings.routes';

/**
 * Admin API. Mounted under /api/v1/admin and completely separate from the user
 * API: different tokens, different credential store, permission checks on every
 * route. Maintenance mode does not apply here, so an administrator can always
 * turn it off again.
 */
export const adminRouter = Router();

adminRouter.use('/auth', adminAuthRouter);
adminRouter.use('/numerology', adminContentRouter);
adminRouter.use('/', adminRulesRouter);
adminRouter.use('/users', adminUsersRouter);
adminRouter.use('/', adminSettingsRouter);

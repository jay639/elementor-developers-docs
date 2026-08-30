import { Router } from 'express';
import { authRouter } from './auth.routes';
import { profileRouter } from './profile.routes';
import { numerologyRouter } from './numerology.routes';
import { historyRouter, favouritesRouter } from './history.routes';
import { analyticsRouter, contentRouter, devicesRouter, settingsRouter } from './content.routes';
import { adminRouter } from './admin';
import { maintenanceGuard } from '../middleware/maintenance';

export const apiRouter = Router();

// The admin API is mounted first and is never affected by maintenance mode.
apiRouter.use('/admin', adminRouter);

// Everything below is the user facing API.
apiRouter.use(maintenanceGuard);
apiRouter.use('/auth', authRouter);
apiRouter.use('/profile', profileRouter);
apiRouter.use('/numerology', numerologyRouter);
apiRouter.use('/history', historyRouter);
apiRouter.use('/favourites', favouritesRouter);
apiRouter.use('/content', contentRouter);
apiRouter.use('/settings', settingsRouter);
apiRouter.use('/analytics', analyticsRouter);
apiRouter.use('/devices', devicesRouter);

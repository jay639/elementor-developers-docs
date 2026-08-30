import type { NextFunction, Request, Response } from 'express';
import { AppError } from '../lib/errors';
import { getSetting } from '../services/settingsService';

interface MaintenanceSetting {
  enabled?: boolean;
  message?: Record<string, string>;
}

/**
 * When an administrator turns maintenance mode on, user facing endpoints stop
 * serving. Admin endpoints and the health check keep working so the mode can be
 * turned off again.
 */
export async function maintenanceGuard(req: Request, _res: Response, next: NextFunction) {
  try {
    const setting = await getSetting<MaintenanceSetting>('maintenance');
    if (!setting?.enabled) {
      next();
      return;
    }
    const message =
      setting.message?.[req.locale] ??
      setting.message?.en ??
      'We are carrying out scheduled maintenance. Please try again shortly.';
    next(new AppError('MAINTENANCE', message));
  } catch (error) {
    next(error);
  }
}

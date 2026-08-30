import type { Request } from 'express';
import { AppError } from './errors';

/**
 * Reads a route parameter that is guaranteed to be present by the route
 * definition. Returning a plain string (rather than `string | undefined`)
 * prevents an accidental `where: { id: undefined }`, which in Prisma would
 * match every row instead of none.
 */
export function pathParam(req: Request, name: string): string {
  const value = (req.params as Record<string, string | undefined>)[name];
  if (!value) throw AppError.validation('Invalid identifier.');
  return value;
}

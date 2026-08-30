import type { NextFunction, Request, Response } from 'express';
import { ZodError, type ZodSchema } from 'zod';
import { AppError } from '../lib/errors';

type Source = 'body' | 'query' | 'params';

/**
 * Validates and replaces one part of the request with the parsed result, so
 * handlers always receive typed, sanitised input. Every write endpoint in this
 * API validates server side - client validation is never trusted.
 */
export function validate<T>(schema: ZodSchema<T>, source: Source = 'body') {
  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      const parsed = schema.parse(req[source]);
      if (source === 'body') {
        req.body = parsed;
      } else {
        // req.query and req.params are getter-only in Express 5 style typings.
        Object.defineProperty(req, source, { value: parsed, writable: true, configurable: true });
      }
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        next(
          AppError.validation(
            'Please check the information you entered.',
            error.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message })),
          ),
        );
        return;
      }
      next(error);
    }
  };
}

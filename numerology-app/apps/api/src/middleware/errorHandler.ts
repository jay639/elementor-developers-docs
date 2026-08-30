import type { NextFunction, Request, Response } from 'express';
import { Prisma } from '@prisma/client';
import { NumerologyError } from '@numerology/core';
import { AppError, type ErrorCode } from '../lib/errors';
import { logger } from '../lib/logger';
import { env } from '../config/env';

/** Numerology engine errors map onto friendly, user facing messages. */
const NUMEROLOGY_MESSAGES: Record<string, string> = {
  INVALID_DATE: 'Please enter a valid date of birth.',
  FUTURE_DATE: 'A date of birth cannot be in the future.',
  DATE_TOO_OLD: 'Please enter a date of birth after 1900.',
  EMPTY_NUMBER: 'Please enter a number.',
  NO_DIGITS: 'Please enter a value that contains at least one digit.',
  NUMBER_TOO_LONG: 'That number is too long. Please enter a shorter number.',
  EMPTY_NAME: 'Please enter a name.',
  NAME_TOO_LONG: 'That name is too long. Please enter a shorter name.',
  NO_MAPPABLE_LETTERS: 'Please enter a name using English letters.',
};

export function notFoundHandler(_req: Request, res: Response) {
  res.status(404).json({
    success: false,
    error: { code: 'NOT_FOUND', message: 'We could not find what you were looking for.' },
  });
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function errorHandler(error: unknown, req: Request, res: Response, _next: NextFunction) {
  let code: ErrorCode = 'INTERNAL_ERROR';
  let status = 500;
  let message = 'Something went wrong. Please try again.';
  let details: unknown;

  if (error instanceof AppError) {
    code = error.code;
    status = error.status;
    message = error.message;
    details = error.details;
  } else if (error instanceof NumerologyError) {
    code = 'VALIDATION_ERROR';
    status = 422;
    message = NUMEROLOGY_MESSAGES[error.code] ?? 'Please check the information you entered.';
    details = { reason: error.code };
  } else if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      code = 'CONFLICT';
      status = 409;
      message = 'That record already exists.';
    } else if (error.code === 'P2025') {
      code = 'NOT_FOUND';
      status = 404;
      message = 'We could not find what you were looking for.';
    }
  }

  // Technical detail is logged for developers; the client only ever sees the
  // safe message above.
  const logPayload = {
    err: error,
    requestId: req.get('x-request-id'),
    method: req.method,
    path: req.originalUrl,
    status,
  };
  if (status >= 500) {
    logger.error(logPayload, 'Unhandled error');
  } else {
    logger.warn(logPayload, 'Request failed');
  }

  const body: Record<string, unknown> = { code, message };
  if (details !== undefined) body.details = details;
  // Stack traces are never returned in production.
  if (!env.isProduction && status >= 500 && error instanceof Error) {
    body.debug = error.message;
  }

  res.status(status).json({ success: false, error: body });
}

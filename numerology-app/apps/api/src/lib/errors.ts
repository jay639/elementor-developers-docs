/**
 * Application error codes. The API returns the code and a safe, already
 * localisable message; the underlying technical detail is logged, never sent
 * to the client.
 */
export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'RATE_LIMITED'
  | 'MAINTENANCE'
  | 'INTERNAL_ERROR';

const STATUS: Record<ErrorCode, number> = {
  VALIDATION_ERROR: 422,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  RATE_LIMITED: 429,
  MAINTENANCE: 503,
  INTERNAL_ERROR: 500,
};

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly status: number;
  readonly details?: unknown;

  constructor(code: ErrorCode, message: string, details?: unknown) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.status = STATUS[code];
    this.details = details;
  }

  static validation(message = 'The information you entered is not valid.', details?: unknown) {
    return new AppError('VALIDATION_ERROR', message, details);
  }

  static unauthorized(message = 'Please sign in to continue.') {
    return new AppError('UNAUTHORIZED', message);
  }

  static forbidden(message = 'You do not have permission to do that.') {
    return new AppError('FORBIDDEN', message);
  }

  static notFound(message = 'We could not find what you were looking for.') {
    return new AppError('NOT_FOUND', message);
  }

  static conflict(message: string) {
    return new AppError('CONFLICT', message);
  }
}

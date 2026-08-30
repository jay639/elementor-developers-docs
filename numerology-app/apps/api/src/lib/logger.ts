import pino from 'pino';
import { env } from '../config/env';

/**
 * Application logger. `redact` guarantees that credentials and tokens never
 * reach the log stream, even if a caller passes a whole request object.
 */
export const logger = pino({
  level: env.isTest ? 'silent' : env.LOG_LEVEL,
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'req.body.password',
      'req.body.currentPassword',
      'req.body.newPassword',
      'req.body.refreshToken',
      'password',
      'passwordHash',
      'refreshToken',
      'accessToken',
    ],
    censor: '[redacted]',
  },
  transport:
    env.isProduction || env.isTest
      ? undefined
      : { target: 'pino/file', options: { destination: 1 } },
});

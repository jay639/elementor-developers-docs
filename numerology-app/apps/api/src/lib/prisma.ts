import { PrismaClient } from '@prisma/client';
import { env } from '../config/env';

/**
 * A single Prisma client for the process. Prisma uses parameterised queries
 * throughout, which is what protects the application from SQL injection - raw
 * string interpolation into a query is never used anywhere in this codebase.
 */
export const prisma = new PrismaClient({
  log: env.isProduction ? ['warn', 'error'] : ['warn', 'error'],
});

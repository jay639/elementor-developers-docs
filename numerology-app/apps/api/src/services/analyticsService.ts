import type { Locale as PrismaLocale, Platform, Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { logger } from '../lib/logger';

/** Events the client is allowed to record. Anything else is rejected. */
export const ALLOWED_EVENTS = [
  'app_open',
  'onboarding_started',
  'onboarding_completed',
  'dob_saved',
  'dob_skipped',
  'mulank_calculated',
  'lucky_number_checked',
  'name_numerology_used',
  'compatibility_checked',
  'daily_number_viewed',
  'history_viewed',
  'history_cleared',
  'favourite_saved',
  'result_shared',
  'profile_updated',
  'language_changed',
  'theme_changed',
  'notification_opened',
] as const;

export type AllowedEvent = (typeof ALLOWED_EVENTS)[number];

/** Property keys that must never be recorded, even if a client sends them. */
const BLOCKED_PROPERTIES = new Set(['dob', 'dateofbirth', 'date_of_birth', 'name', 'email', 'phone', 'password']);

function sanitiseProperties(properties: Record<string, unknown>): Prisma.InputJsonValue {
  const clean: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(properties)) {
    if (BLOCKED_PROPERTIES.has(key.toLowerCase())) continue;
    if (value === null || ['string', 'number', 'boolean'].includes(typeof value)) {
      clean[key] = typeof value === 'string' ? value.slice(0, 120) : value;
    }
  }
  return clean as Prisma.InputJsonValue;
}

export interface TrackInput {
  name: string;
  userId?: string | null;
  sessionId?: string | null;
  properties?: Record<string, unknown>;
  locale: PrismaLocale;
  platform?: Platform;
  appVersion?: string | null;
}

/**
 * Records an analytics event. Failures never break the request that triggered
 * them - analytics is best effort by design.
 */
export async function track(input: TrackInput): Promise<void> {
  try {
    await prisma.analyticsEvent.create({
      data: {
        name: input.name,
        userId: input.userId ?? null,
        sessionId: input.sessionId ?? null,
        properties: sanitiseProperties(input.properties ?? {}),
        locale: input.locale,
        platform: input.platform ?? 'ANDROID',
        appVersion: input.appVersion ?? null,
      },
    });
  } catch (error) {
    logger.warn({ err: error, event: input.name }, 'Failed to record analytics event');
  }
}

export interface AnalyticsOverview {
  totals: { users: number; activeUsers: number; newUsers: number; calculations: number; guests: number };
  calculationsByType: Array<{ type: string; count: number }>;
  topEvents: Array<{ name: string; count: number }>;
  dailyActivity: Array<{ date: string; calculations: number; events: number }>;
  localeBreakdown: Array<{ locale: string; users: number }>;
}

function daysAgo(days: number): Date {
  const date = new Date();
  date.setDate(date.getDate() - days);
  date.setHours(0, 0, 0, 0);
  return date;
}

/** Dashboard figures for the admin panel. */
export async function getOverview(days = 30): Promise<AnalyticsOverview> {
  const since = daysAgo(days);

  const [users, guests, newUsers, activeUsers, calculations, byType, events, localeRows] = await Promise.all([
    prisma.user.count({ where: { deletedAt: null } }),
    prisma.user.count({ where: { deletedAt: null, isGuest: true } }),
    prisma.user.count({ where: { deletedAt: null, createdAt: { gte: since } } }),
    prisma.user.count({ where: { deletedAt: null, lastLoginAt: { gte: daysAgo(7) } } }),
    prisma.calculationHistory.count({ where: { deletedAt: null } }),
    prisma.calculationHistory.groupBy({
      by: ['type'],
      _count: { _all: true },
      where: { deletedAt: null, createdAt: { gte: since } },
    }),
    prisma.analyticsEvent.groupBy({
      by: ['name'],
      _count: { _all: true },
      where: { createdAt: { gte: since } },
      orderBy: { _count: { name: 'desc' } },
      take: 10,
    }),
    prisma.userPreference.groupBy({ by: ['locale'], _count: { _all: true } }),
  ]);

  // Daily buckets are built with parameterised queries through Prisma rather
  // than string interpolation.
  const [historyRows, eventRows] = await Promise.all([
    prisma.calculationHistory.findMany({
      where: { deletedAt: null, createdAt: { gte: since } },
      select: { createdAt: true },
    }),
    prisma.analyticsEvent.findMany({ where: { createdAt: { gte: since } }, select: { createdAt: true } }),
  ]);

  const buckets = new Map<string, { calculations: number; events: number }>();
  for (let index = days - 1; index >= 0; index -= 1) {
    const date = daysAgo(index).toISOString().slice(0, 10);
    buckets.set(date, { calculations: 0, events: 0 });
  }
  for (const row of historyRows) {
    const key = row.createdAt.toISOString().slice(0, 10);
    const bucket = buckets.get(key);
    if (bucket) bucket.calculations += 1;
  }
  for (const row of eventRows) {
    const key = row.createdAt.toISOString().slice(0, 10);
    const bucket = buckets.get(key);
    if (bucket) bucket.events += 1;
  }

  return {
    totals: { users, activeUsers, newUsers, calculations, guests },
    calculationsByType: byType.map((row) => ({ type: row.type, count: row._count._all })),
    topEvents: events.map((row) => ({ name: row.name, count: row._count._all })),
    dailyActivity: [...buckets.entries()].map(([date, value]) => ({ date, ...value })),
    localeBreakdown: localeRows.map((row) => ({ locale: row.locale, users: row._count._all })),
  };
}

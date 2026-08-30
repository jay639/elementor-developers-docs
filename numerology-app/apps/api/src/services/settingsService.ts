import { prisma } from '../lib/prisma';
import { CacheKeys, cached, invalidate } from '../lib/cache';

/** Reads a single setting value by key. */
export async function getSetting<T>(key: string): Promise<T | null> {
  const settings = await getAllSettings();
  return (settings[key] as T | undefined) ?? null;
}

export async function getAllSettings(): Promise<Record<string, unknown>> {
  return cached(CacheKeys.settings, async () => {
    const rows = await prisma.appSetting.findMany();
    return Object.fromEntries(rows.map((row) => [row.key, row.value]));
  });
}

/** Only settings marked public are exposed to the mobile app. */
export async function getPublicSettings(): Promise<Record<string, unknown>> {
  return cached(CacheKeys.publicSettings, async () => {
    const rows = await prisma.appSetting.findMany({ where: { isPublic: true } });
    return Object.fromEntries(rows.map((row) => [row.key, row.value]));
  });
}

export function invalidateSettings(): void {
  invalidate(CacheKeys.settings, CacheKeys.publicSettings);
}

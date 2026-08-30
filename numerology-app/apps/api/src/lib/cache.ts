/**
 * A very small in-process TTL cache.
 *
 * Numerology content and rules change rarely but are read on every calculation,
 * so they are cached for a short period and invalidated explicitly whenever an
 * administrator saves a change. This keeps the database out of the hot path
 * without ever serving stale content after an edit.
 */
interface Entry<T> {
  value: T;
  expiresAt: number;
}

const store = new Map<string, Entry<unknown>>();

export const DEFAULT_TTL_MS = 5 * 60 * 1000;

export async function cached<T>(key: string, loader: () => Promise<T>, ttlMs = DEFAULT_TTL_MS): Promise<T> {
  const existing = store.get(key);
  if (existing && existing.expiresAt > Date.now()) {
    return existing.value as T;
  }
  const value = await loader();
  store.set(key, { value, expiresAt: Date.now() + ttlMs });
  return value;
}

/** Drops every cache entry whose key starts with one of the given prefixes. */
export function invalidate(...prefixes: string[]): void {
  if (prefixes.length === 0) {
    store.clear();
    return;
  }
  for (const key of store.keys()) {
    if (prefixes.some((prefix) => key.startsWith(prefix))) {
      store.delete(key);
    }
  }
}

export const CacheKeys = {
  settings: 'settings',
  publicSettings: 'settings:public',
  marriageRules: 'rules:marriage',
  numberRules: 'rules:number',
  chaldean: 'rules:chaldean',
  numbers: 'content:numbers',
  combination: 'content:combination',
  daily: 'content:daily',
  legal: 'content:legal',
} as const;

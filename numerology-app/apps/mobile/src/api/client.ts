import { clearRefreshToken, readRefreshToken, saveRefreshToken } from '../lib/storage';
import type { Locale } from '../i18n/translations';

/**
 * API client.
 *
 * The access token lives in memory only; the refresh token is kept in the
 * device keychain. A 401 triggers one silent refresh before the app treats the
 * session as expired.
 */

export const API_BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL ?? 'http://10.0.2.2:4000';

let accessToken: string | null = null;
let locale: Locale = 'en';
let refreshPromise: Promise<boolean> | null = null;
let onSessionExpired: (() => void) | null = null;

export type ApiErrorCode =
  | 'VALIDATION_ERROR'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'RATE_LIMITED'
  | 'MAINTENANCE'
  | 'NETWORK'
  | 'INTERNAL_ERROR';

export class ApiError extends Error {
  readonly code: ApiErrorCode;
  readonly status: number;
  readonly details?: unknown;

  constructor(code: ApiErrorCode, message: string, status = 0, details?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.status = status;
    this.details = details;
  }

  get isNetworkError(): boolean {
    return this.code === 'NETWORK';
  }
}

export function setAccessToken(token: string | null): void {
  accessToken = token;
}

export function setLocale(next: Locale): void {
  locale = next;
}

export function setSessionExpiredHandler(handler: (() => void) | null): void {
  onSessionExpired = handler;
}

export async function storeSession(tokens: { accessToken: string; refreshToken: string }): Promise<void> {
  accessToken = tokens.accessToken;
  await saveRefreshToken(tokens.refreshToken);
}

export async function clearSession(): Promise<void> {
  accessToken = null;
  await clearRefreshToken();
}

export function hasAccessToken(): boolean {
  return accessToken !== null;
}

async function refreshSession(): Promise<boolean> {
  const refreshToken = await readRefreshToken();
  if (!refreshToken) return false;

  refreshPromise ??= (async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      });
      if (!response.ok) {
        await clearSession();
        onSessionExpired?.();
        return false;
      }
      const body = await response.json();
      await storeSession(body.data.tokens);
      return true;
    } catch {
      return false;
    } finally {
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

export interface PageMeta {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  hasMore: boolean;
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined>;
  auth?: boolean;
  retry?: boolean;
  timeoutMs?: number;
}

export async function request<T>(
  path: string,
  options: RequestOptions = {},
): Promise<{ data: T; meta?: PageMeta }> {
  const url = new URL(`${API_BASE_URL}/api/v1${path}`);
  for (const [key, value] of Object.entries(options.query ?? {})) {
    if (value !== undefined) url.searchParams.set(key, String(value));
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs ?? 15000);

  let response: Response;
  try {
    response = await fetch(url.toString(), {
      method: options.method ?? 'GET',
      headers: {
        'Content-Type': 'application/json',
        'X-Locale': locale,
        ...(accessToken && options.auth !== false ? { Authorization: `Bearer ${accessToken}` } : {}),
      },
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      signal: controller.signal,
    });
  } catch {
    throw new ApiError('NETWORK', 'Unable to connect. Please check your internet connection.');
  } finally {
    clearTimeout(timeout);
  }

  if (response.status === 401 && options.retry !== false) {
    if (await refreshSession()) {
      return request<T>(path, { ...options, retry: false });
    }
  }

  if (response.status === 204) {
    return { data: undefined as T };
  }

  const body = (await response.json().catch(() => null)) as
    | { success: boolean; data: T; meta?: PageMeta; error?: { code: ApiErrorCode; message: string; details?: unknown } }
    | null;

  if (!response.ok || !body?.success) {
    throw new ApiError(
      body?.error?.code ?? 'INTERNAL_ERROR',
      body?.error?.message ?? 'Something went wrong. Please try again.',
      response.status,
      body?.error?.details,
    );
  }

  return { data: body.data, meta: body.meta };
}

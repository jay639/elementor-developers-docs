/**
 * Thin API client for the admin panel.
 *
 * Access tokens are short lived and kept in memory; only the refresh token is
 * persisted, and a 401 triggers exactly one silent refresh before the panel
 * asks the administrator to sign in again.
 */

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '';
const REFRESH_KEY = 'ankjyoti.admin.refresh';

let accessToken: string | null = null;
let refreshPromise: Promise<boolean> | null = null;

export interface ApiError extends Error {
  code: string;
  status: number;
  details?: unknown;
}

function toApiError(status: number, body: unknown): ApiError {
  const payload = (body as { error?: { code?: string; message?: string; details?: unknown } })?.error;
  const error = new Error(payload?.message ?? 'Something went wrong. Please try again.') as ApiError;
  error.code = payload?.code ?? 'INTERNAL_ERROR';
  error.status = status;
  error.details = payload?.details;
  return error;
}

export function setTokens(tokens: { accessToken: string; refreshToken: string }) {
  accessToken = tokens.accessToken;
  localStorage.setItem(REFRESH_KEY, tokens.refreshToken);
}

export function clearTokens() {
  accessToken = null;
  localStorage.removeItem(REFRESH_KEY);
}

export function hasSession(): boolean {
  return Boolean(accessToken ?? localStorage.getItem(REFRESH_KEY));
}

async function refreshSession(): Promise<boolean> {
  const refreshToken = localStorage.getItem(REFRESH_KEY);
  if (!refreshToken) return false;

  refreshPromise ??= (async () => {
    try {
      const response = await fetch(`${BASE_URL}/api/v1/admin/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      });
      if (!response.ok) {
        clearTokens();
        return false;
      }
      const body = await response.json();
      setTokens(body.data.tokens);
      return true;
    } catch {
      return false;
    } finally {
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  query?: Record<string, string | number | undefined>;
  retry?: boolean;
}

export async function api<T>(path: string, options: RequestOptions = {}): Promise<{ data: T; meta?: PageMeta }> {
  const url = new URL(`${BASE_URL}/api/v1${path}`, window.location.origin);
  for (const [key, value] of Object.entries(options.query ?? {})) {
    if (value !== undefined && value !== '') url.searchParams.set(key, String(value));
  }

  const response = await fetch(url.toString(), {
    method: options.method ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
    },
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });

  if (response.status === 401 && options.retry !== false) {
    if (await refreshSession()) {
      return api<T>(path, { ...options, retry: false });
    }
  }

  if (response.status === 204) {
    return { data: undefined as T };
  }

  const body = await response.json().catch(() => null);
  if (!response.ok) {
    throw toApiError(response.status, body);
  }
  return body as { data: T; meta?: PageMeta };
}

export interface PageMeta {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  hasMore: boolean;
}

export interface AdminProfile {
  id: string;
  name: string;
  email: string;
  role: string;
  roleName: string;
  permissions: string[];
  lastLoginAt: string | null;
  mustChangePassword: boolean;
}

export async function login(email: string, password: string): Promise<AdminProfile> {
  const response = await fetch(`${BASE_URL}/api/v1/admin/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const body = await response.json().catch(() => null);
  if (!response.ok) throw toApiError(response.status, body);

  setTokens(body.data.tokens);
  return body.data.admin as AdminProfile;
}

export async function loadProfile(): Promise<AdminProfile> {
  const { data } = await api<AdminProfile>('/admin/auth/me');
  return data;
}

export async function logout(): Promise<void> {
  const refreshToken = localStorage.getItem(REFRESH_KEY);
  if (refreshToken) {
    await api('/admin/auth/logout', { method: 'POST', body: { refreshToken } }).catch(() => undefined);
  }
  clearTokens();
}

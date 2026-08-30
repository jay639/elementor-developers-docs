import { request } from './client';
import type { PageMeta } from './client';

/** Typed wrappers around every endpoint the app uses. */

export interface Tokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
}

export interface ReductionStep {
  digits: number[];
  sum: number;
  expression: string;
}

export interface ReductionResult {
  value: number;
  compound: number;
  steps: ReductionStep[];
}

export interface NumberContent {
  number: number;
  name: string;
  title: string;
  summary: string;
  personality: string;
  behaviour: string;
  strengths: string[];
  weaknesses: string[];
  career: string;
  relationships: string;
  general: string;
  luckyNumbers: number[];
  unfavourableNumbers: number[];
  colors: string[];
  notes: string | null;
}

export interface CombinationContent {
  mulank: number;
  bhagyank: number;
  title: string;
  description: string;
  personality: string;
  strengths: string[];
  challenges: string[];
  career: string;
  relationships: string;
  recommendations: string;
}

export interface CoreNumbersResult {
  dob: string;
  mulank: number;
  bhagyank: number;
  breakdown: { mulank: ReductionResult; bhagyank: ReductionResult };
  mulankContent: NumberContent | null;
  bhagyankContent: NumberContent | null;
  combination: CombinationContent | null;
  combinationFallback: boolean;
  disclaimer: string;
  dobFromProfile?: boolean;
}

export interface Comparison {
  axis: 'MULANK' | 'BHAGYANK';
  axisLabel: string;
  axisValue: number;
  level: string;
  levelLabel: string;
  message: string;
}

export interface LuckyNumberResult {
  input: string;
  digits: number[];
  compound: number;
  root: number;
  breakdown: ReductionResult;
  mulank: number | null;
  bhagyank: number | null;
  comparisons: Comparison[];
  overall: string;
  overallLabel: string;
  score: number;
  summary: string;
  rootContent: NumberContent | null;
  needsDob: boolean;
  needsDobMessage: string | null;
  disclaimer: string;
  dobFromProfile?: boolean;
}

export interface NameResult {
  name: string;
  letters: Array<{ letter: string; value: number; counted: boolean }>;
  compound: number;
  root: number;
  breakdown: ReductionResult;
  ignoredCharacters: string[];
  rootContent: NumberContent | null;
  comparison: {
    mulank: number;
    bhagyank: number;
    axes: Array<{ axis: 'MULANK' | 'BHAGYANK'; axisValue: number; level: string; levelLabel: string; message: string }>;
    overall: string;
    overallLabel: string;
    score: number;
  } | null;
  needsDob: boolean;
  needsDobMessage: string | null;
  disclaimer: string;
}

export interface CompatibilityDirection {
  direction: 'MALE_TO_FEMALE' | 'FEMALE_TO_MALE';
  driverNumber: number;
  targetMulank: number;
  targetBhagyank: number;
  matched: boolean;
  matchedVia: string;
  viaNote: string | null;
  compatibleMulank: number[];
  compatibleBhagyank: number[];
  ruleMissing: boolean;
  note: string | null;
}

export interface CompatibilityResult {
  male: { dob: string; mulank: number; bhagyank: number };
  female: { dob: string; mulank: number; bhagyank: number };
  directions: CompatibilityDirection[];
  verdict: 'STRONG_MATCH' | 'GOOD_MATCH' | 'NOT_MATCHED';
  verdictLabel: string;
  matchedDirections: number;
  score: number;
  summary: string;
  reasons: string[];
  maleContent: NumberContent | null;
  femaleContent: NumberContent | null;
  kundaliReferral: { enabled: boolean; url: string; label: string; note: string } | null;
  disclaimer: string;
  marriageDisclaimer: string;
}

export interface DailyResult {
  date: string;
  number: number;
  breakdown: ReductionResult;
  insight: { number: number; title: string; message: string } | null;
  content: NumberContent | null;
}

export interface HomeSummary {
  daily: DailyResult;
  numbers: { dob: string; mulank: number; bhagyank: number } | null;
  needsDob: boolean;
  needsDobMessage: string | null;
}

export interface Profile {
  id: string;
  email: string | null;
  isGuest: boolean;
  provider: string;
  memberSince: string;
  profile: {
    displayName: string | null;
    dateOfBirth: string | null;
    gender: string;
    phone: string | null;
    photoUrl: string | null;
    mulank: number | null;
    bhagyank: number | null;
  } | null;
  preferences: {
    locale: 'en' | 'hi' | 'mr';
    theme: 'SYSTEM' | 'LIGHT' | 'DARK';
    notificationsEnabled: boolean;
    dailyNumberOptIn: boolean;
    analyticsConsent: boolean;
    marketingConsent: boolean;
    shareDobOnCards: boolean;
  } | null;
}

export type CalculationType =
  | 'CORE_NUMBERS'
  | 'LUCKY_NUMBER'
  | 'NAME_NUMEROLOGY'
  | 'MARRIAGE_COMPATIBILITY'
  | 'DAILY_NUMBER';

export interface HistoryEntry {
  id: string;
  type: CalculationType;
  label: string;
  input: Record<string, unknown>;
  result: Record<string, unknown>;
  primaryNumber: number | null;
  secondaryNumber: number | null;
  createdAt: string;
}

export const api = {
  // --- Authentication -----------------------------------------------------
  guest: () => request<{ user: { id: string; isGuest: boolean }; tokens: Tokens }>('/auth/guest', { method: 'POST' }),
  register: (body: { email: string; password: string; displayName?: string; dateOfBirth?: string | null }) =>
    request<{ user: { id: string; isGuest: boolean }; tokens: Tokens }>('/auth/register', { method: 'POST', body }),
  login: (body: { email: string; password: string }) =>
    request<{ user: { id: string; isGuest: boolean }; tokens: Tokens }>('/auth/login', { method: 'POST', body }),
  logout: (refreshToken: string) => request('/auth/logout', { method: 'POST', body: { refreshToken } }),

  // --- Profile ------------------------------------------------------------
  profile: () => request<Profile>('/profile'),
  updateProfile: (body: Record<string, unknown>) => request<Profile['profile']>('/profile', { method: 'PUT', body }),
  updatePreferences: (body: Record<string, unknown>) =>
    request<Profile['preferences']>('/profile/preferences', { method: 'PUT', body }),
  deleteAccount: () => request<void>('/profile', { method: 'DELETE' }),

  // --- Numerology ---------------------------------------------------------
  coreNumbers: (body: { dateOfBirth?: string; save?: boolean }) =>
    request<CoreNumbersResult>('/numerology/calculate', { method: 'POST', body }),
  luckyNumber: (body: { number: string; dateOfBirth?: string | null; save?: boolean }) =>
    request<LuckyNumberResult>('/numerology/lucky-number', { method: 'POST', body }),
  nameNumerology: (body: { name: string; dateOfBirth?: string | null; compareWithDob?: boolean }) =>
    request<NameResult>('/numerology/name', { method: 'POST', body }),
  compatibility: (body: { maleDateOfBirth: string; femaleDateOfBirth: string }) =>
    request<CompatibilityResult>('/numerology/compatibility', { method: 'POST', body }),
  daily: (date?: string) => request<DailyResult>('/numerology/daily', { query: { date } }),
  summary: () => request<HomeSummary>('/numerology/summary'),

  // --- History and saved results -----------------------------------------
  history: (query: { page?: number; pageSize?: number; type?: CalculationType }) =>
    request<HistoryEntry[]>('/history', { query }),
  deleteHistory: (id: string) => request<void>(`/history/${id}`, { method: 'DELETE' }),
  clearHistory: () => request<{ cleared: number }>('/history', { method: 'DELETE' }),
  favourites: () => request<HistoryEntry[]>('/favourites'),
  saveFavourite: (body: { type: CalculationType; label: string; input: unknown; result: unknown }) =>
    request<HistoryEntry>('/favourites', { method: 'POST', body }),
  deleteFavourite: (id: string) => request<void>(`/favourites/${id}`, { method: 'DELETE' }),

  // --- Content (cached for offline use) -----------------------------------
  numbers: () => request<NumberContent[]>('/content/numbers'),
  rules: () =>
    request<{
      marriage: Array<{ driverNumber: number; compatibleMulank: number[]; compatibleBhagyank: number[]; enabled: boolean }>;
      numbers: Array<{ baseNumber: number; friendly: number[]; neutral: number[]; unfriendly: number[]; enabled: boolean }>;
      chaldean: Record<string, string[]>;
    }>('/content/rules'),
  legal: (type: 'TERMS' | 'PRIVACY' | 'DISCLAIMER' | 'ABOUT') =>
    request<{ type: string; title: string; body: string; version: string }>(`/content/legal/${type}`),
  settings: () => request<Record<string, unknown>>('/settings'),

  // --- Analytics ----------------------------------------------------------
  track: (body: { name: string; properties?: Record<string, unknown>; platform?: 'ANDROID' | 'IOS' | 'WEB' }) =>
    request<{ recorded: boolean }>('/analytics/events', { method: 'POST', body }),
};

export type { PageMeta };

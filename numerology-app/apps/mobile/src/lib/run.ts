import { ApiError } from '../api/client';
import { NumerologyError } from '@numerology/core';
import { translations, type Locale } from '../i18n/translations';

export interface RunResult<T> {
  data: T;
  /** True when the result came from the on-device engine instead of the API. */
  offline: boolean;
}

/**
 * Runs a calculation online, falling back to the identical on-device engine
 * when the network is unavailable. Any other failure (validation, maintenance)
 * is surfaced to the caller so the user sees the real reason.
 */
export async function withOfflineFallback<T>(
  online: () => Promise<{ data: T }>,
  offline: () => Promise<T>,
): Promise<RunResult<T>> {
  try {
    const response = await online();
    return { data: response.data, offline: false };
  } catch (error) {
    if (error instanceof ApiError && error.isNetworkError) {
      return { data: await offline(), offline: true };
    }
    throw error;
  }
}

/** Turns any thrown value into a message that is safe to show to a user. */
export function toUserMessage(error: unknown, locale: Locale): string {
  const copy = translations[locale].errors;

  if (error instanceof ApiError) {
    if (error.isNetworkError) return copy.network;
    if (error.code === 'UNAUTHORIZED') return copy.sessionExpired;
    return error.message || copy.generic;
  }

  if (error instanceof NumerologyError) {
    switch (error.code) {
      case 'INVALID_DATE':
      case 'FUTURE_DATE':
      case 'DATE_TOO_OLD':
        return copy.invalidDob;
      case 'EMPTY_NUMBER':
      case 'NO_DIGITS':
      case 'NUMBER_TOO_LONG':
        return copy.invalidNumber;
      case 'EMPTY_NAME':
      case 'NAME_TOO_LONG':
      case 'NO_MAPPABLE_LETTERS':
        return copy.invalidName;
      default:
        return copy.generic;
    }
  }

  return copy.generic;
}

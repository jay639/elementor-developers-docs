import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { calculateCoreNumbersFromDob } from '@numerology/core';
import { api } from '../api/endpoints';
import type { Profile } from '../api/endpoints';
import { ApiError, clearSession, setLocale as setClientLocale, setSessionExpiredHandler, storeSession } from '../api/client';
import { deviceLocale, type Locale } from '../i18n';
import { StorageKeys, readJson, readRefreshToken, removeKey, writeJson } from '../lib/storage';
import type { ThemeMode } from '../theme/ThemeProvider';

export interface LocalProfile {
  displayName: string | null;
  dateOfBirth: string | null;
  mulank: number | null;
  bhagyank: number | null;
}

export interface Preferences {
  locale: Locale;
  theme: ThemeMode;
  notificationsEnabled: boolean;
  dailyNumberOptIn: boolean;
  analyticsConsent: boolean;
  shareDobOnCards: boolean;
}

interface AppState {
  ready: boolean;
  onboardingComplete: boolean;
  signedIn: boolean;
  isGuest: boolean;
  email: string | null;
  profile: LocalProfile;
  preferences: Preferences;
}

interface AppContextValue extends AppState {
  completeOnboarding: () => Promise<void>;
  /** Saves the global date of birth used by every module. */
  saveDateOfBirth: (dob: string) => Promise<void>;
  clearDateOfBirth: () => Promise<void>;
  setDisplayName: (name: string) => Promise<void>;
  updatePreferences: (patch: Partial<Preferences>) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, displayName?: string) => Promise<void>;
  continueAsGuest: () => Promise<void>;
  signOut: () => Promise<void>;
  deleteAccount: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const defaultPreferences: Preferences = {
  locale: 'en',
  theme: 'SYSTEM',
  notificationsEnabled: false,
  dailyNumberOptIn: false,
  analyticsConsent: false,
  shareDobOnCards: false,
};

const defaultProfile: LocalProfile = { displayName: null, dateOfBirth: null, mulank: null, bhagyank: null };

const AppContext = createContext<AppContextValue | null>(null);

/**
 * Holds the session, the global date of birth and the user's preferences.
 *
 * Everything is written to device storage first so the app opens instantly and
 * keeps working offline; the API is then updated in the background when the
 * user has an account.
 */
export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AppState>({
    ready: false,
    onboardingComplete: false,
    signedIn: false,
    isGuest: true,
    email: null,
    profile: defaultProfile,
    preferences: { ...defaultPreferences, locale: deviceLocale() },
  });

  const applyProfile = useCallback((remote: Profile) => {
    const profile: LocalProfile = {
      displayName: remote.profile?.displayName ?? null,
      dateOfBirth: remote.profile?.dateOfBirth ?? null,
      mulank: remote.profile?.mulank ?? null,
      bhagyank: remote.profile?.bhagyank ?? null,
    };
    const preferences: Preferences = {
      locale: remote.preferences?.locale ?? deviceLocale(),
      theme: remote.preferences?.theme ?? 'SYSTEM',
      notificationsEnabled: remote.preferences?.notificationsEnabled ?? false,
      dailyNumberOptIn: remote.preferences?.dailyNumberOptIn ?? false,
      analyticsConsent: remote.preferences?.analyticsConsent ?? false,
      shareDobOnCards: remote.preferences?.shareDobOnCards ?? false,
    };

    setState((current) => ({
      ...current,
      signedIn: true,
      isGuest: remote.isGuest,
      email: remote.email,
      profile,
      preferences,
    }));
    setClientLocale(preferences.locale);
    void writeJson(StorageKeys.profile, profile);
    void writeJson(StorageKeys.preferences, preferences);
  }, []);

  // Restore everything from the device, then reconcile with the server.
  useEffect(() => {
    let cancelled = false;

    (async () => {
      const [onboarded, storedProfile, storedPreferences, refreshToken] = await Promise.all([
        readJson<boolean>(StorageKeys.onboardingComplete),
        readJson<LocalProfile>(StorageKeys.profile),
        readJson<Preferences>(StorageKeys.preferences),
        readRefreshToken(),
      ]);

      if (cancelled) return;

      const preferences = { ...defaultPreferences, locale: deviceLocale(), ...(storedPreferences ?? {}) };
      setClientLocale(preferences.locale);

      setState((current) => ({
        ...current,
        onboardingComplete: onboarded === true,
        profile: storedProfile ?? defaultProfile,
        preferences,
        signedIn: Boolean(refreshToken),
        ready: !refreshToken,
      }));

      if (refreshToken) {
        try {
          const { data } = await api.profile();
          if (!cancelled) applyProfile(data);
        } catch {
          // Offline or an expired session: the cached profile is used instead.
        } finally {
          if (!cancelled) setState((current) => ({ ...current, ready: true }));
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [applyProfile]);

  useEffect(() => {
    setSessionExpiredHandler(() => {
      setState((current) => ({ ...current, signedIn: false, isGuest: true, email: null }));
    });
    return () => setSessionExpiredHandler(null);
  }, []);

  const completeOnboarding = useCallback(async () => {
    await writeJson(StorageKeys.onboardingComplete, true);
    setState((current) => ({ ...current, onboardingComplete: true }));
  }, []);

  const saveDateOfBirth = useCallback(
    async (dob: string) => {
      // The numbers are calculated on the device so the UI updates instantly and
      // works offline; the server recalculates them when the profile is saved.
      const numbers = calculateCoreNumbersFromDob(dob);
      const profile: LocalProfile = {
        displayName: state.profile.displayName,
        dateOfBirth: numbers.dob,
        mulank: numbers.mulank,
        bhagyank: numbers.bhagyank,
      };

      setState((current) => ({ ...current, profile }));
      await writeJson(StorageKeys.profile, profile);

      if (state.signedIn) {
        try {
          await api.updateProfile({ dateOfBirth: numbers.dob });
        } catch (error) {
          if (!(error instanceof ApiError) || !error.isNetworkError) throw error;
        }
      }
    },
    [state.profile.displayName, state.signedIn],
  );

  const clearDateOfBirth = useCallback(async () => {
    const profile: LocalProfile = { ...state.profile, dateOfBirth: null, mulank: null, bhagyank: null };
    setState((current) => ({ ...current, profile }));
    await writeJson(StorageKeys.profile, profile);
    if (state.signedIn) {
      await api.updateProfile({ dateOfBirth: null }).catch(() => undefined);
    }
  }, [state.profile, state.signedIn]);

  const setDisplayName = useCallback(
    async (name: string) => {
      const profile: LocalProfile = { ...state.profile, displayName: name };
      setState((current) => ({ ...current, profile }));
      await writeJson(StorageKeys.profile, profile);
      if (state.signedIn) {
        await api.updateProfile({ displayName: name }).catch(() => undefined);
      }
    },
    [state.profile, state.signedIn],
  );

  const updatePreferences = useCallback(
    async (patch: Partial<Preferences>) => {
      const preferences = { ...state.preferences, ...patch };
      setState((current) => ({ ...current, preferences }));
      setClientLocale(preferences.locale);
      await writeJson(StorageKeys.preferences, preferences);
      if (state.signedIn) {
        await api.updatePreferences(patch as Record<string, unknown>).catch(() => undefined);
      }
    },
    [state.preferences, state.signedIn],
  );

  const signIn = useCallback(
    async (email: string, password: string) => {
      const { data } = await api.login({ email, password });
      await storeSession(data.tokens);
      const profile = await api.profile();
      applyProfile(profile.data);
    },
    [applyProfile],
  );

  const signUp = useCallback(
    async (email: string, password: string, displayName?: string) => {
      const { data } = await api.register({
        email,
        password,
        displayName,
        dateOfBirth: state.profile.dateOfBirth,
      });
      await storeSession(data.tokens);
      const profile = await api.profile();
      applyProfile(profile.data);
    },
    [applyProfile, state.profile.dateOfBirth],
  );

  const continueAsGuest = useCallback(async () => {
    const { data } = await api.guest();
    await storeSession(data.tokens);
    setState((current) => ({ ...current, signedIn: true, isGuest: true }));
    // A guest who already entered a date of birth keeps it on the server too.
    if (state.profile.dateOfBirth) {
      await api.updateProfile({ dateOfBirth: state.profile.dateOfBirth }).catch(() => undefined);
    }
  }, [state.profile.dateOfBirth]);

  const signOut = useCallback(async () => {
    const refreshToken = await readRefreshToken();
    if (refreshToken) await api.logout(refreshToken).catch(() => undefined);
    await clearSession();
    setState((current) => ({ ...current, signedIn: false, isGuest: true, email: null }));
  }, []);

  const deleteAccount = useCallback(async () => {
    await api.deleteAccount();
    await clearSession();
    await Promise.all([removeKey(StorageKeys.profile), removeKey(StorageKeys.localHistory)]);
    setState((current) => ({
      ...current,
      signedIn: false,
      isGuest: true,
      email: null,
      profile: defaultProfile,
    }));
  }, []);

  const refreshProfile = useCallback(async () => {
    if (!state.signedIn) return;
    const { data } = await api.profile();
    applyProfile(data);
  }, [applyProfile, state.signedIn]);

  const value = useMemo<AppContextValue>(
    () => ({
      ...state,
      completeOnboarding,
      saveDateOfBirth,
      clearDateOfBirth,
      setDisplayName,
      updatePreferences,
      signIn,
      signUp,
      continueAsGuest,
      signOut,
      deleteAccount,
      refreshProfile,
    }),
    [
      state,
      completeOnboarding,
      saveDateOfBirth,
      clearDateOfBirth,
      setDisplayName,
      updatePreferences,
      signIn,
      signUp,
      continueAsGuest,
      signOut,
      deleteAccount,
      refreshProfile,
    ],
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used inside AppProvider');
  return context;
}

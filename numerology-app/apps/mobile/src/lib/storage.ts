import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

/**
 * Two storage tiers:
 *   - SecureStore for the refresh token (Keychain / Keystore backed).
 *   - AsyncStorage for everything else: preferences, the saved date of birth,
 *     cached content and the offline history of a signed out visitor.
 */

const SECURE_KEY = 'ankjyoti.refreshToken';

export async function saveRefreshToken(token: string): Promise<void> {
  if (Platform.OS === 'web') {
    await AsyncStorage.setItem(SECURE_KEY, token);
    return;
  }
  await SecureStore.setItemAsync(SECURE_KEY, token, {
    keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
  });
}

export async function readRefreshToken(): Promise<string | null> {
  if (Platform.OS === 'web') return AsyncStorage.getItem(SECURE_KEY);
  return SecureStore.getItemAsync(SECURE_KEY);
}

export async function clearRefreshToken(): Promise<void> {
  if (Platform.OS === 'web') {
    await AsyncStorage.removeItem(SECURE_KEY);
    return;
  }
  await SecureStore.deleteItemAsync(SECURE_KEY);
}

export const StorageKeys = {
  onboardingComplete: 'ankjyoti.onboardingComplete',
  profile: 'ankjyoti.profile',
  preferences: 'ankjyoti.preferences',
  localHistory: 'ankjyoti.localHistory',
  cachedContent: 'ankjyoti.cachedContent',
  cachedRules: 'ankjyoti.cachedRules',
  cachedSettings: 'ankjyoti.cachedSettings',
} as const;

export async function readJson<T>(key: string): Promise<T | null> {
  try {
    const raw = await AsyncStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : null;
  } catch {
    return null;
  }
}

export async function writeJson(key: string, value: unknown): Promise<void> {
  try {
    await AsyncStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Storage failures must never break a calculation.
  }
}

export async function removeKey(key: string): Promise<void> {
  try {
    await AsyncStorage.removeItem(key);
  } catch {
    // Ignored for the same reason.
  }
}

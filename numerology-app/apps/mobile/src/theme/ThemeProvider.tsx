import React, { createContext, useContext, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import { darkColors, lightColors, type ThemeColors } from './tokens';

export type ThemeMode = 'SYSTEM' | 'LIGHT' | 'DARK';

interface ThemeContextValue {
  colors: ThemeColors;
  isDark: boolean;
  mode: ThemeMode;
}

const ThemeContext = createContext<ThemeContextValue>({
  colors: lightColors,
  isDark: false,
  mode: 'SYSTEM',
});

/**
 * Supplies the colour set for the current theme. `SYSTEM` follows the device
 * setting; `LIGHT` and `DARK` are explicit user choices stored in preferences.
 */
export function ThemeProvider({ mode, children }: { mode: ThemeMode; children: React.ReactNode }) {
  const scheme = useColorScheme();
  const isDark = mode === 'DARK' || (mode === 'SYSTEM' && scheme === 'dark');

  const value = useMemo<ThemeContextValue>(
    () => ({ colors: isDark ? darkColors : lightColors, isDark, mode }),
    [isDark, mode],
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  return useContext(ThemeContext);
}

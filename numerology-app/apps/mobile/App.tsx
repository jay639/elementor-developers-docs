import React, { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AppProvider, useApp } from './src/state/AppProvider';
import { ThemeProvider, useTheme } from './src/theme/ThemeProvider';
import { I18nProvider } from './src/i18n';
import { FeedbackProvider } from './src/components';
import { RootNavigator } from './src/navigation/RootNavigator';
import { setLocale } from './src/api/client';

/**
 * Application root.
 *
 * Providers are layered so that the theme and the language both follow the
 * user's saved preferences: state -> theme -> language -> feedback -> navigation.
 */
function Shell() {
  const { preferences } = useApp();

  useEffect(() => {
    setLocale(preferences.locale);
  }, [preferences.locale]);

  return (
    <ThemeProvider mode={preferences.theme}>
      <I18nProvider locale={preferences.locale}>
        <FeedbackProvider>
          <ThemedStatusBar />
          <RootNavigator />
        </FeedbackProvider>
      </I18nProvider>
    </ThemeProvider>
  );
}

function ThemedStatusBar() {
  const { isDark } = useTheme();
  return <StatusBar style={isDark ? 'light' : 'dark'} />;
}

export default function App() {
  return (
    <SafeAreaProvider>
      <AppProvider>
        <Shell />
      </AppProvider>
    </SafeAreaProvider>
  );
}

import React from 'react';
import { Text } from 'react-native';
import { NavigationContainer, DefaultTheme, DarkTheme } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { HomeScreen } from '../screens/HomeScreen';
import { ToolsScreen } from '../screens/ToolsScreen';
import { CoreNumbersScreen } from '../screens/CoreNumbersScreen';
import { LuckyNumberScreen } from '../screens/LuckyNumberScreen';
import { NameNumerologyScreen } from '../screens/NameNumerologyScreen';
import { CompatibilityScreen } from '../screens/CompatibilityScreen';
import { HistoryScreen } from '../screens/HistoryScreen';
import { ProfileScreen } from '../screens/ProfileScreen';
import { AuthScreen } from '../screens/AuthScreen';
import { LegalScreen } from '../screens/LegalScreen';
import { OnboardingScreen } from '../screens/OnboardingScreen';
import { LoadingState } from '../components';
import type { HomeStackParamList, ProfileStackParamList, TabParamList, ToolsStackParamList } from './types';

const Tab = createBottomTabNavigator<TabParamList>();
const HomeStack = createNativeStackNavigator<HomeStackParamList>();
const ToolsStack = createNativeStackNavigator<ToolsStackParamList>();
const ProfileStack = createNativeStackNavigator<ProfileStackParamList>();

/** Text glyphs are used as icons so the app ships without an icon font. */
function TabIcon({ glyph, color }: { glyph: string; color: string }) {
  return <Text style={{ color, fontSize: fontSize.title }}>{glyph}</Text>;
}

function HomeNavigator() {
  return (
    <HomeStack.Navigator screenOptions={{ headerShown: false }}>
      <HomeStack.Screen name="HomeMain" component={HomeScreen} />
    </HomeStack.Navigator>
  );
}

function ToolsNavigator() {
  const { t } = useTranslation();
  const { colors } = useTheme();

  return (
    <ToolsStack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.background },
        headerTintColor: colors.text,
        headerShadowVisible: false,
        headerTitleStyle: { fontSize: fontSize.body },
      }}
    >
      <ToolsStack.Screen name="ToolsHome" component={ToolsScreen} options={{ headerShown: false }} />
      <ToolsStack.Screen name="CoreNumbers" component={CoreNumbersScreen} options={{ title: t('tools.coreNumbers') }} />
      <ToolsStack.Screen name="LuckyNumber" component={LuckyNumberScreen} options={{ title: t('tools.luckyNumber') }} />
      <ToolsStack.Screen
        name="NameNumerology"
        component={NameNumerologyScreen}
        options={{ title: t('tools.nameNumerology') }}
      />
      <ToolsStack.Screen
        name="Compatibility"
        component={CompatibilityScreen}
        options={{ title: t('tools.compatibility') }}
      />
    </ToolsStack.Navigator>
  );
}

function ProfileNavigator() {
  const { t } = useTranslation();
  const { colors } = useTheme();

  return (
    <ProfileStack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.background },
        headerTintColor: colors.text,
        headerShadowVisible: false,
      }}
    >
      <ProfileStack.Screen name="ProfileHome" component={ProfileScreen} options={{ headerShown: false }} />
      <ProfileStack.Screen name="Auth" component={AuthScreen} options={{ title: t('profile.signIn') }} />
      <ProfileStack.Screen name="Legal" component={LegalScreen} options={{ title: t('profile.about') }} />
    </ProfileStack.Navigator>
  );
}

/**
 * Root navigation.
 *
 * Onboarding runs once; afterwards the app opens on the four-tab layout. The
 * admin panel is a separate web application and is never reachable from here.
 */
export function RootNavigator() {
  const { colors, isDark } = useTheme();
  const { t } = useTranslation();
  const { ready, onboardingComplete } = useApp();

  const navigationTheme = {
    ...(isDark ? DarkTheme : DefaultTheme),
    colors: {
      ...(isDark ? DarkTheme : DefaultTheme).colors,
      background: colors.background,
      card: colors.surface,
      text: colors.text,
      border: colors.border,
      primary: colors.accent,
    },
  };

  if (!ready) {
    return <LoadingState />;
  }

  return (
    <NavigationContainer theme={navigationTheme}>
      {!onboardingComplete ? (
        <OnboardingScreen />
      ) : (
        <Tab.Navigator
          screenOptions={{
            headerShown: false,
            tabBarActiveTintColor: colors.accent,
            tabBarInactiveTintColor: colors.textMuted,
            tabBarStyle: { backgroundColor: colors.surface, borderTopColor: colors.border, height: 62, paddingBottom: 8 },
            tabBarLabelStyle: { fontSize: fontSize.caption },
          }}
        >
          <Tab.Screen
            name="Home"
            component={HomeNavigator}
            options={{
              title: t('home.welcome'),
              tabBarIcon: ({ color }) => <TabIcon glyph="⌂" color={color} />,
              tabBarAccessibilityLabel: t('home.welcome'),
            }}
          />
          <Tab.Screen
            name="Tools"
            component={ToolsNavigator}
            options={{
              title: t('tools.title'),
              tabBarIcon: ({ color }) => <TabIcon glyph="✦" color={color} />,
              tabBarAccessibilityLabel: t('tools.title'),
            }}
          />
          <Tab.Screen
            name="History"
            component={HistoryScreen}
            options={{
              title: t('history.title'),
              tabBarIcon: ({ color }) => <TabIcon glyph="◷" color={color} />,
              tabBarAccessibilityLabel: t('history.title'),
            }}
          />
          <Tab.Screen
            name="Profile"
            component={ProfileNavigator}
            options={{
              title: t('profile.title'),
              tabBarIcon: ({ color }) => <TabIcon glyph="☺" color={color} />,
              tabBarAccessibilityLabel: t('profile.title'),
            }}
          />
        </Tab.Navigator>
      )}
    </NavigationContainer>
  );
}

import React, { useCallback, useEffect, useState } from 'react';
import { RefreshControl, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, spacing } from '../theme/tokens';
import { formatLongDate, useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { api } from '../api/endpoints';
import type { HomeSummary } from '../api/endpoints';
import { offlineCoreNumbers, offlineDaily, syncOfflineCaches } from '../lib/offline';
import { withOfflineFallback, toUserMessage } from '../lib/run';
import {
  Card,
  DobPrompt,
  ErrorState,
  InfoSection,
  NumberCard,
  OfflineNotice,
  Screen,
  SectionHeader,
  SkeletonCard,
  ToolCard,
} from '../components';
import type { TabParamList } from '../navigation/types';

/**
 * Home dashboard: today's number, the user's own numbers and quick access to
 * every tool. Today's number is always derived from the current date, so it
 * changes on its own each day.
 */
export function HomeScreen() {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const { profile, preferences } = useApp();
  const navigation = useNavigation<BottomTabNavigationProp<TabParamList>>();

  const [summary, setSummary] = useState<HomeSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [offline, setOffline] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const result = await withOfflineFallback<HomeSummary>(
        () => api.summary(),
        async () => {
          const daily = await offlineDaily(locale);
          if (!profile.dateOfBirth) {
            return { daily, numbers: null, needsDob: true, needsDobMessage: t('home.addDobTitle') };
          }
          const core = await offlineCoreNumbers(profile.dateOfBirth, locale);
          return {
            daily,
            numbers: { dob: core.dob, mulank: core.mulank, bhagyank: core.bhagyank },
            needsDob: false,
            needsDobMessage: null,
          };
        },
      );
      setSummary(result.data);
      setOffline(result.offline);
      if (!result.offline) void syncOfflineCaches(locale);
    } catch (caught) {
      setError(toUserMessage(caught, preferences.locale));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [locale, preferences.locale, profile.dateOfBirth, t]);

  useEffect(() => {
    void load();
  }, [load]);

  const greeting = (() => {
    const hour = new Date().getHours();
    if (hour < 12) return t('home.greetingMorning');
    if (hour < 17) return t('home.greetingAfternoon');
    return t('home.greetingEvening');
  })();

  const name = profile.displayName;
  const numbers = summary?.numbers ?? (profile.mulank && profile.bhagyank
    ? { dob: profile.dateOfBirth ?? '', mulank: profile.mulank, bhagyank: profile.bhagyank }
    : null);

  return (
    <Screen
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={() => {
            setRefreshing(true);
            void load();
          }}
          tintColor={colors.accent}
        />
      }
    >
      <Text style={[styles.greeting, { color: colors.textMuted }]}>
        {name ? `${greeting}, ${name}` : t('home.welcome')}
      </Text>

      {offline ? <OfflineNotice /> : null}
      {error ? <ErrorState message={error} onRetry={() => void load()} /> : null}

      {loading ? (
        <>
          <SkeletonCard height={190} />
          <SkeletonCard height={120} />
        </>
      ) : summary ? (
        <>
          <NumberCard
            label={t('home.todaysNumber')}
            value={summary.daily.number}
            caption={t('home.basedOnDate', { date: formatLongDate(summary.daily.date, locale) })}
          />

          {summary.daily.insight ? (
            <Card>
              <InfoSection title={t('home.dailyInsight')} body={summary.daily.insight.message} />
            </Card>
          ) : summary.daily.content ? (
            <Card>
              <InfoSection title={t('home.dailyInsight')} body={summary.daily.content.summary} />
            </Card>
          ) : null}

          {numbers ? (
            <>
              <SectionHeader title={t('home.yourNumbers')} />
              <View style={styles.numberRow}>
                <NumberCard
                  label={t('common.mulank')}
                  value={numbers.mulank}
                  caption={t('common.driverNumber')}
                  tone="accent"
                  compact
                  style={styles.numberHalf}
                />
                <NumberCard
                  label={t('common.bhagyank')}
                  value={numbers.bhagyank}
                  caption={t('common.conductorNumber')}
                  tone="accent"
                  compact
                  style={styles.numberHalf}
                />
              </View>
            </>
          ) : (
            <DobPrompt onAdd={() => navigation.navigate('Tools', { screen: 'CoreNumbers' })} />
          )}
        </>
      ) : null}

      <SectionHeader title={t('home.explore')} />
      <ToolCard
        icon="१"
        title={t('tools.coreNumbers')}
        description={t('tools.coreNumbersHint')}
        onPress={() => navigation.navigate('Tools', { screen: 'CoreNumbers' })}
      />
      <ToolCard
        icon="७"
        title={t('tools.luckyNumber')}
        description={t('tools.luckyNumberHint')}
        onPress={() => navigation.navigate('Tools', { screen: 'LuckyNumber' })}
      />
      <ToolCard
        icon="अ"
        title={t('tools.nameNumerology')}
        description={t('tools.nameNumerologyHint')}
        onPress={() => navigation.navigate('Tools', { screen: 'NameNumerology' })}
      />
      <ToolCard
        icon="♥"
        title={t('tools.compatibility')}
        description={t('tools.compatibilityHint')}
        onPress={() => navigation.navigate('Tools', { screen: 'Compatibility' })}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  greeting: { fontSize: fontSize.bodyLarge, fontWeight: fontWeight.semibold, marginBottom: spacing.lg },
  numberRow: { flexDirection: 'row', gap: spacing.md },
  numberHalf: { flex: 1 },
});

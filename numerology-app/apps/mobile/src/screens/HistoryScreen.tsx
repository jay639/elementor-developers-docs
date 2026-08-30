import React, { useCallback, useEffect, useState } from 'react';
import { FlatList, Pressable, RefreshControl, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, radius, spacing } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { api } from '../api/endpoints';
import type { HistoryEntry } from '../api/endpoints';
import { toUserMessage } from '../lib/run';
import { Badge, EmptyState, ErrorState, LoadingState, ScreenHeader, TextButton, useFeedback } from '../components';
import type { TabParamList } from '../navigation/types';

const TYPE_KEY: Record<string, string> = {
  CORE_NUMBERS: 'tools.coreNumbers',
  LUCKY_NUMBER: 'tools.luckyNumber',
  NAME_NUMEROLOGY: 'tools.nameNumerology',
  MARRIAGE_COMPATIBILITY: 'tools.compatibility',
  DAILY_NUMBER: 'home.todaysNumber',
};

/** Paginated calculation history with view, delete and clear. */
export function HistoryScreen() {
  const { colors } = useTheme();
  const { t } = useTranslation();
  const { signedIn, preferences } = useApp();
  const { confirm, showToast } = useFeedback();
  const navigation = useNavigation<BottomTabNavigationProp<TabParamList>>();

  const [items, setItems] = useState<HistoryEntry[]>([]);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(
    async (nextPage: number, append: boolean) => {
      if (!signedIn) {
        setItems([]);
        setLoading(false);
        return;
      }
      setError(null);
      try {
        const response = await api.history({ page: nextPage, pageSize: 20 });
        setItems((current) => (append ? [...current, ...response.data] : response.data));
        setHasMore(response.meta?.hasMore ?? false);
        setPage(nextPage);
      } catch (caught) {
        setError(toUserMessage(caught, preferences.locale));
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [preferences.locale, signedIn],
  );

  useEffect(() => {
    void load(1, false);
  }, [load]);

  const remove = async (id: string) => {
    try {
      await api.deleteHistory(id);
      setItems((current) => current.filter((item) => item.id !== id));
      showToast(t('history.deleted'));
    } catch (caught) {
      showToast(toUserMessage(caught, preferences.locale), 'error');
    }
  };

  const clearAll = async () => {
    const confirmed = await confirm({
      title: t('history.clearAll'),
      message: t('history.clearConfirm'),
      confirmLabel: t('common.delete'),
      cancelLabel: t('common.cancel'),
    });
    if (!confirmed) return;
    try {
      await api.clearHistory();
      setItems([]);
      showToast(t('history.deleted'));
    } catch (caught) {
      showToast(toUserMessage(caught, preferences.locale), 'error');
    }
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.background }} edges={['top']}>
      <View style={styles.header}>
        <ScreenHeader title={t('history.title')} />
        {items.length > 0 ? <TextButton label={t('history.clearAll')} onPress={() => void clearAll()} /> : null}
      </View>

      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState message={error} onRetry={() => void load(1, false)} />
      ) : items.length === 0 ? (
        <EmptyState
          title={t('history.emptyTitle')}
          description={signedIn ? t('history.emptyBody') : t('history.signInToSync')}
          actionLabel={t('history.startExploring')}
          onAction={() => navigation.navigate('Tools', { screen: 'ToolsHome' })}
        />
      ) : (
        <FlatList
          data={items}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.list}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => {
                setRefreshing(true);
                void load(1, false);
              }}
              tintColor={colors.accent}
            />
          }
          onEndReachedThreshold={0.4}
          onEndReached={() => {
            if (hasMore && !loading) void load(page + 1, true);
          }}
          renderItem={({ item }) => (
            <View style={[styles.row, { backgroundColor: colors.surface, borderColor: colors.border }]}>
              <View style={{ flex: 1 }}>
                <Badge label={t(TYPE_KEY[item.type] ?? 'history.title')} />
                <Text style={[styles.label, { color: colors.text }]} numberOfLines={1}>
                  {item.label}
                </Text>
                <Text style={[styles.meta, { color: colors.textMuted }]}>
                  {item.primaryNumber !== null ? `${item.primaryNumber}` : ''}
                  {item.secondaryNumber !== null ? ` · ${item.secondaryNumber}` : ''}
                  {'  '}
                  {new Date(item.createdAt).toLocaleDateString()}
                </Text>
              </View>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`${t('common.delete')} ${item.label}`}
                onPress={() => void remove(item.id)}
                style={styles.deleteButton}
                hitSlop={8}
              >
                <Text style={{ color: colors.danger, fontSize: fontSize.body }}>✕</Text>
              </Pressable>
            </View>
          )}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.md,
  },
  list: { paddingHorizontal: spacing.lg, paddingBottom: spacing.xxxl },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    borderRadius: radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    padding: spacing.lg,
    marginBottom: spacing.md,
  },
  label: { fontSize: fontSize.body, fontWeight: fontWeight.semibold, marginTop: spacing.xs },
  meta: { fontSize: fontSize.small, marginTop: 2 },
  deleteButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
});

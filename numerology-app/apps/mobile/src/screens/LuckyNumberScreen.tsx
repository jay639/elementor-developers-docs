import React, { useRef, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, spacing } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { api } from '../api/endpoints';
import type { LuckyNumberResult } from '../api/endpoints';
import { offlineLuckyNumber } from '../lib/offline';
import { toUserMessage, withOfflineFallback } from '../lib/run';
import { shareResultCard } from '../lib/share';
import {
  Badge,
  ButtonRow,
  CalculationBreakdown,
  Card,
  Disclaimer,
  DOBPicker,
  DobPrompt,
  ErrorState,
  InfoSection,
  NumberCard,
  NumberField,
  OfflineNotice,
  PrimaryButton,
  Screen,
  ScreenHeader,
  SecondaryButton,
  SectionHeader,
  TextButton,
  useFeedback,
} from '../components';
import type { ToolsStackParamList } from '../navigation/types';

const TONE: Record<string, 'success' | 'warning' | 'danger' | 'neutral'> = {
  STRONG_MATCH: 'success',
  GOOD_MATCH: 'success',
  NEUTRAL: 'neutral',
  WEAK_MATCH: 'danger',
};

/**
 * Lucky Number Finder: any bike, car, mobile, house or business number, checked
 * against the user's own numbers. The saved date of birth is used automatically.
 */
export function LuckyNumberScreen() {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const { profile, preferences, saveDateOfBirth } = useApp();
  const { showToast } = useFeedback();
  const navigation = useNavigation<NativeStackNavigationProp<ToolsStackParamList>>();
  const cardRef = useRef<View>(null);

  const [value, setValue] = useState('');
  const [dob, setDob] = useState<string | null>(profile.dateOfBirth);
  const [editingDob, setEditingDob] = useState(false);
  const [result, setResult] = useState<LuckyNumberResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [offline, setOffline] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const check = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await withOfflineFallback(
        () => api.luckyNumber({ number: value, dateOfBirth: dob }),
        () => offlineLuckyNumber(value, dob, locale),
      );
      setResult(response.data);
      setOffline(response.offline);
    } catch (caught) {
      setError(toUserMessage(caught, preferences.locale));
    } finally {
      setLoading(false);
    }
  };

  const reset = () => {
    setValue('');
    setResult(null);
    setError(null);
  };

  const share = async () => {
    if (!result) return;
    const text = [
      t('lucky.title'),
      `${t('lucky.yourNumber')}: ${result.root}`,
      result.mulank ? `${t('common.mulank')}: ${result.mulank}` : '',
      result.bhagyank ? `${t('common.bhagyank')}: ${result.bhagyank}` : '',
      result.overallLabel,
      result.disclaimer,
    ]
      .filter(Boolean)
      .join('\n');
    const outcome = await shareResultCard(cardRef, text);
    if (outcome === 'cancelled') showToast(t('errors.generic'), 'error');
  };

  return (
    <Screen>
      <ScreenHeader title={t('lucky.title')} subtitle={t('tools.luckyNumberHint')} />

      <Card>
        <NumberField
          label={t('lucky.inputLabel')}
          placeholder={t('lucky.placeholder')}
          value={value}
          onChangeText={setValue}
          maxLength={40}
          onSubmitEditing={() => void check()}
        />

        {profile.dateOfBirth && !editingDob ? (
          <View style={styles.dobRow}>
            <Text style={{ color: colors.textMuted, fontSize: fontSize.small, flex: 1 }}>
              {t('lucky.useSavedDob')} · {profile.dateOfBirth}
            </Text>
            <TextButton label={t('common.dateOfBirth')} onPress={() => setEditingDob(true)} />
          </View>
        ) : (
          <DOBPicker label={t('common.dateOfBirth')} value={dob} onChange={setDob} />
        )}

        <PrimaryButton
          label={loading ? t('common.calculating') : t('lucky.check')}
          onPress={() => void check()}
          loading={loading}
          disabled={value.trim().length === 0}
        />
      </Card>

      {error ? <ErrorState message={error} onRetry={() => void check()} /> : null}
      {offline ? <OfflineNotice /> : null}

      {result ? (
        <>
          <View ref={cardRef} collapsable={false} style={{ backgroundColor: colors.background }}>
            <NumberCard label={t('lucky.yourNumber')} value={result.root} caption={result.input} />

            {result.mulank && result.bhagyank ? (
              <View style={styles.row}>
                <NumberCard label={t('common.mulank')} value={result.mulank} tone="accent" compact style={styles.half} />
                <NumberCard
                  label={t('common.bhagyank')}
                  value={result.bhagyank}
                  tone="accent"
                  compact
                  style={styles.half}
                />
              </View>
            ) : null}
          </View>

          <Card>
            <View style={styles.resultHeader}>
              <Text style={[styles.resultTitle, { color: colors.text }]}>{t('lucky.result')}</Text>
              <Badge label={result.overallLabel} tone={TONE[result.overall] ?? 'neutral'} />
            </View>
            {result.summary ? <Text style={{ color: colors.textMuted, lineHeight: 22 }}>{result.summary}</Text> : null}

            {result.comparisons.map((comparison) => (
              <View key={comparison.axis} style={styles.comparisonRow}>
                <Badge label={`${comparison.axisLabel} ${comparison.axisValue}`} />
                <Text style={{ color: colors.textMuted, flex: 1, marginLeft: spacing.md }}>
                  {comparison.message || comparison.levelLabel}
                </Text>
              </View>
            ))}
          </Card>

          {result.needsDob ? (
            <DobPrompt
              onAdd={() => {
                if (profile.dateOfBirth) {
                  setDob(profile.dateOfBirth);
                } else {
                  navigation.navigate('CoreNumbers');
                }
              }}
            />
          ) : null}

          <Card>
            <CalculationBreakdown title={t('lucky.breakdown')} steps={result.breakdown.steps} />
          </Card>

          {result.rootContent ? (
            <Card>
              <SectionHeader title={result.rootContent.title} />
              <InfoSection title={t('core.general')} body={result.rootContent.summary} />
              <InfoSection title={t('core.strengths')} items={result.rootContent.strengths} />
            </Card>
          ) : null}

          <ButtonRow>
            <SecondaryButton label={t('lucky.tryAnother')} onPress={reset} style={{ flex: 1 }} />
            <SecondaryButton label={t('common.share')} onPress={() => void share()} style={{ flex: 1 }} />
          </ButtonRow>

          <Disclaimer text={result.disclaimer} />
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: spacing.md },
  half: { flex: 1 },
  dobRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.lg },
  resultHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: spacing.md },
  resultTitle: { fontSize: fontSize.bodyLarge, fontWeight: '600' },
  comparisonRow: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.md },
});

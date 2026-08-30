import React, { useRef, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, radius, spacing } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { api } from '../api/endpoints';
import type { NameResult } from '../api/endpoints';
import { offlineName } from '../lib/offline';
import { toUserMessage, withOfflineFallback } from '../lib/run';
import { shareResultCard } from '../lib/share';
import {
  Badge,
  ButtonRow,
  CalculationBreakdown,
  Card,
  Disclaimer,
  ErrorState,
  InfoSection,
  NameField,
  NumberCard,
  OfflineNotice,
  PrimaryButton,
  Screen,
  ScreenHeader,
  SecondaryButton,
  SectionHeader,
  ToggleRow,
  useFeedback,
} from '../components';

/**
 * Chaldean name numerology.
 *
 * Both numbers are shown and stored: the compound number (the raw total) and
 * the root number it reduces to. The compound number is never discarded.
 */
export function NameNumerologyScreen() {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const { profile, preferences } = useApp();
  const { showToast } = useFeedback();
  const cardRef = useRef<View>(null);

  const [name, setName] = useState('');
  const [compare, setCompare] = useState(true);
  const [result, setResult] = useState<NameResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [offline, setOffline] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const analyse = async () => {
    setLoading(true);
    setError(null);
    try {
      const dob = compare ? profile.dateOfBirth : null;
      const response = await withOfflineFallback(
        () => api.nameNumerology({ name, dateOfBirth: dob, compareWithDob: compare }),
        () => offlineName(name, dob, locale),
      );
      setResult(response.data);
      setOffline(response.offline);
    } catch (caught) {
      setError(toUserMessage(caught, preferences.locale));
    } finally {
      setLoading(false);
    }
  };

  const share = async () => {
    if (!result) return;
    const text = [
      t('name.title'),
      result.name,
      `${t('name.compoundNumber')}: ${result.compound}`,
      `${t('name.rootNumber')}: ${result.root}`,
      result.disclaimer,
    ].join('\n');
    const outcome = await shareResultCard(cardRef, text);
    if (outcome === 'cancelled') showToast(t('errors.generic'), 'error');
  };

  return (
    <Screen>
      <ScreenHeader title={t('name.title')} subtitle={t('tools.nameNumerologyHint')} />

      <Card>
        <NameField
          label={t('name.inputLabel')}
          placeholder={t('name.placeholder')}
          value={name}
          onChangeText={setName}
          maxLength={80}
          onSubmitEditing={() => void analyse()}
        />
        {profile.dateOfBirth ? (
          <ToggleRow label={t('name.compareWithMyNumbers')} value={compare} onChange={setCompare} />
        ) : (
          <Text style={{ color: colors.textMuted, marginBottom: spacing.md }}>
            {t('name.addDobForPersonalised')}
          </Text>
        )}
        <PrimaryButton
          label={loading ? t('common.analysing') : t('name.analyze')}
          onPress={() => void analyse()}
          loading={loading}
          disabled={name.trim().length === 0}
        />
      </Card>

      {error ? <ErrorState message={error} onRetry={() => void analyse()} /> : null}
      {offline ? <OfflineNotice /> : null}

      {result ? (
        <>
          <View ref={cardRef} collapsable={false} style={{ backgroundColor: colors.background }}>
            <Text style={[styles.name, { color: colors.text }]}>{result.name}</Text>
            <View style={styles.row}>
              <NumberCard
                label={t('name.compoundNumber')}
                value={result.compound}
                compact
                style={styles.half}
              />
              <NumberCard
                label={t('name.rootNumber')}
                value={result.root}
                tone="accent"
                compact
                style={styles.half}
              />
            </View>
          </View>

          <Card>
            <SectionHeader title={t('name.letterValues')} />
            <View style={styles.letterGrid}>
              {result.letters
                .filter((letter) => letter.counted)
                .map((letter, index) => (
                  <View
                    key={`${letter.letter}-${index}`}
                    style={[styles.letterChip, { backgroundColor: colors.surfaceAlt }]}
                  >
                    <Text style={[styles.letter, { color: colors.text }]}>{letter.letter}</Text>
                    <Text style={[styles.letterValue, { color: colors.accent }]}>{letter.value}</Text>
                  </View>
                ))}
            </View>
            {result.ignoredCharacters.length > 0 ? (
              <Text style={{ color: colors.textMuted, fontSize: fontSize.small, marginTop: spacing.md }}>
                {t('name.ignored', { characters: result.ignoredCharacters.join(' ') })}
              </Text>
            ) : null}
            <CalculationBreakdown title={t('lucky.breakdown')} steps={result.breakdown.steps} />
          </Card>

          {result.comparison ? (
            <Card>
              <SectionHeader title={t('name.compareWithMyNumbers')} />
              <View style={styles.badgeRow}>
                <Badge label={`${t('common.mulank')} ${result.comparison.mulank}`} />
                <Badge label={`${t('common.bhagyank')} ${result.comparison.bhagyank}`} />
                <Badge
                  label={result.comparison.overallLabel}
                  tone={result.comparison.overall === 'WEAK_MATCH' ? 'danger' : 'success'}
                />
              </View>
              {result.comparison.axes.map((axis) => (
                <Text key={axis.axis} style={{ color: colors.textMuted, marginTop: spacing.sm, lineHeight: 21 }}>
                  {axis.message || `${axis.axisValue}: ${axis.levelLabel}`}
                </Text>
              ))}
            </Card>
          ) : result.needsDobMessage ? (
            <Card>
              <Text style={{ color: colors.textMuted }}>{result.needsDobMessage}</Text>
            </Card>
          ) : null}

          {result.rootContent ? (
            <Card>
              <InfoSection title={result.rootContent.title} body={result.rootContent.summary} />
              <InfoSection title={t('core.personality')} body={result.rootContent.personality} />
              <InfoSection title={t('core.strengths')} items={result.rootContent.strengths} />
              <InfoSection title={t('core.challenges')} items={result.rootContent.weaknesses} />
            </Card>
          ) : null}

          <ButtonRow>
            <SecondaryButton label={t('common.share')} onPress={() => void share()} style={{ flex: 1 }} />
          </ButtonRow>

          <Disclaimer text={result.disclaimer} />
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  name: { fontSize: fontSize.title, fontWeight: fontWeight.semibold, textAlign: 'center', marginBottom: spacing.md },
  row: { flexDirection: 'row', gap: spacing.md },
  half: { flex: 1 },
  letterGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  letterChip: { minWidth: 46, borderRadius: radius.sm, alignItems: 'center', paddingVertical: spacing.sm },
  letter: { fontSize: fontSize.body, fontWeight: fontWeight.semibold },
  letterValue: { fontSize: fontSize.small, fontWeight: fontWeight.bold },
  badgeRow: { flexDirection: 'row', gap: spacing.sm, flexWrap: 'wrap' },
});

import React, { useRef, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { spacing } from '../theme/tokens';
import { formatLongDate, useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { api } from '../api/endpoints';
import type { CoreNumbersResult } from '../api/endpoints';
import { offlineCoreNumbers } from '../lib/offline';
import { toUserMessage, withOfflineFallback } from '../lib/run';
import { shareResultCard } from '../lib/share';
import {
  ButtonRow,
  CalculationBreakdown,
  Card,
  Disclaimer,
  DOBPicker,
  ErrorState,
  InfoSection,
  NumberCard,
  NumberChips,
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
 * Mulank & Bhagyank.
 *
 * The saved global date of birth is pre-filled, so a returning user only has to
 * tap the button. Changing the date here affects this calculation only, unless
 * "Save as my Date of Birth" is switched on.
 */
export function CoreNumbersScreen() {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const { profile, preferences, saveDateOfBirth } = useApp();
  const { showToast } = useFeedback();
  const cardRef = useRef<View>(null);

  const [dob, setDob] = useState<string | null>(profile.dateOfBirth);
  const [saveAsDefault, setSaveAsDefault] = useState(false);
  const [result, setResult] = useState<CoreNumbersResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [offline, setOffline] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const calculate = async () => {
    if (!dob) {
      setError(t('errors.invalidDob'));
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const response = await withOfflineFallback(
        () => api.coreNumbers({ dateOfBirth: dob, save: saveAsDefault }),
        () => offlineCoreNumbers(dob, locale),
      );
      setResult(response.data);
      setOffline(response.offline);
      if (saveAsDefault) await saveDateOfBirth(dob);
    } catch (caught) {
      setError(toUserMessage(caught, preferences.locale));
    } finally {
      setLoading(false);
    }
  };

  const share = async () => {
    if (!result) return;
    const text = [
      `${t('core.title')}`,
      `${t('common.mulank')}: ${result.mulank}`,
      `${t('common.bhagyank')}: ${result.bhagyank}`,
      preferences.shareDobOnCards ? `${t('common.dateOfBirth')}: ${formatLongDate(result.dob, locale)}` : '',
      result.disclaimer,
    ]
      .filter(Boolean)
      .join('\n');
    const outcome = await shareResultCard(cardRef, text);
    if (outcome === 'cancelled') showToast(t('errors.generic'), 'error');
  };

  return (
    <Screen>
      <ScreenHeader title={t('tools.coreNumbers')} subtitle={t('tools.coreNumbersHint')} />

      <Card>
        <DOBPicker label={t('common.dateOfBirth')} value={dob} onChange={setDob} />
        {dob && dob !== profile.dateOfBirth ? (
          <ToggleRow label={t('core.saveAsMyDob')} value={saveAsDefault} onChange={setSaveAsDefault} />
        ) : null}
        <PrimaryButton
          label={loading ? t('common.calculating') : t('core.calculate')}
          onPress={() => void calculate()}
          loading={loading}
          disabled={!dob}
        />
      </Card>

      {error ? <ErrorState message={error} onRetry={() => void calculate()} /> : null}
      {offline ? <OfflineNotice /> : null}

      {result ? (
        <>
          <View ref={cardRef} collapsable={false} style={{ backgroundColor: colors.background }}>
            <SectionHeader title={t('core.title')} />
            <View style={styles.numberRow}>
              <NumberCard
                label={t('common.mulank')}
                value={result.mulank}
                caption={t('common.driverNumber')}
                compact
                style={styles.half}
              />
              <NumberCard
                label={t('common.bhagyank')}
                value={result.bhagyank}
                caption={t('common.conductorNumber')}
                tone="accent"
                compact
                style={styles.half}
              />
            </View>
            <Text style={[styles.dobLine, { color: colors.textMuted }]}>
              {formatLongDate(result.dob, locale)}
            </Text>
          </View>

          <Card>
            <CalculationBreakdown
              title={`${t('core.howCalculated')} · ${t('common.mulank')}`}
              steps={result.breakdown.mulank.steps}
            />
            <CalculationBreakdown
              title={`${t('core.howCalculated')} · ${t('common.bhagyank')}`}
              steps={result.breakdown.bhagyank.steps}
            />
          </Card>

          <SectionHeader title={t('core.whatDoesThisMean')} />

          {result.combination ? (
            <Card>
              <InfoSection title={result.combination.title} body={result.combination.description} />
              <InfoSection title={t('core.personality')} body={result.combination.personality} />
              <InfoSection title={t('core.strengths')} items={result.combination.strengths} />
              <InfoSection title={t('core.challenges')} items={result.combination.challenges} />
              <InfoSection title={t('core.career')} body={result.combination.career} />
              <InfoSection title={t('core.relationships')} body={result.combination.relationships} />
              <InfoSection title={t('core.general')} body={result.combination.recommendations} />
            </Card>
          ) : null}

          {result.mulankContent ? (
            <Card>
              <InfoSection
                title={`${t('common.mulank')} ${result.mulank} · ${result.mulankContent.title}`}
                body={result.mulankContent.summary}
              />
              <InfoSection title={t('core.personality')} body={result.mulankContent.personality} />
              <InfoSection title={t('core.behaviour')} body={result.mulankContent.behaviour} />
              <InfoSection title={t('core.strengths')} items={result.mulankContent.strengths} />
              <InfoSection title={t('core.challenges')} items={result.mulankContent.weaknesses} />
              <InfoSection title={t('core.career')} body={result.mulankContent.career} />
              <InfoSection title={t('core.relationships')} body={result.mulankContent.relationships} />
              <InfoSection title={t('core.luckyNumbers')} />
              <NumberChips values={result.mulankContent.luckyNumbers} />
              {result.mulankContent.unfavourableNumbers.length > 0 ? (
                <>
                  <InfoSection title={t('core.unfavourableNumbers')} />
                  <NumberChips values={result.mulankContent.unfavourableNumbers} tone="danger" />
                </>
              ) : null}
              <InfoSection title={t('core.colors')} items={result.mulankContent.colors} />
            </Card>
          ) : null}

          {result.bhagyankContent && result.bhagyank !== result.mulank ? (
            <Card>
              <InfoSection
                title={`${t('common.bhagyank')} ${result.bhagyank} · ${result.bhagyankContent.title}`}
                body={result.bhagyankContent.summary}
              />
              <InfoSection title={t('core.personality')} body={result.bhagyankContent.personality} />
              <InfoSection title={t('core.career')} body={result.bhagyankContent.career} />
              <InfoSection title={t('core.relationships')} body={result.bhagyankContent.relationships} />
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
  numberRow: { flexDirection: 'row', gap: spacing.md },
  half: { flex: 1 },
  dobLine: { textAlign: 'center', marginBottom: spacing.md },
});

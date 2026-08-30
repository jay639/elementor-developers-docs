import React, { useRef, useState } from 'react';
import { Linking, StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, spacing } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { api } from '../api/endpoints';
import type { CompatibilityResult } from '../api/endpoints';
import { offlineCompatibility } from '../lib/offline';
import { toUserMessage, withOfflineFallback } from '../lib/run';
import { shareResultCard } from '../lib/share';
import {
  Badge,
  ButtonRow,
  Card,
  Disclaimer,
  DOBPicker,
  ErrorState,
  NumberCard,
  OfflineNotice,
  PrimaryButton,
  Screen,
  ScreenHeader,
  SecondaryButton,
  SectionHeader,
  useFeedback,
} from '../components';

/**
 * Marriage compatibility.
 *
 * The result is graded rather than a bare yes/no: the rules are evaluated from
 * each partner's Mulank towards the other partner's numbers, and both
 * directions are shown so the user can see exactly why the result came out the
 * way it did. Wording stays interpretive - never an absolute prediction.
 */
export function CompatibilityScreen() {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const { profile, preferences } = useApp();
  const { showToast } = useFeedback();
  const cardRef = useRef<View>(null);

  const [maleDob, setMaleDob] = useState<string | null>(null);
  const [femaleDob, setFemaleDob] = useState<string | null>(null);
  const [result, setResult] = useState<CompatibilityResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [offline, setOffline] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const check = async () => {
    if (!maleDob || !femaleDob) {
      setError(t('errors.invalidDob'));
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const response = await withOfflineFallback(
        () => api.compatibility({ maleDateOfBirth: maleDob, femaleDateOfBirth: femaleDob }),
        () => offlineCompatibility(maleDob, femaleDob, locale),
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
      t('compatibility.result'),
      result.verdictLabel,
      `${t('compatibility.male')}: ${t('common.mulank')} ${result.male.mulank}, ${t('common.bhagyank')} ${result.male.bhagyank}`,
      `${t('compatibility.female')}: ${t('common.mulank')} ${result.female.mulank}, ${t('common.bhagyank')} ${result.female.bhagyank}`,
      result.marriageDisclaimer,
    ].join('\n');
    const outcome = await shareResultCard(cardRef, text);
    if (outcome === 'cancelled') showToast(t('errors.generic'), 'error');
  };

  const verdictTone = result?.verdict === 'STRONG_MATCH' ? 'success' : result?.verdict === 'GOOD_MATCH' ? 'accent' : 'neutral';

  return (
    <Screen>
      <ScreenHeader title={t('compatibility.title')} subtitle={t('tools.compatibilityHint')} />

      <Card>
        <DOBPicker label={t('compatibility.maleDob')} value={maleDob} onChange={setMaleDob} />
        <DOBPicker label={t('compatibility.femaleDob')} value={femaleDob} onChange={setFemaleDob} />
        {profile.dateOfBirth && !maleDob && !femaleDob ? (
          <ButtonRow>
            <SecondaryButton
              label={`${t('compatibility.male')}: ${t('lucky.useSavedDob')}`}
              onPress={() => setMaleDob(profile.dateOfBirth)}
              style={{ flex: 1 }}
            />
            <SecondaryButton
              label={`${t('compatibility.female')}: ${t('lucky.useSavedDob')}`}
              onPress={() => setFemaleDob(profile.dateOfBirth)}
              style={{ flex: 1 }}
            />
          </ButtonRow>
        ) : null}
        <PrimaryButton
          label={loading ? t('common.checking') : t('compatibility.check')}
          onPress={() => void check()}
          loading={loading}
          disabled={!maleDob || !femaleDob}
          style={{ marginTop: spacing.md }}
        />
      </Card>

      {error ? <ErrorState message={error} onRetry={() => void check()} /> : null}
      {offline ? <OfflineNotice /> : null}

      {result ? (
        <>
          <View ref={cardRef} collapsable={false} style={{ backgroundColor: colors.background }}>
            <Card>
              <Text style={[styles.verdictLabel, { color: colors.textMuted }]}>
                {t('compatibility.result')}
              </Text>
              <Text style={[styles.verdict, { color: colors.text }]} accessibilityRole="header">
                {result.verdictLabel}
              </Text>
              <View style={styles.badgeRow}>
                <Badge label={`${result.matchedDirections}/2 ${t('compatibility.bothDirections')}`} tone={verdictTone} />
              </View>
              {result.summary ? (
                <Text style={{ color: colors.textMuted, lineHeight: 22, marginTop: spacing.md }}>
                  {result.summary}
                </Text>
              ) : null}
            </Card>

            <View style={styles.partnerRow}>
              <View style={styles.partnerColumn}>
                <Text style={[styles.partnerLabel, { color: colors.textMuted }]}>{t('compatibility.male')}</Text>
                <NumberCard label={t('common.mulank')} value={result.male.mulank} compact />
                <NumberCard label={t('common.bhagyank')} value={result.male.bhagyank} tone="accent" compact />
              </View>
              <View style={styles.partnerColumn}>
                <Text style={[styles.partnerLabel, { color: colors.textMuted }]}>{t('compatibility.female')}</Text>
                <NumberCard label={t('common.mulank')} value={result.female.mulank} compact />
                <NumberCard label={t('common.bhagyank')} value={result.female.bhagyank} tone="accent" compact />
              </View>
            </View>
          </View>

          <SectionHeader title={t('compatibility.whyThisResult')} />
          {result.directions.map((direction) => (
            <Card key={direction.direction}>
              <View style={styles.directionHeader}>
                <Text style={[styles.directionTitle, { color: colors.text }]}>
                  {direction.direction === 'MALE_TO_FEMALE'
                    ? t('compatibility.maleToFemale')
                    : t('compatibility.femaleToMale')}
                </Text>
                <Badge
                  label={direction.matched ? t('compatibility.matched') : t('compatibility.notMatched')}
                  tone={direction.matched ? 'success' : 'neutral'}
                />
              </View>
              <Text style={{ color: colors.textMuted, lineHeight: 21 }}>
                {t('common.mulank')} {direction.driverNumber} → {t('common.mulank')} {direction.targetMulank},{' '}
                {t('common.bhagyank')} {direction.targetBhagyank}
              </Text>
              <Text style={{ color: colors.textMuted, lineHeight: 21, marginTop: spacing.xs }}>
                {t('common.mulank')}: {direction.compatibleMulank.join(', ') || '—'} · {t('common.bhagyank')}:{' '}
                {direction.compatibleBhagyank.join(', ') || '—'}
              </Text>
              {direction.viaNote ? (
                <Text style={{ color: colors.accent, marginTop: spacing.sm }}>{direction.viaNote}</Text>
              ) : null}
              {direction.note ? (
                <Text style={{ color: colors.textMuted, marginTop: spacing.sm }}>{direction.note}</Text>
              ) : null}
            </Card>
          ))}

          {result.reasons.length > 0 ? (
            <Card>
              {result.reasons.map((reason) => (
                <Text key={reason} style={{ color: colors.textMuted, lineHeight: 22, marginBottom: spacing.sm }}>
                  {reason}
                </Text>
              ))}
            </Card>
          ) : null}

          {/* Shown for every result, and especially when nothing matched, so the
              app never leaves a couple with an alarming verdict. */}
          {result.kundaliReferral?.enabled ? (
            <Card>
              <Text style={[styles.deeperTitle, { color: colors.text }]}>{t('compatibility.deeperTitle')}</Text>
              <Text style={{ color: colors.textMuted, lineHeight: 22, marginTop: spacing.sm }}>
                {result.kundaliReferral.note || t('compatibility.deeperBody')}
              </Text>
              {result.kundaliReferral.url ? (
                <SecondaryButton
                  label={result.kundaliReferral.label || t('compatibility.exploreKundali')}
                  onPress={() => void Linking.openURL(result.kundaliReferral!.url)}
                  style={{ marginTop: spacing.md }}
                />
              ) : null}
            </Card>
          ) : null}

          <ButtonRow>
            <SecondaryButton label={t('common.share')} onPress={() => void share()} style={{ flex: 1 }} />
          </ButtonRow>

          <Disclaimer text={`${result.marriageDisclaimer}\n\n${result.disclaimer}`} />
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  verdictLabel: { fontSize: fontSize.caption, fontWeight: fontWeight.semibold, letterSpacing: 1.1 },
  verdict: { fontSize: fontSize.display, fontWeight: fontWeight.bold, marginTop: spacing.xs, letterSpacing: -0.8 },
  badgeRow: { flexDirection: 'row', gap: spacing.sm, marginTop: spacing.md, flexWrap: 'wrap' },
  partnerRow: { flexDirection: 'row', gap: spacing.md },
  partnerColumn: { flex: 1 },
  partnerLabel: { fontSize: fontSize.small, fontWeight: fontWeight.semibold, marginBottom: spacing.sm, textAlign: 'center' },
  directionHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: spacing.sm },
  directionTitle: { fontSize: fontSize.body, fontWeight: fontWeight.semibold },
  deeperTitle: { fontSize: fontSize.bodyLarge, fontWeight: fontWeight.semibold },
});

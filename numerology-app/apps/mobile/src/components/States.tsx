import React from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, radius, spacing } from '../theme/tokens';
import { PrimaryButton, SecondaryButton } from './Buttons';
import { useTranslation } from '../i18n';

/** Loading state with an explicit message, never a frozen screen. */
export function LoadingState({ message }: { message?: string }) {
  const { colors } = useTheme();
  const { t } = useTranslation();
  return (
    <View style={styles.centered} accessibilityLiveRegion="polite" accessibilityLabel={message ?? t('common.loading')}>
      <ActivityIndicator color={colors.accent} size="large" />
      <Text style={[styles.message, { color: colors.textMuted }]}>{message ?? t('common.loading')}</Text>
    </View>
  );
}

/** Skeleton placeholder used while a result card loads. */
export function SkeletonCard({ height = 120 }: { height?: number }) {
  const { colors } = useTheme();
  return <View accessibilityElementsHidden style={[styles.skeleton, { height, backgroundColor: colors.surfaceAlt }]} />;
}

/**
 * Error state. The message shown here is always the friendly one produced by
 * the API or the app; technical details never reach the user.
 */
export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  const { colors } = useTheme();
  const { t } = useTranslation();
  return (
    <View style={[styles.errorBox, { backgroundColor: colors.dangerSoft }]} accessibilityLiveRegion="assertive">
      <Text style={[styles.errorText, { color: colors.danger }]}>{message}</Text>
      {onRetry ? (
        <SecondaryButton label={t('common.retry')} onPress={onRetry} style={{ marginTop: spacing.md }} />
      ) : null}
    </View>
  );
}

export function EmptyState({
  title,
  description,
  actionLabel,
  onAction,
}: {
  title: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
}) {
  const { colors } = useTheme();
  return (
    <View style={styles.centered}>
      <Text style={[styles.emptyTitle, { color: colors.text }]} accessibilityRole="header">
        {title}
      </Text>
      {description ? <Text style={[styles.message, { color: colors.textMuted }]}>{description}</Text> : null}
      {actionLabel && onAction ? (
        <PrimaryButton label={actionLabel} onPress={onAction} style={{ marginTop: spacing.lg, minWidth: 200 }} />
      ) : null}
    </View>
  );
}

/**
 * Prompt shown wherever a calculation needs a date of birth and none is saved.
 */
export function DobPrompt({ onAdd }: { onAdd: () => void }) {
  const { colors } = useTheme();
  const { t } = useTranslation();
  return (
    <View style={[styles.prompt, { backgroundColor: colors.accentSoft }]}>
      <Text style={[styles.promptText, { color: colors.text }]}>{t('home.addDobTitle')}</Text>
      <PrimaryButton label={t('home.addDob')} onPress={onAdd} style={{ marginTop: spacing.md }} />
    </View>
  );
}

/** Small notice explaining that a result was calculated on the device. */
export function OfflineNotice() {
  const { colors } = useTheme();
  const { t } = useTranslation();
  return (
    <View style={[styles.offline, { backgroundColor: colors.warningSoft }]}>
      <Text style={[styles.offlineText, { color: colors.warning }]}>
        {t('common.offline')} · {t('common.offlineNote')}
      </Text>
    </View>
  );
}

/** The legal disclaimer shown under every result. */
export function Disclaimer({ text }: { text: string }) {
  const { colors } = useTheme();
  return (
    <Text style={[styles.disclaimer, { color: colors.textMuted }]} accessibilityRole="text">
      {text}
    </Text>
  );
}

const styles = StyleSheet.create({
  centered: { alignItems: 'center', justifyContent: 'center', paddingVertical: spacing.xxxl, paddingHorizontal: spacing.lg },
  message: { fontSize: fontSize.body, marginTop: spacing.md, textAlign: 'center', lineHeight: 22 },
  emptyTitle: { fontSize: fontSize.title, fontWeight: fontWeight.semibold, textAlign: 'center' },
  skeleton: { borderRadius: radius.lg, marginBottom: spacing.md, opacity: 0.7 },
  errorBox: { borderRadius: radius.md, padding: spacing.lg, marginBottom: spacing.md },
  errorText: { fontSize: fontSize.body, lineHeight: 22 },
  prompt: { borderRadius: radius.lg, padding: spacing.lg, marginBottom: spacing.md },
  promptText: { fontSize: fontSize.body, lineHeight: 22 },
  offline: { borderRadius: radius.sm, paddingHorizontal: spacing.md, paddingVertical: spacing.sm, marginBottom: spacing.md },
  offlineText: { fontSize: fontSize.small, fontWeight: fontWeight.semibold },
  disclaimer: { fontSize: fontSize.caption, lineHeight: 18, marginTop: spacing.lg, marginBottom: spacing.xl },
});

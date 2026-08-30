import React from 'react';
import { Pressable, StyleSheet, Text, View, type ViewStyle } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { MIN_TOUCH_TARGET, fontSize, fontWeight, radius, shadow, spacing } from '../theme/tokens';

/** Base surface used by every card in the app. */
export function Card({
  children,
  style,
  onPress,
  accessibilityLabel,
}: {
  children: React.ReactNode;
  style?: ViewStyle;
  onPress?: () => void;
  accessibilityLabel?: string;
}) {
  const { colors } = useTheme();
  const content = (
    <View
      style={[
        styles.card,
        { backgroundColor: colors.surface, borderColor: colors.border },
        shadow.card,
        style,
      ]}
    >
      {children}
    </View>
  );

  if (!onPress) return content;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      onPress={onPress}
      style={({ pressed }) => ({ opacity: pressed ? 0.9 : 1, transform: [{ scale: pressed ? 0.995 : 1 }] })}
    >
      {content}
    </Pressable>
  );
}

/**
 * The signature numerology card: a large, unmistakable number with its label.
 * Used for Mulank, Bhagyank, Today's number and any calculated root.
 */
export function NumberCard({
  label,
  value,
  caption,
  tone = 'primary',
  compact = false,
  style,
}: {
  label: string;
  value: number | string;
  caption?: string;
  tone?: 'primary' | 'accent' | 'plain';
  compact?: boolean;
  style?: ViewStyle;
}) {
  const { colors } = useTheme();
  const background =
    tone === 'primary' ? colors.primary : tone === 'accent' ? colors.accentSoft : colors.surface;
  const foreground = tone === 'primary' ? colors.primaryContrast : colors.text;
  const muted = tone === 'primary' ? colors.primaryContrast : colors.textMuted;

  return (
    <View
      accessible
      accessibilityLabel={`${label}: ${value}${caption ? `. ${caption}` : ''}`}
      style={[
        styles.card,
        styles.numberCard,
        { backgroundColor: background, borderColor: tone === 'plain' ? colors.border : 'transparent' },
        compact && styles.numberCardCompact,
        shadow.card,
        style,
      ]}
    >
      <Text
        style={[styles.numberLabel, { color: muted, opacity: tone === 'primary' ? 0.8 : 1 }]}
        maxFontSizeMultiplier={1.4}
      >
        {label.toUpperCase()}
      </Text>
      <Text
        style={[styles.numberValue, { color: foreground, fontSize: compact ? 40 : 64 }]}
        maxFontSizeMultiplier={1.3}
        allowFontScaling
      >
        {value}
      </Text>
      {caption ? (
        <Text
          style={[styles.numberCaption, { color: muted, opacity: tone === 'primary' ? 0.8 : 1 }]}
          maxFontSizeMultiplier={1.5}
        >
          {caption}
        </Text>
      ) : null}
    </View>
  );
}

/** Small pill used for match levels and statuses. */
export function Badge({
  label,
  tone = 'neutral',
}: {
  label: string;
  tone?: 'neutral' | 'success' | 'warning' | 'danger' | 'accent';
}) {
  const { colors } = useTheme();
  const map = {
    neutral: { background: colors.surfaceAlt, text: colors.textMuted },
    success: { background: colors.successSoft, text: colors.success },
    warning: { background: colors.warningSoft, text: colors.warning },
    danger: { background: colors.dangerSoft, text: colors.danger },
    accent: { background: colors.accentSoft, text: colors.accent },
  } as const;
  const style = map[tone];

  return (
    <View style={[styles.badge, { backgroundColor: style.background }]}>
      <Text style={[styles.badgeText, { color: style.text }]} maxFontSizeMultiplier={1.4}>
        {label}
      </Text>
    </View>
  );
}

/** A titled block of interpretation text. */
export function InfoSection({ title, body, items }: { title: string; body?: string; items?: string[] }) {
  const { colors } = useTheme();
  if (!body && (!items || items.length === 0)) return null;

  return (
    <View style={styles.infoSection}>
      <Text style={[styles.infoTitle, { color: colors.text }]} accessibilityRole="header">
        {title}
      </Text>
      {body ? <Text style={[styles.infoBody, { color: colors.textMuted }]}>{body}</Text> : null}
      {items?.map((item) => (
        <View key={item} style={styles.bulletRow}>
          <View style={[styles.bullet, { backgroundColor: colors.accent }]} />
          <Text style={[styles.infoBody, { color: colors.textMuted, flex: 1 }]}>{item}</Text>
        </View>
      ))}
    </View>
  );
}

/** Row of small number chips, e.g. lucky numbers. */
export function NumberChips({ values, tone = 'accent' }: { values: number[]; tone?: 'accent' | 'danger' }) {
  const { colors } = useTheme();
  if (values.length === 0) return null;

  return (
    <View style={styles.chipRow}>
      {values.map((value) => (
        <View
          key={value}
          style={[
            styles.chip,
            { backgroundColor: tone === 'accent' ? colors.accentSoft : colors.dangerSoft },
          ]}
        >
          <Text style={[styles.chipText, { color: tone === 'accent' ? colors.accent : colors.danger }]}>
            {value}
          </Text>
        </View>
      ))}
    </View>
  );
}

/** Navigation tile used on the home and tools screens. */
export function ToolCard({
  title,
  description,
  icon,
  onPress,
}: {
  title: string;
  description?: string;
  icon: string;
  onPress: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Card onPress={onPress} accessibilityLabel={title} style={styles.toolCard}>
      <View style={[styles.toolIcon, { backgroundColor: colors.accentSoft }]}>
        <Text style={[styles.toolIconText, { color: colors.accent }]}>{icon}</Text>
      </View>
      <View style={styles.toolBody}>
        <Text style={[styles.toolTitle, { color: colors.text }]} maxFontSizeMultiplier={1.5}>
          {title}
        </Text>
        {description ? (
          <Text style={[styles.toolDescription, { color: colors.textMuted }]} maxFontSizeMultiplier={1.5}>
            {description}
          </Text>
        ) : null}
      </View>
    </Card>
  );
}

/** Shows the digit-by-digit working behind a result. */
export function CalculationBreakdown({ title, steps }: { title: string; steps: Array<{ expression: string }> }) {
  const { colors } = useTheme();
  if (steps.length === 0) return null;

  return (
    <View style={[styles.breakdown, { backgroundColor: colors.surfaceAlt }]}>
      <Text style={[styles.breakdownTitle, { color: colors.textMuted }]}>{title}</Text>
      {steps.map((step, index) => (
        <Text key={`${step.expression}-${index}`} style={[styles.breakdownStep, { color: colors.text }]}>
          {step.expression}
        </Text>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: radius.lg,
    borderWidth: StyleSheet.hairlineWidth,
    padding: spacing.lg,
    marginBottom: spacing.md,
  },
  numberCard: { alignItems: 'center', paddingVertical: spacing.xl },
  numberCardCompact: { paddingVertical: spacing.lg, flex: 1 },
  numberLabel: { fontSize: fontSize.caption, fontWeight: fontWeight.semibold, letterSpacing: 1.2 },
  numberValue: { fontWeight: fontWeight.bold, lineHeight: 76, letterSpacing: -1 },
  numberCaption: { fontSize: fontSize.small, marginTop: spacing.xs },
  badge: {
    borderRadius: radius.pill,
    paddingHorizontal: spacing.md,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  badgeText: { fontSize: fontSize.small, fontWeight: fontWeight.semibold },
  infoSection: { marginBottom: spacing.lg },
  infoTitle: { fontSize: fontSize.body, fontWeight: fontWeight.semibold, marginBottom: spacing.xs },
  infoBody: { fontSize: fontSize.body, lineHeight: 22 },
  bulletRow: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.sm, marginTop: spacing.xs },
  bullet: { width: 6, height: 6, borderRadius: 3, marginTop: 8 },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, marginTop: spacing.sm },
  chip: {
    minWidth: 36,
    height: 36,
    borderRadius: radius.sm,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.sm,
  },
  chipText: { fontSize: fontSize.body, fontWeight: fontWeight.bold },
  toolCard: { flexDirection: 'row', alignItems: 'center', gap: spacing.md, minHeight: MIN_TOUCH_TARGET + 20 },
  toolIcon: { width: 44, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
  toolIconText: { fontSize: 20, fontWeight: fontWeight.bold },
  toolBody: { flex: 1 },
  toolTitle: { fontSize: fontSize.body, fontWeight: fontWeight.semibold },
  toolDescription: { fontSize: fontSize.small, marginTop: 2 },
  breakdown: { borderRadius: radius.md, padding: spacing.md, marginBottom: spacing.md },
  breakdownTitle: { fontSize: fontSize.caption, fontWeight: fontWeight.semibold, letterSpacing: 0.8, marginBottom: spacing.xs },
  breakdownStep: { fontSize: fontSize.body, fontVariant: ['tabular-nums'], lineHeight: 22 },
});

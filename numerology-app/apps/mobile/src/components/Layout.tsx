import React from 'react';
import { ScrollView, StyleSheet, Text, View, type ViewStyle } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, spacing } from '../theme/tokens';

/** Standard screen wrapper: safe area, background colour and scroll behaviour. */
export function Screen({
  children,
  scroll = true,
  style,
  refreshControl,
}: {
  children: React.ReactNode;
  scroll?: boolean;
  style?: ViewStyle;
  refreshControl?: React.ReactElement;
}) {
  const { colors } = useTheme();
  const insets = useSafeAreaInsets();

  if (!scroll) {
    return (
      <SafeAreaView style={[styles.flex, { backgroundColor: colors.background }, style]} edges={['top']}>
        {children}
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[styles.flex, { backgroundColor: colors.background }]} edges={['top']}>
      <ScrollView
        contentContainerStyle={[styles.scrollContent, { paddingBottom: insets.bottom + spacing.xxxl }, style]}
        keyboardShouldPersistTaps="handled"
        refreshControl={refreshControl}
        showsVerticalScrollIndicator={false}
      >
        {children}
      </ScrollView>
    </SafeAreaView>
  );
}

/** Screen title with an optional supporting line. */
export function ScreenHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.header}>
      <Text
        accessibilityRole="header"
        style={[styles.title, { color: colors.text }]}
        maxFontSizeMultiplier={1.6}
      >
        {title}
      </Text>
      {subtitle ? (
        <Text style={[styles.subtitle, { color: colors.textMuted }]} maxFontSizeMultiplier={1.8}>
          {subtitle}
        </Text>
      ) : null}
    </View>
  );
}

export function SectionHeader({ title, action }: { title: string; action?: React.ReactNode }) {
  const { colors } = useTheme();
  return (
    <View style={styles.sectionHeader}>
      <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.text }]}>
        {title}
      </Text>
      {action}
    </View>
  );
}

export function Divider() {
  const { colors } = useTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

export function Spacer({ size = spacing.lg }: { size?: number }) {
  return <View style={{ height: size }} />;
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  scrollContent: { paddingHorizontal: spacing.lg, paddingTop: spacing.md },
  header: { marginBottom: spacing.lg },
  title: { fontSize: fontSize.heading, fontWeight: fontWeight.bold, letterSpacing: -0.4 },
  subtitle: { fontSize: fontSize.body, marginTop: spacing.xs, lineHeight: 21 },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: spacing.xl,
    marginBottom: spacing.md,
  },
  sectionTitle: { fontSize: fontSize.bodyLarge, fontWeight: fontWeight.semibold },
  divider: { height: StyleSheet.hairlineWidth, marginVertical: spacing.md },
});

import React, { useState } from 'react';
import { Dimensions, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, radius, spacing } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { DOBPicker, PrimaryButton, TextButton, SegmentedControl } from '../components';
import { LOCALE_NAMES, SUPPORTED_LOCALES } from '../i18n';
import { toUserMessage } from '../lib/run';
import type { Locale } from '../i18n/translations';

const { width } = Dimensions.get('window');

/**
 * First launch flow: three short slides, a language choice and an optional date
 * of birth. The date of birth is never forced - "Skip for now" leads straight
 * into the app, and every module then offers to add it later.
 */
export function OnboardingScreen() {
  const { colors } = useTheme();
  const { t } = useTranslation();
  const { completeOnboarding, saveDateOfBirth, preferences, updatePreferences } = useApp();
  const [step, setStep] = useState(0);
  const [dob, setDob] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const slides = [
    { title: t('onboarding.slide1Title'), body: t('onboarding.slide1Body'), glyph: '१' },
    { title: t('onboarding.slide2Title'), body: t('onboarding.slide2Body'), glyph: '६' },
    { title: t('onboarding.slide3Title'), body: t('onboarding.slide3Body'), glyph: '९' },
  ];

  const finish = async (withDob: boolean) => {
    setSaving(true);
    setError(null);
    try {
      if (withDob && dob) {
        await saveDateOfBirth(dob);
      }
      await completeOnboarding();
    } catch (caught) {
      setError(toUserMessage(caught, preferences.locale));
    } finally {
      setSaving(false);
    }
  };

  if (step < slides.length) {
    const slide = slides[step]!;
    return (
      <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
        <View style={styles.slideContent}>
          <View style={[styles.glyph, { backgroundColor: colors.accentSoft }]}>
            <Text style={[styles.glyphText, { color: colors.accent }]}>{slide.glyph}</Text>
          </View>
          <Text style={[styles.slideTitle, { color: colors.text }]} accessibilityRole="header">
            {slide.title}
          </Text>
          <Text style={[styles.slideBody, { color: colors.textMuted }]}>{slide.body}</Text>
        </View>

        <View style={styles.dots} accessibilityElementsHidden>
          {slides.map((item, index) => (
            <View
              key={item.title}
              style={[
                styles.dot,
                { backgroundColor: index === step ? colors.accent : colors.border, width: index === step ? 22 : 8 },
              ]}
            />
          ))}
        </View>

        <View style={styles.footer}>
          <PrimaryButton label={t('common.continue')} onPress={() => setStep(step + 1)} />
          <TextButton label={t('common.skip')} onPress={() => setStep(slides.length)} />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <ScrollView contentContainerStyle={styles.dobContent} keyboardShouldPersistTaps="handled">
        <Text style={[styles.slideTitle, { color: colors.text }]} accessibilityRole="header">
          {t('onboarding.dobTitle')}
        </Text>
        <Text style={[styles.slideBody, { color: colors.textMuted, marginBottom: spacing.xl }]}>
          {t('onboarding.dobBody')}
        </Text>

        <SegmentedControl
          label={t('profile.language')}
          value={preferences.locale}
          options={SUPPORTED_LOCALES.map((locale) => ({ value: locale, label: LOCALE_NAMES[locale] }))}
          onChange={(locale: Locale) => void updatePreferences({ locale })}
        />

        <DOBPicker label={t('common.dateOfBirth')} value={dob} onChange={setDob} error={error} />

        <Text style={[styles.disclaimer, { color: colors.textMuted }]}>{t('onboarding.disclaimer')}</Text>
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          label={t('onboarding.saveDob')}
          onPress={() => void finish(true)}
          disabled={!dob}
          loading={saving}
        />
        <TextButton label={t('common.skip')} onPress={() => void finish(false)} />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingHorizontal: spacing.xl },
  slideContent: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: spacing.md },
  glyph: {
    width: Math.min(140, width * 0.36),
    height: Math.min(140, width * 0.36),
    borderRadius: radius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.xl,
  },
  glyphText: { fontSize: 56, fontWeight: fontWeight.bold },
  slideTitle: { fontSize: fontSize.heading, fontWeight: fontWeight.bold, textAlign: 'center', letterSpacing: -0.4 },
  slideBody: { fontSize: fontSize.body, textAlign: 'center', lineHeight: 23, paddingHorizontal: spacing.md },
  dots: { flexDirection: 'row', gap: spacing.sm, justifyContent: 'center', marginBottom: spacing.xl },
  dot: { height: 8, borderRadius: 4 },
  footer: { gap: spacing.sm, paddingBottom: spacing.xl },
  dobContent: { flexGrow: 1, justifyContent: 'center', paddingTop: spacing.xxl },
  disclaimer: { fontSize: fontSize.caption, lineHeight: 18, marginTop: spacing.lg },
});

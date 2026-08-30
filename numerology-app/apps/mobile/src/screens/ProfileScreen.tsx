import React, { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, spacing } from '../theme/tokens';
import { LOCALE_NAMES, SUPPORTED_LOCALES, formatLongDate, useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { toUserMessage } from '../lib/run';
import {
  Card,
  DOBPicker,
  Divider,
  PrimaryButton,
  Screen,
  ScreenHeader,
  SecondaryButton,
  SectionHeader,
  SegmentedControl,
  TextButton,
  TextField,
  ToggleRow,
  useFeedback,
} from '../components';
import type { ProfileStackParamList } from '../navigation/types';
import type { Locale } from '../i18n/translations';
import type { ThemeMode } from '../theme/ThemeProvider';

/** Profile, global date of birth, preferences and legal links. */
export function ProfileScreen() {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const navigation = useNavigation<NativeStackNavigationProp<ProfileStackParamList>>();
  const { confirm, showToast } = useFeedback();
  const {
    profile,
    preferences,
    signedIn,
    isGuest,
    email,
    saveDateOfBirth,
    setDisplayName,
    updatePreferences,
    signOut,
    deleteAccount,
  } = useApp();

  const [name, setName] = useState(profile.displayName ?? '');
  const [busy, setBusy] = useState(false);

  const saveName = async () => {
    setBusy(true);
    try {
      await setDisplayName(name.trim());
      showToast(t('common.save'));
    } catch (caught) {
      showToast(toUserMessage(caught, preferences.locale), 'error');
    } finally {
      setBusy(false);
    }
  };

  const changeDob = async (iso: string) => {
    try {
      await saveDateOfBirth(iso);
      showToast(t('common.save'));
    } catch (caught) {
      showToast(toUserMessage(caught, preferences.locale), 'error');
    }
  };

  const handleDelete = async () => {
    const confirmed = await confirm({
      title: t('profile.deleteAccount'),
      message: t('profile.deleteConfirm'),
      confirmLabel: t('common.delete'),
      cancelLabel: t('common.cancel'),
    });
    if (!confirmed) return;
    try {
      await deleteAccount();
      showToast(t('common.done'));
    } catch (caught) {
      showToast(toUserMessage(caught, preferences.locale), 'error');
    }
  };

  return (
    <Screen>
      <ScreenHeader
        title={t('profile.title')}
        subtitle={signedIn && !isGuest ? (email ?? undefined) : t('profile.guest')}
      />

      <Card>
        <TextField
          label={t('profile.editName')}
          value={name}
          onChangeText={setName}
          maxLength={60}
          autoComplete="name"
        />
        <SecondaryButton label={t('common.save')} onPress={() => void saveName()} loading={busy} />
      </Card>

      <Card>
        <Text style={[styles.rowLabel, { color: colors.textMuted }]}>{t('profile.yourDob')}</Text>
        <Text style={[styles.rowValue, { color: colors.text }]}>
          {profile.dateOfBirth ? formatLongDate(profile.dateOfBirth, locale) : t('profile.notSet')}
        </Text>
        {profile.mulank && profile.bhagyank ? (
          <Text style={{ color: colors.textMuted, marginBottom: spacing.md }}>
            {t('common.mulank')} {profile.mulank} · {t('common.bhagyank')} {profile.bhagyank}
          </Text>
        ) : null}
        <DOBPicker
          label={t('common.dateOfBirth')}
          value={profile.dateOfBirth}
          onChange={(iso) => void changeDob(iso)}
        />
      </Card>

      <SectionHeader title={t('profile.settings')} />
      <Card>
        <SegmentedControl
          label={t('profile.language')}
          value={preferences.locale}
          options={SUPPORTED_LOCALES.map((item) => ({ value: item, label: LOCALE_NAMES[item] }))}
          onChange={(value: Locale) => void updatePreferences({ locale: value })}
        />

        <SegmentedControl
          label={t('profile.theme')}
          value={preferences.theme}
          options={[
            { value: 'SYSTEM' as ThemeMode, label: t('profile.themeSystem') },
            { value: 'LIGHT' as ThemeMode, label: t('profile.themeLight') },
            { value: 'DARK' as ThemeMode, label: t('profile.themeDark') },
          ]}
          onChange={(value: ThemeMode) => void updatePreferences({ theme: value })}
        />

        <Divider />

        <ToggleRow
          label={t('profile.notifications')}
          value={preferences.notificationsEnabled}
          onChange={(value) => void updatePreferences({ notificationsEnabled: value })}
        />
        <ToggleRow
          label={t('profile.dailyNumberNotification')}
          value={preferences.dailyNumberOptIn}
          onChange={(value) => void updatePreferences({ dailyNumberOptIn: value })}
        />
        <ToggleRow
          label={t('profile.analytics')}
          value={preferences.analyticsConsent}
          onChange={(value) => void updatePreferences({ analyticsConsent: value })}
        />
        <ToggleRow
          label={t('profile.shareDob')}
          value={preferences.shareDobOnCards}
          onChange={(value) => void updatePreferences({ shareDobOnCards: value })}
        />
      </Card>

      <SectionHeader title={t('profile.about')} />
      <Card>
        <TextButton label={t('profile.privacy')} onPress={() => navigation.navigate('Legal', { type: 'PRIVACY' })} />
        <TextButton label={t('profile.terms')} onPress={() => navigation.navigate('Legal', { type: 'TERMS' })} />
        <TextButton
          label={t('profile.disclaimer')}
          onPress={() => navigation.navigate('Legal', { type: 'DISCLAIMER' })}
        />
        <TextButton label={t('profile.about')} onPress={() => navigation.navigate('Legal', { type: 'ABOUT' })} />
      </Card>

      {signedIn && !isGuest ? (
        <>
          <SecondaryButton label={t('profile.signOut')} onPress={() => void signOut()} />
          <TextButton label={t('profile.deleteAccount')} onPress={() => void handleDelete()} />
        </>
      ) : (
        <>
          <Text style={{ color: colors.textMuted, marginBottom: spacing.md, lineHeight: 21 }}>
            {t('auth.whySignIn')}
          </Text>
          <PrimaryButton
            label={t('profile.signIn')}
            onPress={() => navigation.navigate('Auth', { mode: 'signIn' })}
          />
          <SecondaryButton
            label={t('profile.signUp')}
            onPress={() => navigation.navigate('Auth', { mode: 'signUp' })}
            style={{ marginTop: spacing.sm }}
          />
        </>
      )}

      <View style={{ height: spacing.xxxl }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  rowLabel: { fontSize: fontSize.small, fontWeight: fontWeight.semibold },
  rowValue: { fontSize: fontSize.bodyLarge, fontWeight: fontWeight.semibold, marginTop: 2, marginBottom: spacing.sm },
});

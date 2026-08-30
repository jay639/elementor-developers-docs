import React, { useState } from 'react';
import { Text } from 'react-native';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import { useTheme } from '../theme/ThemeProvider';
import { spacing } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { toUserMessage } from '../lib/run';
import {
  Card,
  ErrorState,
  PrimaryButton,
  Screen,
  ScreenHeader,
  TextButton,
  TextField,
} from '../components';
import type { ProfileStackParamList } from '../navigation/types';

/**
 * Email sign in and registration.
 *
 * Creating an account is never required for a calculation - it only adds cloud
 * history, sync and cross-device settings.
 */
export function AuthScreen() {
  const { colors } = useTheme();
  const { t } = useTranslation();
  const navigation = useNavigation();
  const route = useRoute<RouteProp<ProfileStackParamList, 'Auth'>>();
  const { signIn, signUp, preferences } = useApp();

  const [mode, setMode] = useState<'signIn' | 'signUp'>(route.params?.mode ?? 'signIn');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      if (mode === 'signIn') {
        await signIn(email.trim(), password);
      } else {
        await signUp(email.trim(), password, name.trim() || undefined);
      }
      navigation.goBack();
    } catch (caught) {
      setError(toUserMessage(caught, preferences.locale));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Screen>
      <ScreenHeader title={mode === 'signIn' ? t('auth.signInTitle') : t('auth.signUpTitle')} />

      {error ? <ErrorState message={error} /> : null}

      <Card>
        {mode === 'signUp' ? (
          <TextField label={t('auth.name')} value={name} onChangeText={setName} maxLength={60} autoComplete="name" />
        ) : null}

        <TextField
          label={t('auth.email')}
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          autoComplete="email"
          maxLength={180}
        />

        <TextField
          label={t('auth.password')}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          autoCapitalize="none"
          autoComplete="password"
          maxLength={128}
          onSubmitEditing={() => void submit()}
        />

        <PrimaryButton
          label={mode === 'signIn' ? t('auth.signInAction') : t('auth.signUpAction')}
          onPress={() => void submit()}
          loading={busy}
          disabled={email.trim().length === 0 || password.length === 0}
        />

        <TextButton
          label={mode === 'signIn' ? t('auth.switchToSignUp') : t('auth.switchToSignIn')}
          onPress={() => {
            setMode(mode === 'signIn' ? 'signUp' : 'signIn');
            setError(null);
          }}
          style={{ marginTop: spacing.sm }}
        />
      </Card>

      <Text style={{ color: colors.textMuted, lineHeight: 21 }}>{t('auth.whySignIn')}</Text>
    </Screen>
  );
}

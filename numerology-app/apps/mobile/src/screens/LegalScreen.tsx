import React, { useEffect, useState } from 'react';
import { Text } from 'react-native';
import { useRoute, type RouteProp } from '@react-navigation/native';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize } from '../theme/tokens';
import { useTranslation } from '../i18n';
import { useApp } from '../state/AppProvider';
import { api } from '../api/endpoints';
import { toUserMessage } from '../lib/run';
import { Card, ErrorState, LoadingState, Screen, ScreenHeader } from '../components';
import type { ProfileStackParamList } from '../navigation/types';

/** Terms, privacy policy, disclaimer and about, served in the user's language. */
export function LegalScreen() {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const { preferences } = useApp();
  const route = useRoute<RouteProp<ProfileStackParamList, 'Legal'>>();
  const type = route.params.type;

  const [document, setDocument] = useState<{ title: string; body: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    api
      .legal(type)
      .then(({ data }) => {
        if (!cancelled) setDocument({ title: data.title, body: data.body });
      })
      .catch((caught) => {
        if (!cancelled) setError(toUserMessage(caught, preferences.locale));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [locale, preferences.locale, type]);

  return (
    <Screen>
      <ScreenHeader title={document?.title ?? t('profile.about')} />
      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState message={error} />
      ) : (
        <Card>
          <Text style={{ color: colors.text, fontSize: fontSize.body, lineHeight: 23 }}>{document?.body}</Text>
        </Card>
      )}
    </Screen>
  );
}

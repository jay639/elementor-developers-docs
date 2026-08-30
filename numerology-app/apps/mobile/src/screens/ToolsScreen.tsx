import React from 'react';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTranslation } from '../i18n';
import { Screen, ScreenHeader, ToolCard } from '../components';
import type { ToolsStackParamList } from '../navigation/types';

/** The Tools tab: one entry per numerology module. */
export function ToolsScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NativeStackNavigationProp<ToolsStackParamList>>();

  return (
    <Screen>
      <ScreenHeader title={t('tools.title')} />

      <ToolCard
        icon="१"
        title={t('tools.coreNumbers')}
        description={t('tools.coreNumbersHint')}
        onPress={() => navigation.navigate('CoreNumbers')}
      />
      <ToolCard
        icon="७"
        title={t('tools.luckyNumber')}
        description={t('tools.luckyNumberHint')}
        onPress={() => navigation.navigate('LuckyNumber')}
      />
      <ToolCard
        icon="अ"
        title={t('tools.nameNumerology')}
        description={t('tools.nameNumerologyHint')}
        onPress={() => navigation.navigate('NameNumerology')}
      />
      <ToolCard
        icon="♥"
        title={t('tools.compatibility')}
        description={t('tools.compatibilityHint')}
        onPress={() => navigation.navigate('Compatibility')}
      />
    </Screen>
  );
}

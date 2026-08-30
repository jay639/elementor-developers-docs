import type { NavigatorScreenParams } from '@react-navigation/native';

/** Route parameters, so navigation calls are type checked. */
export type ToolsStackParamList = {
  ToolsHome: undefined;
  CoreNumbers: { dateOfBirth?: string } | undefined;
  LuckyNumber: undefined;
  NameNumerology: undefined;
  Compatibility: undefined;
};

export type ProfileStackParamList = {
  ProfileHome: undefined;
  Auth: { mode: 'signIn' | 'signUp' } | undefined;
  Legal: { type: 'TERMS' | 'PRIVACY' | 'DISCLAIMER' | 'ABOUT' };
};

export type HomeStackParamList = {
  HomeMain: undefined;
};

export type TabParamList = {
  Home: NavigatorScreenParams<HomeStackParamList>;
  Tools: NavigatorScreenParams<ToolsStackParamList>;
  History: undefined;
  Profile: NavigatorScreenParams<ProfileStackParamList>;
};

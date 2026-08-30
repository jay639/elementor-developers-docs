import React, { useMemo, useState } from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  type KeyboardTypeOptions,
} from 'react-native';
import { daysInMonth, formatISODate, isValidDateParts, MIN_BIRTH_YEAR } from '@numerology/core';
import { useTheme } from '../theme/ThemeProvider';
import { MIN_TOUCH_TARGET, fontSize, fontWeight, radius, spacing } from '../theme/tokens';
import { MONTH_NAMES, formatLongDate, useTranslation } from '../i18n';
import { PrimaryButton, SecondaryButton } from './Buttons';

/** Labelled text field used across the app. */
export function TextField({
  label,
  value,
  onChangeText,
  placeholder,
  keyboardType,
  autoCapitalize = 'sentences',
  secureTextEntry,
  error,
  maxLength,
  autoComplete,
  onSubmitEditing,
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  placeholder?: string;
  keyboardType?: KeyboardTypeOptions;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  secureTextEntry?: boolean;
  error?: string | null;
  maxLength?: number;
  autoComplete?: 'email' | 'password' | 'name' | 'off';
  onSubmitEditing?: () => void;
}) {
  const { colors } = useTheme();
  return (
    <View style={styles.field}>
      <Text style={[styles.label, { color: colors.textMuted }]} maxFontSizeMultiplier={1.6}>
        {label}
      </Text>
      <TextInput
        accessibilityLabel={label}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={colors.textMuted}
        keyboardType={keyboardType}
        autoCapitalize={autoCapitalize}
        autoCorrect={false}
        secureTextEntry={secureTextEntry}
        maxLength={maxLength}
        autoComplete={autoComplete}
        onSubmitEditing={onSubmitEditing}
        returnKeyType="done"
        style={[
          styles.input,
          {
            backgroundColor: colors.surface,
            borderColor: error ? colors.danger : colors.border,
            color: colors.text,
          },
        ]}
      />
      {error ? (
        <Text style={[styles.error, { color: colors.danger }]} accessibilityLiveRegion="polite">
          {error}
        </Text>
      ) : null}
    </View>
  );
}

/** Numeric field for vehicle, mobile and house numbers. */
export function NumberField(props: Omit<Parameters<typeof TextField>[0], 'keyboardType' | 'autoCapitalize'>) {
  return <TextField {...props} keyboardType="numbers-and-punctuation" autoCapitalize="characters" />;
}

/** Name field for Chaldean name numerology. */
export function NameField(props: Omit<Parameters<typeof TextField>[0], 'keyboardType' | 'autoCapitalize'>) {
  return <TextField {...props} keyboardType="default" autoCapitalize="words" />;
}

interface DateParts {
  day: number;
  month: number;
  year: number;
}

/**
 * Date of birth picker with separate day, month and year columns.
 *
 * Written in plain React Native so it behaves identically on Android and iOS,
 * shows month names in the selected language, and can never produce an
 * impossible date: the day column is rebuilt from the chosen month and year, so
 * 30 February simply cannot be selected.
 */
export function DOBPicker({
  label,
  value,
  onChange,
  error,
}: {
  label: string;
  value: string | null;
  onChange: (iso: string) => void;
  error?: string | null;
}) {
  const { colors } = useTheme();
  const { t, locale } = useTranslation();
  const [open, setOpen] = useState(false);

  const today = new Date();
  const initial: DateParts = useMemo(() => {
    if (value) {
      const [year, month, day] = value.split('-').map(Number);
      if (year && month && day) return { year, month, day };
    }
    return { day: 1, month: 1, year: today.getFullYear() - 25 };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const [draft, setDraft] = useState<DateParts>(initial);

  const years = useMemo(() => {
    const list: number[] = [];
    for (let year = today.getFullYear(); year >= MIN_BIRTH_YEAR; year -= 1) list.push(year);
    return list;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const days = useMemo(() => {
    const count = daysInMonth(draft.month, draft.year);
    return Array.from({ length: count }, (_, index) => index + 1);
  }, [draft.month, draft.year]);

  const confirm = () => {
    const safeDay = Math.min(draft.day, daysInMonth(draft.month, draft.year));
    const parts = { ...draft, day: safeDay };
    if (!isValidDateParts(parts)) return;
    onChange(formatISODate(parts));
    setOpen(false);
  };

  const openPicker = () => {
    setDraft(initial);
    setOpen(true);
  };

  return (
    <View style={styles.field}>
      <Text style={[styles.label, { color: colors.textMuted }]} maxFontSizeMultiplier={1.6}>
        {label}
      </Text>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${label}. ${value ? formatLongDate(value, locale) : t('profile.notSet')}`}
        onPress={openPicker}
        style={({ pressed }) => [
          styles.input,
          styles.dobTrigger,
          {
            backgroundColor: colors.surface,
            borderColor: error ? colors.danger : colors.border,
            opacity: pressed ? 0.9 : 1,
          },
        ]}
      >
        <Text style={{ color: value ? colors.text : colors.textMuted, fontSize: fontSize.body }}>
          {value ? formatLongDate(value, locale) : t('profile.notSet')}
        </Text>
        <Text style={{ color: colors.accent, fontSize: fontSize.body, fontWeight: fontWeight.semibold }}>
          {value ? '✎' : '+'}
        </Text>
      </Pressable>

      {error ? (
        <Text style={[styles.error, { color: colors.danger }]} accessibilityLiveRegion="polite">
          {error}
        </Text>
      ) : null}

      <Modal visible={open} transparent animationType="slide" onRequestClose={() => setOpen(false)}>
        <View style={[styles.sheetBackdrop, { backgroundColor: colors.overlay }]}>
          <View style={[styles.sheet, { backgroundColor: colors.surface }]}>
            <Text style={[styles.sheetTitle, { color: colors.text }]} accessibilityRole="header">
              {label}
            </Text>

            <View style={styles.wheelRow}>
              <Wheel
                label={t('common.day')}
                items={days.map((day) => ({ value: day, label: String(day) }))}
                selected={Math.min(draft.day, days.length)}
                onSelect={(day) => setDraft((current) => ({ ...current, day }))}
              />
              <Wheel
                label={t('common.month')}
                items={MONTH_NAMES[locale].map((name, index) => ({ value: index + 1, label: name }))}
                selected={draft.month}
                onSelect={(month) =>
                  setDraft((current) => ({
                    ...current,
                    month,
                    day: Math.min(current.day, daysInMonth(month, current.year)),
                  }))
                }
              />
              <Wheel
                label={t('common.year')}
                items={years.map((year) => ({ value: year, label: String(year) }))}
                selected={draft.year}
                onSelect={(year) =>
                  setDraft((current) => ({
                    ...current,
                    year,
                    day: Math.min(current.day, daysInMonth(current.month, year)),
                  }))
                }
              />
            </View>

            <View style={styles.sheetActions}>
              <SecondaryButton label={t('common.cancel')} onPress={() => setOpen(false)} style={{ flex: 1 }} />
              <PrimaryButton label={t('common.done')} onPress={confirm} style={{ flex: 1 }} />
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

function Wheel({
  label,
  items,
  selected,
  onSelect,
}: {
  label: string;
  items: Array<{ value: number; label: string }>;
  selected: number;
  onSelect: (value: number) => void;
}) {
  const { colors } = useTheme();
  return (
    <View style={styles.wheel}>
      <Text style={[styles.wheelLabel, { color: colors.textMuted }]}>{label}</Text>
      <ScrollView style={styles.wheelScroll} showsVerticalScrollIndicator={false}>
        {items.map((item) => {
          const active = item.value === selected;
          return (
            <Pressable
              key={item.value}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => onSelect(item.value)}
              style={[styles.wheelItem, active && { backgroundColor: colors.accentSoft }]}
            >
              <Text
                numberOfLines={1}
                style={{
                  color: active ? colors.text : colors.textMuted,
                  fontWeight: active ? fontWeight.semibold : fontWeight.regular,
                  fontSize: fontSize.body,
                }}
              >
                {item.label}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
    </View>
  );
}

/** Simple row with a label and a switch-like toggle. */
export function ToggleRow({
  label,
  description,
  value,
  onChange,
}: {
  label: string;
  description?: string;
  value: boolean;
  onChange: (value: boolean) => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityState={{ checked: value }}
      accessibilityLabel={label}
      onPress={() => onChange(!value)}
      style={({ pressed }) => [styles.toggleRow, { opacity: pressed ? 0.85 : 1 }]}
    >
      <View style={{ flex: 1 }}>
        <Text style={{ color: colors.text, fontSize: fontSize.body }}>{label}</Text>
        {description ? (
          <Text style={{ color: colors.textMuted, fontSize: fontSize.small, marginTop: 2 }}>{description}</Text>
        ) : null}
      </View>
      <View
        style={[
          styles.switchTrack,
          { backgroundColor: value ? colors.accent : colors.surfaceAlt, borderColor: colors.border },
        ]}
      >
        <View
          style={[
            styles.switchThumb,
            { backgroundColor: colors.surface, alignSelf: value ? 'flex-end' : 'flex-start' },
          ]}
        />
      </View>
    </Pressable>
  );
}

/** Segmented control used for language and appearance. */
export function SegmentedControl<T extends string>({
  label,
  options,
  value,
  onChange,
}: {
  label?: string;
  options: Array<{ value: T; label: string }>;
  value: T;
  onChange: (value: T) => void;
}) {
  const { colors } = useTheme();
  return (
    <View style={styles.field}>
      {label ? <Text style={[styles.label, { color: colors.textMuted }]}>{label}</Text> : null}
      <View style={[styles.segment, { backgroundColor: colors.surfaceAlt }]}>
        {options.map((option) => {
          const active = option.value === value;
          return (
            <Pressable
              key={option.value}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => onChange(option.value)}
              style={[styles.segmentItem, active && { backgroundColor: colors.surface }]}
            >
              <Text
                numberOfLines={1}
                style={{
                  color: active ? colors.text : colors.textMuted,
                  fontWeight: active ? fontWeight.semibold : fontWeight.regular,
                  fontSize: fontSize.small,
                }}
              >
                {option.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  field: { marginBottom: spacing.lg },
  label: { fontSize: fontSize.small, fontWeight: fontWeight.semibold, marginBottom: spacing.xs },
  input: {
    minHeight: MIN_TOUCH_TARGET + 4,
    borderRadius: radius.md,
    borderWidth: 1,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    fontSize: fontSize.body,
  },
  dobTrigger: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  error: { fontSize: fontSize.small, marginTop: spacing.xs },
  sheetBackdrop: { flex: 1, justifyContent: 'flex-end' },
  sheet: {
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
    paddingBottom: spacing.xxl,
  },
  sheetTitle: { fontSize: fontSize.bodyLarge, fontWeight: fontWeight.semibold, marginBottom: spacing.md },
  wheelRow: { flexDirection: 'row', gap: spacing.sm, height: 260 },
  wheel: { flex: 1 },
  wheelLabel: { fontSize: fontSize.caption, fontWeight: fontWeight.semibold, marginBottom: spacing.xs },
  wheelScroll: { flex: 1 },
  wheelItem: {
    minHeight: MIN_TOUCH_TARGET,
    justifyContent: 'center',
    paddingHorizontal: spacing.sm,
    borderRadius: radius.sm,
  },
  sheetActions: { flexDirection: 'row', gap: spacing.md, marginTop: spacing.lg },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: MIN_TOUCH_TARGET + 8,
    paddingVertical: spacing.sm,
  },
  switchTrack: { width: 52, height: 30, borderRadius: radius.pill, borderWidth: 1, padding: 3, justifyContent: 'center' },
  switchThumb: { width: 22, height: 22, borderRadius: 11 },
  segment: { flexDirection: 'row', borderRadius: radius.md, padding: 3, gap: 3 },
  segmentItem: {
    flex: 1,
    minHeight: MIN_TOUCH_TARGET - 4,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.sm,
    paddingHorizontal: spacing.sm,
  },
});

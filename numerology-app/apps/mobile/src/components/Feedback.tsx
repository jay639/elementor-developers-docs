import React, { createContext, useCallback, useContext, useMemo, useRef, useState } from 'react';
import { Animated, Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { fontSize, fontWeight, radius, spacing } from '../theme/tokens';
import { PrimaryButton, SecondaryButton } from './Buttons';

interface ToastState {
  message: string;
  tone: 'info' | 'error';
}

interface FeedbackContextValue {
  showToast: (message: string, tone?: 'info' | 'error') => void;
  confirm: (options: { title: string; message?: string; confirmLabel: string; cancelLabel: string }) => Promise<boolean>;
}

const FeedbackContext = createContext<FeedbackContextValue | null>(null);

/**
 * Toast and confirmation dialog. Both are rendered by the app itself rather
 * than the platform alert, so they follow the app's theme in light and dark
 * mode and read correctly to a screen reader.
 */
export function FeedbackProvider({ children }: { children: React.ReactNode }) {
  const { colors } = useTheme();
  const [toast, setToast] = useState<ToastState | null>(null);
  const [dialog, setDialog] = useState<{
    title: string;
    message?: string;
    confirmLabel: string;
    cancelLabel: string;
    resolve: (value: boolean) => void;
  } | null>(null);
  const opacity = useRef(new Animated.Value(0)).current;

  const showToast = useCallback(
    (message: string, tone: 'info' | 'error' = 'info') => {
      setToast({ message, tone });
      Animated.sequence([
        Animated.timing(opacity, { toValue: 1, duration: 160, useNativeDriver: true }),
        Animated.delay(2600),
        Animated.timing(opacity, { toValue: 0, duration: 220, useNativeDriver: true }),
      ]).start(() => setToast(null));
    },
    [opacity],
  );

  const confirm = useCallback<FeedbackContextValue['confirm']>(
    (options) =>
      new Promise<boolean>((resolve) => {
        setDialog({ ...options, resolve });
      }),
    [],
  );

  const close = (result: boolean) => {
    dialog?.resolve(result);
    setDialog(null);
  };

  const value = useMemo(() => ({ showToast, confirm }), [showToast, confirm]);

  return (
    <FeedbackContext.Provider value={value}>
      {children}

      {toast ? (
        <Animated.View
          pointerEvents="none"
          accessibilityLiveRegion="polite"
          style={[
            styles.toast,
            { backgroundColor: toast.tone === 'error' ? colors.danger : colors.primary, opacity },
          ]}
        >
          <Text style={[styles.toastText, { color: colors.primaryContrast }]}>{toast.message}</Text>
        </Animated.View>
      ) : null}

      <Modal visible={dialog !== null} transparent animationType="fade" onRequestClose={() => close(false)}>
        <Pressable style={[styles.backdrop, { backgroundColor: colors.overlay }]} onPress={() => close(false)}>
          <Pressable style={[styles.dialog, { backgroundColor: colors.surface }]} onPress={() => undefined}>
            <Text style={[styles.dialogTitle, { color: colors.text }]} accessibilityRole="header">
              {dialog?.title}
            </Text>
            {dialog?.message ? (
              <Text style={[styles.dialogMessage, { color: colors.textMuted }]}>{dialog.message}</Text>
            ) : null}
            <View style={styles.dialogActions}>
              <SecondaryButton label={dialog?.cancelLabel ?? ''} onPress={() => close(false)} style={{ flex: 1 }} />
              <PrimaryButton label={dialog?.confirmLabel ?? ''} onPress={() => close(true)} style={{ flex: 1 }} />
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </FeedbackContext.Provider>
  );
}

export function useFeedback(): FeedbackContextValue {
  const context = useContext(FeedbackContext);
  if (!context) throw new Error('useFeedback must be used inside FeedbackProvider');
  return context;
}

const styles = StyleSheet.create({
  toast: {
    position: 'absolute',
    left: spacing.lg,
    right: spacing.lg,
    bottom: spacing.xxxl,
    borderRadius: radius.md,
    padding: spacing.lg,
  },
  toastText: { fontSize: fontSize.body, lineHeight: 21 },
  backdrop: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: spacing.xl },
  dialog: { width: '100%', maxWidth: 420, borderRadius: radius.lg, padding: spacing.xl },
  dialogTitle: { fontSize: fontSize.bodyLarge, fontWeight: fontWeight.semibold },
  dialogMessage: { fontSize: fontSize.body, lineHeight: 22, marginTop: spacing.sm },
  dialogActions: { flexDirection: 'row', gap: spacing.md, marginTop: spacing.xl },
});

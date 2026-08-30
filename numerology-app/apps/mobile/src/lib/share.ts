import { Share } from 'react-native';
import * as Sharing from 'expo-sharing';
import { captureRef } from 'react-native-view-shot';
import type { RefObject } from 'react';
import type { View } from 'react-native';

/**
 * Result sharing.
 *
 * A rendered card is preferred; if image capture or the share sheet is not
 * available the app falls back to sharing plain text. Nothing is shared that
 * the caller did not put in the card - the date of birth is only included when
 * the user has turned that on in their preferences.
 */
export async function shareResultCard(
  cardRef: RefObject<View>,
  fallbackText: string,
): Promise<'image' | 'text' | 'cancelled'> {
  try {
    if (cardRef.current && (await Sharing.isAvailableAsync())) {
      const uri = await captureRef(cardRef, { format: 'png', quality: 0.95, result: 'tmpfile' });
      await Sharing.shareAsync(uri, { mimeType: 'image/png', dialogTitle: fallbackText.slice(0, 60) });
      return 'image';
    }
  } catch {
    // Falls through to the text share below.
  }

  try {
    const result = await Share.share({ message: fallbackText });
    return result.action === Share.dismissedAction ? 'cancelled' : 'text';
  } catch {
    return 'cancelled';
  }
}

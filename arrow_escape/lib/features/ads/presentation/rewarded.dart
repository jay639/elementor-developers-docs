import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a rewarded ad for [kind]. Returns true when the reward was earned;
/// explains politely when no video is available.
Future<bool> watchRewarded(
  BuildContext context,
  WidgetRef ref,
  RewardKind kind,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final earned = await ref.read(adServiceProvider).showRewarded(kind);
  if (!earned) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('No video available right now. Please try again soon.'),
      ),
    );
  }
  return earned;
}

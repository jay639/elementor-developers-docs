import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/purchases/application/entitlements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The only banner in the app, at the bottom of the map screen. Gone once
/// `remove_ads` is owned.
class MapBanner extends ConsumerWidget {
  const MapBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(noAdsProvider)) return const SizedBox.shrink();
    return Center(
      heightFactor: 1,
      child: ref.watch(adServiceProvider).buildBanner(),
    );
  }
}

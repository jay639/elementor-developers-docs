import 'dart:math' as math;

import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';

/// Merges the local save with the cloud copy.
///
/// Progress only ever grows, so it is merged field by field (highest
/// unlock, best stars). Owned things are unioned. Everything that can go
/// down as well as up (coins, selected skin, streaks, settings) comes from
/// whichever copy changed last.
SaveData mergeSaves(SaveData local, SaveData remote) {
  if (local == remote) return local;
  final newer = remote.updatedAt > local.updatedAt ? remote : local;

  Map<K, int> best<K>(Map<K, int> a, Map<K, int> b) => {
    ...a,
    for (final e in b.entries) e.key: math.max(e.value, a[e.key] ?? 0),
  };

  final progress = Progress(
    unlocked: math.max(local.progress.unlocked, remote.progress.unlocked),
    stars: best(local.progress.stars, remote.progress.stars),
    dailyStars: best(local.progress.dailyStars, remote.progress.dailyStars),
  );
  final owned = {...local.ownedSkins, ...remote.ownedSkins}.toList()..sort();
  final bundles = {...local.claimedBundles, ...remote.claimedBundles}.toList()
    ..sort();

  return newer.copyWith(
    progress: progress,
    ownedSkins: owned,
    claimedBundles: bundles,
    selectedSkin: owned.contains(newer.selectedSkin)
        ? newer.selectedSkin
        : 'classic',
    revision: math.max(local.revision, remote.revision),
  );
}

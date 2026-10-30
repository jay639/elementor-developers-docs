import 'dart:async';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/app.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/core/services/haptics.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/purchases/domain/products.dart';
import 'package:arrow_escape/features/save/data/save_repository.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/board_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class RecordingHaptics implements HapticsService {
  final played = <HapticKind>[];

  @override
  void play(HapticKind kind) => played.add(kind);
}

class RecordingSound implements SoundService {
  final played = <Sfx>[];

  @override
  void play(Sfx sfx) => played.add(sfx);

  @override
  void warmUp() {}

  @override
  Future<void> dispose() async {}
}

class RecordingAnalytics extends AnalyticsService {
  final events = <({String name, Map<String, Object> params})>[];

  @override
  Future<void> log(
    String name, [
    Map<String, Object> params = const {},
  ]) async => events.add((name: name, params: params));
}

/// Ads that "play" instantly. [earn] decides whether rewards are granted.
class FakeAdService implements AdService {
  bool earn = true;
  final rewarded = <RewardKind>[];
  final completedLevels = <int>[];

  @override
  bool adsRemoved = false;

  @override
  Future<void> initialize() async {}

  @override
  bool get rewardedReady => earn;

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    rewarded.add(kind);
    return earn;
  }

  @override
  Future<void> onLevelCompleted(int level) async => completedLevels.add(level);

  @override
  Widget buildBanner() => adsRemoved
      ? const SizedBox.shrink()
      : const SizedBox(key: Key('banner'), height: 50);

  @override
  Future<bool> privacyOptionsRequired() async => true;

  @override
  Future<void> showPrivacyOptions() async {}
}

/// A store that succeeds instantly and reports entitlements.
class FakePurchaseService implements PurchaseService {
  final _changes = StreamController<Entitlements>.broadcast();
  Entitlements _entitlements = const Entitlements();
  PurchaseStatus next = PurchaseStatus.success;
  final bought = <String>[];

  void grant(String entitlement) {
    _entitlements = Entitlements(
      active: {..._entitlements.active, entitlement},
    );
    _changes.add(_entitlements);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify(String userId) async {}

  @override
  bool get available => true;

  @override
  Entitlements get entitlements => _entitlements;

  @override
  Stream<Entitlements> get entitlementChanges => _changes.stream;

  @override
  Future<List<ProductInfo>> loadProducts() async => [
    for (final d in Products.all) ProductInfo(d, price: '€1.00'),
  ];

  @override
  Future<PurchaseOutcome> buy(String productId) async {
    bought.add(productId);
    if (next == PurchaseStatus.success) {
      final entitlement = Products.byId(productId)?.entitlement;
      if (entitlement != null) grant(entitlement);
    }
    return PurchaseOutcome(next);
  }

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome(next);
}

/// Serves fixed levels, so tests don't depend on the shipped content.
class FakeLevelRepository implements LevelRepository {
  FakeLevelRepository(this.levels);

  final List<Level> levels;

  @override
  int get count => levels.length;

  @override
  Future<Level> load(int number) async => levels[number - 1];
}

/// Fixed "now" for tests: Thursday 29 Oct 2026, 21:30.
final testNow = DateTime(2026, 10, 29, 21, 30);

List<Override> testOverrides({
  RecordingHaptics? haptics,
  RecordingSound? sound,
  List<Level>? levels,
  Level? daily,
  DateTime? now,
  AnalyticsService? analytics,
  AdService? ads,
  PurchaseService? purchases,
  SaveData? save,
}) => [
  analyticsProvider.overrideWithValue(analytics ?? RecordingAnalytics()),
  adServiceProvider.overrideWithValue(ads ?? FakeAdService()),
  if (purchases != null) purchaseServiceProvider.overrideWithValue(purchases),
  if (save != null) initialSaveProvider.overrideWithValue(LoadedSave(save)),
  hapticsProvider.overrideWithValue(haptics ?? RecordingHaptics()),
  soundProvider.overrideWithValue(sound ?? RecordingSound()),
  clockProvider.overrideWithValue(() => now ?? testNow),
  // The real generator runs in an isolate, which fake-async tests can't
  // wait for; serve a known level instead.
  dailyLevelGeneratorProvider.overrideWithValue(
    (key) async => (daily ?? levels?.first ?? sampleLevels.first).copyWith(
      id: DailyChallenge.idFor(DailyChallenge.parseKey(key)),
    ),
  ),
  if (levels != null)
    levelRepositoryProvider.overrideWithValue(FakeLevelRepository(levels)),
];

Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  List<Level>? levels,
  Level? daily,
  AdService? ads,
  PurchaseService? purchases,
  SaveData? save,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(
          levels: levels,
          daily: daily,
          ads: ads,
          purchases: purchases,
          save: save,
        ),
        ...overrides,
      ],
      child: const ArrowEscapeApp(),
    ),
  );
}

/// Taps the centre of [piece]'s head cell on the visible board.
Future<void> tapPiece(WidgetTester tester, Level level, int piece) async {
  final finder = find.byType(BoardView);
  final box = tester.renderObject<RenderBox>(finder);
  final layout = BoardLayout(level, box.size);
  final local = layout.centerOf(level.pieces[piece].head);
  await tester.tapAt(box.localToGlobal(local));
  await tester.pump();
}

/// Lets animations and the result-card delay finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

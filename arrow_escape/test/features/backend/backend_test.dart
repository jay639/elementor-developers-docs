import 'package:arrow_escape/features/backend/application/cloud_sync.dart';
import 'package:arrow_escape/features/backend/data/backend.dart';
import 'package:arrow_escape/features/backend/domain/save_merge.dart';
import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/data/save_repository.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryCloud implements CloudSaveService {
  MemoryCloud([this.stored]);

  SaveData? stored;
  int pushes = 0;

  @override
  Future<SaveData?> fetch(String uid) async => stored;

  @override
  Future<void> push(String uid, SaveData save) async {
    stored = save;
    pushes++;
  }
}

void main() {
  group('mergeSaves', () {
    const local = SaveData(
      cloudSynced: true,
      progress: Progress(
        unlocked: 30,
        stars: {1: 3, 2: 1},
        dailyStars: {'d1': 2},
      ),
      coins: 100,
      ownedSkins: ['classic', 'ocean'],
      selectedSkin: 'ocean',
      updatedAt: 1000,
      revision: 5,
    );
    const remote = SaveData(
      progress: Progress(
        unlocked: 25,
        stars: {2: 3, 3: 2},
        dailyStars: {'d2': 1},
      ),
      coins: 40,
      ownedSkins: ['classic', 'gold'],
      selectedSkin: 'gold',
      updatedAt: 2000,
      revision: 9,
      claimedBundles: ['starter_bundle'],
    );

    test('a fresh install adopts cloud balances plus what it earned', () {
      final fresh = local.copyWith(
        cloudSynced: false,
        coins: 25,
        updatedAt: 9999,
      );
      final m = mergeSaves(fresh, remote);
      expect(m.coins, 65, reason: 'cloud 40 + 25 earned since install');
      expect(m.selectedSkin, 'gold');
    });

    test('progress grows to the best of both', () {
      final m = mergeSaves(local, remote);
      expect(m.progress.unlocked, 30);
      expect(m.progress.stars, {1: 3, 2: 3, 3: 2});
      expect(m.progress.dailyStars, {'d1': 2, 'd2': 1});
    });

    test('owned things are unioned', () {
      final m = mergeSaves(local, remote);
      expect(m.ownedSkins, ['classic', 'gold', 'ocean']);
      expect(m.claimedBundles, ['starter_bundle']);
    });

    test('balances come from the newer copy', () {
      expect(mergeSaves(local, remote).coins, 40);
      expect(mergeSaves(local, remote).selectedSkin, 'gold');
      final older = remote.copyWith(updatedAt: 10);
      expect(mergeSaves(local, older).coins, 100);
      expect(mergeSaves(local, remote).revision, 9);
    });

    test('is symmetric for progress and idempotent', () {
      final a = mergeSaves(local, remote);
      final b = mergeSaves(remote, local);
      expect(a.progress, b.progress);
      expect(mergeSaves(a, a), a);
    });
  });

  group('CloudSync', () {
    ProviderContainer container(SaveData local) {
      final c = ProviderContainer(
        overrides: [
          initialSaveProvider.overrideWithValue(LoadedSave(local)),
          saveRepositoryProvider.overrideWithValue(InMemorySaveRepository()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('first sync uploads a new player\'s save', () async {
      final c = container(const SaveData(coins: 7));
      final cloud = MemoryCloud();
      final sync = CloudSync(
        uid: 'u',
        cloud: cloud,
        controller: c.read(saveProvider.notifier),
      );
      await sync.start();
      expect(cloud.stored?.coins, 7);
      await sync.dispose();
    });

    test('restores progress from the cloud on a new install', () async {
      final c = container(const SaveData());
      final cloud = MemoryCloud(
        const SaveData(
          progress: Progress(unlocked: 90),
          coins: 300,
          updatedAt: 5,
        ),
      );
      final sync = CloudSync(
        uid: 'u',
        cloud: cloud,
        controller: c.read(saveProvider.notifier),
      );
      await sync.start();
      expect(c.read(saveProvider).progress.unlocked, 90);
      expect(c.read(saveProvider).coins, 300);
      expect(c.read(saveProvider).cloudSynced, isTrue);
      await sync.dispose();
    });

    test(
      'changes are pushed after the debounce, and flush pushes now',
      () async {
        final c = container(const SaveData());
        final cloud = MemoryCloud(const SaveData());
        final sync = CloudSync(
          uid: 'u',
          cloud: cloud,
          controller: c.read(saveProvider.notifier),
          debounce: const Duration(milliseconds: 20),
        );
        await sync.start();
        final before = cloud.pushes;
        c.read(saveProvider.notifier).addCoins(5, reason: 'test');
        c.read(saveProvider.notifier).addCoins(5, reason: 'test');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(cloud.pushes, before + 1, reason: 'debounced into one push');
        expect(cloud.stored?.coins, 10);
        c.read(saveProvider.notifier).addCoins(1, reason: 'test');
        await sync.flush();
        expect(cloud.stored?.coins, 11);
        await sync.dispose();
      },
    );
  });

  test('offline defaults', () async {
    expect(await OfflineAuth().signIn(), isNull);
    expect(await OfflineCloudSave().fetch('u'), isNull);
    expect(const DefaultRemoteConfig().interstitial.minLevel, 10);
  });
}

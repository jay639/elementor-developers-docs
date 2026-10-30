import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/data/save_repository.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveCodec', () {
    final codec = SaveCodec(List.generate(32, (i) => i));
    final save = const SaveData(coins: 420, ownedSkins: ['classic', 'gold']);

    test('round trips a signed save', () {
      final json = codec.encode(save);
      final loaded = codec.decode(json, codec.sign(json));
      expect(loaded.tampered, isFalse);
      expect(loaded.save, save);
    });

    test('an edited file is detected and the economy reset', () {
      final json = codec.encode(save);
      final sig = codec.sign(json);
      final edited = json.replaceFirst('420', '999999');
      final loaded = codec.decode(edited, sig);
      expect(loaded.tampered, isTrue);
      expect(loaded.save.coins, 0);
      expect(loaded.save.ownedSkins, ['classic']);
    });

    test('a different key does not verify', () {
      final json = codec.encode(save);
      final other = SaveCodec(List.filled(32, 7));
      expect(other.verify(json, codec.sign(json)), isFalse);
    });

    test('missing or garbage data starts fresh', () {
      expect(codec.decode(null, null).save, const SaveData());
      final junk = codec.decode('{not json', 'x');
      expect(junk.save, const SaveData());
      expect(junk.tampered, isFalse);
    });

    test('progress survives tampering', () {
      final s = save.copyWith.progress(unlocked: 77);
      final json = codec.encode(s);
      expect(codec.decode(json, 'bad').save.progress.unlocked, 77);
    });
  });

  group('SaveController', () {
    test(
      'persists every change with a bumped revision and timestamp',
      () async {
        final repo = InMemorySaveRepository();
        final now = DateTime(2026, 10, 29, 12);
        final c = ProviderContainer(
          overrides: [
            saveRepositoryProvider.overrideWithValue(repo),
            clockProvider.overrideWithValue(() => now),
          ],
        );
        addTearDown(c.dispose);
        final ctrl = c.read(saveProvider.notifier);
        ctrl.addCoins(10);
        ctrl.addCoins(5);
        await ctrl.flush();
        expect(repo.data!.coins, 15);
        expect(repo.data!.revision, 2);
        expect(repo.data!.updatedAt, now.millisecondsSinceEpoch);
        expect(repo.writes, 2);
      },
    );

    test('no-op changes are not written', () async {
      final repo = InMemorySaveRepository();
      final c = ProviderContainer(
        overrides: [saveRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.read(saveProvider.notifier).selectSkin('gold'); // not owned
      await c.read(saveProvider.notifier).flush();
      expect(repo.writes, 0);
    });

    test('starts from the loaded save', () {
      final c = ProviderContainer(
        overrides: [
          initialSaveProvider.overrideWithValue(
            const LoadedSave(SaveData(coins: 9)),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(saveProvider).coins, 9);
    });

    test('a failing disk never breaks the game', () async {
      final c = ProviderContainer(
        overrides: [saveRepositoryProvider.overrideWithValue(_Broken())],
      );
      addTearDown(c.dispose);
      c.read(saveProvider.notifier).addCoins(1);
      await c.read(saveProvider.notifier).flush();
      expect(c.read(saveProvider).coins, 1);
    });
  });
}

class _Broken implements SaveRepository {
  @override
  Future<LoadedSave> load() async => const LoadedSave(SaveData());

  @override
  Future<void> save(SaveData data) async => throw StateError('disk full');
}

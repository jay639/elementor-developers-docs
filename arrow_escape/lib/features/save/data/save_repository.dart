import 'dart:convert';
import 'dart:math';

import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// What [SaveRepository.load] found.
class LoadedSave {
  const LoadedSave(this.save, {this.tampered = false});

  final SaveData save;

  /// The signature didn't match: someone edited the file. Coins and
  /// purchased-with-coins skins were reset; progress was kept.
  final bool tampered;
}

abstract interface class SaveRepository {
  Future<LoadedSave> load();
  Future<void> save(SaveData data);
}

class InMemorySaveRepository implements SaveRepository {
  InMemorySaveRepository([this.data]);

  SaveData? data;
  int writes = 0;

  @override
  Future<LoadedSave> load() async => LoadedSave(data ?? const SaveData());

  @override
  Future<void> save(SaveData data) async {
    this.data = data;
    writes++;
  }
}

/// Serialises a save and signs it with HMAC-SHA256 so edits to the stored
/// file are detected.
class SaveCodec {
  SaveCodec(List<int> hmacKey) : _hmac = Hmac(sha256, hmacKey);

  final Hmac _hmac;

  String encode(SaveData data) => jsonEncode(data.toJson());

  String sign(String json) => _hmac.convert(utf8.encode(json)).toString();

  bool verify(String json, String signature) {
    final expected = sign(json);
    // Constant-time comparison.
    if (expected.length != signature.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ signature.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Decodes a stored save. A bad signature keeps progress and settings
  /// but resets the economy, which is what cheaters edit.
  LoadedSave decode(String? json, String? signature) {
    if (json == null) return const LoadedSave(SaveData());
    SaveData data;
    try {
      data = SaveData.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
    } catch (e) {
      debugPrint('Save unreadable, starting fresh: $e');
      return const LoadedSave(SaveData());
    }
    if (signature != null && verify(json, signature)) return LoadedSave(data);
    return LoadedSave(
      data.copyWith(
        coins: 0,
        ownedSkins: const ['classic'],
        selectedSkin: 'classic',
      ),
      tampered: true,
    );
  }
}

/// Local save in an AES-encrypted Hive box. The box key and the HMAC key
/// are random per install and live in the platform keystore
/// (Keychain / Android Keystore) via flutter_secure_storage.
class HiveSaveRepository implements SaveRepository {
  HiveSaveRepository._(this._box, this._codec);

  static const _boxName = 'arrow_save';
  static const _boxKey = 'save_box_key_v1';
  static const _hmacKey = 'save_hmac_key_v1';

  final Box<String> _box;
  final SaveCodec _codec;

  static Future<HiveSaveRepository> open({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) async {
    await Hive.initFlutter();
    final boxKey = await _secret(storage, _boxKey);
    final hmacKey = await _secret(storage, _hmacKey);
    final box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(boxKey),
    );
    return HiveSaveRepository._(box, SaveCodec(hmacKey));
  }

  static Future<List<int>> _secret(
    FlutterSecureStorage storage,
    String name,
  ) async {
    final existing = await storage.read(key: name);
    if (existing != null) return base64Decode(existing);
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    await storage.write(key: name, value: base64Encode(key));
    return key;
  }

  @override
  Future<LoadedSave> load() async =>
      _codec.decode(_box.get('data'), _box.get('sig'));

  @override
  Future<void> save(SaveData data) async {
    final json = _codec.encode(data);
    await _box.putAll({'data': json, 'sig': _codec.sign(json)});
  }
}

/// Overridden in bootstrap with the opened repository.
final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => InMemorySaveRepository(),
);

/// The save as loaded at start-up. Overridden in bootstrap.
final initialSaveProvider = Provider<LoadedSave>(
  (ref) => const LoadedSave(SaveData()),
);

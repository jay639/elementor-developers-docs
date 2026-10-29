import 'dart:convert';
import 'dart:io';

import 'package:arrow_engine/arrow_engine.dart';

/// Contents of `assets/levels/manifest.json`.
class PackManifest {
  const PackManifest({
    required this.count,
    required this.packSize,
    required this.packs,
    required this.seed,
  });

  static const version = 1;

  final int count;
  final int packSize;
  final List<String> packs;
  final int seed;

  Map<String, Object> toJson() => {
    'version': version,
    'count': count,
    'packSize': packSize,
    'seed': seed,
    'packs': packs,
  };

  static PackManifest fromJson(Map<String, Object?> json) => PackManifest(
    count: json['count'] as int,
    packSize: json['packSize'] as int,
    seed: json['seed'] as int,
    packs: (json['packs'] as List).cast<String>(),
  );
}

/// gzip at the highest level: the assets ship inside the app.
final _gzip = GZipCodec(level: 9);

List<int> compressPack(List<Level> levels) =>
    _gzip.encode(utf8.encode(encodeLevelPack(levels)));

List<Level> decompressPack(List<int> bytes) =>
    decodeLevelPack(utf8.decode(_gzip.decode(bytes)));

void writePacks(Directory dir, List<Level> levels, {required int packSize}) {
  dir.createSync(recursive: true);
  final names = <String>[];
  for (var start = 0; start < levels.length; start += packSize) {
    final end = (start + packSize).clamp(0, levels.length);
    final name = Campaign.packFile(start ~/ packSize + 1);
    File(
      '${dir.path}/$name',
    ).writeAsBytesSync(compressPack(levels.sublist(start, end)));
    names.add(name);
  }
  final manifest = PackManifest(
    count: levels.length,
    packSize: packSize,
    packs: names,
    seed: Campaign.seed,
  );
  File('${dir.path}/manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
}

List<Level> readPacks(Directory dir) {
  final manifest = PackManifest.fromJson(
    (jsonDecode(File('${dir.path}/manifest.json').readAsStringSync()) as Map)
        .cast<String, Object?>(),
  );
  return [
    for (final name in manifest.packs)
      ...decompressPack(File('${dir.path}/$name').readAsBytesSync()),
  ];
}

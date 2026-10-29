import 'dart:io';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_tool/arrow_tool.dart';
import 'package:test/test.dart';

void main() {
  final campaign = [for (var n = 1; n <= 30; n++) Campaign.build(n)];

  test('packs round trip through gzip and the manifest', () {
    final dir = Directory.systemTemp.createTempSync('packs');
    addTearDown(() => dir.deleteSync(recursive: true));
    writePacks(dir, campaign, packSize: 12);
    expect(File('${dir.path}/pack_03.json.gz').existsSync(), isTrue);
    final back = readPacks(dir);
    expect(
      [for (final l in back) l.toJson()],
      [for (final l in campaign) l.toJson()],
    );
  });

  test('a real campaign slice verifies clean', () {
    expect(verifyCampaign(campaign), isEmpty);
  });

  test('detects wrong ids, early mechanics and bad breather flags', () {
    final broken = [...campaign];
    broken[6] = broken[6].copyWith(id: 99);
    broken[7] = parseAsciiLevel(
      id: 8,
      '>.r.',
      meta: const LevelMeta(difficulty: 0),
    );
    broken[8] = broken[8].copyWith(
      meta: broken[8].meta.copyWith(breather: true),
    );
    final problems = verifyCampaign(broken);
    expect(problems, contains('L7: id is 99'));
    expect(problems.any((p) => p.startsWith('L8: lights before')), isTrue);
    expect(problems, contains('L9: breather flag is true'));
  });

  test('detects unsolvable levels', () {
    final broken = [...campaign];
    broken[3] = parseAsciiLevel(id: 4, '>.<');
    expect(verifyCampaign(broken), contains('L4: unsolvable'));
  });

  test('drawLevel shows heads, bodies, lights and gates', () {
    final level = parseAsciiLevel(
      '''
.g.
..6
''',
      vehicles: [
        (kind: PieceKind.truck, dir: Dir.up, cells: [(0, 0), (0, 1)]),
      ],
    );
    expect(drawLevel(level), '^g.\nA.6');
  });

  test('report has one row per 100 levels', () {
    final report = campaignReport(campaign);
    expect(report.trim().split('\n'), hasLength(2));
  });
}

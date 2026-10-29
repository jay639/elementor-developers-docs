import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_tool/arrow_tool.dart';

/// Generates the campaign into gzip-compressed JSON packs.
///
///   dart run bin/generate_levels.dart [--count 1500] [--out ../assets/levels]
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('count', defaultsTo: '${Campaign.levelCount}')
    ..addOption('out', defaultsTo: '../assets/levels')
    ..addOption(
      'jobs',
      defaultsTo: '${Platform.numberOfProcessors}',
      help: 'Parallel isolates.',
    )
    ..addFlag('verify', defaultsTo: true, help: 'Verify after generating.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final opts = parser.parse(args);
  if (opts.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }
  final count = int.parse(opts.option('count')!);
  final jobs = int.parse(opts.option('jobs')!).clamp(1, 64);
  final out = Directory(opts.option('out')!);

  final sw = Stopwatch()..start();
  final chunk = (count / jobs).ceil();
  final parts = await Future.wait([
    for (var start = 1; start <= count; start += chunk)
      Isolate.run(() {
        final end = (start + chunk - 1).clamp(1, count);
        return [for (var n = start; n <= end; n++) Campaign.build(n).toJson()];
      }),
  ]);
  final levels = [
    for (final part in parts)
      for (final json in part) Level.fromJson(json),
  ];
  stdout.writeln(
    'Generated ${levels.length} levels in ${sw.elapsed.inSeconds}s '
    'with $jobs isolates.',
  );

  writePacks(out, levels, packSize: Campaign.packSize);
  final bytes = out.listSync().whereType<File>().fold<int>(
    0,
    (a, f) => a + f.lengthSync(),
  );
  stdout
    ..writeln('Wrote ${out.path} (${(bytes / 1024).toStringAsFixed(0)} KB)')
    ..writeln()
    ..writeln(campaignReport(levels));

  if (opts.flag('verify')) {
    final problems = verifyCampaign(readPacks(out));
    if (problems.isEmpty) {
      stdout.writeln('Verification passed.');
    } else {
      stderr.writeln('Verification FAILED:');
      problems.take(40).forEach((p) => stderr.writeln('  $p'));
      exitCode = 1;
    }
  }
}

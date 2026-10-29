import 'dart:io';

import 'package:args/args.dart';
import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_tool/arrow_tool.dart';

/// Prints a level and its solver stats.
///
///   dart run bin/show_level.dart 42
///   dart run bin/show_level.dart --daily 2026-11-01
void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('dir', defaultsTo: '../assets/levels')
    ..addOption('daily', help: 'yyyy-mm-dd');
  final opts = parser.parse(args);
  final Level level;
  if (opts.option('daily') case final key?) {
    level = DailyChallenge.levelFor(DailyChallenge.parseKey(key));
  } else if (opts.rest.isNotEmpty) {
    final n = int.parse(opts.rest.first);
    level = readPacks(Directory(opts.option('dir')!))[n - 1];
  } else {
    stderr.writeln('Usage: show_level <number> | --daily yyyy-mm-dd');
    exitCode = 64;
    return;
  }
  final m = level.meta;
  stdout
    ..writeln(
      'Level ${level.id} — ${m.shape}, ${level.width}x${level.height}'
      '${m.breather ? ', breather' : ''}',
    )
    ..writeln(drawLevel(level))
    ..writeln(analyzeLevel(level));
}

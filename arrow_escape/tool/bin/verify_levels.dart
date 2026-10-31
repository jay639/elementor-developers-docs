import 'dart:io';

import 'package:args/args.dart';
import 'package:arrow_tool/arrow_tool.dart';

/// Re-solves every shipped level and checks the campaign rules.
///
///   dart run bin/verify_levels.dart [--dir ../assets/levels]
void main(List<String> args) {
  final parser = ArgParser()..addOption('dir', defaultsTo: '../assets/levels');
  final opts = parser.parse(args);
  final levels = readPacks(Directory(opts.option('dir')!));
  stdout
    ..writeln('Checking ${levels.length} levels…')
    ..writeln(campaignReport(levels));
  final problems = [
    ...verifyCampaign(levels),
    ...verifyPuzzles(readPuzzles(Directory(opts.option('dir')!))),
  ];
  if (problems.isEmpty) {
    stdout.writeln('All checks passed.');
    return;
  }
  for (final p in problems) {
    stderr.writeln(p);
  }
  exitCode = 1;
}
